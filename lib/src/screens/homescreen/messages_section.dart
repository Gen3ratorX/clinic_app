import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessagesSection extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final Color primaryColor;
  final Color bgColor;
  final Color lightPrimaryColor;
  final void Function(int index) onDismiss;
  final void Function(int index) onTapMessage;
  final VoidCallback onCompose;

  const MessagesSection({
    super.key,
    required this.messages,
    required this.primaryColor,
    required this.bgColor,
    required this.lightPrimaryColor,
    required this.onDismiss,
    required this.onTapMessage,
    required this.onCompose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: primaryColor),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCompose();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            messages.length,
                (index) => Dismissible(
              key: Key('message_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                onDismiss(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: messages[index]['unread']
                      ? lightPrimaryColor.withOpacity(0.1)
                      : bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lightPrimaryColor,
                    child: Text(
                      messages[index]['sender'][0],
                      style: TextStyle(color: bgColor),
                    ),
                  ),
                  title: Text(
                    messages[index]['sender'],
                    style: TextStyle(
                      fontWeight: messages[index]['unread']
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    messages[index]['preview'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        messages[index]['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (messages[index]['unread'])
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTapMessage(index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
