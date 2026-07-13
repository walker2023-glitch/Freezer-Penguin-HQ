import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_zh.dart';

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
    Locale('es'),
    Locale('zh'),
    Locale('zh', 'HK')
  ];

  /// Application name shown in AppBar and window title.
  ///
  /// In en, this message translates to:
  /// **'Freezer Penguin'**
  String get appTitle;

  /// Dashboard greeting headline.
  ///
  /// In en, this message translates to:
  /// **'Stay frosty!'**
  String get welcomeMsg;

  /// Dashboard greeting subtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is the current state of your icebox.'**
  String get subWelcome;

  /// Bottom navigation tab label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Bottom navigation tab label.
  ///
  /// In en, this message translates to:
  /// **'The Ice Floe'**
  String get tabInventory;

  /// Bottom navigation tab label.
  ///
  /// In en, this message translates to:
  /// **'Intake Portal'**
  String get tabIntake;

  /// Bottom navigation tab label.
  ///
  /// In en, this message translates to:
  /// **'Penguin Tips'**
  String get tabTips;

  /// Dashboard capacity card title.
  ///
  /// In en, this message translates to:
  /// **'Icebox Capacity'**
  String get capacityTitle;

  /// Capacity status badge — below threshold.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get statusOptimal;

  /// Capacity fill-bar label.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get statusFull;

  /// Dashboard expiring-items counter label.
  ///
  /// In en, this message translates to:
  /// **'EXPIRING'**
  String get lblExpiring;

  /// Dashboard total-items counter label.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get lblTotal;

  /// Inventory screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your frozen assets.'**
  String get invSub;

  /// Inventory filter button.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get btnFilter;

  /// Intake portal subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log new provisions for the frozen expanse.'**
  String get intakeSub;

  /// Intake mode toggle label.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get toggleBarcode;

  /// Intake mode toggle label.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get toggleManual;

  /// Intake mode toggle label.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get toggleVision;

  /// Manual intake form field label.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get formName;

  /// Manual intake item name hint text.
  ///
  /// In en, this message translates to:
  /// **'e.g., Krill Patties, Frozen Peas'**
  String get hintName;

  /// Manual intake form field label.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get formQty;

  /// Manual intake form field label.
  ///
  /// In en, this message translates to:
  /// **'Storage Zone'**
  String get formZone;

  /// Manual intake storage zone hint text.
  ///
  /// In en, this message translates to:
  /// **'Deep Freeze (Bottom)'**
  String get hintZone;

  /// Intake submit button label.
  ///
  /// In en, this message translates to:
  /// **'Add to Freezer'**
  String get btnAdd;

  /// Tips screen spotlight badge.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY SPOTLIGHT'**
  String get tipsSpotlight;

  /// Tips card 1 headline.
  ///
  /// In en, this message translates to:
  /// **'Master the Deep Freeze'**
  String get tipsTitle1;

  /// Tips card 1 body text.
  ///
  /// In en, this message translates to:
  /// **'Discover eco-friendly ways to preserve your fresh produce and reduce food waste with our ultimate penguin-approved kitchen strategies!'**
  String get tipsBody1;

  /// Tips card 2 headline.
  ///
  /// In en, this message translates to:
  /// **'Blanching 101'**
  String get tipsTitle2;

  /// Tips card 2 body text.
  ///
  /// In en, this message translates to:
  /// **'A quick boil followed by an ice bath stops enzymes, locking in bright colors and flavor.'**
  String get tipsBody2;

  /// Settings bottom sheet title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings sheet theme section header.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get settingsThemeHeader;

  /// Settings sheet language section header.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsLanguageHeader;

  /// Theme selector option label — Arctic / icy blue theme.
  ///
  /// In en, this message translates to:
  /// **'Arctic'**
  String get themeNameGlacier;

  /// Theme selector option label — Light / crisp white theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeNameKitchen;

  /// Theme selector option label — Dark / deep navy theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeNameOcean;

  /// Login screen heading and button label.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// Register screen heading and button label.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Email text field label on the login / register form.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailLabel;

  /// Password text field label on the login / register form.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// Toggle link shown on the login form to navigate to register.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get switchToRegister;

  /// Toggle link shown on the register form to navigate to login.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get switchToLogin;

  /// Sign-out button label in the settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logoutButton;

  /// Validation error shown when either field is blank.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required.'**
  String get loginErrorEmptyFields;

  /// Error shown when the server rejects credentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginErrorInvalid;

  /// Snackbar shown after successful registration.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please sign in.'**
  String get registerSuccess;

  /// Tagline shown beneath the app title on the loading screen.
  ///
  /// In en, this message translates to:
  /// **'Stay frosty, stay smart.'**
  String get loadingTagline;

  /// Fallback status text. Superseded by the rotating quote cycle.
  ///
  /// In en, this message translates to:
  /// **'Organizing your icebox…'**
  String get loadingMessage;

  /// Loading screen rotating quote 1 of 5.
  ///
  /// In en, this message translates to:
  /// **'No fragment forgotten, no food wasted.'**
  String get loadingQuote1;

  /// Loading screen rotating quote 2 of 5.
  ///
  /// In en, this message translates to:
  /// **'Master your freezer.'**
  String get loadingQuote2;

  /// Loading screen rotating quote 3 of 5.
  ///
  /// In en, this message translates to:
  /// **'Stop guessing. Start chilling.'**
  String get loadingQuote3;

  /// Loading screen rotating quote 4 of 5.
  ///
  /// In en, this message translates to:
  /// **'A friendly face for an organized space.'**
  String get loadingQuote4;

  /// Loading screen rotating quote 5 of 5.
  ///
  /// In en, this message translates to:
  /// **'Cold storage, clear vision.'**
  String get loadingQuote5;

  /// Inventory / Cold Storage tab label — same across all themes.
  ///
  /// In en, this message translates to:
  /// **'Cold Storage'**
  String get tabColdStorage;

  /// Home tab label in Standard (Crisp Kitchen / Deep Ocean) themes.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHomeStandard;

  /// Home tab label in the Frozen Glacier / Arctic theme.
  ///
  /// In en, this message translates to:
  /// **'Basecamp'**
  String get tabHomeArctic;

  /// Consume tab label in Standard themes.
  ///
  /// In en, this message translates to:
  /// **'Feast'**
  String get tabConsumeStandard;

  /// Consume tab label in Arctic theme.
  ///
  /// In en, this message translates to:
  /// **'Rations'**
  String get tabConsumeArctic;

  /// Community/Tips tab label in Standard themes.
  ///
  /// In en, this message translates to:
  /// **'Cool Tips'**
  String get tabCommunityStandard;

  /// Community/Tips tab label in Arctic theme.
  ///
  /// In en, this message translates to:
  /// **'The Huddle'**
  String get tabCommunityArctic;

  /// Subtitle shown beneath the Consume / Feast / Rations page heading.
  ///
  /// In en, this message translates to:
  /// **'Fuel your body, track your intake.'**
  String get consumePageSub;

  /// Section header for the inventory subtraction card.
  ///
  /// In en, this message translates to:
  /// **'Log What You Ate'**
  String get consumeSectionSubtract;

  /// Helper text inside the inventory subtraction card.
  ///
  /// In en, this message translates to:
  /// **'Select an item from your inventory to mark as consumed.'**
  String get consumeSubtractHint;

  /// Action button label in the inventory subtraction section.
  ///
  /// In en, this message translates to:
  /// **'Mark as Eaten'**
  String get consumeMarkEaten;

  /// Section header for the calorie and macro tracking card.
  ///
  /// In en, this message translates to:
  /// **'Calorie & Macro Tracker'**
  String get consumeSectionCalorie;

  /// Helper text inside the calorie tracker card.
  ///
  /// In en, this message translates to:
  /// **'Track your daily nutritional intake.'**
  String get consumeCalorieHint;

  /// Calories text field label.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get consumeFieldCalories;

  /// Protein text field label.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get consumeFieldProtein;

  /// Carbohydrates text field label.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get consumeFieldCarbs;

  /// Fat text field label.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get consumeFieldFat;

  /// Action button that submits the calorie / macro entry.
  ///
  /// In en, this message translates to:
  /// **'Log Macros'**
  String get consumeLogMacros;

  /// Section header for the meal photo upload card.
  ///
  /// In en, this message translates to:
  /// **'Snap Your Meal'**
  String get consumeSectionPhoto;

  /// Helper text inside the meal photo card.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo to visually log what you ate.'**
  String get consumePhotoHint;

  /// Button that opens the image picker for meal photo upload.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get consumePhotoBtn;

  /// Empty-state message shown in the Ice Floe / inventory screen.
  ///
  /// In en, this message translates to:
  /// **'Your freezer is empty.\nTap + to scan a barcode or use Vision!'**
  String get inventoryEmpty;

  /// Error text shown when the inventory fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load inventory.'**
  String get inventoryLoadError;

  /// AppBar title for the Pantry Insights analytics screen.
  ///
  /// In en, this message translates to:
  /// **'Pantry Insights'**
  String get insightsTitle;

  /// Error text shown when the analytics API fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load insights.'**
  String get insightsLoadError;

  /// Retry button label on the analytics error state.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get insightsRetry;

  /// Section title for the SUBQUERY alert banner.
  ///
  /// In en, this message translates to:
  /// **'High Priority Alert'**
  String get insightsHighPriorityTitle;

  /// Section title for the CONDITIONAL ring chart card.
  ///
  /// In en, this message translates to:
  /// **'Pantry Health'**
  String get insightsHealthTitle;

  /// Centre label beneath the total count in the ring chart.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get insightsItemsLabel;

  /// Ring chart legend label — safe items (≥ 7 days).
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get insightsSafe;

  /// Ring chart legend label — items expiring in 1–6 days.
  ///
  /// In en, this message translates to:
  /// **'Use Soon'**
  String get insightsUseSoon;

  /// Ring chart legend label — past-date items.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get insightsExpired;

  /// Ring chart legend subtitle for the Safe bucket.
  ///
  /// In en, this message translates to:
  /// **'≥ 7 days'**
  String get insightsDays7Plus;

  /// Ring chart legend subtitle for the Use Soon bucket.
  ///
  /// In en, this message translates to:
  /// **'1–6 days'**
  String get insightsDays1to6;

  /// Ring chart legend subtitle for the Expired bucket.
  ///
  /// In en, this message translates to:
  /// **'Past date'**
  String get insightsPastDate;

  /// Section label for the INNER JOIN + FUNCTION carousel.
  ///
  /// In en, this message translates to:
  /// **'Ready to Cook Now'**
  String get insightsReadyToCook;

  /// Section label for the AGGREGATE storage-zone card.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get insightsZones;

  /// Section label for the WINDOW leaderboard card.
  ///
  /// In en, this message translates to:
  /// **'Top Picks'**
  String get insightsTopPicks;

  /// Section label for the OUTER JOIN missing-ingredients card.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get insightsShoppingList;

  /// Subtitle under the Shopping List section header.
  ///
  /// In en, this message translates to:
  /// **'Missing ingredients for your saved recipes.'**
  String get insightsShoppingSub;

  /// Action pill on each shopping list row.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get insightsBuyBtn;
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
      <String>['en', 'es', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'HK':
            return AppLocalizationsZhHk();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
