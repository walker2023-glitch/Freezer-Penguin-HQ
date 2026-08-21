// Sample payloads for offline UI preview (no backend required).
// Shapes match the live FastAPI JSON so screens can swap to HTTP later.

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

List<Map<String, dynamic>> mockInventoryItems() {
  final today = DateTime.now();
  return [
    {
      'item_id': 1,
      'product_name': 'Ground Chicken',
      'quantity': 4,
      'expiration_date': _iso(today.subtract(const Duration(days: 18))),
      'upc': '041196910719',
      'location_name': 'Kitchen freezer',
      'kind': 'Meat',
    },
    {
      'item_id': 2,
      'product_name': 'Steam-in-Bag Broccoli Florets',
      'quantity': 6,
      'expiration_date': _iso(today.add(const Duration(days: 3))),
      'upc': '014500001234',
      'location_name': 'Fridge',
      'kind': 'Produce',
    },
    {
      'item_id': 3,
      'product_name': 'Whole Milk',
      'quantity': 1,
      'expiration_date': _iso(today.add(const Duration(days: 30))),
      'upc': '041220123456',
      'location_name': 'Fridge',
      'kind': 'Dairy',
    },
    {
      'item_id': 4,
      'product_name': 'Leftover Chili',
      'quantity': 2,
      'expiration_date': _iso(today.add(const Duration(days: 2))),
      'upc': null,
      'location_name': 'Fridge',
      'kind': 'Leftovers',
    },
    {
      'item_id': 5,
      'product_name': 'Frozen Peas',
      'quantity': 1,
      'expiration_date': _iso(today.add(const Duration(days: 40))),
      'upc': '070038123456',
      'location_name': 'Kitchen freezer',
      'kind': 'Frozen',
    },
  ];
}

Map<String, dynamic> mockPantryInsights() {
  final today = DateTime.now();
  return {
    'high_priority_alert': {
      'alert_count': 2,
      'threshold_days': 7,
      'expiring_items': [
        {
          'product_name': 'Leftover Chili',
          'expiration_date': _iso(today.add(const Duration(days: 2))),
          'days_remaining': 2,
        },
        {
          'product_name': 'Steam-in-Bag Broccoli Florets',
          'expiration_date': _iso(today.add(const Duration(days: 3))),
          'days_remaining': 3,
        },
      ],
    },
    'pantry_health': {
      'safe': 2,
      'use_soon': 2,
      'expired': 1,
      'total': 5,
    },
    'expiry_function_results': [],
    'ready_to_cook': [
      {
        'recipe_title': 'Chicken Stir Fry',
        'days_left_for_key_ingredient': 3,
        'key_ingredient': 'Steam-in-Bag Broccoli Florets',
      },
      {
        'recipe_title': 'Chili Mac',
        'days_left_for_key_ingredient': 2,
        'key_ingredient': 'Leftover Chili',
      },
    ],
    'storage_zones': [
      {'zone_name': 'Kitchen Freezer', 'item_count': 3},
      {'zone_name': 'Fridge', 'item_count': 2},
    ],
    'leaderboard': [
      {'rank': 1, 'product_name': 'Frozen Peas', 'times_consumed': 8},
      {'rank': 2, 'product_name': 'Whole Milk', 'times_consumed': 5},
      {'rank': 3, 'product_name': 'Ground Chicken', 'times_consumed': 3},
    ],
    'shopping_list': [
      {
        'ingredient_name': 'Soy Sauce',
        'needed_for_recipe': 'Chicken Stir Fry',
      },
      {
        'ingredient_name': 'Elbow Pasta',
        'needed_for_recipe': 'Chili Mac',
      },
    ],
  };
}
