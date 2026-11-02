import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/remote_config_service.dart';

final remote = RemoteConfigService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await remote.init();
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // كل تغيير في الإعدادات عن بعد يعيد بناء الواجهة مباشرة
    return ListenableBuilder(
      listenable: remote,
      builder: (context, _) {
        final c = remote.config;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: c.appTitle,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: c.primaryColor,
            brightness: c.darkMode ? Brightness.dark : Brightness.light,
          ),
          home: HomeScreen(remote: remote),
        );
      },
    );
  }
}
