import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira_backup/financial_form_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saas_gestao_financeira_backup/models/transaction_model.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isSaving = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveIncome(double value, String description) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Obter o ID do usuário logado
      final User? user = supabase.auth.currentUser;
      if (user == null) {
        print('Nenhum usuário logado. Não é possível salvar a receita.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não logado.')),
          );
          Navigator.pop(context); // Volta se não houver usuário logado
        }
        return;
      }

      final transactionData = Transaction(
        id: '', // Supabase irá gerar o ID automaticamente
        description: description,
        value: value,
        date: DateTime.now(),
        type: TransactionType.income,
      ).toJson();

      // 2. Adicionar o user_id ao transactionData
      transactionData['user_id'] = user.id;

      await supabase.from('transactions').insert(transactionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita salva com sucesso!')),
        );
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      print('Erro ao salvar receita no Supabase: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar receita: ${e.message}')),
        );
      }
    } catch (e) {
      print('Erro inesperado ao salvar receita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao salvar receita.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Receita'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Align( // Alterado de Center para Align
        alignment: Alignment.topCenter, // Alinha ao topo e centraliza horizontalmente
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isSaving
              ? const Center(child: CircularProgressIndicator())
              : FinancialFormWidget(
                  formTitle: 'Insira os detalhes',
                  buttonText: 'Salvar Receita',
                  titleStyle: Theme.of(context).textTheme.headlineLarge!.copyWith(fontSize: 18),
                  onSave: (value, description) {
                    _saveIncome(value, description);
                  },
                ),
        ),
      ),
    );
  }
}