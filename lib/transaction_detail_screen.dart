import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction; // A transação a ser editada/visualizada

  const TransactionDetailScreen({Key? key, required this.transaction})
      : super(key: key);

  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  // Controladores para os campos de texto e variáveis para os dropdowns/datas
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late TransactionType _selectedType; // Use o enum TransactionType
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores e variáveis com os dados da transação que foi passada
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _valueController = TextEditingController(
        text: widget.transaction.value.toStringAsFixed(2));
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  // Função para atualizar a transação no Supabase
  Future<void> _updateTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        await supabase
            .from('transactions') // Nome da sua tabela no Supabase
            .update({
          'description': _descriptionController.text,
          'value': double.parse(_valueController.text
              .replaceAll(',', '.')), // Substitui vírgula por ponto para parse
          'type':
              _selectedType.toString().split('.').last, // 'income' ou 'expense'
          'date':
              _selectedDate.toIso8601String(), // Formato ISO 8601 para Supabase
        }).eq(
                'id',
                widget.transaction
                    .id); // Condição: atualiza onde o ID corresponde

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação atualizada com sucesso!')),
        );
        Navigator.pop(context,
            true); // Retorna e sinaliza que a lista deve ser recarregada
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar transação: $error')),
        );
        print('Erro de atualização Supabase: $error'); // Para depuração
      }
    }
  }

  // Função para excluir a transação do Supabase
  Future<void> _deleteTransaction() async {
    final bool? confirm = await showDialog(
      // Pergunta ao usuário se ele realmente quer excluir
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir esta transação?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancela
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirma
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Se o usuário confirmou
      try {
        await supabase
            .from('transactions') // Nome da sua tabela no Supabase
            .delete()
            .eq(
                'id',
                widget
                    .transaction.id); // Condição: exclui onde o ID corresponde

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída com sucesso!')),
        );
        Navigator.pop(context,
            true); // Retorna e sinaliza que a lista deve ser recarregada
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir transação: $error')),
        );
        print('Erro de exclusão Supabase: $error'); // Para depuração
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Transação'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete), // Ícone de lixeira para exclusão
            onPressed: _deleteTransaction, // Chama a função de exclusão
            tooltip: 'Excluir Transação',
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Permite rolar a tela se o conteúdo for grande
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Chave para validar o formulário
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: true), // Teclado numérico com suporte a decimais
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ', // Prefixo de moeda
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    // Valida com ponto ou vírgula
                    return 'Por favor, insira um número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Salário, Aluguel, Compras',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // Espaçamento
              DropdownButtonFormField<TransactionType>(
                // Dropdown para selecionar o tipo (Receita/Despesa)
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('Receita'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('Despesa'),
                  ),
                ],
                onChanged: (TransactionType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione um tipo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                // Widget para selecionar a data
                title: const Text('Data da Transação'),
                subtitle: Text(DateFormat('dd/MM/yyyy')
                    .format(_selectedDate)), // Mostra a data formatada
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000), // Data mínima
                    lastDate: DateTime(2101), // Data máxima
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Center(
                // Botão para salvar as alterações
                child: ElevatedButton(
                  onPressed:
                      _updateTransaction, // Chama a função de atualização
                  child: const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
