// lib/custom_notification_dialog.dart

import 'package:flutter/material.dart';

class CustomNotificationDialog extends StatelessWidget {
  final String title;
  final String content;

  const CustomNotificationDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone de sino decorativo
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color.fromARGB(255, 172, 224, 207),
              child: Icon(
                Icons.notifications,
                color: Color(0xFF2C735F),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            // Título da notificação
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C735F),
              ),
            ),
            const SizedBox(height: 12),
            // Conteúdo da notificação
            Flexible(
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 24),
            // Botão para fechar
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C735F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                elevation: 5,
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
