package com.wafrat.elysium

import android.content.Intent
import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity(): FlutterActivity() {
  private var sharedText: String? = null
  private var sharedImage: ByteArray? = null;
  private var sharedImageFilename: String? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    val action = intent.action
    val type = intent.type

    if (Intent.ACTION_SEND.equals(action) && type != null) {
      if ("text/plain".equals(type)) {
        handleSendText(intent)
      } else {
        handleSendImage(intent)
      }
    }

    MethodChannel(flutterView, "app.channel.shared.data")
            .setMethodCallHandler { call, result ->
              if (call.method.contentEquals("getSharedText")) {
                result.success(sharedText)
                sharedText = null
              }
              if (call.method.contentEquals("getSharedImage")) {
                result.success(sharedImage)
                sharedImage = null
              }
              if (call.method.contentEquals("getSharedImageFilename")) {
                result.success(sharedImageFilename)
                sharedImageFilename = null
              }
            }
  }

  fun handleSendText(intent : Intent) {
    sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
  }

  fun handleSendImage(intent : Intent) {
    val uri = intent.getClipData().getItemAt(0).getUri()
    val inputStream = contentResolver.openInputStream(uri)
    sharedImage = inputStream.readBytes()
    // TODO: Fix. This is not the actual filename.
    sharedImageFilename = uri.path
  }
}
