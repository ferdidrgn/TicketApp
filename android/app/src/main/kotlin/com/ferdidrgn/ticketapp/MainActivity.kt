package com.ferdidrgn.ticketapp

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Flutter yerleşmeden önce ekran ayarını yap
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}