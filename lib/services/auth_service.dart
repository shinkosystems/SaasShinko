import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para registrar um novo usuário
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username, // O username será tratado na signup_page
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Erro desconhecido ao registrar: $e');
    }
  }

  // Método para fazer login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw e; // Lança a exceção para ser tratada na UI
    } catch (e) {
      throw Exception('Erro desconhecido ao fazer login: $e');
    }
  }

  // Método para fazer logout
  Future<void> signOut() async {
    try {
      print('DEBUG: Tentando fazer logout no Supabase...');
      await _supabase.auth.signOut();
      print('DEBUG: AuthService.signOut() executado com sucesso.');
    } on AuthException catch (e) {
      print('DEBUG: Erro no AuthService.signOut() (AuthException): ${e.message}');
      throw e;
    } catch (e) {
      print('DEBUG: Erro no AuthService.signOut() (desconhecido): $e');
      throw Exception('Erro desconhecido ao fazer logout: $e');
    }
  }

  // Stream para observar o estado da autenticação
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}