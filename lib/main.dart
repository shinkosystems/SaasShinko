import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira_backup/pages/home_page.dart';
import 'package:saas_gestao_financeira_backup/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rquhueanhjdozuhielag.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdWh1ZWFuaGpkb3p1aGllbGFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MjQ2MzMsImV4cCI6MjA2OTMwMDYzM30.kXkdpa6I7KnknyyAvdu1up2DEHyBC1-hy9BaYgKag4k',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKCash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 172, 224, 207),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data!.session != null) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
