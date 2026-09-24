// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brand => 'TiyatRol';

  @override
  String get home => 'Home';

  @override
  String get plays => 'Plays';

  @override
  String get team => 'Our Team';

  @override
  String get tickets => 'Get Tickets';

  @override
  String get upcomingPlays => 'Upcoming Plays';

  @override
  String get seoHomeTitle => 'TiyatRol | Theatre and Arts Group';

  @override
  String get seoHomeDesc =>
      'Everything about TiyatRol Team\'s theatre plays, actor biographies, behind-the-scenes visuals, and tour schedule.';

  @override
  String get seoPlaysTitle => 'Our Plays | TiyatRol';

  @override
  String get seoPlaysDesc =>
      'Discover the latest theatre plays staged by TiyatRol and book your tickets.';

  @override
  String get seoTeamTitle => 'Our Team | TiyatRol';

  @override
  String get seoTeamDesc =>
      'Meet our talented actors and technical crew working on and off stage.';

  @override
  String get seoAboutTitle => 'About Us | TiyatRol';

  @override
  String get seoAboutDesc =>
      'The story of TiyatRol, with our artistic vision and years of stage experience.';

  @override
  String get seoPlayDetailSuffix => 'View Play | TiyatRol';

  @override
  String get seoDiscoverTitle => 'Discover New Plays | TiyatRol';

  @override
  String get seoDiscoverDesc =>
      'Discover the latest productions, premieres, and highlights of the season on the TiyatRol stage.';

  @override
  String get seoNearbyTitle => 'Tours and Venues | TiyatRol';

  @override
  String get seoNearbyDesc =>
      'Where is TiyatRol performing near you? Check out our tour schedule and theatre venues.';

  @override
  String get buyTicketAction => 'Buy Your Ticket Now';

  @override
  String get sharePlayMessage => 'You shouldn\'t miss this play!';

  @override
  String get galleryEmpty => 'Gallery is empty';

  @override
  String get searchTitle => 'Art Gallery';

  @override
  String get searchHint => 'Step into the heart of art...';

  @override
  String searchEmptyState(String query) {
    return 'We couldn\'t find any masterpieces for \'$query\'.';
  }

  @override
  String get searchClearGallery => 'Refresh Gallery';

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterShows => 'Events';

  @override
  String get searchFilterPlayers => 'Artists';

  @override
  String get searchFilterStages => 'Venues';

  @override
  String get searchFilterTeams => 'Collectives';

  @override
  String get searchSectionsShowsSubtitle => 'Flow of Art';

  @override
  String get searchSectionsPlayersSubtitle => 'Stars of the Stage';

  @override
  String get searchSectionsStagesSubtitle => 'Heart of Art';

  @override
  String get searchSectionsTeamsSubtitle => 'Creative Groups';

  @override
  String get loginHeroTitle => 'WORLD OF\nART';

  @override
  String get loginPhoneButton => 'CONTINUE WITH PHONE';

  @override
  String get loginGoogleButton => 'Continue with Google';

  @override
  String get loginTermsNotice =>
      'BY JOINING THE COLLECTION YOU ACCEPT THE TERMS';

  @override
  String get homeTooltipNotifications => 'Notifications';

  @override
  String get homeTooltipSettings => 'Settings';

  @override
  String get homeErrorTitleMobile => 'The Curtains Haven\'t Opened Yet!';

  @override
  String get homeErrorRetryMobile => 'Refresh the Stage';

  @override
  String get homeErrorTitleWeb => 'The Curtains Haven\'t Opened Yet';

  @override
  String get homeErrorMessageWeb =>
      'There was a problem loading the stage data.';

  @override
  String get homeFeaturedTitle => 'Featured';

  @override
  String get homeFeaturedSubtitle => 'Showcase';

  @override
  String get homeFeaturedKicker => 'SHOWCASE';

  @override
  String get homeCategoriesTitle => 'Categories';

  @override
  String get homeCategoriesSubtitle => 'Colors of Art';

  @override
  String get homeCategoriesKicker => 'COLORS OF ART';

  @override
  String get homeActiveShowsTitle => 'Active Plays';

  @override
  String get homeActiveShowsSubtitle => 'On Stage Now';

  @override
  String get homeDiscoverTitle => 'Discover';

  @override
  String get homeDiscoverKicker => 'DISCOVER';

  @override
  String get homeCuratedForYou => 'Curated For You';

  @override
  String get homeVenuesTitle => 'Venues';

  @override
  String get homeVenuesSubtitle => 'Stages of the City';

  @override
  String get homeVenuesKicker => 'VENUES';

  @override
  String get homeTeamsTitle => 'Stage Communities';

  @override
  String get homeTeamsSubtitle => 'Discover Teams';

  @override
  String get homeCampaignDiscoverSubtitle => 'Discover the Campaign';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeEmptyShowsHint =>
      'There are no plays to list right now. Check back soon.';

  @override
  String get homeAccountSectionTitle => 'What Do You Need?';

  @override
  String get homeAccountKicker => 'MY ACCOUNT';

  @override
  String get homeTrendingTitle => 'Trending Now';

  @override
  String get homeTrendingKicker => 'TRENDING';

  @override
  String get homeHeroBrandMark => 'TIYATROL';

  @override
  String get homeHeroBrandSubtitle => 'PERFORMING ARTS';

  @override
  String get homeHeroEyebrow => 'PERFORMING ARTS SEASON';

  @override
  String get homeHeroHeadline => 'Tonight,\nwhich stage awaits you?';

  @override
  String homeHeroLedeWithCounts(int stageCount, int showCount) {
    return 'Discover $showCount active plays this season across $stageCount stages in the city; check out the shows nearest you and get your ticket in a few taps.';
  }

  @override
  String get homeHeroLedeFallback =>
      'Discover the plays showing this season on the city\'s stages, check out nearby events, and get your ticket in a few clicks.';

  @override
  String get homeHeroDiscoverButton => 'Discover Stages';

  @override
  String get homeHeroNearbyButton => 'Near Me';

  @override
  String get homeHeroSearchPlaceholder =>
      'Search for theatre, concerts, artists…';

  @override
  String get homeHeroSearchLabel => 'SEARCH';

  @override
  String get homeNextShowLabel => 'NEXT SHOW';

  @override
  String get homeSeeDetails => 'See Details';

  @override
  String get homeNearMeLabel => 'NEARBY';

  @override
  String get homeTicketsLoginPrompt => 'Sign in to see your tickets';

  @override
  String get homeTicketsNoneYet => 'No upcoming tickets yet';

  @override
  String get homeTicketsSeeDetails => 'See ticket details';

  @override
  String homeTicketsNext(String showName) {
    return 'Next: $showName';
  }

  @override
  String get homeFavoritesLoginPrompt => 'Sign in to see your favorites';

  @override
  String get homeFavoritesNoneYet => 'You haven\'t added any favorites yet';

  @override
  String get homeFavoritesView => 'View your saved items';

  @override
  String get homeNearbyNoneYet => 'No new events planned right now';

  @override
  String get homeNearbyView => 'See what\'s on stage this week';

  @override
  String get homeStatUpcomingTicket => 'Upcoming Ticket';

  @override
  String get homeStatFavorite => 'Favorite';

  @override
  String get homeStatNearby => 'Nearby';

  @override
  String get homeAccountSettingsTitle => 'Account Settings';

  @override
  String get homeAccountSettingsSubtitle =>
      'Your profile, notification, and privacy preferences';

  @override
  String get homeQuoteLatin =>
      '\"Ars longa, vita brevis, occasio praeceps, experimentum periculosum, iudicium difficile.\"';

  @override
  String get homeQuoteTranslation =>
      '\"Art is long, life is short, opportunity fleeting, experience treacherous, judgment difficult.\"';

  @override
  String get homeDailyDiscoveryTag => 'A NEW DISCOVERY EVERY DAY';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage your permissions and app preferences.';

  @override
  String get settingsQuoteText =>
      'Art washes away from the soul the dust of everyday life.';

  @override
  String get settingsQuoteAuthor => 'Pablo Picasso';

  @override
  String get settingsSectionPermissions => 'PERMISSIONS';

  @override
  String get settingsLocationPermissionTitle => 'Location Permission';

  @override
  String get settingsLocationPermissionSubtitle =>
      'Allow access so we can find shows near you.';

  @override
  String get settingsNotificationsPermissionTitle => 'Notifications';

  @override
  String get settingsNotificationsPermissionSubtitle =>
      'Get notified about new shows and campaigns.';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsAccentColorTitle => 'Accent Color';

  @override
  String get settingsAccentColorCustomSubtitle =>
      'You\'re currently using your own custom color.';

  @override
  String get settingsAccentColorDefaultSubtitle =>
      'Choose the app\'s accent color yourself.';

  @override
  String get settingsAccentColorPickerTitle => 'Choose Accent Color';

  @override
  String get settingsAccentColorSemanticLabel => 'Select as accent color';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageTitle => 'App Language';

  @override
  String get settingsLanguageSubtitle => 'Change the app\'s language.';

  @override
  String get settingsLanguageTurkish => 'Turkish';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsSectionSupport => 'SUPPORT THE APP';

  @override
  String get settingsRecommendAppTitle => 'Recommend the App';

  @override
  String get settingsRecommendAppDesc =>
      'Support us by sharing the store download link.';

  @override
  String get settingsShareWithFriendsTitle => 'Share with Friends';

  @override
  String get settingsShareWithFriendsDesc =>
      'Share TiyatRol via message or social media.';

  @override
  String get settingsVersionFooter => 'Version 1.0.4 - Designed with Art';

  @override
  String settingsShareMessage(String url) {
    return 'Join this adventure that will nourish your soul with art: $url';
  }

  @override
  String get settingsShareSubject => 'Art Adventure';
}
