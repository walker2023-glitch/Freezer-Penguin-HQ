// Local state for the Kitchen redesign preview only.

import 'package:flutter/material.dart';

import '../offline/mock_data.dart';
import '../widgets/cold_storage_filter.dart';

class PreviewRecipe {
  PreviewRecipe({
    required this.id,
    required this.title,
    required this.minutes,
    required this.uses,
    required this.missing,
    required this.steps,
    required this.isMine,
    this.isPublic = false,
    this.soonCount = 0,
    this.heroIcon = Icons.restaurant,
    this.heroColor = const Color(0xFF7BA8D4),
    this.likes = 0,
  });

  final String id;
  final String title;
  final int minutes;
  final List<String> uses;
  final List<String> missing;
  final List<String> steps;
  final bool isMine;
  bool isPublic;
  final int soonCount;
  final IconData heroIcon;
  final Color heroColor;
  final int likes;
}

class ItemHabit {
  const ItemHabit({
    required this.name,
    required this.bought,
    required this.eaten,
  });

  final String name;
  final int bought;
  final int eaten;
}

class RookeryPost {
  RookeryPost({
    required this.author,
    required this.body,
    required this.likes,
    this.isRecipeShare = false,
  });

  final String author;
  final String body;
  final int likes;
  final bool isRecipeShare;
}

enum CompanionKind { waddle, pip, scout, custom }

class CompanionProfile {
  CompanionProfile({
    required this.kind,
    this.customName = '',
  });

  CompanionKind kind;
  String customName;

  String get name {
    switch (kind) {
      case CompanionKind.waddle:
        return 'Waddle';
      case CompanionKind.pip:
        return 'Pip';
      case CompanionKind.scout:
        return 'Scout';
      case CompanionKind.custom:
        final trimmed = customName.trim();
        return trimmed.isEmpty ? 'My penguin' : trimmed;
    }
  }

  String get personality {
    switch (kind) {
      case CompanionKind.waddle:
        return 'Warm and chatty. Cheers you on and keeps it simple.';
      case CompanionKind.pip:
        return 'Tiny and playful. Short answers, lots of encouragement.';
      case CompanionKind.scout:
        return 'Direct expedition lead. Expiry first, no fluff.';
      case CompanionKind.custom:
        return 'Your colony scout — same cooking help, your name on the badge.';
    }
  }

  String get disclaimer =>
      '$name · cooking scout — not medical or nutrition advice';
}

enum HqWidgetId {
  colonyStatus,
  tonightBriefing,
  askCompanion,
  shoppingList,
  zoneCounts,
  huddleTrending,
  topPicks,
  boughtNotEaten,
  mostLikedRecipe,
}

class PreviewShellNav extends ChangeNotifier {
  int index = 0;
  ColdStorageFilter storageFilter = const ColdStorageFilter();

  void setIndex(int i) {
    index = i;
    notifyListeners();
  }

  void setStorageFilter(ColdStorageFilter filter) {
    storageFilter = filter;
    notifyListeners();
  }

  void openColdStorage({String? band}) {
    index = 1;
    if (band != null) {
      storageFilter = ColdStorageFilter(
        method: ColdFilterMethod.expiry,
        value: band,
      );
    }
    notifyListeners();
  }
}

class PreviewKitchenStore extends ChangeNotifier {
  PreviewKitchenStore() {
    _items = mockInventoryItems().map((e) => Map<String, dynamic>.from(e)).toList();
    _recipes = [
      PreviewRecipe(
        id: 's1',
        title: 'Lemon Herb Chicken',
        minutes: 40,
        uses: ['Ground Chicken', 'Leftover Chili', 'Steam-in-Bag Broccoli Florets'],
        missing: ['Lemon', 'Rosemary'],
        steps: [
          'Season chicken with salt, lemon, and herbs.',
          'Roast until golden.',
          'Serve with broccoli from the Soon list.',
        ],
        isMine: false,
        soonCount: 3,
        likes: 41,
        heroIcon: Icons.set_meal,
        heroColor: const Color(0xFF5B8C5A),
      ),
      PreviewRecipe(
        id: 's2',
        title: 'Chili Mac',
        minutes: 20,
        uses: ['Leftover Chili'],
        missing: ['Elbow Pasta'],
        steps: [
          'Boil pasta until just tender.',
          'Warm leftover chili.',
          'Fold together and serve.',
        ],
        isMine: false,
        soonCount: 1,
        likes: 19,
        heroIcon: Icons.ramen_dining,
        heroColor: const Color(0xFFC45C26),
      ),
      PreviewRecipe(
        id: 's3',
        title: 'Chicken Stir Fry',
        minutes: 25,
        uses: ['Ground Chicken', 'Steam-in-Bag Broccoli Florets'],
        missing: ['Soy Sauce'],
        steps: [
          'Brown the chicken.',
          'Add broccoli.',
          'Finish with soy sauce.',
        ],
        isMine: false,
        soonCount: 2,
        likes: 12,
        heroIcon: Icons.soup_kitchen,
        heroColor: const Color(0xFF2D5B88),
      ),
      PreviewRecipe(
        id: 'm1',
        title: "Grandma's Krill Patties",
        minutes: 35,
        uses: ['Frozen Peas'],
        missing: [],
        steps: [
          'Mix krill, crumbs, and an egg.',
          'Shape into patties and pan-sear.',
          'Serve with peas on the side.',
        ],
        isMine: true,
        isPublic: false,
        heroIcon: Icons.outdoor_grill,
        heroColor: const Color(0xFF3D5A80),
      ),
    ];
    _posts = [
      RookeryPost(
        author: 'Ivy · Colony 4',
        body: 'Blanch broccoli before freezing — color stays brighter in stir fry.',
        likes: 24,
      ),
      RookeryPost(
        author: 'Sam',
        body: 'Public recipe: sheet-pan lemon chicken using whatever herb is left.',
        likes: 41,
        isRecipeShare: true,
      ),
      RookeryPost(
        author: 'HQ',
        body: 'Tip: cook Urgent items tonight. Safe stock can wait.',
        likes: 18,
      ),
    ];
  }

  late List<Map<String, dynamic>> _items;
  late List<PreviewRecipe> _recipes;
  late List<RookeryPost> _posts;
  CompanionProfile companion = CompanionProfile(kind: CompanionKind.waddle);

  final Set<HqWidgetId> _enabled = {
    HqWidgetId.colonyStatus,
    HqWidgetId.tonightBriefing,
    HqWidgetId.askCompanion,
    HqWidgetId.topPicks,
    HqWidgetId.boughtNotEaten,
    HqWidgetId.mostLikedRecipe,
    HqWidgetId.huddleTrending,
  };

  final List<HqWidgetId> _order = [
    HqWidgetId.colonyStatus,
    HqWidgetId.tonightBriefing,
    HqWidgetId.askCompanion,
    HqWidgetId.topPicks,
    HqWidgetId.boughtNotEaten,
    HqWidgetId.mostLikedRecipe,
    HqWidgetId.huddleTrending,
    HqWidgetId.shoppingList,
    HqWidgetId.zoneCounts,
  ];

  static const lockedWidgets = {
    HqWidgetId.colonyStatus,
    HqWidgetId.tonightBriefing,
  };

  final List<String> shoppingList = [
    'Elbow pasta',
    'Soy sauce',
    'Lemons',
  ];

  final List<ItemHabit> itemHabits = const [
    ItemHabit(name: 'Frozen Peas', bought: 11, eaten: 2),
    ItemHabit(name: 'Steam-in-Bag Broccoli', bought: 8, eaten: 2),
    ItemHabit(name: 'Whole Milk', bought: 6, eaten: 5),
    ItemHabit(name: 'Ground Chicken', bought: 5, eaten: 3),
    ItemHabit(name: 'Leftover Chili', bought: 3, eaten: 3),
  ];

  final List<String> savedRecipeIds = ['s1'];

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  List<PreviewRecipe> get suggested =>
      _recipes.where((r) => !r.isMine).take(3).toList();
  List<PreviewRecipe> get allCookable =>
      _recipes.where((r) => !r.isMine).toList();
  List<PreviewRecipe> get nestRecipes =>
      _recipes.where((r) => r.isMine).toList();
  List<PreviewRecipe> get mine => nestRecipes;
  List<RookeryPost> get rookeryPosts => List.unmodifiable(_posts);

  RookeryPost get topTip {
    final tips = _posts.where((p) => !p.isRecipeShare).toList()
      ..sort((a, b) => b.likes.compareTo(a.likes));
    return tips.first;
  }

  bool isEnabled(HqWidgetId id) =>
      lockedWidgets.contains(id) || _enabled.contains(id);

  List<HqWidgetId> get widgetCatalog => List.unmodifiable(_order);

  List<HqWidgetId> get visibleWidgets =>
      _order.where(isEnabled).toList();

  List<ItemHabit> get topPicks {
    final ranked = [...itemHabits]..sort((a, b) => b.eaten.compareTo(a.eaten));
    return ranked.take(3).toList();
  }

  List<ItemHabit> get boughtNotEaten => itemHabits
      .where((h) => h.bought >= 6 && h.eaten < h.bought * 0.4)
      .toList();

  PreviewRecipe get mostLikedRecipe {
    final public = _recipes.where((r) => !r.isMine).toList()
      ..sort((a, b) => b.likes.compareTo(a.likes));
    return public.first;
  }

  void toggleWidget(HqWidgetId id) {
    if (lockedWidgets.contains(id)) return;
    if (_enabled.contains(id)) {
      _enabled.remove(id);
    } else {
      _enabled.add(id);
    }
    notifyListeners();
  }

  void moveWidget(HqWidgetId id, {required bool up}) {
    final i = _order.indexOf(id);
    if (i < 0) return;
    final j = up ? i - 1 : i + 1;
    if (j < 0 || j >= _order.length) return;
    final swap = _order[j];
    _order[j] = id;
    _order[i] = swap;
    notifyListeners();
  }

  List<PreviewRecipe> get savedRecipes =>
      _recipes.where((r) => savedRecipeIds.contains(r.id)).toList();

  void toggleSaved(String id) {
    if (savedRecipeIds.contains(id)) {
      savedRecipeIds.remove(id);
    } else {
      savedRecipeIds.add(id);
    }
    notifyListeners();
  }

  void setCompanionKind(CompanionKind kind) {
    companion = CompanionProfile(
      kind: kind,
      customName: companion.customName,
    );
    notifyListeners();
  }

  void setCustomName(String name) {
    companion = CompanionProfile(
      kind: CompanionKind.custom,
      customName: name,
    );
    notifyListeners();
  }

  ({int urgent, int soon, int safe}) colonyCounts() {
    var urgent = 0, soon = 0, safe = 0;
    for (final item in _items) {
      final days = daysLeft(item['expiration_date'] as String?);
      if (days == null) continue;
      if (days <= 2) {
        urgent++;
      } else if (days <= 6) {
        soon++;
      } else {
        safe++;
      }
    }
    return (urgent: urgent, soon: soon, safe: safe);
  }

  void togglePublic(String id) {
    for (final recipe in _recipes) {
      if (recipe.id == id) {
        recipe.isPublic = !recipe.isPublic;
        notifyListeners();
        return;
      }
    }
  }

  void addRecipe({
    required String title,
    required List<String> ingredients,
    required List<String> steps,
  }) {
    _recipes.add(
      PreviewRecipe(
        id: 'm${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        minutes: 30,
        uses: ingredients.take(2).toList(),
        missing: ingredients.skip(2).toList(),
        steps: steps.isEmpty ? ['Add your steps when you cook this.'] : steps,
        isMine: true,
        isPublic: false,
      ),
    );
    notifyListeners();
  }
}

int? daysLeft(String? expiry) {
  if (expiry == null || expiry == '—') return null;
  try {
    final parsed = DateTime.parse(expiry);
    final today = DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  } catch (_) {
    return null;
  }
}
