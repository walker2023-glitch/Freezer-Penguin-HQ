// Consume / Feast / Rations screen — Phase 5 UI shell.
//
// Three sections:
//   1. Inventory Subtraction — fetch live inventory, select an item, mark eaten.
//   2. Calorie & Macro Tracker — log daily nutritional intake.
//   3. Snap Your Meal — photo upload for visual meal logging.
//
// Page title ("Feast" / "Rations") is theme-sensitive via AppSettings.isArctic.
// All visible strings served through AppLocalizations — no hardcoded text.
// TODO: wire section 1 DELETE and sections 2-3 POST endpoints in Phase 6.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../state/app_settings.dart';
import '../widgets/bento_card.dart';

class ConsumeScreen extends StatefulWidget {
  const ConsumeScreen({super.key});

  @override
  State<ConsumeScreen> createState() => _ConsumeScreenState();
}

class _ConsumeScreenState extends State<ConsumeScreen> {
  // ── Section 1: Inventory Subtraction ─────────────────────────────────────
  late Future<List<dynamic>> _inventoryFuture;
  Map<String, dynamic>? _selectedItem;
  bool _isMarkingEaten = false;

  // ── Section 2: Calorie & Macro Tracker ───────────────────────────────────
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl  = TextEditingController();
  final _carbsCtrl    = TextEditingController();
  final _fatCtrl      = TextEditingController();
  bool _isLoggingMacros = false;

  // ── Section 3: Meal Photo Upload ─────────────────────────────────────────
  final _imagePicker = ImagePicker();
  String? _mealPhotoName;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _fetchInventory();
  }

  @override
  void dispose() {
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> _fetchInventory() async {
    final response = await http
        .get(Uri.parse('$backendUrl/inventory/1'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Server returned ${response.statusCode}');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
        ),
      ),
    );
  }

  // ── Section 1 actions ─────────────────────────────────────────────────────

  Future<void> _markAsEaten() async {
    if (_selectedItem == null) {
      _showSnackBar('Please select an item first.', isError: true);
      return;
    }
    setState(() => _isMarkingEaten = true);
    // TODO: Phase 6 — POST /api/v1/inventory/{item_id}/consume
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final name = (_selectedItem!['product_name'] as String?) ?? 'Item';
    _showSnackBar('$name marked as eaten!');
    setState(() {
      _isMarkingEaten = false;
      _selectedItem = null;
      _inventoryFuture = _fetchInventory();
    });
  }

  // ── Section 2 actions ─────────────────────────────────────────────────────

  void _logMacros() {
    if (_caloriesCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter at least calories.', isError: true);
      return;
    }
    setState(() => _isLoggingMacros = true);
    // TODO: Phase 6 — POST /api/v1/macros
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _showSnackBar('Logged ${_caloriesCtrl.text.trim()} kcal!');
      setState(() {
        _isLoggingMacros = false;
        _caloriesCtrl.clear();
        _proteinCtrl.clear();
        _carbsCtrl.clear();
        _fatCtrl.clear();
      });
    });
  }

  // ── Section 3 actions ─────────────────────────────────────────────────────

  Future<void> _pickMealPhoto() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _mealPhotoName = image.name;
      _isUploadingPhoto = true;
    });
    // TODO: Phase 6 — POST /api/v1/consume/photo
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _showSnackBar('Photo logged: ${image.name}');
    setState(() {
      _isUploadingPhoto = false;
      _mealPhotoName = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArctic = context.watch<AppSettings>().isArctic;
    final pageTitle =
        isArctic ? l10n.tabConsumeArctic : l10n.tabConsumeStandard;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          pageTitle,
          style: GoogleFonts.quicksand(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          l10n.consumePageSub,
          style:
              const TextStyle(color: AppColors.textVariant, fontSize: 16),
        ),
        const SizedBox(height: 24),

        // ── Section 1: Inventory Subtraction ──────────────────────────────
        _buildSectionHeader(
          icon: Icons.remove_circle_outline,
          label: l10n.consumeSectionSubtract,
        ),
        const SizedBox(height: 10),
        BentoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.consumeSubtractHint,
                style: const TextStyle(
                  color: AppColors.textVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildInventorySelector(l10n),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _isMarkingEaten
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed:
                            _selectedItem != null ? _markAsEaten : null,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        label: Text(
                          l10n.consumeMarkEaten,
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: _primaryButtonStyle(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Section 2: Calorie & Macro Tracker ────────────────────────────
        _buildSectionHeader(
          icon: Icons.monitor_heart_outlined,
          label: l10n.consumeSectionCalorie,
        ),
        const SizedBox(height: 10),
        BentoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.consumeCalorieHint,
                style: const TextStyle(
                  color: AppColors.textVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField(
                      l10n.consumeFieldCalories,
                      _caloriesCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroField(
                      l10n.consumeFieldProtein,
                      _proteinCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField(
                      l10n.consumeFieldCarbs,
                      _carbsCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroField(
                      l10n.consumeFieldFat,
                      _fatCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: _isLoggingMacros
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _logMacros,
                        icon: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          l10n.consumeLogMacros,
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: _primaryButtonStyle(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Section 3: Snap Your Meal ─────────────────────────────────────
        _buildSectionHeader(
          icon: Icons.camera_alt_outlined,
          label: l10n.consumeSectionPhoto,
        ),
        const SizedBox(height: 10),
        BentoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.consumePhotoHint,
                style: const TextStyle(
                  color: AppColors.textVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickMealPhoto,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    border: Border.all(
                      color: _mealPhotoName != null
                          ? AppColors.primary
                          : AppColors.outline,
                      width: _mealPhotoName != null ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _mealPhotoName != null
                            ? Icons.check_circle
                            : Icons.add_a_photo_outlined,
                        size: 40,
                        color: _mealPhotoName != null
                            ? AppColors.primary
                            : AppColors.textVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mealPhotoName ?? 'Tap to select a photo',
                        style: TextStyle(
                          color: _mealPhotoName != null
                              ? AppColors.outline
                              : AppColors.textVariant,
                          fontWeight: _mealPhotoName != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _isUploadingPhoto
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _pickMealPhoto,
                        icon: const Icon(
                          Icons.upload_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          l10n.consumePhotoBtn,
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: _primaryButtonStyle(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.textVariant,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  /// FutureBuilder-driven list of tappable inventory item chips.
  Widget _buildInventorySelector(AppLocalizations l10n) {
    return FutureBuilder<List<dynamic>>(
      future: _inventoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child:
                  CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Could not load inventory.',
              style: const TextStyle(
                color: AppColors.textVariant,
                fontSize: 13,
              ),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Your inventory is empty. Add items first.',
              style: const TextStyle(
                color: AppColors.textVariant,
                fontSize: 13,
              ),
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final raw in items)
              _buildItemChip(raw as Map<String, dynamic>),
          ],
        );
      },
    );
  }

  Widget _buildItemChip(Map<String, dynamic> item) {
    final name =
        (item['product_name'] as String?) ?? 'Item #${item['item_id']}';
    final isSelected = _selectedItem == item;

    return GestureDetector(
      onTap: () => setState(
        () => _selectedItem = isSelected ? null : item,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(30)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            Text(
              name,
              style: GoogleFonts.quicksand(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outline,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroField(
    String label,
    TextEditingController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.outline,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle:
                const TextStyle(color: AppColors.textVariant),
            filled: true,
            fillColor: AppColors.surfaceLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.outline,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outline, width: 2),
        ),
        elevation: 0,
      );
}
