import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira_backup/pages/home_page.dart';
import 'package:saas_gestao_financeira_backup/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Carregue as variáveis do .env

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Use a variável de ambiente
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Use a variável de ambiente
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
