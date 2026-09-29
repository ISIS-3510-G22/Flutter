import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:plansync/firebase_options.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/auth_service.dart';
import 'package:plansync/services/theme_service.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/views/auth/login_view.dart';
import 'package:plansync/views/home_shell.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const AuthGate(),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        MaterialApp app(Widget home) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.watch<ThemeService>().mode,
          home: home,
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return app(
            Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final user = snapshot.data;

        if (user == null) {
          return app(LoginView());
        }
        return Provider<User>.value(value: user, child: app(HomeShell()));
      },
    );
  }
}
