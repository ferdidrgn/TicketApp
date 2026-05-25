package com.ferdidrgn.ticketapp

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Native katmanda tam ekran geçiş pencerelerini temizle
        WindowCompat.setDecorFitsSystemWindows(window, false)

        super.onCreate(savedInstanceState)

        // TargetSDK 37 / Android 15+ cihazlarda sistem navigasyon çubuklarının
        // şeffaflık ve kontrast korumalarını native düzeyde yönetir
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
    }
}