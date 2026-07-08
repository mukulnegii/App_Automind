import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {

  final String? title;
  final String? message;
  final List<Map<String, String>>? notifications;

  const NotificationsPage({
    super.key,
    this.title,
    this.message,
    this.notifications,
  });

  @override
  Widget build(BuildContext context) {

    final List<Map<String, String>> displayNotifications =
        notifications ??
            [
              {
                "title": title ?? "",
                "message": message ?? "",
              }
            ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayNotifications.length,
        itemBuilder: (context, index) {

          final item = displayNotifications[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [

                const Icon(Icons.notifications, color: Colors.blue),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        item["title"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        item["message"] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}