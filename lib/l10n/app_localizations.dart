import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @brand.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol'**
  String get brand;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @plays.
  ///
  /// In tr, this message translates to:
  /// **'Oyunlar'**
  String get plays;

  /// No description provided for @team.
  ///
  /// In tr, this message translates to:
  /// **'Ekibimiz'**
  String get team;

  /// No description provided for @tickets.
  ///
  /// In tr, this message translates to:
  /// **'Bilet Al'**
  String get tickets;

  /// No description provided for @upcomingPlays.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Oyunlar'**
  String get upcomingPlays;

  /// No description provided for @seoHomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol | Tiyatro ve Sanat Ekibi'**
  String get seoHomeTitle;

  /// No description provided for @seoHomeDesc.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol Ekibi\'nin sahnelediği tiyatro oyunları, oyuncu biyografileri, sahne arkası görselleri ve turne takvimi hakkında her şey.'**
  String get seoHomeDesc;

  /// No description provided for @seoPlaysTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyunlarımız | TiyatRol'**
  String get seoPlaysTitle;

  /// No description provided for @seoPlaysDesc.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol tarafından sahnelenen güncel tiyatro oyunlarını inceleyin ve biletinizi ayırtın.'**
  String get seoPlaysDesc;

  /// No description provided for @seoTeamTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekibimiz | TiyatRol'**
  String get seoTeamTitle;

  /// No description provided for @seoTeamDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sahne önünde ve arkasında emeği geçen yetenekli oyuncularımız ve teknik ekibimizle tanışın.'**
  String get seoTeamDesc;

  /// No description provided for @seoAboutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hakkımızda | TiyatRol'**
  String get seoAboutTitle;

  /// No description provided for @seoAboutDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sanata değer katan vizyonumuz ve sahne deneyimimizle TiyatRol\'ün hikayesi.'**
  String get seoAboutDesc;

  /// No description provided for @seoPlayDetailSuffix.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu İncele | TiyatRol'**
  String get seoPlayDetailSuffix;

  /// No description provided for @seoDiscoverTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Oyunları Keşfet | TiyatRol'**
  String get seoDiscoverTitle;

  /// No description provided for @seoDiscoverDesc.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol sahnesindeki en yeni prodüksiyonları, prömiyerleri ve sezonun öne çıkan oyunlarını keşfedin.'**
  String get seoDiscoverDesc;

  /// No description provided for @seoNearbyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Turne ve Sahneler | TiyatRol'**
  String get seoNearbyTitle;

  /// No description provided for @seoNearbyDesc.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol size en yakın hangi sahnede? Turne takvimimizi ve sahne alacağımız tiyatro salonlarını inceleyin.'**
  String get seoNearbyDesc;

  /// No description provided for @buyTicketAction.
  ///
  /// In tr, this message translates to:
  /// **'Biletini Hemen Al'**
  String get buyTicketAction;

  /// No description provided for @sharePlayMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu oyunu kaçırmamalısın!'**
  String get sharePlayMessage;

  /// No description provided for @galleryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Galeri boş'**
  String get galleryEmpty;

  /// No description provided for @searchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sanat Galerisi'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Sanatın kalbine bir adım at...'**
  String get searchHint;

  /// Arama sonucu bulunamadığında gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'\'{query}\' arayışına dair bir eser bulamadık.'**
  String searchEmptyState(String query);

  /// No description provided for @searchClearGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriyi Yenile'**
  String get searchClearGallery;

  /// No description provided for @searchFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get searchFilterAll;

  /// No description provided for @searchFilterShows.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get searchFilterShows;

  /// No description provided for @searchFilterPlayers.
  ///
  /// In tr, this message translates to:
  /// **'Sanatçılar'**
  String get searchFilterPlayers;

  /// No description provided for @searchFilterStages.
  ///
  /// In tr, this message translates to:
  /// **'Mekanlar'**
  String get searchFilterStages;

  /// No description provided for @searchFilterTeams.
  ///
  /// In tr, this message translates to:
  /// **'Topluluklar'**
  String get searchFilterTeams;

  /// No description provided for @searchSectionsShowsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sanatın Akışı'**
  String get searchSectionsShowsSubtitle;

  /// No description provided for @searchSectionsPlayersSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sahne Yıldızları'**
  String get searchSectionsPlayersSubtitle;

  /// No description provided for @searchSectionsStagesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sanatın Kalbi'**
  String get searchSectionsStagesSubtitle;

  /// No description provided for @searchSectionsTeamsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaratıcı Gruplar'**
  String get searchSectionsTeamsSubtitle;

  /// No description provided for @loginHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'SANATIN\nDÜNYASI'**
  String get loginHeroTitle;

  /// No description provided for @loginPhoneButton.
  ///
  /// In tr, this message translates to:
  /// **'TELEFON İLE DEVAM ET'**
  String get loginPhoneButton;

  /// No description provided for @loginGoogleButton.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Bağlan'**
  String get loginGoogleButton;

  /// No description provided for @loginTermsNotice.
  ///
  /// In tr, this message translates to:
  /// **'KOLEKSİYONA KATILARAK ŞARTLARI KABUL EDERSİNİZ'**
  String get loginTermsNotice;

  /// No description provided for @homeTooltipNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get homeTooltipNotifications;

  /// No description provided for @homeTooltipSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get homeTooltipSettings;

  /// No description provided for @homeErrorTitleMobile.
  ///
  /// In tr, this message translates to:
  /// **'Perdeler Henüz Açılmadı!'**
  String get homeErrorTitleMobile;

  /// No description provided for @homeErrorRetryMobile.
  ///
  /// In tr, this message translates to:
  /// **'Sahneyi Yenile'**
  String get homeErrorRetryMobile;

  /// No description provided for @homeErrorTitleWeb.
  ///
  /// In tr, this message translates to:
  /// **'Perdeler Henüz Açılmadı'**
  String get homeErrorTitleWeb;

  /// No description provided for @homeErrorMessageWeb.
  ///
  /// In tr, this message translates to:
  /// **'Sahne verileri yüklenirken bir sorun oluştu.'**
  String get homeErrorMessageWeb;

  /// No description provided for @homeFeaturedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkanlar'**
  String get homeFeaturedTitle;

  /// No description provided for @homeFeaturedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vitrin'**
  String get homeFeaturedSubtitle;

  /// No description provided for @homeFeaturedKicker.
  ///
  /// In tr, this message translates to:
  /// **'VİTRİN'**
  String get homeFeaturedKicker;

  /// No description provided for @homeCategoriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get homeCategoriesTitle;

  /// No description provided for @homeCategoriesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sanatın Renkleri'**
  String get homeCategoriesSubtitle;

  /// No description provided for @homeCategoriesKicker.
  ///
  /// In tr, this message translates to:
  /// **'SANATIN RENKLERİ'**
  String get homeCategoriesKicker;

  /// No description provided for @homeActiveShowsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Oyunlar'**
  String get homeActiveShowsTitle;

  /// No description provided for @homeActiveShowsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu An Sahnede'**
  String get homeActiveShowsSubtitle;

  /// No description provided for @homeDiscoverTitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get homeDiscoverTitle;

  /// No description provided for @homeDiscoverKicker.
  ///
  /// In tr, this message translates to:
  /// **'KEŞFET'**
  String get homeDiscoverKicker;

  /// No description provided for @homeCuratedForYou.
  ///
  /// In tr, this message translates to:
  /// **'Sana Özel Seçkiler'**
  String get homeCuratedForYou;

  /// No description provided for @homeVenuesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mekanlar'**
  String get homeVenuesTitle;

  /// No description provided for @homeVenuesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şehrin Sahneleri'**
  String get homeVenuesSubtitle;

  /// No description provided for @homeVenuesKicker.
  ///
  /// In tr, this message translates to:
  /// **'MEKANLAR'**
  String get homeVenuesKicker;

  /// No description provided for @homeTeamsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sahne Toplulukları'**
  String get homeTeamsTitle;

  /// No description provided for @homeTeamsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekipleri Keşfet'**
  String get homeTeamsSubtitle;

  /// No description provided for @homeCampaignDiscoverSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kampanyayı Keşfet'**
  String get homeCampaignDiscoverSubtitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyShowsHint.
  ///
  /// In tr, this message translates to:
  /// **'Şu anda listelenecek bir oyun bulunmuyor. Yakında burada olacak.'**
  String get homeEmptyShowsHint;

  /// No description provided for @homeAccountSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neye İhtiyacın Var?'**
  String get homeAccountSectionTitle;

  /// No description provided for @homeAccountKicker.
  ///
  /// In tr, this message translates to:
  /// **'HESABIM'**
  String get homeAccountKicker;

  /// No description provided for @homeTrendingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu An Popüler'**
  String get homeTrendingTitle;

  /// No description provided for @homeTrendingKicker.
  ///
  /// In tr, this message translates to:
  /// **'GÜNDEM'**
  String get homeTrendingKicker;

  /// No description provided for @homeHeroBrandMark.
  ///
  /// In tr, this message translates to:
  /// **'TİYATROL'**
  String get homeHeroBrandMark;

  /// No description provided for @homeHeroBrandSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'SAHNE SANATLARI'**
  String get homeHeroBrandSubtitle;

  /// No description provided for @homeHeroEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'SAHNE SANATLARI SEZONU'**
  String get homeHeroEyebrow;

  /// No description provided for @homeHeroHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Bu akşam,\nhangi sahne seni bekliyor?'**
  String get homeHeroHeadline;

  /// Hero bölümündeki tanıtım cümlesi, sahne ve oyun sayısı bilindiğinde
  ///
  /// In tr, this message translates to:
  /// **'Şehrin {stageCount} sahnesinde bu sezon aktif {showCount} oyunu keşfet; sana en yakın gösterimlere göz at ve birkaç dokunuşla biletini al.'**
  String homeHeroLedeWithCounts(int stageCount, int showCount);

  /// No description provided for @homeHeroLedeFallback.
  ///
  /// In tr, this message translates to:
  /// **'Şehrin sahnelerinde bu sezon oynayan oyunları keşfet, yakınındaki etkinliklere göz at ve biletini birkaç tıkla al.'**
  String get homeHeroLedeFallback;

  /// No description provided for @homeHeroDiscoverButton.
  ///
  /// In tr, this message translates to:
  /// **'Sahneleri Keşfet'**
  String get homeHeroDiscoverButton;

  /// No description provided for @homeHeroNearbyButton.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımdakiler'**
  String get homeHeroNearbyButton;

  /// No description provided for @homeHeroSearchPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Tiyatro, konser, sanatçı ara…'**
  String get homeHeroSearchPlaceholder;

  /// No description provided for @homeHeroSearchLabel.
  ///
  /// In tr, this message translates to:
  /// **'ARA'**
  String get homeHeroSearchLabel;

  /// No description provided for @homeNextShowLabel.
  ///
  /// In tr, this message translates to:
  /// **'SIRADAKİ OYUN'**
  String get homeNextShowLabel;

  /// No description provided for @homeSeeDetails.
  ///
  /// In tr, this message translates to:
  /// **'Detayları Gör'**
  String get homeSeeDetails;

  /// No description provided for @homeNearMeLabel.
  ///
  /// In tr, this message translates to:
  /// **'YAKINIMDA'**
  String get homeNearMeLabel;

  /// No description provided for @homeTicketsLoginPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yaparak biletlerini gör'**
  String get homeTicketsLoginPrompt;

  /// No description provided for @homeTicketsNoneYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yaklaşan bileğin yok'**
  String get homeTicketsNoneYet;

  /// No description provided for @homeTicketsSeeDetails.
  ///
  /// In tr, this message translates to:
  /// **'Bilet detaylarını gör'**
  String get homeTicketsSeeDetails;

  /// Hızlı erişim panelinde bir sonraki biletin oyun adı
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki: {showName}'**
  String homeTicketsNext(String showName);

  /// No description provided for @homeFavoritesLoginPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yaparak favorilerini gör'**
  String get homeFavoritesLoginPrompt;

  /// No description provided for @homeFavoritesNoneYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz favori eklemedin'**
  String get homeFavoritesNoneYet;

  /// No description provided for @homeFavoritesView.
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiklerini görüntüle'**
  String get homeFavoritesView;

  /// No description provided for @homeNearbyNoneYet.
  ///
  /// In tr, this message translates to:
  /// **'Şu an planlanan yeni etkinlik yok'**
  String get homeNearbyNoneYet;

  /// No description provided for @homeNearbyView.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta sahnede neler var, gör'**
  String get homeNearbyView;

  /// No description provided for @homeStatUpcomingTicket.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan Bilet'**
  String get homeStatUpcomingTicket;

  /// No description provided for @homeStatFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get homeStatFavorite;

  /// No description provided for @homeStatNearby.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get homeStatNearby;

  /// No description provided for @homeAccountSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Ayarları'**
  String get homeAccountSettingsTitle;

  /// No description provided for @homeAccountSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil, bildirim ve gizlilik tercihlerin'**
  String get homeAccountSettingsSubtitle;

  /// No description provided for @homeQuoteLatin.
  ///
  /// In tr, this message translates to:
  /// **'\"Ars longa, vita brevis, occasio praeceps, experimentum periculosum, iudicium difficile.\"'**
  String get homeQuoteLatin;

  /// No description provided for @homeQuoteTranslation.
  ///
  /// In tr, this message translates to:
  /// **'\"Sanat (zanaat/bilgi) uzun, hayat kısa, fırsat kaçıcı, deneyim yanıltıcı (tehlikeli), karar vermek zordur.\"'**
  String get homeQuoteTranslation;

  /// No description provided for @homeDailyDiscoveryTag.
  ///
  /// In tr, this message translates to:
  /// **'HER GÜN YENİ BİR KEŞİF'**
  String get homeDailyDiscoveryTag;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İzinlerini ve uygulama tercihlerini yönet.'**
  String get settingsSubtitle;

  /// No description provided for @settingsQuoteText.
  ///
  /// In tr, this message translates to:
  /// **'Sanat, ruhun üzerindeki günlük yaşamın tozunu siler.'**
  String get settingsQuoteText;

  /// No description provided for @settingsQuoteAuthor.
  ///
  /// In tr, this message translates to:
  /// **'Pablo Picasso'**
  String get settingsQuoteAuthor;

  /// No description provided for @settingsSectionPermissions.
  ///
  /// In tr, this message translates to:
  /// **'İZİNLER'**
  String get settingsSectionPermissions;

  /// No description provided for @settingsLocationPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum İzni'**
  String get settingsLocationPermissionTitle;

  /// No description provided for @settingsLocationPermissionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki gösterileri bulabilmemiz için izin ver.'**
  String get settingsLocationPermissionSubtitle;

  /// No description provided for @settingsNotificationsPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotificationsPermissionTitle;

  /// No description provided for @settingsNotificationsPermissionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni gösteriler ve kampanyalardan haberdar ol.'**
  String get settingsNotificationsPermissionSubtitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In tr, this message translates to:
  /// **'GÖRÜNÜM'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsAccentColorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema Rengi'**
  String get settingsAccentColorTitle;

  /// No description provided for @settingsAccentColorCustomSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu an kendi seçtiğin renk kullanılıyor.'**
  String get settingsAccentColorCustomSubtitle;

  /// No description provided for @settingsAccentColorDefaultSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın vurgu rengini kendin seç.'**
  String get settingsAccentColorDefaultSubtitle;

  /// No description provided for @settingsAccentColorPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema Rengini Seç'**
  String get settingsAccentColorPickerTitle;

  /// No description provided for @settingsAccentColorSemanticLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tema rengi olarak seç'**
  String get settingsAccentColorSemanticLabel;

  /// No description provided for @settingsCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get settingsCancel;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In tr, this message translates to:
  /// **'DİL'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Dili'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın dilini değiştir.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTurkish;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In tr, this message translates to:
  /// **'UYGULAMAYI DESTEKLE'**
  String get settingsSectionSupport;

  /// No description provided for @settingsRecommendAppTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Öner'**
  String get settingsRecommendAppTitle;

  /// No description provided for @settingsRecommendAppDesc.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza indirme bağlantısını paylaşarak bize destek ol.'**
  String get settingsRecommendAppDesc;

  /// No description provided for @settingsShareWithFriendsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarınla Paylaş'**
  String get settingsShareWithFriendsTitle;

  /// No description provided for @settingsShareWithFriendsDesc.
  ///
  /// In tr, this message translates to:
  /// **'TiyatRol\'ü mesajla ya da sosyal medyada paylaş.'**
  String get settingsShareWithFriendsDesc;

  /// No description provided for @settingsVersionFooter.
  ///
  /// In tr, this message translates to:
  /// **'Versiyon 1.0.4 - Sanatla Tasarlandı'**
  String get settingsVersionFooter;

  /// Uygulamayı paylaşırken gönderilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'Ruhunu sanatla besleyecek bu serüvene sen de katıl: {url}'**
  String settingsShareMessage(String url);

  /// No description provided for @settingsShareSubject.
  ///
  /// In tr, this message translates to:
  /// **'Sanat Serüveni'**
  String get settingsShareSubject;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
