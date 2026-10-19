package com.example.healthmate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private lateinit var privateData: PrivateLocalData
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        privateData = PrivateLocalData(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "healthmate/private_local_data")
            .setMethodCallHandler(privateData)
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::privateData.isInitialized && privateData.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}
