import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  ThemeMode themeMode = ThemeMode.light;

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
      final savedTheme = await opened.setting('theme');
      if (mounted) {
        setState(() {
          store = opened;
          themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      password.clear();
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    DaymarkColors.dark = themeMode == ThemeMode.dark;
    return MaterialApp(
      title: 'Daymark',
      debugShowCheckedModeBanner: false,
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: daymarkTheme(),
      darkTheme: daymarkTheme(dark: true),
      themeMode: themeMode,
      home: store != null
          ? DaymarkApp(
              store: store!,
              onSessionEnded: () => setState(() => store = null),
              onThemeChanged: (value) => setState(() => themeMode = value),
            )
          : Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 120,
                        color: Colors.white,
                        child: Image.asset(
                          'assets/branding/daymark-logo-v1.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'Daymark',
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
