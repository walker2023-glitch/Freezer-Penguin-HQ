// Custom loading / splash screen — Phase 4.
//
// Lifecycle:
//   1. Entrance animation plays (700 ms fade + elastic scale on brand mark).
//   2. A Timer.periodic rotates through 5 localized quotes every 2 500 ms.
//      Each quote fades in via AnimatedSwitcher (400 ms crossfade).
//   3. After the 5th quote has been displayed (≈ 12.5 s total), the timer
//      fires one final tick, cancels itself, and calls AuthState.setReady().
//      In production, setReady() would be called when async init work
//      (token validation, prefetch) completes rather than a fixed timer.
//
// All visible strings are served through AppLocalizations — no hardcoded text.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_state.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  // ── Entrance animation ────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  // ── Rotating quote state ─────────────────────────────────────────────────
  // 0 = first quote shown; advances to 5 on the 5th tick then advances screen.
  int _quoteIndex = 0;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();

    // Entrance animation — plays once on mount
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();

    // Quote rotation — 2 500 ms per quote, 5 quotes = ≈ 12.5 s total
    _quoteTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _quoteIndex++;
        if (_quoteIndex >= 5) {
          timer.cancel();
          _quoteTimer = null;
          _advance();
        }
      });
    });
  }

  void _advance() {
    if (!mounted) return;
    context.read<AuthState>().setReady();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Quote list built in build() so l10n context is always available
    final quotes = [
      l10n.loadingQuote1,
      l10n.loadingQuote2,
      l10n.loadingQuote3,
      l10n.loadingQuote4,
      l10n.loadingQuote5,
    ];
    final currentQuote = quotes[_quoteIndex.clamp(0, 4)];

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated brand mark ─────────────────────────────────
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(
                          color: AppColors.outline,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.ac_unit,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── App title ────────────────────────────────────────────
                  Text(
                    l10n.appTitle,
                    style: GoogleFonts.quicksand(
                      color: AppColors.outline,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Tagline ──────────────────────────────────────────────
                  Text(
                    l10n.loadingTagline,
                    style: GoogleFonts.quicksand(
                      color: AppColors.textVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  // ── Separator ────────────────────────────────────────────
                  const SizedBox(height: 52),
                  SizedBox(
                    width: 72,
                    child: Divider(
                      color: AppColors.outline.withAlpha(55),
                      thickness: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Progress indicator ───────────────────────────────────
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                      backgroundColor: AppColors.textVariant.withAlpha(40),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Rotating quote (AnimatedSwitcher crossfade) ──────────
                  SizedBox(
                    height: 48, // fixed height prevents layout jump on text wrap
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: Text(
                        currentQuote,
                        key: ValueKey(_quoteIndex),
                        style: GoogleFonts.quicksand(
                          color: AppColors.textVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
