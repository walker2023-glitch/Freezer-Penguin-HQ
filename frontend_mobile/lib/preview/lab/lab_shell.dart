import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_settings.dart';
import '../preview_chrome.dart';
import 'lab_home_board.dart';
import 'lab_storage.dart';
import 'lab_store.dart';

class LabShell extends StatelessWidget {
  const LabShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabLayoutStore(),
      child: const _LabBody(),
    );
  }
}

class _LabBody extends StatefulWidget {
  const _LabBody();

  @override
  State<_LabBody> createState() => _LabBodyState();
}

class _LabBodyState extends State<_LabBody> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArctic = context.watch<AppSettings>().isArctic;

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
            const PenguinMark(size: 28),
            const SizedBox(width: 8),
            Text(
              'Layout lab',
              style: GoogleFonts.quicksand(
                color: AppColors.outline,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.orange,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Experiment only. Back returns to the real Kitchen HQ.',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                LabHomeBoard(),
                LabStorageView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Icon(isArctic ? Icons.explore_outlined : Icons.home_outlined),
              label: isArctic ? l10n.tabHomeArctic : l10n.tabHomeStandard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.ac_unit_outlined),
              label: l10n.tabColdStorage,
            ),
          ],
        ),
      ),
    );
  }
}
