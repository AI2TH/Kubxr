package com.ai2th.kubxr

import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ai2th.kubxr/vm"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val app = application as KubxrApp
        val vmManager = app.vmManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVm" -> {
                    Log.d(TAG, "MethodChannel: startVm")
                    startVmService()
                    result.success(null)
                }
                "stopVm" -> {
                    Log.d(TAG, "MethodChannel: stopVm")
                    stopVmService()
                    result.success(null)
                }
                "checkHealth" -> {
                    result.success(vmManager.checkHealth())
                }
                "getVmStatus" -> {
                    result.success(vmManager.getStatus())
                }
                "getKubeconfig" -> {
                    result.success(vmManager.getKubeconfig())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startVmService() {
        val intent = Intent(this, VmService::class.java).apply {
            action = "START"
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopVmService() {
        val intent = Intent(this, VmService::class.java).apply {
            action = "STOP"
        }
        startService(intent)
    }
}
