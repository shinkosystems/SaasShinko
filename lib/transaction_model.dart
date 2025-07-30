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

factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      description: json['description'] as String,
      value: (json['value'] as num).toDouble(), // Supabase pode retornar como int ou double
      date: DateTime.parse(json['date'] as String), // Parse a string de data para DateTime
      type: (json['type'] == 'income') ? TransactionType.income : TransactionType.expense,
    );
  }

  // Método para converter um objeto Transaction para um Map (para enviar ao Supabase)
  Map<String, dynamic> toJson() {
    return {
      // 'id' não é enviado no INSERT se for gerado automaticamente pelo Supabase
      'description': description,
      'value': value,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }
}