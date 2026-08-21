import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../widgets/bento_card.dart';
import 'preview_add_recipe.dart';
import 'preview_recipe_detail.dart';
import 'preview_store.dart';

class PreviewKitchenView extends StatefulWidget {
  const PreviewKitchenView({super.key});

  @override
  State<PreviewKitchenView> createState() => _PreviewKitchenViewState();
}

class _PreviewKitchenViewState extends State<PreviewKitchenView> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();
    final recipes = _segment == 0 ? store.suggested : store.mine;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Kitchen',
          style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Suggested from your icebox, or recipes you added.',
          style: TextStyle(color: AppColors.textVariant, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.outline, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _seg(0, 'For you'),
              _seg(1, 'My recipes'),
            ],
          ),
        ),
        if (_segment == 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final store = context.read<PreviewKitchenStore>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: store,
                      child: const PreviewAddRecipePage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add my recipe',
                style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outline, width: 2),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (recipes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'No recipes here yet. Add one to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textVariant),
            ),
          )
        else
          for (final r in recipes) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PreviewRecipeDetail(recipe: r)),
              ),
              child: BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${r.minutes} min',
                          style: const TextStyle(
                            color: AppColors.textVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Uses ${r.uses.length} you have'
                      '${r.missing.isEmpty ? '' : ' · missing ${r.missing.length}'}',
                      style: const TextStyle(
                        color: AppColors.textVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _seg(int index, String label) {
    final selected = _segment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceLowest : Colors.transparent,
            border: selected ? Border.all(color: AppColors.outline, width: 2) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.outline : AppColors.textVariant,
            ),
          ),
        ),
      ),
    );
  }
}
