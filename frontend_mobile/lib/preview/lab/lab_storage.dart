import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/cold_storage_filter.dart';
import '../preview_store.dart';

class LabStorageView extends StatefulWidget {
  const LabStorageView({super.key});

  @override
  State<LabStorageView> createState() => _LabStorageViewState();
}

class _LabStorageViewState extends State<LabStorageView> {
  ColdStorageFilter _filter = const ColdStorageFilter();

  @override
  Widget build(BuildContext context) {
    final kitchen = context.watch<PreviewKitchenStore>();
    final items = kitchen.items.where((item) => itemMatchesColdFilter(item, _filter)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Cold Storage',
                style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            ColdStorageFilterButton(
              filter: _filter,
              onChanged: (next) => setState(() => _filter = next),
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
            BentoCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coldItemName(item),
                          style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          '${coldItemLocation(item)} · ${coldItemType(item)}',
                          style: const TextStyle(
                            color: AppColors.textVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
