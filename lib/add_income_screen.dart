import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/financial_form_widget.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  // Vamos criar TextControllers para pegar o valor dos campos de texto
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    // É importante descartar os controllers quando o widget não for mais usado
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Receita'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FinancialFormWidget(
        // Use o novo widget aqui!
        formTitle: 'Insira os detalhes da Receita',
        buttonText: 'Salvar Receita',
        titleStyle: Theme.of(context).textTheme.headlineLarge!,
        onSave: (value, description) {
          // Este callback será chamado quando o botão Salvar for pressionado e a validação passar
          print(
            'Receita salva (via callback)! Valor: R\$ ${value.toStringAsFixed(2)}, Descrição: $description',
          );
          // Aqui no futuro, você enviará para o Supabase
          Navigator.pop(
            context, //PORQUE CONTEXT
          ); // Opcional: Voltar para a tela anterior após salvar
        },
      ),
    );
  }
}
