import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';

final supabase = Supabase.instance.client;

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // Variáveis de estado
  String _userName = 'Carregando...';
  String _userEmail = 'Carregando...';
  File? _profileImage;
  String? _avatarUrl;

  bool _isLoading = true;
  String? _userId;

  bool _profileLoaded = false;

  // Controladores para os campos de troca de senha
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  // Chave para o formulário de senha (se você quiser validação de formulário)
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _getProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    if (_profileLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _userId = supabase.auth.currentUser?.id;

      if (_userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nenhum usuário logado. Por favor, faça login.')),
          );
        }
        setState(() {
          _isLoading = false;
          _profileLoaded = true;
          _userName = 'Usuário não logado';
          _userEmail = '';
        });
        return;
      }

      // Buscar os dados do perfil na tabela 'profiles'
      final response = await supabase
          .from('profiles')
          .select('username, email, avatar_url')
          .eq('id', _userId!)
          .single();

      if (mounted) {
        setState(() {
          _userName = response['username'] as String? ?? 'Nome não definido';
          _userEmail = response['email'] as String? ?? 'Email não definido';
          _avatarUrl = response['avatar_url'] as String?;
          _isLoading = false;
          _profileLoaded = true;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        if (e.code == 'PGRST116') {
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
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70);

    if (image == null) return;

    // Verificar se o usuário está logado antes de tentar upload
    _userId = supabase.auth.currentUser?.id;
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Nenhum usuário logado para fazer upload de imagem.')),
        );
      }
      return;
    }

    final File imageFile = File(image.path);
    final String fileExtension = image.path.split('.').last;
    final String fileName =
        '${_userId!}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final String storagePath =
        'avatars/$fileName'; // 'avatars' é o bucket no Supabase Storage

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
              upsert:
                  true, // Se já existir um arquivo com o mesmo nome, substitui
            ),
          );

      // Atualize o URL do avatar na tabela 'profiles'
      await supabase.from('profiles').update({
        'avatar_url':
            storagePath, // Salve o caminho no storage, não o public URL completo
        'updated_at': DateTime.now().toIso8601String(), // Atualiza o timestamp
      }).eq('id', _userId!);

      if (mounted) {
        setState(() {
          _profileImage =
              imageFile; // Atualiza a imagem local (opcional, pois NetworkImage será usado)
          _avatarUrl =
              storagePath; // Atualiza o URL local para que o NetworkImage possa carregar
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao atualizar foto: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Função para lidar com a troca de senha (DENTRO DO APP)
  // Agora abrirá um diálogo para coletar as senhas
  void _changePassword() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Trocar Senha'),
          content: Form(
            key: _passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha Atual'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha atual.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova Senha'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a nova senha.';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter no mínimo 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirme a Nova Senha'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme a nova senha.';
                    }
                    if (value != _newPasswordController.text) {
                      return 'As senhas não coincidem.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                // Limpa os controladores após fechar o diálogo
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmNewPasswordController.clear();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(); // Fecha o diálogo antes de iniciar a operação

                  setState(() { _isLoading = true; }); // Ativa o loading na página principal

                  try {
                    // Supabase não exige a senha atual para update,
                    // mas é uma boa prática para UX/segurança na validação do seu lado.
                    // O Supabase irá verificar a sessão do usuário.
                    await supabase.auth.updateUser(
                      UserAttributes(
                        password: _newPasswordController.text,
                      ),
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Senha atualizada com sucesso!')),
                      );
                    }
                  } on AuthException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao atualizar senha: ${e.message}')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro inesperado ao atualizar senha: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() { _isLoading = false; }); // Desativa o loading
                      // Limpa os controladores após a tentativa de atualização
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmNewPasswordController.clear();
                    }
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
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
          ? const Center(
              child:
                  CircularProgressIndicator()) // Mostra um indicador de carregamento
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Foto de Perfil
                    GestureDetector(
                      onTap:
                          _pickAndUploadImage, // Chama a nova função de upload
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        // Usa NetworkImage se _avatarUrl existir, FileImage se _profileImage existir localmente, senão null
                        backgroundImage:
                            _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? (() {
                                    final imageUrl = supabase.storage
                                        .from('avatars')
                                        .getPublicUrl(_avatarUrl!);
                                    print(
                                        'DEBUG: Tentando carregar imagem da URL: $imageUrl');
                                    return NetworkImage(imageUrl)
                                        as ImageProvider<Object>?;
                                  })()
                                : (_profileImage != null
                                    ? FileImage(_profileImage!)
                                        as ImageProvider<Object>?
                                    : null),
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty) &&
                                _profileImage == null
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}