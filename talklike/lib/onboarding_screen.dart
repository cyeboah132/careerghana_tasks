import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function(Profile) onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _country = TextEditingController();
  String _native = 'en';
  String? _other;
  String _gender = 'Prefer not to say';
  String? _error;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  void _submit() {
    final age = int.tryParse(_age.text.trim());
    if (_name.text.trim().isEmpty ||
        _country.text.trim().isEmpty ||
        age == null ||
        age < 1 ||
        age > 120) {
      setState(() => _error = 'Please fill in your name, age and country.');
      return;
    }
    widget.onDone(
      Profile(
        name: _name.text.trim(),
        age: age,
        country: _country.text.trim(),
        native: _native,
        other: _other,
        gender: _gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const Text(
              'Welcome to TalkLike',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'A few quick questions to get started.',
              style: TextStyle(color: kMuted),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _country,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _native,
              dropdownColor: kSurface,
              decoration: const InputDecoration(labelText: 'Your language'),
              items: [
                for (final l in langs)
                  DropdownMenuItem(value: l.code, child: Text(l.name)),
              ],
              onChanged: (v) => setState(() => _native = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _other,
              dropdownColor: kSurface,
              decoration: const InputDecoration(
                labelText: 'Another language you love',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final l in langs)
                  DropdownMenuItem(value: l.code, child: Text(l.name)),
              ],
              onChanged: (v) => setState(() => _other = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              dropdownColor: kSurface,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: [
                for (final g in _genders)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: kMuted)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _submit, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}
