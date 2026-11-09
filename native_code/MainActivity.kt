package com.sakapay.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sakapay.app/share"
    private var sharedData: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND) {
            val type = intent.type ?: return
            if (type.startsWith("image/")) {
                @Suppress("DEPRECATION")
                val imageUri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                imageUri?.let { uri ->
                    try {
                        val inputStream = contentResolver.openInputStream(uri)
                        val tempFile = File(cacheDir, "shared_image.jpg")
                        val outputStream = FileOutputStream(tempFile)
                        inputStream?.copyTo(outputStream)
                        inputStream?.close()
                        outputStream.close()
                        sharedData = "IMAGE:" + tempFile.absolutePath
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            } else if (type.startsWith("text/")) {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (text != null) {
                    sharedData = "TEXT:$text"
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSharedData") {
                result.success(sharedData)
                sharedData = null
            } else {
                result.notImplemented()
            }
        }
    }
}
