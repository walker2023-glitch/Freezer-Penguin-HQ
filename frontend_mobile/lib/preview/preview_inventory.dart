import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../widgets/bento_card.dart';
import '../widgets/cold_storage_filter.dart';
import 'preview_nav.dart';
import 'preview_recipe_detail.dart';
import 'preview_store.dart';

class PreviewInventoryView extends StatelessWidget {
  const PreviewInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();
    final nav = context.watch<PreviewShellNav>();
    final filter = nav.storageFilter;
    final items = store.items.where((item) => itemMatchesColdFilter(item, filter)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cold Storage',
                    style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Filter by expiry, location, or type.',
                    style: TextStyle(color: AppColors.textVariant, fontSize: 16),
                  ),
                ],
              ),
            ),
            ColdStorageFilterButton(
              filter: filter,
              onChanged: nav.setStorageFilter,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Nothing matches this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
            ),
          )
        else
          for (final item in items) ...[
            _ItemCard(item: item),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = (item['product_name'] as String?) ?? 'Item';
    final qty = item['quantity'] ?? 1;
    final expiry = (item['expiration_date'] as String?) ?? '—';
    final days = daysLeft(expiry);
    final Color badgeColor;
    final String badge;
    if (days == null) {
      badgeColor = AppColors.textVariant;
      badge = '—';
    } else if (days <= 2) {
      badgeColor = const Color(0xFFE84040);
      badge = 'URGENT';
    } else if (days <= 6) {
      badgeColor = AppColors.orange;
      badge = 'SOON';
    } else {
      badgeColor = const Color(0xFF3DB05B);
      badge = 'SAFE';
    }

    return GestureDetector(
      onTap: () => _openDetail(context, name, qty, expiry, badge),
      child: BentoCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                border: Border.all(color: AppColors.outline, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.kitchen, color: AppColors.outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(
                    '${coldItemLocation(item)} · Qty: $qty  •  Exp: $expiry',
                    style: const TextStyle(
                      color: AppColors.textVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                border: Border.all(color: AppColors.outline, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    String name,
    Object qty,
    String expiry,
    String badge,
  ) {
    final store = context.read<PreviewKitchenStore>();
    final matches = store.suggested
        .where((r) => r.uses.any((u) => name.toLowerCase().contains(u.toLowerCase().split(' ').first) || u.toLowerCase().contains(name.toLowerCase().split(' ').first)))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textVariant.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.w800)),
            Text('Qty $qty · Exp $expiry · $badge', style: const TextStyle(color: AppColors.textVariant)),
            const SizedBox(height: 16),
            Text('Recipes with this', style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (matches.isEmpty)
              const Text(
                'No suggested recipes for this item in the preview.',
                style: TextStyle(color: AppColors.textVariant),
              )
            else
              for (final r in matches)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.title, style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
                  subtitle: Text('${r.minutes} min'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    pushPreview(context, PreviewRecipeDetail(recipe: r));
                  },
                ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mark eaten will persist when the backend is back.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outline, width: 2),
                  foregroundColor: AppColors.outline,
                ),
                child: const Text('Mark as eaten'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

