import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira_backup/financial_form_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saas_gestao_financeira_backup/models/transaction_model.dart';
import 'package:saas_gestao_financeira_backup/ad_banner.dart';

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

  Future<void> _saveIncome(
      double value, String description, DateTime date) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final User? user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não logado.')),
          );
          // Retorna `false` se não houver usuário logado
          Navigator.pop(context, false);
        }
        return;
      }

      final transactionData = Transaction(
        id: '',
        description: description,
        value: value,
        date: date,
        type: TransactionType.income,
      ).toJson();

      transactionData['user_id'] = user.id;

      await supabase.from('transactions').insert(transactionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita salva com sucesso!')),
        );
        // Retorna `true` se a transação foi salva com sucesso
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar receita: ${e.message}')),
        );
        // Retorna `false` em caso de erro na API
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado ao salvar receita.')),
        );
        // Retorna `false` em caso de erro inesperado
        Navigator.pop(context, false);
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      FinancialFormWidget(
                        formTitle: 'Insira os detalhes',
                        buttonText: 'Salvar Receita',
                        titleStyle:
                            Theme.of(context).textTheme.headlineLarge!.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                        onSave: (value, description, date) {
                          _saveIncome(value, description, date);
                        },
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