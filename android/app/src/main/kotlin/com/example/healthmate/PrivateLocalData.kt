package com.example.healthmate

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** No plaintext disk cache, external-storage permission, or automatic sharing. */
class PrivateLocalData(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private var pickerResult: MethodChannel.Result? = null
    private val documents = mutableMapOf<String, Uri>()
    companion object { const val REQUEST_CSV = 6271 }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "chooseCsv") {
            if (pickerResult != null) { result.error("busy", "Hộp chọn tệp đang mở.", null); return }
            pickerResult = result
            try {
                val filename = call.argument<String>("filename") ?: "HealthMate.csv"
                require(Regex("HealthMate-[0-9-]+\\.csv").matches(filename))
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "text/csv"
                    putExtra(Intent.EXTRA_TITLE, filename)
                }
                activity.startActivityForResult(intent, REQUEST_CSV)
            } catch (_: Exception) {
                pickerResult = null
                result.error("picker", "Không mở được hộp chọn nơi lưu.", null)
            }
            return
        }
        worker.execute {
            try {
                val value: Any? = when (call.method) {
                    "readDrafts" -> read(uid(call))
                    "writeDrafts" -> {
                        val uid = uid(call)
                        val json = requireNotNull(call.argument<String>("json"))
                        require(json.toByteArray(Charsets.UTF_8).size <= 512 * 1024)
                        write(uid, json); null
                    }
                    "clearDrafts" -> {
                        val uid = uid(call)
                        file(uid).delete()
                        keyStore().deleteEntry(alias(uid))
                        null
                    }
                    "writeCsv" -> {
                        val ticket = requireNotNull(call.argument<String>("ticket"))
                        val uri = synchronized(documents) { documents.remove(ticket) }
                            ?: error("Document ticket expired")
                        val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                        require(bytes.size <= 5 * 1024 * 1024)
                        try {
                            activity.contentResolver.openOutputStream(uri, "wt")!!.use { it.write(bytes) }
                            val restored = activity.contentResolver.openInputStream(uri)!!.use {
                                it.readBytesLimited(5 * 1024 * 1024)
                            }
                            check(bytes.contentEquals(restored))
                            bytes.size
                        } catch (e: Exception) {
                            try { android.provider.DocumentsContract.deleteDocument(activity.contentResolver, uri) }
                            catch (_: Exception) { /* Provider may require manual removal; report failure. */ }
                            throw e
                        }
                    }
                    "cancelCsv" -> {
                        val ticket = requireNotNull(call.argument<String>("ticket"))
                        val uri = synchronized(documents) { documents.remove(ticket) }
                        if (uri != null) android.provider.DocumentsContract.deleteDocument(activity.contentResolver, uri)
                        null
                    }
                    else -> { activity.runOnUiThread { result.notImplemented() }; return@execute }
                }
                activity.runOnUiThread { result.success(value) }
            } catch (_: Exception) {
                // Do not log UID, draft JSON, exported rows, URIs, or encryption internals.
                activity.runOnUiThread {
                    result.error("private_data", "Không thể đọc/ghi dữ liệu riêng trên thiết bị. Không xác nhận đã lưu; hãy thử lại.", null)
                }
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CSV) return false
        val pending = pickerResult ?: return true
        pickerResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) pending.success(null)
        else {
            val ticket = UUID.randomUUID().toString()
            synchronized(documents) { documents[ticket] = uri }
            pending.success(ticket)
        }
        return true
    }

    private fun uid(call: MethodCall): String {
        val uid = requireNotNull(call.argument<String>("uid"))
        require(uid.isNotBlank() && uid.length <= 128)
        return uid
    }
    private fun alias(uid: String) = "hm-draft-v1-" + MessageDigest.getInstance("SHA-256")
        .digest(uid.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
    private fun file(uid: String) = AtomicFile(File(activity.noBackupFilesDir, alias(uid) + ".enc"))
    private fun keyStore() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private fun key(uid: String, create: Boolean): SecretKey {
        val store = keyStore()
        (store.getKey(alias(uid), null) as? SecretKey)?.let { return it }
        check(create) // Never replace a missing key and pretend an old draft is empty.
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias(uid), KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256).build())
        }.generateKey()
    }
    private fun read(uid: String): String? {
        val target = file(uid)
        if (!target.baseFile.exists() && !File(target.baseFile.path + ".bak").exists()) return null
        val bytes = target.openRead().use { it.readBytesLimited(513 * 1024) }
        require(bytes.size >= 29 && bytes[0].toInt() == 1)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(uid, false), GCMParameterSpec(128, bytes.copyOfRange(1, 13)))
        cipher.updateAAD(uid.toByteArray(Charsets.UTF_8))
        return String(cipher.doFinal(bytes.copyOfRange(13, bytes.size)), Charsets.UTF_8)
    }
    private fun write(uid: String, json: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key(uid, true))
        cipher.updateAAD(uid.toByteArray(Charsets.UTF_8))
        check(cipher.iv.size == 12)
        val bytes = byteArrayOf(1) + cipher.iv + cipher.doFinal(json.toByteArray(Charsets.UTF_8))
        val target = file(uid)
        val stream = target.startWrite()
        try { stream.write(bytes); target.finishWrite(stream) }
        catch (e: Exception) { target.failWrite(stream); throw e }
    }
    private fun java.io.InputStream.readBytesLimited(limit: Int): ByteArray {
        val buffer = java.io.ByteArrayOutputStream()
        val part = ByteArray(8192)
        while (true) {
            val count = read(part)
            if (count < 0) break
            check(buffer.size() + count <= limit)
            buffer.write(part, 0, count)
        }
        return buffer.toByteArray()
    }
}
