import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira_backup/financial_form_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saas_gestao_financeira_backup/models/transaction_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isSaving = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveExpense(
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
        type: TransactionType.expense,
      ).toJson();

      transactionData['user_id'] = user.id;

      await supabase.from('transactions').insert(transactionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Despesa salva com sucesso!')),
        );
        // Retorna `true` se a transação foi salva com sucesso
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar despesa: ${e.message}')),
        );
        // Retorna `false` em caso de erro na API
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado ao salvar despesa.')),
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
        title: const Text('Adicionar Despesa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isSaving
              ? const Center(child: CircularProgressIndicator())
              : FinancialFormWidget(
                  formTitle: 'Insira os detalhes',
                  buttonText: 'Salvar Despesa',
                  titleStyle: Theme.of(context)
                      .textTheme
                      .headlineLarge!
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  onSave: (value, description, date) {
                    _saveExpense(value, description, date);
                  },
                ),
        ),
      ),
    );
  }
}