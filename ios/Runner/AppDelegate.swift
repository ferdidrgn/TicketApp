import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TODO(maps): GERÇEK bir Google Maps API anahtarı YOK (sahte/uydurma bir
    // anahtar bilerek eklenmedi). `google_maps_flutter` iOS'ta bu anahtar
    // olmadan haritayı gösteremez (bkz. stage_details.dart,
    // nearby_events_page.dart). Kurulum: Google Cloud Console'da
    // "Maps SDK for iOS" için bir anahtar oluştur, `import GoogleMaps` ekle
    // ve burada `GMSServices.provideAPIKey("GERÇEK_ANAHTAR")` çağır —
    // anahtarı commit edilmeyen bir yapılandırma dosyasından oku.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
