import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import 'preview_chrome.dart';
import 'preview_store.dart';

class ChatMessage {
  ChatMessage({required this.fromPenguin, required this.text});
  final bool fromPenguin;
  final String text;
}

void openPenguinChat(BuildContext context, {PreviewRecipe? recipe}) {
  final store = context.read<PreviewKitchenStore>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: store,
      child: _PenguinChatSheet(recipe: recipe),
    ),
  );
}

class _PenguinChatSheet extends StatefulWidget {
  const _PenguinChatSheet({this.recipe});
  final PreviewRecipe? recipe;

  @override
  State<_PenguinChatSheet> createState() => _PenguinChatSheetState();
}

class _PenguinChatSheetState extends State<_PenguinChatSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    final name = context.read<PreviewKitchenStore>().companion.name;
    _messages = [
      ChatMessage(
        fromPenguin: true,
        text: recipe == null
            ? 'I’m $name. Ask about cooking with what’s in your icebox. I’m a helper, not a doctor or dietitian.'
            : 'Let’s cook ${recipe.title}. Ask me about swaps, timing, or missing ingredients — I’m $name, not medical advice.',
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(fromPenguin: false, text: text));
      _messages.add(ChatMessage(fromPenguin: true, text: _reply(text)));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _reply(String text) {
    final companion = context.read<PreviewKitchenStore>().companion;
    final q = text.toLowerCase();
    final body = () {
      if (q.contains('expir') || q.contains('tonight')) {
        return 'Cook the leftover chili first — shortest clock. Chili Mac is about 20 minutes.';
      }
      if (q.contains('swap') || q.contains('substitut') || q.contains('instead')) {
        return 'No soy sauce? Salt plus a squeeze of lemon gets you close. Taste at the end.';
      }
      if (q.contains('milk')) {
        return 'Milk still has plenty of days. Save it for breakfast and cook the broccoli this week.';
      }
      return 'Use Urgent first, then Soon. This preview uses canned answers — live Gemini can plug in later.';
    }();
    switch (companion.kind) {
      case CompanionKind.pip:
        return 'Pip hop: $body';
      case CompanionKind.scout:
        return 'Scout report: $body';
      case CompanionKind.custom:
        return '${companion.name} here. $body';
      case CompanionKind.waddle:
        return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, sheetScroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: AppColors.outline, width: 2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textVariant.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const PenguinMark(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask ${context.watch<PreviewKitchenStore>().companion.name}',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          context.watch<PreviewKitchenStore>().companion.disclaimer,
                          style: const TextStyle(
                            color: AppColors.textVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('What should I cook tonight?'),
                _chip('Ingredient swap?'),
                _chip('Use the milk?'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  return Align(
                    alignment:
                        m.fromPenguin ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: m.fromPenguin
                            ? Theme.of(context).colorScheme.surface
                            : AppColors.primary,
                        border: Border.all(color: AppColors.outline, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color: m.fromPenguin ? AppColors.outline : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask a cooking question…',
                        filled: true,
                        fillColor: AppColors.surfaceLowest,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.outline, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.outline, width: 2),
                    ),
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      side: const BorderSide(color: AppColors.outline, width: 1.5),
      backgroundColor: AppColors.surfaceLowest,
      onPressed: () => _send(label),
    );
  }
}
