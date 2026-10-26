package com.example.healthmate

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.json.JSONObject

/** Separate encrypted namespaces; never overwrites meal drafts. */
class WellnessStorage(private val context: Context) {
    private fun alias(uid: String, scope: String): String = "hm-wellness-v1-" +
        MessageDigest.getInstance("SHA-256").digest((scope + ":" + uid).toByteArray())
            .joinToString("") { "%02x".format(it) }
    private fun store() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private fun target(uid: String, scope: String) =
        AtomicFile(File(context.noBackupFilesDir, alias(uid, scope) + ".enc"))
    private fun key(uid: String, scope: String, create: Boolean): SecretKey {
        (store().getKey(alias(uid, scope), null) as? SecretKey)?.let { return it }
        check(create)
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias(uid, scope),
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).setKeySize(256).build())
        }.generateKey()
    }
    @Synchronized fun read(uid: String, scope: String): JSONObject {
        val file = target(uid, scope)
        if (!file.baseFile.exists() && !File(file.baseFile.path + ".bak").exists()) return JSONObject()
        val bytes = file.openRead().use { it.readBytes() }
        require(bytes.size in 29..524288 && bytes[0].toInt() == 1)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(uid, scope, false),
            GCMParameterSpec(128, bytes.copyOfRange(1, 13)))
        cipher.updateAAD((scope + ":" + uid).toByteArray())
        return JSONObject(String(cipher.doFinal(bytes.copyOfRange(13, bytes.size)), Charsets.UTF_8))
    }
    @Synchronized fun write(uid: String, scope: String, value: JSONObject) {
        val plain = value.toString().toByteArray(Charsets.UTF_8)
        require(plain.size <= 500000)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key(uid, scope, true))
        cipher.updateAAD((scope + ":" + uid).toByteArray())
        val bytes = byteArrayOf(1) + cipher.iv + cipher.doFinal(plain)
        val file = target(uid, scope); val stream = file.startWrite()
        try { stream.write(bytes); file.finishWrite(stream) }
        catch (e: Exception) { file.failWrite(stream); throw e }
    }
    @Synchronized fun clear(uid: String, scope: String) {
        target(uid, scope).delete(); store().deleteEntry(alias(uid, scope))
    }
    fun activeUid(): String? = read("device", "active").optString("uid").takeIf { it.isNotBlank() }
    fun setActive(uid: String?) = write("device", "active",
        JSONObject().apply { if (uid != null) put("uid", uid) })
}
