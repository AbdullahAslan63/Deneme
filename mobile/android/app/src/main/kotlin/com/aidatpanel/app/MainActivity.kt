package com.aidatpanel.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val systemChannel = "com.aidatpanel.app/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Geri tuşunda Activity.finish() yerine task'i arka plana al.
                    // Böylece kullanıcı uygulamayı recents'tan swipe'lamadıkça
                    // process yaşamaya devam eder ve tekrar açılışta splash
                    // gözükmeden kaldığı yerden devam eder.
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
