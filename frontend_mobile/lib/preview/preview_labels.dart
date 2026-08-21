import '../state/app_settings.dart';
import 'preview_store.dart';

class PreviewCopy {
  PreviewCopy(this.isArctic, this.companionName);

  factory PreviewCopy.of(AppSettings settings, CompanionProfile companion) {
    return PreviewCopy(settings.isArctic, companion.name);
  }

  final bool isArctic;
  final String companionName;

  String get colonyTitle => isArctic ? 'Colony Status' : 'Icebox Status';
  String get briefingTitle => isArctic ? "Tonight's Briefing" : 'What you can cook';
  String get huddleTitle => 'Discover';
  String get rookeryTitle => isArctic ? 'The Huddle' : 'Tips & Tricks';
  String get messTitle => isArctic ? 'Provisions' : 'Clear the Fridge';
  String get nestTitle => isArctic ? 'My Collection' : 'My Cookbook';
  String get askTitle => 'Ask $companionName';
  String get customizeTitle => 'Customize HQ';

  String get huddleSubtitle =>
      'Three rooms: talk with the colony, cook from stock, and keep your recipes.';

  String get rookeryBlurb =>
      'Tips, chatter, and the recipes people liked most.';
  String get messBlurb =>
      'Every meal you can make from Soon and Urgent food — not just the top 3.';
  String get nestBlurb =>
      'Saved recipes and ones you wrote. Add a recipe here.';

  String widgetTitle(HqWidgetId id) {
    switch (id) {
      case HqWidgetId.colonyStatus:
        return colonyTitle;
      case HqWidgetId.tonightBriefing:
        return briefingTitle;
      case HqWidgetId.askCompanion:
        return askTitle;
      case HqWidgetId.shoppingList:
        return 'Shopping list';
      case HqWidgetId.zoneCounts:
        return isArctic ? 'Colony zones' : 'Storage zones';
      case HqWidgetId.huddleTrending:
        return 'Top tips';
      case HqWidgetId.topPicks:
        return isArctic ? 'Eaten most' : 'Top picks';
      case HqWidgetId.boughtNotEaten:
        return 'Bought, barely eaten';
      case HqWidgetId.mostLikedRecipe:
        return 'Most liked recipe';
    }
  }

  String widgetHint(HqWidgetId id) {
    switch (id) {
      case HqWidgetId.colonyStatus:
      case HqWidgetId.tonightBriefing:
        return 'Always on — move it anywhere in the stack';
      case HqWidgetId.askCompanion:
        return 'Opens $companionName on Home';
      case HqWidgetId.shoppingList:
        return 'Things you still need for recipes';
      case HqWidgetId.zoneCounts:
        return 'How full each freezer or fridge is';
      case HqWidgetId.huddleTrending:
        return isArctic
            ? 'A peek at The Huddle'
            : 'A peek at Tips & Tricks';
      case HqWidgetId.topPicks:
        return 'What you eat (and buy) most often';
      case HqWidgetId.boughtNotEaten:
        return 'Restocked a lot, cooked a little';
      case HqWidgetId.mostLikedRecipe:
        return 'The colony’s favorite right now';
    }
  }
}
