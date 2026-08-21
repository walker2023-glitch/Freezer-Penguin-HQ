import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import 'preview_store.dart';

class PreviewAddRecipePage extends StatefulWidget {
  const PreviewAddRecipePage({super.key});

  @override
  State<PreviewAddRecipePage> createState() => _PreviewAddRecipePageState();
}

class _PreviewAddRecipePageState extends State<PreviewAddRecipePage> {
  final _title = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _steps.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your recipe a name.')),
      );
      return;
    }
    context.read<PreviewKitchenStore>().addRecipe(
          title: title,
          ingredients: _ingredients.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          steps: _steps.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Text(
          'Add my recipe',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w800,
            color: AppColors.outline,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Title', style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _field(_title, 'e.g., Krill Patties'),
          const SizedBox(height: 16),
          Text('Ingredients (comma-separated)', style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _field(_ingredients, 'krill, crumbs, egg'),
          const SizedBox(height: 16),
          Text('Steps (one per line)', style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _field(_steps, 'Mix…\nSear…', maxLines: 5),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.outline, width: 2),
              ),
            ),
            child: Text(
              'Save recipe',
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceLowest,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
    );
  }
}
