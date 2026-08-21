import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/app_settings.dart';
import '../widgets/bento_card.dart';
import 'preview_chat.dart';
import 'preview_labels.dart';
import 'preview_nav.dart';
import 'preview_recipe_detail.dart';
import 'preview_store.dart';

class PreviewHomeView extends StatelessWidget {
  const PreviewHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();
    final copy = PreviewCopy.of(context.watch<AppSettings>(), store.companion);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay frosty!',
                    style: GoogleFonts.quicksand(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Your HQ widgets. Cook what’s Urgent, then Soon.',
                    style: TextStyle(color: AppColors.textVariant, fontSize: 15),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: copy.customizeTitle,
              onPressed: () => _openCustomize(context, copy),
              icon: const Icon(Icons.edit_outlined, color: AppColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onLongPress: () => _openCustomize(context, copy),
          child: Column(
            children: [
              for (var i = 0; i < store.visibleWidgets.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _hqWidget(context, store, copy, store.visibleWidgets[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _hqWidget(
    BuildContext context,
    PreviewKitchenStore store,
    PreviewCopy copy,
    HqWidgetId id,
  ) {
    switch (id) {
      case HqWidgetId.colonyStatus:
        return _ColonyStatusCard(copy: copy);
      case HqWidgetId.tonightBriefing:
        return _TonightBriefingCard(copy: copy);
      case HqWidgetId.askCompanion:
        return _AskCompanionRow(copy: copy);
      case HqWidgetId.shoppingList:
        return BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.widgetTitle(id),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final line in store.shoppingList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $line', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        );
      case HqWidgetId.zoneCounts:
        return BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.widgetTitle(id),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              _zoneRow('Kitchen freezer', 3),
              const SizedBox(height: 8),
              _zoneRow('Fridge', 2),
            ],
          ),
        );
      case HqWidgetId.huddleTrending:
        return GestureDetector(
          onTap: () => context.read<PreviewShellNav>().setIndex(3),
          child: BentoCard(
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.widgetTitle(id),
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        store.topTip.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
      case HqWidgetId.topPicks:
        return BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.widgetTitle(id),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'What you eat most — bought counts sit beside.',
                style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < store.topPicks.length; i++) ...[
                _habitRow(
                  rank: i + 1,
                  habit: store.topPicks[i],
                  detail: 'Eaten ${store.topPicks[i].eaten} · bought ${store.topPicks[i].bought}',
                ),
                if (i < store.topPicks.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      case HqWidgetId.boughtNotEaten:
        return BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.widgetTitle(id),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'You keep restocking these, but they linger.',
                style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < store.boughtNotEaten.length; i++) ...[
                _habitRow(
                  rank: i + 1,
                  habit: store.boughtNotEaten[i],
                  detail:
                      'Bought ${store.boughtNotEaten[i].bought} · eaten ${store.boughtNotEaten[i].eaten}',
                ),
                if (i < store.boughtNotEaten.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      case HqWidgetId.mostLikedRecipe:
        final recipe = store.mostLikedRecipe;
        return GestureDetector(
          onTap: () => pushPreview(context, PreviewRecipeDetail(recipe: recipe)),
          child: BentoCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: recipe.heroColor,
                    border: Border.all(color: AppColors.outline, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(recipe.heroIcon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.widgetTitle(id),
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        recipe.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${recipe.likes} likes in ${copy.rookeryTitle}',
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

  Widget _habitRow({
    required int rank,
    required ItemHabit habit,
    required String detail,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _zoneRow(String name, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Text(
          '$count items',
          style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _openCustomize(BuildContext context, PreviewCopy copy) {
    final store = context.read<PreviewKitchenStore>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: _CustomizeHqSheet(copy: copy),
      ),
    );
  }
}

class _ColonyStatusCard extends StatelessWidget {
  const _ColonyStatusCard({required this.copy});
  final PreviewCopy copy;

  @override
  Widget build(BuildContext context) {
    final counts = context.watch<PreviewKitchenStore>().colonyCounts();
    final total = counts.urgent + counts.soon + counts.safe;
    final nav = context.read<PreviewShellNav>();

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.colonyTitle,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => nav.openColdStorage(band: 'urgent'),
            child: SizedBox(
              height: 168,
              child: Center(
                child: SizedBox(
                  width: 168,
                  height: 168,
                  child: CustomPaint(
                    painter: _ColonyRingPainter(
                      urgent: counts.urgent,
                      soon: counts.soon,
                      safe: counts.safe,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: GoogleFonts.quicksand(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: AppColors.textVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(const Color(0xFFE84040), 'Urgent', counts.urgent, () {
                nav.openColdStorage(band: 'urgent');
              }),
              _legend(AppColors.orange, 'Soon', counts.soon, () {
                nav.openColdStorage(band: 'soon');
              }),
              _legend(const Color(0xFF3DB05B), 'Safe', counts.safe, () {
                nav.openColdStorage(band: 'safe');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, int count, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label $count',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TonightBriefingCard extends StatefulWidget {
  const _TonightBriefingCard({required this.copy});
  final PreviewCopy copy;

  @override
  State<_TonightBriefingCard> createState() => _TonightBriefingCardState();
}

class _TonightBriefingCardState extends State<_TonightBriefingCard> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<PreviewKitchenStore>().suggested;

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              widget.copy.briefingTitle,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          if (recipes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No Soon or Urgent matches yet. Add food to unlock briefing cards.',
                style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
              ),
            )
          else
            SizedBox(
              height: 236,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _page,
                    itemCount: recipes.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _BriefingSlide(recipe: recipes[i]),
                  ),
                  if (recipes.length > 1) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _roundArrow(
                        Icons.chevron_left,
                        _index == 0
                            ? null
                            : () => _page.previousPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _roundArrow(
                        Icons.chevron_right,
                        _index == recipes.length - 1
                            ? null
                            : () => _page.nextPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (recipes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < recipes.length; i++)
                    Container(
                      width: i == _index ? 8 : 6,
                      height: i == _index ? 8 : 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.outline : AppColors.textVariant.withAlpha(90),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundArrow(IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white.withAlpha(230),
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.outline, width: 2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: AppColors.outline),
          ),
        ),
      ),
    );
  }
}

class _BriefingSlide extends StatelessWidget {
  const _BriefingSlide({required this.recipe});
  final PreviewRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GestureDetector(
        onTap: () => pushPreview(context, PreviewRecipeDetail(recipe: recipe)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: recipe.heroColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline, width: 2),
                ),
                child: Icon(recipe.heroIcon, size: 64, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              recipe.title,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Uses ${recipe.soonCount} items from Soon list',
              style: const TextStyle(
                color: AppColors.textVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskCompanionRow extends StatelessWidget {
  const _AskCompanionRow({required this.copy});
  final PreviewCopy copy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openPenguinChat(context),
      child: BentoCard(
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.askTitle,
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const Text(
                    'Swaps, timing, and what to cook first.',
                    style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
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

class _CustomizeHqSheet extends StatelessWidget {
  const _CustomizeHqSheet({required this.copy});
  final PreviewCopy copy;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PreviewKitchenStore>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: ListView(
          controller: scroll,
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
            Text(
              copy.customizeTitle,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const Text(
              'Turn widgets on or off, then move them up or down. Status and Briefing stay on, but they can sit anywhere.',
              style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < store.widgetCatalog.length; i++)
              _catalogRow(store, store.widgetCatalog[i], i),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _catalogRow(PreviewKitchenStore store, HqWidgetId id, int index) {
    final locked = PreviewKitchenStore.lockedWidgets.contains(id);
    final on = store.isEnabled(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (locked)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.lock_outline, size: 22, color: AppColors.textVariant),
            )
          else
            Checkbox(
              value: on,
              activeColor: AppColors.primary,
              onChanged: (_) => store.toggleWidget(id),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.widgetTitle(id), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  copy.widgetHint(id),
                  style: const TextStyle(color: AppColors.textVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: index == 0 ? null : () => store.moveWidget(id, up: true),
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            onPressed: index == store.widgetCatalog.length - 1
                ? null
                : () => store.moveWidget(id, up: false),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }
}

class _ColonyRingPainter extends CustomPainter {
  const _ColonyRingPainter({
    required this.urgent,
    required this.soon,
    required this.safe,
  });

  final int urgent;
  final int soon;
  final int safe;

  @override
  void paint(Canvas canvas, Size size) {
    final total = urgent + soon + safe;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 22.0;
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = const Color(0x3305162E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    const gap = 0.06;
    const startAngle = -pi / 2;
    final segments = [
      (urgent / total, const Color(0xFFE84040)),
      (soon / total, AppColors.orange),
      (safe / total, const Color(0xFF3DB05B)),
    ];

    var angle = startAngle;
    for (final seg in segments) {
      if (seg.$1 <= 0) continue;
      final sweep = seg.$1 * 2 * pi - gap;
      canvas.drawArc(
        rect,
        angle + gap / 2,
        sweep < 0 ? 0 : sweep,
        false,
        Paint()
          ..color = seg.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      angle += seg.$1 * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _ColonyRingPainter old) =>
      old.urgent != urgent || old.soon != soon || old.safe != safe;
}
