import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/auth_state.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _nameController = TextEditingController(text: 'Apartment Household');
  final _inviteController = TextEditingController();
  bool _joining = false;
  bool _working = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _joining
        ? _inviteController.text.trim()
        : _nameController.text.trim();
    if (value.isEmpty) {
      setState(() => _error = _joining
          ? 'Enter an invite code.'
          : 'Enter a household name.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthState>();
      final response = _joining
          ? await http.post(
              Uri.parse('$backendUrl/household-invites/$value/accept'),
              headers: auth.authHeaders(),
            )
          : await http.post(
              Uri.parse('$backendUrl/households'),
              headers: auth.authHeaders(json: true),
              body: jsonEncode({'name': value}),
            );
      if (response.statusCode != 200 && response.statusCode != 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['detail']?.toString() ?? 'Server returned ${response.statusCode}');
      }
      if (mounted) widget.onComplete();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.home_work_outlined, size: 64, color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text(
                    'Set up your household',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create a household or join one with an invite code before using shared inventory.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Create')),
                      ButtonSegment(value: true, label: Text('Join')),
                    ],
                    selected: {_joining},
                    onSelectionChanged: _working
                        ? null
                        : (selection) => setState(() => _joining = selection.first),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _joining ? _inviteController : _nameController,
                    decoration: InputDecoration(
                      labelText: _joining ? 'Invite code' : 'Household name',
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !_working,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _working ? null : _submit,
                    child: _working
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_joining ? 'Join household' : 'Create household'),
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
