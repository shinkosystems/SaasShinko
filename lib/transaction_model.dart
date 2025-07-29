enum TransactionType { income, expense }

class Transaction {
  final String
  id; //É como se estivessemos criando uma tabela no Supa base. Nome da coluna, tipo de dado que é aceito nessa coluna (text, timestamp...)
  final String description;
  final double value;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.description,
    required this.value,
    required this.date,
    required this.type,
  });
}
