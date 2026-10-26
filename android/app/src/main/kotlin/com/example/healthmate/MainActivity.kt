package com.example.healthmate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private lateinit var privateData: PrivateLocalData
    private lateinit var wellness: WellnessBridge
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        privateData = PrivateLocalData(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "healthmate/private_local_data")
            .setMethodCallHandler(privateData)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "healthmate/wellness")
        wellness = WellnessBridge(this, channel)
        channel.setMethodCallHandler(wellness)
        wellness.receiveIntent(intent)
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::privateData.isInitialized && privateData.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (::wellness.isInitialized) wellness.receiveIntent(intent)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (::wellness.isInitialized && wellness.onPermissionResult(requestCode, grantResults)) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
