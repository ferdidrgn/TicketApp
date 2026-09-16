package com.ferdidrgn.ticketapp

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Native katmanda tam ekran geçiş pencerelerini temizle
        WindowCompat.setDecorFitsSystemWindows(window, false)

        super.onCreate(savedInstanceState)

        // NOT: window.isStatusBarContrastEnforced / isNavigationBarContrastEnforced
        // (ve styles.xml'deki android:statusBarColor/navigationBarColor) Android 15
        // (API 35) itibarıyla kullanımdan kaldırıldı (deprecated) — Google Play
        // Console "uçtan uca ekran" uyarısının kaynağı buydu. Edge-to-edge artık
        // Android 15+ cihazlarda varsayılan olarak zorunlu ve otomatik; eski
        // API'lerde de yukarıdaki setDecorFitsSystemWindows(false) çağrısı yeterli.
    }
}