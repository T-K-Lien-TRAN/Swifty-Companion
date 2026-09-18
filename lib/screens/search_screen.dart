import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/exeptions.dart';
import 'profile_screen.dart';

class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({super.key});
  @override
  State<StudentSearchPage> createState() => _StudentSearchPageState();
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  final _controller = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final login = _controller.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z][a-z0-9_-]{0,31}$').hasMatch(login)) {
      setState(() => _error = 'Enter a valid 42 login.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final student = await _api.fetchStudent(login);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(student: student),
      ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16E883);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.polyline, size: 40, color: green),
                const SizedBox(height: 20),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Swifty'),
                    TextSpan(text: 'Companion', style: TextStyle(color: green)),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('42 student profile lookup', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 48),
                const Text('STUDENT LOGIN', style: TextStyle(
                    fontSize: 12, letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  enabled: !_loading,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    hintText: 'jdupont',
                    prefixIcon: Icon(Icons.chevron_right, color: green),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: green, foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Search'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
