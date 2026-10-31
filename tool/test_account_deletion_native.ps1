param(
  [string]$JavaHome='C:\Program Files\Android\Android Studio\jbr',
  [string]$GradleCache=(Join-Path $env:USERPROFILE '.gradle\caches\modules-2\files-2.1')
)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$run=Join-Path $repo ('build\account-deletion-native-host\'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $run 'android\content'),(Join-Path $run 'android\util'),(Join-Path $run 'classes') -Force | Out-Null
# Host-only adapters. These do not emulate Android keystore, sensor service,
# AlarmManager or its actual AtomicFile implementation. Compile the production
# AccountDeletionBlock source unchanged against this filesystem contract.
@'
package android.content;
import java.io.File;
public class Context {
  private final File dir;
  public Context(File dir) { this.dir=dir; dir.mkdirs(); }
  public File getNoBackupFilesDir() { return dir; }
}
'@ | Set-Content -LiteralPath (Join-Path $run 'android\content\Context.java') -Encoding utf8
@'
package android.util;
import java.io.*;
import java.nio.file.*;
public class AtomicFile {
  private final File file;
  public AtomicFile(File file) { this.file=file; }
  public File getBaseFile() { return file; }
  public FileOutputStream startWrite() throws IOException {
    file.getParentFile().mkdirs(); return new FileOutputStream(file.getPath()+".new");
  }
  public void finishWrite(FileOutputStream stream) throws IOException {
    stream.close(); Files.move(Path.of(file.getPath()+".new"), file.toPath(), StandardCopyOption.REPLACE_EXISTING);
  }
  public void failWrite(FileOutputStream stream) throws IOException {
    stream.close(); new File(file.getPath()+".new").delete();
  }
}
'@ | Set-Content -LiteralPath (Join-Path $run 'android\util\AtomicFile.java') -Encoding utf8
@'
package com.example.healthmate
import android.content.Context
import java.io.File
import java.nio.file.Files
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

fun main() {
  val folder = Files.createTempDirectory("hm-native-deletion-").toFile()
  val context = Context(folder)
  val uid = "synthetic-native-account"
  var writes = 0
  AccountDeletionBlock.writeAllowed(context, uid) { writes++ }
  check(writes == 1 && !AccountDeletionBlock.isBlocked(context, uid))
  println("PASS 1: pre-deletion writer allowed")

  AccountDeletionBlock.mark(context, uid)
  check(AccountDeletionBlock.isBlocked(Context(folder), uid))
  val marker = folder.listFiles()!!.single()
  check(!marker.name.contains(uid) && marker.readBytes().contentEquals(byteArrayOf(1)))
  AccountDeletionBlock.mark(context, uid)
  check(folder.listFiles()!!.size == 1)
  check(runCatching { AccountDeletionBlock.writeAllowed(context, uid) { writes++ } }.isFailure)
  check(writes == 1)
  println("PASS 2: marker persists across context recreation, retry is idempotent and late writes fail")

  AccountDeletionBlock.writeAllowed(context, "another-uid") { writes++ }
  check(writes == 2)
  println("PASS 3: unrelated account is isolated")

  val interrupted = "interrupted-uid"
  val hash = MessageDigest.getInstance("SHA-256").digest(interrupted.toByteArray())
    .joinToString("") { "%02x".format(it) }
  File(folder, "hm-deleting-v1-$hash.new").writeBytes(byteArrayOf(1))
  check(AccountDeletionBlock.isBlocked(context, interrupted))
  check(runCatching { AccountDeletionBlock.writeAllowed(context, interrupted) { error("must not execute") } }.isFailure)
  println("PASS 4: interrupted marker fails closed")

  val entered = CountDownLatch(1)
  val release = CountDownLatch(1)
  val markAttempted = CountDownLatch(1)
  val marked = CountDownLatch(1)
  val racingUid = "racing-uid"
  val writer = thread {
    AccountDeletionBlock.writeAllowed(context, racingUid) {
      entered.countDown(); check(release.await(5, TimeUnit.SECONDS)); writes++
    }
  }
  check(entered.await(5, TimeUnit.SECONDS))
  val deletion = thread {
    markAttempted.countDown(); AccountDeletionBlock.mark(context, racingUid); marked.countDown()
  }
  check(markAttempted.await(5, TimeUnit.SECONDS))
  check(!marked.await(100, TimeUnit.MILLISECONDS))
  release.countDown(); writer.join(5000); deletion.join(5000)
  check(!writer.isAlive && !deletion.isAlive && marked.count == 0L)
  check(writes == 3)
  check(runCatching { AccountDeletionBlock.writeAllowed(context, racingUid) { writes++ } }.isFailure)
  check(writes == 3)
  println("PASS 5: marker serializes with an in-flight write and prevents subsequent writes")
  println("5/5 host contract tests passed; no Android runtime or keystore acceptance.")
}
'@ | Set-Content -LiteralPath (Join-Path $run 'DeletionBlockHost.kt') -Encoding utf8

function CachedJar([string]$group,[string]$module,[string]$version) {
  $folder=Join-Path $GradleCache "$group\$module\$version"
  $file=Get-ChildItem -LiteralPath $folder -Recurse -Filter '*.jar' | Select-Object -First 1
  if(-not $file){throw "Missing cached Kotlin compiler dependency $group/$module/$version"}
  return $file.FullName
}
$compiler=CachedJar 'org.jetbrains.kotlin' 'kotlin-compiler-embeddable' '2.3.20'
$stdlib=CachedJar 'org.jetbrains.kotlin' 'kotlin-stdlib' '2.3.20'
$compilerJars=@($compiler,$stdlib,
  (CachedJar 'org.jetbrains.kotlin' 'kotlin-script-runtime' '2.3.20'),
  (CachedJar 'org.jetbrains.kotlin' 'kotlin-daemon-embeddable' '2.3.20'),
  (CachedJar 'org.jetbrains.kotlin' 'kotlin-reflect' '2.2.10'),
  (CachedJar 'org.jetbrains.kotlinx' 'kotlinx-coroutines-core-jvm' '1.9.0'),
  (CachedJar 'org.jetbrains' 'annotations' '23.0.0'),
  (CachedJar 'org.jetbrains.intellij.deps' 'trove4j' '1.0.20200330'))
$java=Join-Path $JavaHome 'bin\java.exe'
$javac=Join-Path $JavaHome 'bin\javac.exe'
$classes=Join-Path $run 'classes'
& $javac -encoding UTF-8 -d $classes (Join-Path $run 'android\content\Context.java') (Join-Path $run 'android\util\AtomicFile.java')
if($LASTEXITCODE -ne 0){throw 'Cannot compile host adapters'}
$source=Join-Path $repo 'android\app\src\main\kotlin\com\example\healthmate\AccountDeletionBlock.kt'
& $java -cp ($compilerJars -join ';') org.jetbrains.kotlin.cli.jvm.K2JVMCompiler '-no-stdlib' '-no-reflect' '-jvm-target' '17' '-classpath' "$classes;$stdlib" '-d' $classes $source (Join-Path $run 'DeletionBlockHost.kt')
if($LASTEXITCODE -ne 0){throw 'Cannot compile production marker with host tests'}
& $java -cp "$classes;$stdlib" com.example.healthmate.DeletionBlockHostKt
if($LASTEXITCODE -ne 0){throw 'Native marker host contract failed'}
