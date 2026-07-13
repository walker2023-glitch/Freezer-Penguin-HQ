// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Freezer Penguin';

  @override
  String get welcomeMsg => 'Stay frosty!';

  @override
  String get subWelcome => 'Here is the current state of your icebox.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabInventory => 'The Ice Floe';

  @override
  String get tabIntake => 'Intake Portal';

  @override
  String get tabTips => 'Penguin Tips';

  @override
  String get capacityTitle => 'Icebox Capacity';

  @override
  String get statusOptimal => 'Optimal';

  @override
  String get statusFull => 'Full';

  @override
  String get lblExpiring => 'EXPIRING';

  @override
  String get lblTotal => 'TOTAL';

  @override
  String get invSub => 'Your frozen assets.';

  @override
  String get btnFilter => 'Filter';

  @override
  String get intakeSub => 'Log new provisions for the frozen expanse.';

  @override
  String get toggleBarcode => 'Barcode';

  @override
  String get toggleManual => 'Manual';

  @override
  String get toggleVision => 'Vision';

  @override
  String get formName => 'Item Name';

  @override
  String get hintName => 'e.g., Krill Patties, Frozen Peas';

  @override
  String get formQty => 'Quantity';

  @override
  String get formZone => 'Storage Zone';

  @override
  String get hintZone => 'Deep Freeze (Bottom)';

  @override
  String get btnAdd => 'Add to Freezer';

  @override
  String get tipsSpotlight => 'WEEKLY SPOTLIGHT';

  @override
  String get tipsTitle1 => 'Master the Deep Freeze';

  @override
  String get tipsBody1 =>
      'Discover eco-friendly ways to preserve your fresh produce and reduce food waste with our ultimate penguin-approved kitchen strategies!';

  @override
  String get tipsTitle2 => 'Blanching 101';

  @override
  String get tipsBody2 =>
      'A quick boil followed by an ice bath stops enzymes, locking in bright colors and flavor.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsThemeHeader => 'THEME';

  @override
  String get settingsLanguageHeader => 'LANGUAGE';

  @override
  String get themeNameGlacier => 'Arctic';

  @override
  String get themeNameKitchen => 'Light';

  @override
  String get themeNameOcean => 'Dark';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get loginEmailLabel => 'Email Address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get switchToRegister => 'Don\'t have an account? Register';

  @override
  String get switchToLogin => 'Already have an account? Sign In';

  @override
  String get logoutButton => 'Sign Out';

  @override
  String get loginErrorEmptyFields => 'Email and password are required.';

  @override
  String get loginErrorInvalid => 'Invalid email or password.';

  @override
  String get registerSuccess => 'Account created! Please sign in.';

  @override
  String get loadingTagline => 'Stay frosty, stay smart.';

  @override
  String get loadingMessage => 'Organizing your icebox…';

  @override
  String get loadingQuote1 => 'No fragment forgotten, no food wasted.';

  @override
  String get loadingQuote2 => 'Master your freezer.';

  @override
  String get loadingQuote3 => 'Stop guessing. Start chilling.';

  @override
  String get loadingQuote4 => 'A friendly face for an organized space.';

  @override
  String get loadingQuote5 => 'Cold storage, clear vision.';

  @override
  String get tabColdStorage => 'Cold Storage';

  @override
  String get tabHomeStandard => 'Home';

  @override
  String get tabHomeArctic => 'Basecamp';

  @override
  String get tabConsumeStandard => 'Feast';

  @override
  String get tabConsumeArctic => 'Rations';

  @override
  String get tabCommunityStandard => 'Cool Tips';

  @override
  String get tabCommunityArctic => 'The Huddle';

  @override
  String get consumePageSub => 'Fuel your body, track your intake.';

  @override
  String get consumeSectionSubtract => 'Log What You Ate';

  @override
  String get consumeSubtractHint =>
      'Select an item from your inventory to mark as consumed.';

  @override
  String get consumeMarkEaten => 'Mark as Eaten';

  @override
  String get consumeSectionCalorie => 'Calorie & Macro Tracker';

  @override
  String get consumeCalorieHint => 'Track your daily nutritional intake.';

  @override
  String get consumeFieldCalories => 'Calories';

  @override
  String get consumeFieldProtein => 'Protein (g)';

  @override
  String get consumeFieldCarbs => 'Carbs (g)';

  @override
  String get consumeFieldFat => 'Fat (g)';

  @override
  String get consumeLogMacros => 'Log Macros';

  @override
  String get consumeSectionPhoto => 'Snap Your Meal';

  @override
  String get consumePhotoHint => 'Upload a photo to visually log what you ate.';

  @override
  String get consumePhotoBtn => 'Upload Photo';

  @override
  String get inventoryEmpty =>
      'Your freezer is empty.\nTap + to scan a barcode or use Vision!';

  @override
  String get inventoryLoadError => 'Could not load inventory.';

  @override
  String get insightsTitle => 'Pantry Insights';

  @override
  String get insightsLoadError => 'Could not load insights.';

  @override
  String get insightsRetry => 'Retry';

  @override
  String get insightsHighPriorityTitle => 'High Priority Alert';

  @override
  String get insightsHealthTitle => 'Pantry Health';

  @override
  String get insightsItemsLabel => 'items';

  @override
  String get insightsSafe => 'Safe';

  @override
  String get insightsUseSoon => 'Use Soon';

  @override
  String get insightsExpired => 'Expired';

  @override
  String get insightsDays7Plus => '≥ 7 days';

  @override
  String get insightsDays1to6 => '1–6 days';

  @override
  String get insightsPastDate => 'Past date';

  @override
  String get insightsReadyToCook => 'Ready to Cook Now';

  @override
  String get insightsZones => 'Zones';

  @override
  String get insightsTopPicks => 'Top Picks';

  @override
  String get insightsShoppingList => 'Shopping List';

  @override
  String get insightsShoppingSub =>
      'Missing ingredients for your saved recipes.';

  @override
  String get insightsBuyBtn => 'Buy';
}
