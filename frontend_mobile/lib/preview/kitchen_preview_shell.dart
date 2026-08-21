// Kitchen redesign preview — source of truth.
// Opened from login via "Preview Kitchen redesign".
// Do not replace this shell with lib/preview/lab (layout experiments live there).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../screens/consume_screen.dart';
import '../state/app_settings.dart';
import 'preview_chrome.dart';
import 'preview_home.dart';
import 'preview_huddle.dart';
import 'preview_inventory.dart';
import 'preview_labels.dart';
import 'preview_store.dart';

class KitchenPreviewShell extends StatelessWidget {
  const KitchenPreviewShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreviewKitchenStore()),
        ChangeNotifierProvider(create: (_) => PreviewShellNav()),
      ],
      child: const _KitchenPreviewBody(),
    );
  }
}

class _KitchenPreviewBody extends StatelessWidget {
  const _KitchenPreviewBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArctic = context.watch<AppSettings>().isArctic;
    final nav = context.watch<PreviewShellNav>();
    final copy = PreviewCopy.of(
      context.watch<AppSettings>(),
      context.watch<PreviewKitchenStore>().companion,
    );

    const views = [
      PreviewHomeView(),
      PreviewInventoryView(),
      ConsumeScreen(),
      PreviewHuddleHub(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Row(
          children: [
            const PenguinMark(),
            const SizedBox(width: 10),
            Text(
              l10n.appTitle,
              style: GoogleFonts.quicksand(
                color: AppColors.outline,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.outline),
            onPressed: () => openPreviewSettings(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        tooltip: l10n.tabIntake,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline, width: 2),
        ),
        onPressed: () {
          final copy = PreviewCopy.of(
            context.read<AppSettings>(),
            context.read<PreviewKitchenStore>().companion,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Food + adds food only. Add recipes from ${copy.nestTitle}.',
              ),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          Material(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kitchen redesign preview — classic app is unchanged.',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: nav.index,
              children: views,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: nav.index,
          onTap: nav.setIndex,
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
              activeIcon: Icon(isArctic ? Icons.explore : Icons.home),
              label: isArctic ? l10n.tabHomeArctic : l10n.tabHomeStandard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.ac_unit_outlined),
              activeIcon: const Icon(Icons.ac_unit),
              label: l10n.tabColdStorage,
            ),
            BottomNavigationBarItem(
              icon: Icon(isArctic ? Icons.food_bank_outlined : Icons.restaurant_outlined),
              activeIcon: Icon(isArctic ? Icons.food_bank : Icons.restaurant),
              label: isArctic ? l10n.tabConsumeArctic : l10n.tabConsumeStandard,
            ),
            BottomNavigationBarItem(
              icon: Icon(isArctic ? Icons.forum_outlined : Icons.lightbulb_outline),
              activeIcon: Icon(isArctic ? Icons.forum : Icons.lightbulb),
              label: copy.huddleTitle,
            ),
          ],
        ),
      ),
    );
  }
}
