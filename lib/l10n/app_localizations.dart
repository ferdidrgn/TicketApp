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
