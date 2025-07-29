import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/financial_form_widget.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Sempre que a tela atual não foi a principal ou a primeira, o app bar já vem, automaticamente, com o botão de voltar.
        title: const Text('Adicionar Despesa'),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.inversePrimary, // Cor da AppBar
      ),
      body: FinancialFormWidget(
        // Use o novo widget aqui!
        formTitle: 'Insira os detalhes da Despesa',
        buttonText: 'Salvar Despesa',
        titleStyle: Theme.of(context).textTheme.headlineLarge!,
        onSave: (value, description) {
          // Este callback será chamado quando o botão Salvar for pressionado e a validação passar
          print(
            'Receita salva (via callback)! Valor: R\$ ${value.toStringAsFixed(2)}, Descrição: $description',
          );
          // Aqui no futuro, você enviará para o Supabase
          Navigator.pop(
            context, //context serve para infromar ao programa qual navigator está solicitando o .pop, evitando fechar a tela errada.
          ); // Opcional: Voltar para a tela anterior após salvar
        },
      ),
    );
  }
}
