// financial_form_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira/ad_interstitial.dart';

class FinancialFormWidget extends StatefulWidget {
  final Function(double value, String description, DateTime date) onSave;
  final String formTitle;
  final String buttonText;
  final TextStyle titleStyle;

  const FinancialFormWidget({
    super.key,
    required this.onSave,
    required this.formTitle,
    required this.buttonText,
    required this.titleStyle,
  });

  @override
  State<FinancialFormWidget> createState() => _FinancialFormWidgetState();
}

class _FinancialFormWidgetState extends State<FinancialFormWidget> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  // Adiciona uma instância da classe AdInterstitial
  final AdInterstitial _adManager = AdInterstitial();

  @override
  void initState() {
    super.initState();
    // Pré-carrega o anúncio quando o widget é inicializado
    _adManager.loadAd();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

    // Chama o anúncio intersticial.
    _adManager.showAd();

    // A lógica de salvar a transação permanece a mesma.
    widget.onSave(value, description, _selectedDate);

    // Opcional: Limpar os campos após salvar e resetar a data para hoje
    _valueController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
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
            widget.formTitle,
            style: widget.titleStyle,
            textAlign: TextAlign.center,
          ),
          const Divider(),
          const SizedBox(height: 20),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelText: 'Valor',
              prefixText: 'R\$ ',
              hintText: 'Ex: 1500.00',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              border: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelText: 'Descrição',
              hintText: 'Ex: Salário, Venda de Produto, Freela',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('Data da Transação'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.buttonText,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}