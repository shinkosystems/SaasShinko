import 'package:flutter/material.dart';

class FinancialFormWidget extends StatefulWidget {
  final Function(double value, String description) onSave;
  final String formTitle; // Para diferenciar Receita/Despesa no título
  final String buttonText; // Para diferenciar o texto do botão
  final TextStyle titleStyle; // <--- NOVA PROPRIEDADE AQUI!

  const FinancialFormWidget({
    super.key,
    required this.onSave,
    required this.formTitle,
    required this.buttonText,
    required this.titleStyle, // <--- ADICIONE AO CONSTRUTOR
  });

  @override
  State<FinancialFormWidget> createState() => _FinancialFormWidgetState();
}

class _FinancialFormWidgetState extends State<FinancialFormWidget> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final String valueText = _valueController.text;
    final String description = _descriptionController.text;

    if (valueText.isEmpty) {
      _showSnackBar('Erro: O campo "Valor" não pode ser vazio!');
      return;
    }

    final double? value = double.tryParse(valueText.replaceAll(',', '.'));
    if (value == null) {
      _showSnackBar('Erro: Por favor, insira um número válido para o valor!');
      return;
    }

    // Se tudo estiver OK, chame o callback para a tela pai
    widget.onSave(value, description);

    // Opcional: Limpar os campos após salvar
    _valueController.clear();
    _descriptionController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.formTitle, // Usa o título passado pelo construtor
            style: widget.titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Valor', // Genérico
              prefixText: 'R\$ ',
              hintText: 'Ex: 1500.00',
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Descrição', // Genérico
              hintText: 'Ex: Salário, Venda de Produto, Freela',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveTransaction, // Chama o método de salvar
              child: Text(
                widget
                    .buttonText, // Usa o texto do botão passado pelo construtor
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
