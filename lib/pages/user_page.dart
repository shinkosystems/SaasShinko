import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:saas_gestao_financeira_backup/ad_banner.dart';
import 'package:saas_gestao_financeira_backup/ad_interstitial.dart'; // Importe o arquivo do AdInterstitial

final supabase = Supabase.instance.client;

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String _userName = 'Carregando...';
  String _userEmail = 'Carregando...';
  File? _profileImage;
  String? _avatarUrl;

  bool _isLoading = true;
  String? _userId;

  bool _profileLoaded = false;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final AdInterstitial _adManager = AdInterstitial(); // Adiciona esta linha

  @override
  void initState() {
    super.initState();
    _adManager.loadAd(); // Adiciona esta linha
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
              content: Text('Nenhum usuário logado. Por favor, faça login.'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
          _profileLoaded = true;
          _userName = 'Usuário não logado';
          _userEmail = '';
        });
        print('DEBUG: Usuário não logado. _isLoading = false.'); // DEBUG
        return;
      }

      print('DEBUG: userId encontrado: $_userId'); // DEBUG

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
        print('DEBUG: Perfil carregado com sucesso!'); // DEBUG
        print('DEBUG: _userName: $_userName'); // DEBUG
        print('DEBUG: _userEmail: $_userEmail'); // DEBUG
        print('DEBUG: _avatarUrl no _getProfile: $_avatarUrl'); // DEBUG
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        if (e.code == 'PGRST116') {
          setState(() {
            _userName = 'Perfil novo';
            _userEmail =
                supabase.auth.currentUser?.email ?? 'Email não definido';
            _isLoading = false;
            _profileLoaded = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crie seu perfil inicial.')),
          );
          print(
              'DEBUG: Perfil não encontrado (PGRST116). _isLoading = false.',
          ); // DEBUG
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
          print(
              'DEBUG: Erro Postgrest ao carregar perfil: ${e.message}. _isLoading = false.',
          ); // DEBUG
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
        print(
            'DEBUG: Erro inesperado ao carregar perfil: $e. _isLoading = false.',
        ); // DEBUG
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    _userId = supabase.auth.currentUser?.id;
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum usuário logado para fazer upload de imagem.'),
          ),
        );
      }
      return;
    }

    final bytes = await image.readAsBytes();
    // -----------------------

    final String fileExtension = image.name.split('.').last;
    final String fileName =
        '${_userId!}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final String storagePath =
        'avatars/$fileName'; // 'avatars' é o bucket no Supabase Storage

    setState(() {
      _isLoading = true; // Mostra carregamento ao fazer upload
    });

    print('DEBUG: Tentando fazer upload para o path: $storagePath'); // DEBUG

    try {
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes, // Use os bytes do arquivo aqui
            fileOptions: const FileOptions(
              cacheControl: '3600', // Cache por 1 hora
              upsert:
                  true, // Se já existir um arquivo com o mesmo nome, substitui
            ),
          );

      await supabase
          .from('profiles')
          .update({
            'avatar_url':
                storagePath, // Salve o caminho no storage, não o public URL completo
            'updated_at': DateTime.now()
                .toIso8601String(), // Atualiza o timestamp
          })
          .eq('id', _userId!);

      if (mounted) {
        setState(() {
          _profileImage = null; // Limpe a imagem local para carregar da URL
          _avatarUrl = storagePath;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada!')),
        );
        print(
            'DEBUG: Upload e atualização do perfil concluídos. Novo _avatarUrl: $_avatarUrl',
        ); // DEBUG
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload da foto: ${e.message}')),
        );
        setState(() {
          _isLoading = false;
        });
        print(
            'DEBUG: Erro StorageException ao fazer upload: ${e.message}',
        ); // DEBUG
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao atualizar foto: $e')),
        );
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Erro inesperado ao fazer upload da foto: $e'); // DEBUG
      }
    }
  }

  void _changePassword() {
    _adManager.showAd(); // Adiciona esta linha
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
                  decoration: InputDecoration(
                    labelText: 'Senha Atual',
                    border: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(16), // AQUI
                    ),
                  ),
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
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    border: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(16), // AQUI
                    ),
                  ),
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
                  decoration: InputDecoration(
                    labelText: 'Confirme a Nova Senha',
                    border: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(16), // AQUI
                    ),
                  ),
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
                Navigator.of(dialogContext).pop();
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmNewPasswordController.clear();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    await supabase.auth.updateUser(
                      UserAttributes(password: _newPasswordController.text),
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Senha atualizada com sucesso!'),
                        ),
                      );
                    }
                  } on AuthException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao atualizar senha: ${e.message}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro inesperado ao atualizar senha: $e',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmNewPasswordController.clear();
                    }
                  }
                }
              },
              child: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // AQUI
                ),
              ),
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? (() {
                                      final imageUrl = supabase.storage
                                          .from('avatars')
                                          .getPublicUrl(_avatarUrl!);
                                      print(
                                          'DEBUG: Tentando carregar imagem da URL: $imageUrl',
                                      );
                                      return NetworkImage(imageUrl)
                                          as ImageProvider<Object>?;
                                    })()
                                  : (_profileImage != null
                                      ? FileImage(_profileImage!)
                                      : null),
                          child:
                              (_avatarUrl == null || _avatarUrl!.isEmpty) &&
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
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Trocar Senha'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BD9BC),
                          foregroundColor: const Color.fromARGB(255, 3, 3, 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // AQUI
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(child: AdBanner()),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}