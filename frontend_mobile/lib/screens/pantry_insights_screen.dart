// Pantry Insights Dashboard — Phase 6 SQL Assignment Scaffolding.
//
// Consumes GET /api/v1/analytics/pantry-insights?user_id=1 and renders
// five sections, each backed by a distinct SQL technique placeholder:
//
//   ① Alert Banner          ← SUBQUERY mock
//   ② Ring Chart            ← CONDITIONAL mock
//   ③ Ready-to-Cook Carousel← INNER JOIN + FUNCTION mock
//   ④ Split Row             ← AGGREGATE (zones) + WINDOW (leaderboard) mock
//   ⑤ Shopping List         ← OUTER JOIN mock
//
// All HTTP calls use package:http; no new packages were added.
// Colors are sourced from AppColors (config.dart) plus inlined analytics
// constants at the top of this file.

import 'dart:convert';
import 'dart:math' show pi, min;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../widgets/bento_card.dart';

// ── Analytics-specific color constants ───────────────────────────────────────
const _kSafeGreen    = Color(0xFF3DB05B);
const _kDangerRed    = Color(0xFFE84040);
const _kRingTrack    = Color(0x22000000); // subtle dark ring background

class PantryInsightsScreen extends StatefulWidget {
  const PantryInsightsScreen({super.key});

  @override
  State<PantryInsightsScreen> createState() => _PantryInsightsScreenState();
}

class _PantryInsightsScreenState extends State<PantryInsightsScreen> {
  late Future<Map<String, dynamic>> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = _loadInsights();
  }

  Future<Map<String, dynamic>> _loadInsights() async {
    final response = await http
        .get(Uri.parse('$backendUrl/analytics/pantry-insights?user_id=1'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Analytics API returned ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.outline, width: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.outline),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.insights, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Pantry Insights',
              style: GoogleFonts.quicksand(
                color: AppColors.outline,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _insightsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 56,
                    color: AppColors.textVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load insights.',
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: AppColors.textVariant,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(
                      () => _insightsFuture = _loadInsights(),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      'Retry',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                          color: AppColors.outline,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ① Alert Banner — SUBQUERY ─────────────────────────────────
              _buildAlertBanner(data['high_priority_alert']
                  as Map<String, dynamic>),
              const SizedBox(height: 16),

              // ② Pantry Health Ring Chart — CONDITIONAL ─────────────────
              _buildPantryHealthCard(
                  data['pantry_health'] as Map<String, dynamic>),
              const SizedBox(height: 16),

              // ③ Ready-to-Cook Carousel — INNER JOIN + FUNCTION ──────────
              _buildCarouselSection(
                  data['ready_to_cook'] as List<dynamic>),
              const SizedBox(height: 16),

              // ④ Split Row — AGGREGATE + WINDOW ──────────────────────────
              _buildSplitRow(
                zones: data['storage_zones'] as List<dynamic>,
                leaderboard: data['leaderboard'] as List<dynamic>,
              ),
              const SizedBox(height: 16),

              // ⑤ Shopping List — OUTER JOIN ──────────────────────────────
              _buildShoppingList(
                  data['shopping_list'] as List<dynamic>),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ── ① Alert Banner (SUBQUERY) ─────────────────────────────────────────────

  Widget _buildAlertBanner(Map<String, dynamic> alert) {
    final items = (alert['expiring_items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final count = alert['alert_count'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange,
        border: Border.all(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(Icons.warning_amber, color: Colors.white, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High Priority Alert',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '$count item${count == 1 ? '' : 's'} expiring within '
                  '${alert['threshold_days']} days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final item in items)
                      _buildAlertChip(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertChip(Map<String, dynamic> item) {
    final days = item['days_remaining'] as int;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        border: Border.all(color: Colors.white.withAlpha(150), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${item['product_name']} · ${days}d',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ── ② Pantry Health Ring Chart (CONDITIONAL) ─────────────────────────────

  Widget _buildPantryHealthCard(Map<String, dynamic> health) {
    final safe     = health['safe']     as int;
    final useSoon  = health['use_soon'] as int;
    final expired  = health['expired']  as int;
    final total    = health['total']    as int;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            icon: Icons.donut_large_rounded,
            label: 'Pantry Health',
            badge: 'CONDITIONAL',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Ring chart
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 140),
                      painter: _RingChartPainter(
                        safe: safe,
                        useSoon: useSoon,
                        expired: expired,
                      ),
                    ),
                    // Center total
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: GoogleFonts.quicksand(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.outline,
                          ),
                        ),
                        const Text(
                          'items',
                          style: TextStyle(
                            color: AppColors.textVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(
                      color: _kSafeGreen,
                      label: 'Safe',
                      count: safe,
                      subtitle: '≥ 7 days',
                    ),
                    const SizedBox(height: 14),
                    _legendItem(
                      color: AppColors.orange,
                      label: 'Use Soon',
                      count: useSoon,
                      subtitle: '1–6 days',
                    ),
                    const SizedBox(height: 14),
                    _legendItem(
                      color: _kDangerRed,
                      label: 'Expired',
                      count: expired,
                      subtitle: 'Past date',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required int count,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.outline,
                    ),
                  ),
                  Text(
                    '$count',
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ③ Ready-to-Cook Carousel (INNER JOIN + FUNCTION) ──────────────────────

  Widget _buildCarouselSection(List<dynamic> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _sectionLabel(
            icon: Icons.soup_kitchen_outlined,
            label: 'Ready to Cook Now',
            badge: 'INNER JOIN + FUNCTION',
          ),
        ),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final card = cards[i] as Map<String, dynamic>;
              return _buildRecipeCard(card);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> card) {
    final days = card['days_left_for_key_ingredient'] as int;
    final badgeColor = days <= 2
        ? _kDangerRed
        : days <= 5
            ? AppColors.orange
            : _kSafeGreen;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Days badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              border: Border.all(color: AppColors.outline, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$days day${days == 1 ? '' : 's'} left',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Recipe title
          Text(
            card['recipe_title'] as String,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Key ingredient chip
          Row(
            children: [
              const Icon(
                Icons.kitchen_outlined,
                size: 13,
                color: AppColors.textVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  card['key_ingredient'] as String,
                  style: const TextStyle(
                    color: AppColors.textVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ④ Split Row — Storage Zones (AGGREGATE) + Leaderboard (WINDOW) ────────

  Widget _buildSplitRow({
    required List<dynamic> zones,
    required List<dynamic> leaderboard,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Storage Zone Counts
        Expanded(child: _buildZonesCard(zones)),
        const SizedBox(width: 12),
        // Right: Greatest Hits Leaderboard
        Expanded(child: _buildLeaderboardCard(leaderboard)),
      ],
    );
  }

  Widget _buildZonesCard(List<dynamic> zones) {
    final maxCount = zones
        .map((z) => (z as Map<String, dynamic>)['item_count'] as int)
        .fold(0, (a, b) => a > b ? a : b);

    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            icon: Icons.location_on_outlined,
            label: 'Zones',
            badge: 'AGGREGATE',
            compact: true,
          ),
          const SizedBox(height: 12),
          for (final raw in zones) ...[
            _buildZoneBar(raw as Map<String, dynamic>, maxCount),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneBar(Map<String, dynamic> zone, int maxCount) {
    final count = zone['item_count'] as int;
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                zone['zone_name'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.outline.withAlpha(25),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(List<dynamic> entries) {
    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            icon: Icons.emoji_events_outlined,
            label: 'Top Picks',
            badge: 'WINDOW',
            compact: true,
          ),
          const SizedBox(height: 12),
          for (final raw in entries.take(5)) ...[
            _buildLeaderRow(raw as Map<String, dynamic>),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderRow(Map<String, dynamic> entry) {
    final rank = entry['rank'] as int;
    final medalColor = rank == 1
        ? const Color(0xFFFFD700) // gold
        : rank == 2
            ? const Color(0xFFC0C0C0) // silver
            : rank == 3
                ? const Color(0xFFCD7F32) // bronze
                : AppColors.textVariant;

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
            style: TextStyle(
              fontSize: rank <= 3 ? 14 : 11,
              color: medalColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            entry['product_name'] as String,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.outline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '×${entry['times_consumed']}',
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ── ⑤ Shopping List (OUTER JOIN) ──────────────────────────────────────────

  Widget _buildShoppingList(List<dynamic> items) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            icon: Icons.shopping_cart_outlined,
            label: 'Shopping List',
            badge: 'OUTER JOIN',
          ),
          const SizedBox(height: 4),
          const Text(
            'Missing ingredients for your saved recipes.',
            style: TextStyle(color: AppColors.textVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final raw in items)
            _buildShoppingRow(raw as Map<String, dynamic>),
        ],
      ),
    );
  }

  Widget _buildShoppingRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              border: Border.all(color: AppColors.outline, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['ingredient_name'] as String,
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.outline,
                  ),
                ),
                Text(
                  'for ${item['needed_for_recipe']}',
                  style: const TextStyle(
                    color: AppColors.textVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              border: Border.all(
                color: AppColors.primary.withAlpha(100),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Buy',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared sub-builders ────────────────────────────────────────────────────

  Widget _sectionLabel({
    required IconData icon,
    required String label,
    required String badge,
    bool compact = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: compact ? 16 : 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: compact ? 13 : 15,
            color: AppColors.outline,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.outline.withAlpha(15),
            border: Border.all(
              color: AppColors.outline.withAlpha(60),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: AppColors.textVariant,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ring Chart CustomPainter ──────────────────────────────────────────────────

class _RingChartPainter extends CustomPainter {
  final int safe;
  final int useSoon;
  final int expired;

  const _RingChartPainter({
    required this.safe,
    required this.useSoon,
    required this.expired,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = safe + useSoon + expired;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 22.0;
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = _kRingTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Gap between arc segments (radians)
    const gap = 0.06;
    const startAngle = -pi / 2; // top

    final segments = [
      _Segment(safe / total, _kSafeGreen),
      _Segment(useSoon / total, AppColors.orange),
      _Segment(expired / total, _kDangerRed),
    ];

    double angle = startAngle;
    for (final seg in segments) {
      if (seg.fraction <= 0) continue;
      final sweep = seg.fraction * 2 * pi - gap;
      canvas.drawArc(
        rect,
        angle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      angle += seg.fraction * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter old) =>
      old.safe != safe || old.useSoon != useSoon || old.expired != expired;
}

class _Segment {
  final double fraction;
  final Color color;
  const _Segment(this.fraction, this.color);
}
