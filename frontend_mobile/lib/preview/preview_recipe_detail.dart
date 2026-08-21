import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../widgets/bento_card.dart';
import 'preview_chat.dart';
import 'preview_chrome.dart';
import 'preview_store.dart';

class PreviewRecipeDetail extends StatelessWidget {
  const PreviewRecipeDetail({super.key, required this.recipe});

  final PreviewRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.outline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const PenguinMark(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                recipe.title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w800,
                  color: AppColors.outline,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline, width: 2),
        ),
        onPressed: () => openPenguinChat(context, recipe: recipe),
        icon: const PenguinMark(size: 28),
        label: Text(
          'Ask ${context.watch<PreviewKitchenStore>().companion.name}',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: recipe.isMine ? AppColors.orange : AppColors.primary,
                        border: Border.all(color: AppColors.outline, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.isMine ? 'YOURS' : 'SUGGESTED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${recipe.minutes} min',
                      style: const TextStyle(
                        color: AppColors.textVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recipe.title,
                  style: GoogleFonts.quicksand(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In your icebox',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final u in recipe.uses)
                      Chip(
                        label: Text(u),
                        backgroundColor: const Color(0xFF3DB05B).withAlpha(40),
                        side: const BorderSide(color: AppColors.outline, width: 1.5),
                      ),
                  ],
                ),
                if (recipe.missing.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Missing',
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in recipe.missing)
                        Chip(
                          label: Text(m),
                          backgroundColor: AppColors.orange.withAlpha(40),
                          side: const BorderSide(color: AppColors.outline, width: 1.5),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < recipe.steps.length; i++) ...[
                  Text(
                    '${i + 1}. ${recipe.steps[i]}',
                    style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
