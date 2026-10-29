import 'package:flutter/material.dart';

import 'data/daymark_store.dart';
import 'ui/daymark_app.dart';
import 'ui/theme/daymark_theme.dart';

void main() => runApp(const DaymarkLogin());

class DaymarkLogin extends StatefulWidget {
  const DaymarkLogin({super.key});
  @override
  State<DaymarkLogin> createState() => _DaymarkLoginState();
}

class _DaymarkLoginState extends State<DaymarkLogin> {
  final password = TextEditingController();
  DaymarkStore? store;
  String? error;
  bool loading = false;

  @override
  void dispose() {
    password.dispose();
    store?.close();
    super.dispose();
  }

  Future<void> unlock() async {
    if (password.text.isEmpty) {
      setState(() => error = 'Bitte ein Passwort eingeben.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final opened = await DaymarkStore.open(password.text);
      if (mounted) setState(() => store = opened);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      password.clear();
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daymark',
      debugShowCheckedModeBanner: false,
      theme: daymarkTheme(),
      home: store != null
          ? DaymarkApp(store: store!)
          : Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_outlined, size: 52),
                      const SizedBox(height: 12),
                      const Text(
                        'Daymark',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lokale Schülerverwaltung. Beim ersten Start wird mit diesem Passwort eine verschlüsselte Datenbank angelegt.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: password,
                        obscureText: true,
                        onSubmitted: (_) => unlock(),
                        decoration: const InputDecoration(
                          labelText: 'App-Passwort',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: loading ? null : unlock,
                        child: Text(loading ? 'Öffne…' : 'Öffnen'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
