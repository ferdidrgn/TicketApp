import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';

class KadinlikBizdeKalsinLanding extends StatelessWidget {
  const KadinlikBizdeKalsinLanding({super.key});

  static const String _heroImage =
      'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg';

  static const String _youtubeVideoId = 'joEK2NmpwuM';
  static const String _youtubeUrl =
      'https://www.youtube.com/watch?v=$_youtubeVideoId&t=699s';
  static const String _youtubeThumbnail =
      'https://img.youtube.com/vi/$_youtubeVideoId/hqdefault.jpg';

  Future<void> _openYoutube() async {
    final uri = Uri.parse(_youtubeUrl);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(final BuildContext context) => Container(
        width: double.infinity,
        color: WebColors.darkBlueBackground,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: context.paddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  SizedBox(height: context.gridSpacing * 2),
                  context.isDesktop
                      ? _buildDesktopLayout(context)
                      : _buildMobileLayout(context),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader(final BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PRÖMİYER',
              style: TextStyle(
                fontSize: context.captionSize,
                fontWeight: FontWeight.w900,
                color: WebColors.darkBlueBackground,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(height: context.gridSpacing),
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'KADINLIK BİZDE KALSIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(mobile: 30.0, desktop: 52.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: context.isMobile ? 1.0 : 2.5,
              ),
            ),
          ),
        ],
      );

  Widget _buildDesktopLayout(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildHeroImage(context)),
          SizedBox(width: context.gridSpacing),
          Expanded(flex: 2, child: _buildMediaSection(context)),
        ],
      );

  Widget _buildMobileLayout(final BuildContext context) => Column(
        children: [
          _buildHeroImage(context),
          SizedBox(height: context.gridSpacing * 1.5),
          _buildMediaSection(context),
        ],
      );

  Widget _buildHeroImage(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(context.borderRadius(1.5)),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: OptimizedCachedImage(
            imageUrl: _heroImage,
            fit: BoxFit.cover,
            borderRadius: 0,
          ),
        ),
      );

  Widget _buildMediaSection(final BuildContext context) => Container(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 20.0)),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'MEDYA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.gridSpacing),
            Text(
              'Prömiyer öncesi tanıtım videomuzu izleyin.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: context.bodySize,
              ),
            ),
            SizedBox(height: context.gridSpacing),
            _buildYoutubeCard(context),
          ],
        ),
      );

  Widget _buildYoutubeCard(final BuildContext context) => InkWell(
        onTap: _openYoutube,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OptimizedCachedImage(
                  imageUrl: _youtubeThumbnail,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                ),
                Container(color: Colors.black.withOpacity(0.25)),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: WebColors.primaryGold.withOpacity(0.8),
                          width: 2),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
