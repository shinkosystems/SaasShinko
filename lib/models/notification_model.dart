// notification_model.dart

import 'package:flutter/foundation.dart';

@immutable
class NotificationModel {
  final String title;
  final String content;

  const NotificationModel({
    required this.title,
    required this.content,
  });

  // Construtor de fábrica para criar uma instância a partir de um mapa (como o retornado pelo Supabase)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['titulo'] as String,
      content: json['corpo'] as String,
    );
  }
}