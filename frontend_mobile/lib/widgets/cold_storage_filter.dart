// Shared Cold Storage filter — one button, then a method, then its values.
// Same in Arctic, Light, and Dark. Used by classic inventory and Kitchen preview.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';

enum ColdFilterMethod { expiry, location, type }

class ColdStorageFilter {
  const ColdStorageFilter({this.method, this.value});

  final ColdFilterMethod? method;
  final String? value;

  bool get isActive => method != null && value != null && value != 'all';

  String get methodLabel {
    switch (method) {
      case ColdFilterMethod.expiry:
        return 'By expiry';
      case ColdFilterMethod.location:
        return 'By location';
      case ColdFilterMethod.type:
        return 'By type';
      case null:
        return 'Filter';
    }
  }

  String get summary {
    if (!isActive) return 'Filter';
    return '$methodLabel · ${_valueLabel(method!, value!)}';
  }
}

String _valueLabel(ColdFilterMethod method, String value) {
  if (value == 'all') return 'All';
  if (method == ColdFilterMethod.expiry) {
    switch (value) {
      case 'urgent':
        return 'Urgent';
      case 'soon':
        return 'Soon';
      case 'safe':
        return 'Safe';
    }
  }
  return value;
}

String coldItemName(Map<String, dynamic> item) =>
    (item['product_name'] as String?) ?? 'Item';

String coldItemLocation(Map<String, dynamic> item) {
  final named = item['location_name'] as String?;
  if (named != null && named.isNotEmpty) return named;
  return _inferLocation(coldItemName(item));
}

String coldItemType(Map<String, dynamic> item) {
  final kind = item['kind'] as String?;
  if (kind != null && kind.isNotEmpty) return kind;
  return _inferType(coldItemName(item));
}

String _inferLocation(String name) {
  final n = name.toLowerCase();
  if (n.contains('frozen') || n.contains('chicken') || n.contains('peas')) {
    return 'Kitchen freezer';
  }
  return 'Fridge';
}

String _inferType(String name) {
  final n = name.toLowerCase();
  if (n.contains('chicken') || n.contains('beef') || n.contains('turkey')) {
    return 'Meat';
  }
  if (n.contains('broccoli') || n.contains('lettuce') || n.contains('apple')) {
    return 'Produce';
  }
  if (n.contains('milk') || n.contains('cheese') || n.contains('yogurt')) {
    return 'Dairy';
  }
  if (n.contains('leftover') || n.contains('chili')) return 'Leftovers';
  if (n.contains('frozen') || n.contains('peas')) return 'Frozen';
  return 'Other';
}

bool itemMatchesColdFilter(Map<String, dynamic> item, ColdStorageFilter filter) {
  if (!filter.isActive) return true;
  switch (filter.method!) {
    case ColdFilterMethod.expiry:
      final days = _daysLeft(item['expiration_date'] as String?);
      return _expiryBand(days) == filter.value;
    case ColdFilterMethod.location:
      return coldItemLocation(item) == filter.value;
    case ColdFilterMethod.type:
      return coldItemType(item) == filter.value;
  }
}

String _expiryBand(int? days) {
  if (days == null) return 'unknown';
  if (days <= 2) return 'urgent';
  if (days <= 6) return 'soon';
  return 'safe';
}

int? _daysLeft(String? expiry) {
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

class ColdStorageFilterButton extends StatelessWidget {
  const ColdStorageFilterButton({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final ColdStorageFilter filter;
  final ValueChanged<ColdStorageFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final next = await showColdStorageFilterSheet(context, filter);
        if (next != null) onChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filter.isActive ? AppColors.orange : AppColors.primary,
          border: Border.all(color: AppColors.outline, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              filter.isActive ? filter.summary : 'Filter',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ColdStorageFilter?> showColdStorageFilterSheet(
  BuildContext context,
  ColdStorageFilter current,
) {
  return showModalBottomSheet<ColdStorageFilter>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ColdFilterSheet(current: current),
  );
}

class _ColdFilterSheet extends StatefulWidget {
  const _ColdFilterSheet({required this.current});
  final ColdStorageFilter current;

  @override
  State<_ColdFilterSheet> createState() => _ColdFilterSheetState();
}

class _ColdFilterSheetState extends State<_ColdFilterSheet> {
  ColdFilterMethod? _openMethod;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (_openMethod == null) _methods() else _values(_openMethod!),
        ],
      ),
    );
  }

  Widget _methods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter',
          style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Pick how you want to sort the icebox, then choose a value.',
          style: TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _methodRow(
          ColdFilterMethod.expiry,
          'By expiry',
          'Urgent, Soon, or Safe — same bands as Home',
        ),
        _methodRow(
          ColdFilterMethod.location,
          'By location',
          'Kitchen freezer, Fridge, and other zones',
        ),
        _methodRow(
          ColdFilterMethod.type,
          'By type',
          'Meat, produce, dairy, leftovers, frozen',
        ),
        if (widget.current.isActive) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, const ColdStorageFilter()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.outline,
                side: const BorderSide(color: AppColors.outline, width: 2),
              ),
              child: const Text('Clear filter'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _methodRow(ColdFilterMethod method, String title, String hint) {
    final selected = widget.current.method == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
        ),
        title: Text(title, style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
        subtitle: Text(hint, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
        onTap: () => setState(() => _openMethod = method),
      ),
    );
  }

  Widget _values(ColdFilterMethod method) {
    final options = _optionsFor(method);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _openMethod = null),
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.outline),
            ),
            Expanded(
              child: Text(
                ColdStorageFilter(method: method).methodLabel,
                style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final value in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: widget.current.method == method &&
                          (value == 'all'
                              ? !widget.current.isActive
                              : widget.current.value == value)
                      ? AppColors.primary
                      : AppColors.outline,
                  width: 2,
                ),
              ),
              title: Text(
                _valueLabel(method, value),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.pop(
                  context,
                  value == 'all'
                      ? const ColdStorageFilter()
                      : ColdStorageFilter(method: method, value: value),
                );
              },
            ),
          ),
      ],
    );
  }

  List<String> _optionsFor(ColdFilterMethod method) {
    switch (method) {
      case ColdFilterMethod.expiry:
        return const ['all', 'urgent', 'soon', 'safe'];
      case ColdFilterMethod.location:
        return const ['all', 'Kitchen freezer', 'Fridge'];
      case ColdFilterMethod.type:
        return const ['all', 'Meat', 'Produce', 'Dairy', 'Leftovers', 'Frozen'];
    }
  }
}
