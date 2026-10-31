package com.example.healthmate

import android.content.Context
import android.util.AtomicFile
import java.io.File
import java.security.MessageDigest

/** Local monotonic guard, shared by drafts, reminders and the sensor writer.
 * The hash only identifies a blocked account; no health payload is retained.
 * A no-backup marker survives process death, but not uninstall/clear app data.
 * The server tombstone remains the authority across devices/reinstallation.
 */
object AccountDeletionBlock {
    private fun target(context: Context, uid: String): AtomicFile {
        require(uid.isNotBlank() && uid.length <= 128)
        val hash = MessageDigest.getInstance("SHA-256")
            .digest(uid.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
        return AtomicFile(File(context.noBackupFilesDir, "hm-deleting-v1-$hash"))
    }

    @Synchronized fun isBlocked(context: Context, uid: String): Boolean {
        val file = target(context, uid).baseFile
        // Treat an interrupted marker write as blocked, never as a reset.
        return file.exists() || File(file.path + ".bak").exists() || File(file.path + ".new").exists()
    }

    @Synchronized fun mark(context: Context, uid: String) {
        if (isBlocked(context, uid)) return
        val file = target(context, uid)
        val stream = file.startWrite()
        try { stream.write(byteArrayOf(1)); file.finishWrite(stream) }
        catch (e: Exception) { file.failWrite(stream); throw e }
        check(isBlocked(context, uid))
    }

    @Synchronized fun <T> writeAllowed(context: Context, uid: String, action: () -> T): T {
        check(!isBlocked(context, uid)) { "Account deletion is in progress" }
        // This monitor spans the entire write: a marker cannot land between a
        // successful guard check and an AtomicFile commit from another instance.
        return action()
    }
}
