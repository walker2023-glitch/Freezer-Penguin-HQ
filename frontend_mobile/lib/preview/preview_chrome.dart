import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../state/app_settings.dart';
import '../state/auth_state.dart';
import 'lab/lab_shell.dart';
import 'preview_store.dart';

class PenguinMark extends StatelessWidget {
  const PenguinMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.outline,
        borderRadius: BorderRadius.circular(size * 0.29),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.15,
            child: Container(
              width: size * 0.41,
              height: size * 0.41,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.18,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void openPreviewSettings(BuildContext context) {
  final appSettings = context.read<AppSettings>();
  final authState = context.read<AuthState>();
  final store = context.read<PreviewKitchenStore>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: authState),
        ChangeNotifierProvider.value(value: store),
      ],
      child: const _PreviewSettingsSheet(),
    ),
  );
}

class _PreviewSettingsSheet extends StatelessWidget {
  const _PreviewSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final l10n = AppLocalizations.of(context)!;

    final store = context.watch<PreviewKitchenStore>();
    final companion = store.companion;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
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
      child: ListView(
        shrinkWrap: true,
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
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kitchen redesign preview — sign out to return to login.',
            style: GoogleFonts.quicksand(
              color: AppColors.textVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your penguin',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            companion.personality,
            style: GoogleFonts.quicksand(
              color: AppColors.textVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _companionOpt(context, store, CompanionKind.waddle, 'Waddle', 'Warm and chatty'),
          const SizedBox(height: 8),
          _companionOpt(context, store, CompanionKind.pip, 'Pip', 'Tiny and playful'),
          const SizedBox(height: 8),
          _companionOpt(context, store, CompanionKind.scout, 'Scout', 'Direct expedition lead'),
          const SizedBox(height: 8),
          _companionOpt(context, store, CompanionKind.custom, 'Custom', 'Name your own'),
          if (companion.kind == CompanionKind.custom) ...[
            const SizedBox(height: 10),
            const _CustomNameField(),
          ],
          const SizedBox(height: 20),
          _opt(context, l10n.themeNameGlacier, Icons.ac_unit, AppTheme.arctic, settings),
          const SizedBox(height: 8),
          _opt(context, l10n.themeNameKitchen, Icons.wb_sunny_outlined, AppTheme.light, settings),
          const SizedBox(height: 8),
          _opt(context, l10n.themeNameOcean, Icons.dark_mode_outlined, AppTheme.dark, settings),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final store = context.read<PreviewKitchenStore>();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: store,
                      child: const LabShell(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Try layout lab (experiment)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.outline,
                side: const BorderSide(color: AppColors.outline, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                side: BorderSide(color: Colors.red.shade700, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opt(
    BuildContext context,
    String label,
    IconData icon,
    AppTheme value,
    AppSettings settings,
  ) {
    final selected = settings.theme == value;
    return GestureDetector(
      onTap: () => settings.setTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(30)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.outline),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _companionOpt(
    BuildContext context,
    PreviewKitchenStore store,
    CompanionKind kind,
    String name,
    String blurb,
  ) {
    final selected = store.companion.kind == kind;
    return GestureDetector(
      onTap: () => store.setCompanionKind(kind),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withAlpha(35)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const PenguinMark(size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
                  Text(
                    blurb,
                    style: const TextStyle(
                      color: AppColors.textVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CustomNameField extends StatefulWidget {
  const _CustomNameField();

  @override
  State<_CustomNameField> createState() => _CustomNameFieldState();
}

class _CustomNameFieldState extends State<_CustomNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<PreviewKitchenStore>().companion.customName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: context.read<PreviewKitchenStore>().setCustomName,
      decoration: InputDecoration(
        hintText: 'e.g., Captain Frost',
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
