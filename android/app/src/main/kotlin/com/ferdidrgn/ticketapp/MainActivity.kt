import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        // Bu satır uygulamanın sistem çubuklarının altına uzanmasını sağlar
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}