import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Ativa o estado de carregamento
      });
      try {
        final AuthResponse response = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _usernameController.text.trim().isEmpty
              ? null
              : _usernameController.text.trim(),
        );

        if (mounted) {
          if (response.user != null) {
            final user = response.user!;
            try {
              // --- INÍCIO DA ALTERAÇÃO: VERIFICA E INSERE O PERFIL ---
              // Primeiro, tenta buscar o perfil para ver se ele já existe
              final existingProfile = await Supabase.instance.client
                  .from('profiles')
                  .select('id')
                  .eq('id', user.id)
                  .maybeSingle(); // maybeSingle retorna null se não encontrar

              if (existingProfile == null) {
                // Se o perfil NÃO existe, então insira-o
                await Supabase.instance.client.from('profiles').insert({
                  'id': user.id,
                  'username': _usernameController.text.trim(),
                  'email': user.email,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conta criada com sucesso! Verifique seu e-mail para confirmar.')),
                );
                // Navegar para a página de login ou para a home
                Navigator.of(context).pushReplacementNamed('/login'); // Ou '/home' se for login automático
              } else {
                // Se o perfil JÁ existe (o que causa o "profiles_pkey" em chamadas duplicadas)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro: Perfil já existente para este usuário. Redirecionando para Login.')),
                );
                Navigator.of(context).pushReplacementNamed('/login'); // Ou outra ação apropriada
              }
              // --- FIM DA ALTERAÇÃO ---

            } catch (profileInsertError) {
              print('Erro ao inserir perfil: $profileInsertError');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao criar perfil do usuário: $profileInsertError')),
              );
            }
          } else {
            // Isso pode acontecer se o email já estiver em uso, mas o Supabase já trata com AuthException
            // Este bloco pode ser redundante se a AuthException pegar tudo.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email já utilizado por outro usuário!')),
            );
          }
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de autenticação: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro inesperado: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Desativa o estado de carregamento no final
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Nome de Usuário (Opcional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter no mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // --- INÍCIO DA ALTERAÇÃO: DESABILITAR BOTÃO DURANTE CARREGAMENTO ---
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp, // Removido o ternário, pois o _isLoading já controla qual widget é exibido
                        child: const Text('Criar Conta'),
                      ),
                // --- FIM DA ALTERAÇÃO ---
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text('Já tem uma conta? Faça Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}