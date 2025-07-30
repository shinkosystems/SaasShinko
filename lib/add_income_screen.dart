import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/financial_form_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';

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
      final transactionData = Transaction(
        id: '', // Supabase irá gerar o ID automaticamente
        description: description,
        value: value,
        date: DateTime.now(),
        type: TransactionType.income,
      ).toJson();

      await supabase.from('transactions').insert(transactionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receita salva com sucesso!')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      print('Erro ao salvar receita no Supabase: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar receita: ${e.message}')),
      );
    } catch (e) {
      print('Erro inesperado ao salvar receita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado ao salvar receita.')),
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
        title: const Text('Adicionar Receita'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : FinancialFormWidget(
              formTitle: 'Insira os detalhes da Receita',
              buttonText: 'Salvar Receita',
              titleStyle: Theme.of(context).textTheme.headlineLarge!,
              onSave: (value, description) {
                _saveIncome(value, description);
              },
            ),
    );
  }
}