import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/financial_form_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';

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

  Future<void> _saveExpense(double value, String description) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final transactionData = Transaction(
        id: '', // Supabase irá gerar o ID automaticamente
        description: description,
        value: value,
        date: DateTime.now(),
        type: TransactionType.expense,
      ).toJson();

      await supabase.from('transactions').insert(transactionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Despesa salva com sucesso!')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      print('Erro ao salvar despesa no Supabase: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar despesa: ${e.message}')),
      );
    } catch (e) {
      print('Erro inesperado ao salvar despesa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado ao salvar despesa.')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : FinancialFormWidget(
              formTitle: 'Insira os detalhes da Despesa',
              buttonText: 'Salvar Despesa',
              titleStyle: Theme.of(context).textTheme.headlineLarge!,
              onSave: (value, description) {
                _saveExpense(value, description);
              },
            ),
    );
  }
}