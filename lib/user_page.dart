//modificação teste.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart'; // Import necessário para SchedulerBinding

// Acesse o cliente Supabase globalmente (ou passe-o via construtor/Provider)
final supabase = Supabase.instance.client;

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // Variáveis de estado
  String _userName = 'Carregando...'; // Texto inicial para carregamento
  String _userEmail = 'Carregando...'; // Texto inicial para carregamento
  File? _profileImage;
  String? _avatarUrl; // Para armazenar o URL da imagem do Supabase Storage

  bool _isLoading = true; // Para gerenciar o estado de carregamento inicial
  String? _userId; // ID do usuário logado

  // Variável para controlar se o perfil já foi carregado para evitar chamadas múltiplas
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    // Agendamos _getProfile para ser chamado após o primeiro frame de construção.
    // Isso garante que o BuildContext esteja completamente disponível para ScaffoldMessenger.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _getProfile();
    });
  }

  // didChangeDependencies não é mais necessário para a chamada inicial do perfil.
  // Pode ser removido ou usado para outras dependências se houver.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se você tiver outras lógicas que dependem de InheritedWidgets e precisam
    // ser reexecutadas quando as dependências mudam, coloque-as aqui.
    // Para _getProfile, removemos a chamada daqui para evitar múltiplas execuções.
  }


  // Função para buscar os dados do perfil do Supabase
  Future<void> _getProfile() async {
    // Evita chamar a função se o perfil já foi carregado
    if (_profileLoaded) return;

    setState(() {
      _isLoading = true; // Inicia o estado de carregamento
    });

    try {
      // Obter o ID do usuário logado
      _userId = supabase.auth.currentUser?.id;

      if (_userId == null) {
        // Se não há usuário logado, mostrar erro ou redirecionar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum usuário logado. Por favor, faça login.')),
          );
          // Opcional: Redirecionar para tela de login
          // await Future.delayed(const Duration(seconds: 2)); // Pequeno atraso para o SnackBar ser visível
          // if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        }
        setState(() {
          _isLoading = false; // Finaliza o carregamento
          _profileLoaded = true; // Marca como carregado mesmo com erro de usuário
          _userName = 'Usuário não logado';
          _userEmail = '';
        });
        return;
      }

      // Buscar os dados do perfil na tabela 'profiles'
      final response = await supabase
          .from('profiles')
          .select('username, email, avatar_url') // Seleciona as colunas desejadas
          .eq('id', _userId!) // Filtra pelo ID do usuário
          .single(); // Espera um único resultado

      if (mounted) {
        setState(() {
          _userName = response['username'] as String? ?? 'Nome não definido';
          _userEmail = response['email'] as String? ?? 'Email não definido';
          _avatarUrl = response['avatar_url'] as String?; // Pega o URL da imagem

          _isLoading = false; // Finaliza o carregamento
          _profileLoaded = true; // Marca que o perfil foi carregado
        });
      }

      // Se houver um avatar_url, tenta carregar a imagem (seja do local ou do Supabase)
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        // Não é necessário chamar _loadImageFromSupabase para NetworkImage,
        // pois NetworkImage lida com o carregamento da URL diretamente no `build`.
        // Apenas para garantir que o _avatarUrl seja o que estamos mostrando,
        // mas ele já está sendo usado.
      }

    } on PostgrestException catch (e) {
      if (mounted) {
        if (e.code == 'PGRST116') { // Código comum para "no rows found" (nenhuma linha encontrada)
          setState(() {
            _userName = 'Perfil novo';
            _userEmail = supabase.auth.currentUser?.email ?? 'Email não definido';
            _isLoading = false;
            _profileLoaded = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crie seu perfil inicial.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar perfil: ${e.message}')),
          );
          setState(() {
            _isLoading = false;
            _profileLoaded = true; // Marca como carregado mesmo com erro
            _userName = 'Erro ao carregar';
            _userEmail = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao carregar perfil: $e')),
        );
        setState(() {
          _isLoading = false;
          _profileLoaded = true; // Marca como carregado mesmo com erro
          _userName = 'Erro inesperado';
          _userEmail = '';
        });
      }
    }
  }

  // Função para selecionar e fazer upload da imagem de perfil
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Reduzir qualidade para uploads mais rápidos

    if (image == null) return;

    // Verificar se o usuário está logado antes de tentar upload
    _userId = supabase.auth.currentUser?.id;
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum usuário logado para fazer upload de imagem.')),
        );
      }
      return;
    }

    final File imageFile = File(image.path);
    final String fileExtension = image.path.split('.').last;
    final String fileName = '${_userId!}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final String storagePath = 'avatars/$fileName'; // 'avatars' é o bucket no Supabase Storage

    setState(() {
      _isLoading = true; // Mostra carregamento ao fazer upload
    });

    try {
      // Faça o upload da imagem para o Supabase Storage
      await supabase.storage.from('avatars').upload(
        storagePath,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600', // Cache por 1 hora
          upsert: true, // Se já existir um arquivo com o mesmo nome, substitui
        ),
      );

      // Atualize o URL do avatar na tabela 'profiles'
      await supabase.from('profiles').update({
        'avatar_url': storagePath, // Salve o caminho no storage, não o public URL completo
        'updated_at': DateTime.now().toIso8601String(), // Atualiza o timestamp
      }).eq('id', _userId!);

      if (mounted) {
        setState(() {
          _profileImage = imageFile; // Atualiza a imagem local (opcional, pois NetworkImage será usado)
          _avatarUrl = storagePath; // Atualiza o URL local para que o NetworkImage possa carregar
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada!')),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload da foto: ${e.message}')),
        );
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao atualizar foto: $e')),
        );
        setState(() { _isLoading = false; });
      }
    }
  }

  // Função para lidar com a troca de senha (usando Supabase Auth)
  void _changePassword() async {
    try {
      final userEmail = supabase.auth.currentUser?.email;
      if (userEmail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-mail do usuário não encontrado para redefinição de senha.')),
          );
        }
        return;
      }

      setState(() { _isLoading = true; }); // Opcional: mostrar carregamento durante esta operação

      await supabase.auth.resetPasswordForEmail(
        userEmail,
        // Certifique-se de que SUA_URL_DE_REDIRECIONAMENTO_DE_SENHA está configurada
        // corretamente no seu projeto Supabase e que seu aplicativo pode lidar com deep links.
        // redirectTo: 'sua_url_de_redirecionamento_de_senha_aqui',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Link de redefinição de senha enviado para seu e-mail! Verifique sua caixa de entrada.')),
        );
        setState(() { _isLoading = false; });
      }
    } on AuthException catch (e) { // Use AuthException para erros de autenticação do Supabase
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao solicitar redefinição de senha: ${e.message}')),
        );
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao solicitar redefinição: $e')),
        );
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80.0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra um indicador de carregamento
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Foto de Perfil
                    GestureDetector(
                      onTap: _pickAndUploadImage, // Chama a nova função de upload
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        // Usa NetworkImage se _avatarUrl existir, FileImage se _profileImage existir localmente, senão null
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(supabase.storage.from('avatars').getPublicUrl(_avatarUrl!)) as ImageProvider<Object>?
                            : (_profileImage != null ? FileImage(_profileImage!) as ImageProvider<Object>? : null),
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _profileImage == null
                            ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey[700],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Exibição do Nome (maior e em negrito)
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Exibição do E-mail
                    Text(
                      _userEmail,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Botão para Trocar Senha
                    ElevatedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Trocar Senha'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF025928),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Ainda mais funcionalidades em breve!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}