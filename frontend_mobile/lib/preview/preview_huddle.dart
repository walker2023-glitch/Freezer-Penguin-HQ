import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/app_settings.dart';
import '../widgets/bento_card.dart';
import 'preview_add_recipe.dart';
import 'preview_labels.dart';
import 'preview_nav.dart';
import 'preview_recipe_detail.dart';
import 'preview_store.dart';

class PreviewHuddleHub extends StatelessWidget {
  const PreviewHuddleHub({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = PreviewCopy.of(
      context.watch<AppSettings>(),
      context.watch<PreviewKitchenStore>().companion,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          copy.huddleTitle,
          style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(
          copy.huddleSubtitle,
          style: const TextStyle(color: AppColors.textVariant, fontSize: 15),
        ),
        const SizedBox(height: 16),
        _DoorCard(
          title: copy.rookeryTitle,
          body: copy.rookeryBlurb,
          icon: Icons.groups_outlined,
          onTap: () => pushPreview(context, const PreviewRookeryPage()),
        ),
        const SizedBox(height: 12),
        _DoorCard(
          title: copy.messTitle,
          body: copy.messBlurb,
          icon: Icons.restaurant_outlined,
          onTap: () => pushPreview(context, const PreviewMessPage()),
        ),
        const SizedBox(height: 12),
        _DoorCard(
          title: copy.nestTitle,
          body: copy.nestBlurb,
          icon: Icons.menu_book_outlined,
          onTap: () => pushPreview(context, const PreviewNestPage()),
        ),
      ],
    );
  }
}

class _DoorCard extends StatelessWidget {
  const _DoorCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BentoCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                border: Border.all(color: AppColors.outline, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.textVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class PreviewRookeryPage extends StatelessWidget {
  const PreviewRookeryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();
    final copy = PreviewCopy.of(context.watch<AppSettings>(), store.companion);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Text(
          copy.rookeryTitle,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, color: AppColors.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            copy.rookeryBlurb,
            style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => pushPreview(
              context,
              PreviewRecipeDetail(recipe: store.mostLikedRecipe),
            ),
            child: BentoCard(
              backgroundColor: AppColors.primary,
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MOST LIKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          store.mostLikedRecipe.title,
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${store.mostLikedRecipe.likes} likes this week',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final post in store.rookeryPosts) ...[
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author, style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(post.body, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.favorite_border, size: 18, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text('${post.likes}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          store.toggleSaved('s1');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved to ${copy.nestTitle}.')),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PreviewMessPage extends StatelessWidget {
  const PreviewMessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();
    final copy = PreviewCopy.of(context.watch<AppSettings>(), store.companion);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Text(
          copy.messTitle,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, color: AppColors.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Same cook-from-icebox list as Home, with every match — not just tonight’s top 3.',
            style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (final recipe in store.allCookable) ...[
            _RecipeRow(recipe: recipe),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PreviewNestPage extends StatefulWidget {
  const PreviewNestPage({super.key});

  @override
  State<PreviewNestPage> createState() => _PreviewNestPageState();
}

class _PreviewNestPageState extends State<PreviewNestPage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();
    final copy = PreviewCopy.of(context.watch<AppSettings>(), store.companion);
    final recipes = _segment == 0 ? store.savedRecipes : store.nestRecipes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Text(
          copy.nestTitle,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, color: AppColors.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: AppColors.outline, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _seg(0, 'Saved'),
                _seg(1, 'Created'),
              ],
            ),
          ),
          if (_segment == 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  pushPreview(context, const PreviewAddRecipePage());
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
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                _segment == 0
                    ? 'Nothing saved yet. Save a recipe from ${copy.rookeryTitle}.'
                    : 'No created recipes yet. Add one here — not from the food + button.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
              ),
            )
          else
            for (final recipe in recipes) ...[
              _RecipeRow(recipe: recipe, showVisibility: _segment == 1),
              const SizedBox(height: 12),
            ],
        ],
      ),
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

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe, this.showVisibility = false});

  final PreviewRecipe recipe;
  final bool showVisibility;

  @override
  Widget build(BuildContext context) {
    final store = context.read<PreviewKitchenStore>();
    return GestureDetector(
      onTap: () => pushPreview(context, PreviewRecipeDetail(recipe: recipe)),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${recipe.minutes} min',
                  style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              recipe.soonCount > 0
                  ? 'Uses ${recipe.soonCount} items from Soon list'
                  : 'Uses ${recipe.uses.length} you have'
                      '${recipe.missing.isEmpty ? '' : ' · missing ${recipe.missing.length}'}',
              style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
            ),
            if (showVisibility) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Private'),
                    selected: !recipe.isPublic,
                    onSelected: (_) {
                      if (recipe.isPublic) store.togglePublic(recipe.id);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Colony'),
                    selected: recipe.isPublic,
                    onSelected: (_) {
                      if (!recipe.isPublic) store.togglePublic(recipe.id);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
