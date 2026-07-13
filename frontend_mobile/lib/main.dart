import 'dart:convert';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'config.dart';                      // backendUrl + AppColors
import 'screens/consume_screen.dart';          // Phase 5 — Consume / Feast / Rations tab
import 'screens/loading_screen.dart';          // Phase 4 — animated splash/loading screen
import 'screens/login_screen.dart';            // Feature 2.0 — LoginScreen
import 'screens/pantry_insights_screen.dart';  // Phase 6 — SQL analytics dashboard
import 'state/app_settings.dart';        // Phase 5 — AppTheme/AppLocale/AppSettings
import 'state/auth_state.dart';          // Feature 2.0 — AuthState ChangeNotifier
import 'widgets/bento_card.dart';        // Phase 5 — extracted shared card widget

// AppTheme / AppLocale / AppLocaleExtension / AppSettings
// ↳ moved to lib/state/app_settings.dart (Phase 5)

// ─────────────────────────────────────────────────────────────────────────────
// APP ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const FreezerPenguinApp());
}

class FreezerPenguinApp extends StatelessWidget {
  const FreezerPenguinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => AuthState()),
      ],
      child: Consumer<AppSettings>(
        builder: (_, settings, __) => MaterialApp(
          title: 'Freezer Penguin',
          debugShowCheckedModeBanner: false,
          theme: settings.buildTheme(),

          // ── Flutter l10n wiring ──────────────────────────────────────────
          locale: settings.flutterLocale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
            Locale('zh', 'HK'),
            Locale('es'),
          ],

          // ── Three-state routing ──────────────────────────────────────────
          // 1. isInitializing → LoadingScreen  (splash, shown once at launch)
          // 2. isAuthenticated → MainNavigationScreen
          // 3. default          → LoginScreen
          //
          // AnimatedSwitcher provides a 450 ms crossfade between states.
          // ValueKey on each child ensures the switcher detects the swap.
          home: Consumer<AuthState>(
            builder: (_, auth, __) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: auth.isInitializing
                  ? const LoadingScreen(key: ValueKey('loading'))
                  : auth.isAuthenticated
                      ? const MainNavigationScreen(key: ValueKey('main'))
                      : const LoginScreen(key: ValueKey('login')),
            ),
          ),
        ),
      ),
    );
  }
}

// AppColors — moved to lib/config.dart (shared with login_screen.dart)

// ─────────────────────────────────────────────────────────────────────────────
// MAIN NAVIGATION
// ─────────────────────────────────────────────────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _openSettings() {
    // Capture both providers before the builder runs in the modal route context
    // (which is outside the main widget tree and cannot access them directly).
    final appSettings = context.read<AppSettings>();
    final authState = context.read<AuthState>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: authState),
        ],
        child: const _SettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // watch so nav re-renders immediately when theme changes
    final isArctic = context.watch<AppSettings>().isArctic;

    // IndexedStack preserves widget state on tab switch (e.g. IceFloeView
    // retains its loaded inventory list; ConsumeScreen retains form state).
    const views = [
      HomeDashboardView(),
      IceFloeView(),
      ConsumeScreen(),       // Phase 5 — replaces IntakePortalView in nav
      PenguinTipsView(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.outline, width: 2)),
        title: Row(
          children: [
            // Penguin brand mark — dark body / orange beak circle
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // White belly oval
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Orange beak dot
                  Positioned(
                    top: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.appTitle,
              style: GoogleFonts.quicksand(
                color: AppColors.outline,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.outline),
            tooltip: l10n.settings,
            onPressed: _openSettings,
          ),
        ],
      ),
      // Centre FAB — opens the Intake Portal (Barcode / Vision / Manual entry).
      // FloatingActionButtonLocation.centerDocked slots the button into the
      // notch of the BottomAppBar, making it the most prominent action on screen.
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        tooltip: l10n.tabIntake,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline, width: 2),
        ),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.92,
              minChildSize: 0.5,
              maxChildSize: 0.97,
              expand: false,
              builder: (_, scrollController) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: const Border(
                    top: BorderSide(color: AppColors.outline, width: 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textVariant.withAlpha(100),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      // IntakePortalView owns the ListView — pass the sheet
                      // controller directly; do NOT wrap in another scroll view.
                      child: IntakePortalView(scrollController: scrollController),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // IndexedStack keeps all tab widgets alive so state is preserved
      body: IndexedStack(
        index: _currentIndex,
        children: views,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          items: [
            // Tab 0 — Home / Basecamp
            BottomNavigationBarItem(
              icon: Icon(isArctic ? Icons.explore_outlined : Icons.home_outlined),
              activeIcon: Icon(isArctic ? Icons.explore : Icons.home),
              label: isArctic ? l10n.tabHomeArctic : l10n.tabHomeStandard,
            ),
            // Tab 1 — Cold Storage (label same in both themes)
            BottomNavigationBarItem(
              icon: const Icon(Icons.ac_unit_outlined),
              activeIcon: const Icon(Icons.ac_unit),
              label: l10n.tabColdStorage,
            ),
            // Tab 2 — Feast / Rations
            BottomNavigationBarItem(
              icon: Icon(isArctic ? Icons.food_bank_outlined : Icons.restaurant_outlined),
              activeIcon: Icon(isArctic ? Icons.food_bank : Icons.restaurant),
              label: isArctic ? l10n.tabConsumeArctic : l10n.tabConsumeStandard,
            ),
            // Tab 3 — Cool Tips / The Huddle
            BottomNavigationBarItem(
              icon: Icon(isArctic ? Icons.forum_outlined : Icons.lightbulb_outline),
              activeIcon: Icon(isArctic ? Icons.forum : Icons.lightbulb),
              label: isArctic ? l10n.tabCommunityArctic : l10n.tabCommunityStandard,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
          const SizedBox(height: 20),
          Text(
            l10n.settings,
            style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.outline),
          ),
          const SizedBox(height: 24),

          // ── Theme ──────────────────────────────────────────────────────────
          Text(
            l10n.settingsThemeHeader,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textVariant, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          _ThemeOption(label: l10n.themeNameGlacier, icon: Icons.ac_unit,           value: AppTheme.arctic, settings: settings),
          const SizedBox(height: 8),
          _ThemeOption(label: l10n.themeNameKitchen, icon: Icons.wb_sunny_outlined, value: AppTheme.light,  settings: settings),
          const SizedBox(height: 8),
          _ThemeOption(label: l10n.themeNameOcean,   icon: Icons.dark_mode_outlined, value: AppTheme.dark,  settings: settings),
          const SizedBox(height: 24),

          // ── Language ───────────────────────────────────────────────────────
          Text(
            l10n.settingsLanguageHeader,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textVariant, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: AppColors.outline, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLocale>(
                value: settings.locale,
                isExpanded: true,
                style: GoogleFonts.quicksand(color: AppColors.outline, fontWeight: FontWeight.w600, fontSize: 15),
                // Language names are intentionally in their native script (not localized)
                items: const [
                  DropdownMenuItem(value: AppLocale.en,  child: Text('English')),
                  DropdownMenuItem(value: AppLocale.yue, child: Text('廣東話')),
                  DropdownMenuItem(value: AppLocale.es,  child: Text('Español')),
                ],
                onChanged: (v) {
                  if (v != null) context.read<AppSettings>().setLocale(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Account ────────────────────────────────────────────────────
          const Divider(thickness: 1, color: AppColors.outline),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthState>().logout();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.logoutButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppTheme value;
  final AppSettings settings;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = settings.theme == value;

    return GestureDetector(
      onTap: () => context.read<AppSettings>().setTheme(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(30) : Theme.of(context).colorScheme.surface,
          border: Border.all(color: selected ? AppColors.primary : AppColors.outline, width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.outline),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.outline,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// BentoCard — moved to lib/widgets/bento_card.dart (Phase 5)

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN VIEWS
// ─────────────────────────────────────────────────────────────────────────────

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.welcomeMsg, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(l10n.subWelcome, style: const TextStyle(color: AppColors.textVariant, fontSize: 16)),
        const SizedBox(height: 24),

        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.severe_cold, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(l10n.capacityTitle, style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.outline, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l10n.statusOptimal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('78%', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l10n.statusFull, style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  border: Border.all(color: AppColors.outline, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      border: Border(right: BorderSide(color: AppColors.outline, width: 2)),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: BentoCard(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('3', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(l10n.lblExpiring, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BentoCard(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('42', style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(l10n.lblTotal, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Pantry Insights entry card (Phase 6 — SQL analytics dashboard) ──
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PantryInsightsScreen(),
            ),
          ),
          child: BentoCard(
            backgroundColor: const Color(0xFF05162E),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.insights, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pantry Insights',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Expiry · Health · Recipes · Zones',
                        style: TextStyle(
                          color: Color(0xFF7BA8D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// IceFloeView
// ---------------------------------------------------------------------------

class IceFloeView extends StatefulWidget {
  const IceFloeView({super.key});

  @override
  State<IceFloeView> createState() => _IceFloeViewState();
}

class _IceFloeViewState extends State<IceFloeView> {
  late Future<List<dynamic>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _fetchInventory();
  }

  Future<List<dynamic>> _fetchInventory() async {
    final response = await http
        .get(Uri.parse('$backendUrl/inventory/1'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tabColdStorage, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(l10n.invSub, style: const TextStyle(color: AppColors.textVariant, fontSize: 16)),
              ],
            ),
            GestureDetector(
              onTap: () => setState(() => _inventoryFuture = _fetchInventory()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  border: Border.all(color: AppColors.outline, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(l10n.btnFilter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<dynamic>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    '${l10n.inventoryLoadError}\n${snapshot.error}',
                    style: const TextStyle(color: AppColors.textVariant, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Penguin empty-state illustration
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primary, width: 2.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 14,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.inventoryEmpty,
                        style: const TextStyle(
                          color: AppColors.textVariant,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _buildInventoryItem(context, items[i] as Map<String, dynamic>),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInventoryItem(BuildContext context, Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final String name = (item['product_name'] as String?) ??
        (item['upc'] != null ? 'UPC: ${item['upc']}' : 'Unknown Item');
    final int qty = (item['quantity'] as int?) ?? 1;
    final String expiry = (item['expiration_date'] as String?) ?? '—';
    final String subtitle = 'Qty: $qty  •  Exp: $expiry';

    return BentoCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              border: Border.all(color: AppColors.outline, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.kitchen, size: 32, color: AppColors.outline),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: AppColors.textVariant, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange,
              border: Border.all(color: AppColors.outline, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(l10n.lblExpiring, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// IntakePortalView
// ---------------------------------------------------------------------------

class IntakePortalView extends StatefulWidget {
  const IntakePortalView({super.key, this.scrollController});

  /// Optional controller from [DraggableScrollableSheet] so the sheet and
  /// the intake list share a single scrollable (avoids unbounded height).
  final ScrollController? scrollController;

  @override
  State<IntakePortalView> createState() => _IntakePortalViewState();
}

class _IntakePortalViewState extends State<IntakePortalView> {
  int _selectedMode = 1;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController  = TextEditingController(text: '1');
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _upcController  = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  String? _pickedImageName;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _zoneController.dispose();
    _upcController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
      ),
    );
  }

  Future<void> _submitBarcode() async {
    final upc = _upcController.text.trim();
    if (upc.isEmpty) {
      _showSnackBar('Please enter a UPC barcode number.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http
          .post(Uri.parse('$backendUrl/inventory/barcode/$upc?user_id=1&location_id=1&unit_id=1'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final name = (data['product_name'] as String?) ?? 'Item';
        _showSnackBar('Added: $name');
        _upcController.clear();
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final detail = body?['detail']?.toString() ?? 'Unknown error';
        _showSnackBar('Error ${response.statusCode}: $detail', isError: true);
      }
    } catch (e) {
      _showSnackBar('Connection failed. Check your network and try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndSubmitVision() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _pickedImageName = image.name;
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/inventory/scan-leftover?user_id=1&location_id=1&unit_id=1'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final name = (data['product_name'] as String?) ?? 'Item';
        _showSnackBar('Scanned: $name');
        setState(() => _pickedImageName = null);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final detail = body?['detail']?.toString() ?? 'Unknown error';
        _showSnackBar('Error ${response.statusCode}: $detail', isError: true);
      }
    } catch (e) {
      _showSnackBar('Connection failed. Check your network and try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitManual() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Captured Entry: ${_nameController.text}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    switch (_selectedMode) {
      case 0: await _submitBarcode(); break;
      case 2: await _pickAndSubmitVision(); break;
      default: _submitManual();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.tabIntake, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(l10n.intakeSub, style: const TextStyle(color: AppColors.textVariant, fontSize: 16)),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.outline, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildToggleButton(0, l10n.toggleBarcode, Icons.barcode_reader),
              _buildToggleButton(1, l10n.toggleManual,  Icons.edit_document),
              _buildToggleButton(2, l10n.toggleVision,  Icons.visibility),
            ],
          ),
        ),
        const SizedBox(height: 24),

        BentoCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildModeContent(l10n),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _handleSubmit,
                        icon: const Icon(Icons.inventory_2, color: Colors.white),
                        label: Text(
                          l10n.btnAdd,
                          style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppColors.outline, width: 2),
                          ),
                          elevation: 0,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildModeContent(AppLocalizations l10n) {
    if (_selectedMode == 0) return _buildBarcodeForm(l10n);
    if (_selectedMode == 2) return _buildVisionForm(l10n);
    return _buildManualForm(l10n);
  }

  List<Widget> _buildBarcodeForm(AppLocalizations l10n) {
    return [
      Text(l10n.formName, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Enter the product UPC barcode number below.', style: TextStyle(color: AppColors.textVariant, fontSize: 13)),
      const SizedBox(height: 8),
      _buildTextField('e.g., 012345678905', controller: _upcController, keyboardType: TextInputType.number),
    ];
  }

  List<Widget> _buildVisionForm(AppLocalizations l10n) {
    return [
      Text(l10n.formName, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Select a photo of your leftover or packaged item.', style: TextStyle(color: AppColors.textVariant, fontSize: 13)),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _isLoading ? null : () async {
          final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
          if (image != null) setState(() => _pickedImageName = image.name);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            border: Border.all(color: AppColors.outline, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textVariant),
              const SizedBox(height: 8),
              Text(
                _pickedImageName ?? 'Tap to select an image',
                style: TextStyle(
                  color: _pickedImageName != null ? AppColors.outline : AppColors.textVariant,
                  fontWeight: _pickedImageName != null ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildManualForm(AppLocalizations l10n) {
    return [
      Text(l10n.formName, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _buildTextField(l10n.hintName, controller: _nameController),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.formQty, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField('1', textAlign: TextAlign.center, controller: _qtyController),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.formZone, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField(l10n.hintZone, controller: _zoneController),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildToggleButton(int index, String label, IconData icon) {
    final bool isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLowest : Colors.transparent,
            border: isSelected ? Border.all(color: AppColors.outline, width: 2) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.outline : AppColors.textVariant),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.outline : AppColors.textVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextAlign textAlign = TextAlign.start,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textVariant),
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

// ---------------------------------------------------------------------------
// PenguinTipsView
// ---------------------------------------------------------------------------

class PenguinTipsView extends StatelessWidget {
  const PenguinTipsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BentoCard(
          backgroundColor: AppColors.surfaceLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l10n.tipsSpotlight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              ),
              const SizedBox(height: 16),
              Text(l10n.tipsTitle1, style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.tipsBody1, style: const TextStyle(fontSize: 16, color: AppColors.textVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BentoCard(
          backgroundColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  border: Border.all(color: AppColors.outline, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(l10n.tipsTitle2, style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(l10n.tipsBody2, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
