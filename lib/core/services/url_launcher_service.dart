import 'package:url_launcher/url_launcher.dart';

mixin UrlLauncherService {
  static Future<void> launchUrl(final String url) async {
    if (await canLaunch(url)) await launch(url);
    else throw 'URL açılamadı: $url';
  }
}
