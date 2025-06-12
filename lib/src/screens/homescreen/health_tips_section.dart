import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HealthTipsSection extends StatelessWidget {
  final List<Map<String, String>> tips;
  final Color primaryColor;
  final Color bgColor;

  const HealthTipsSection({
    super.key,
    required this.tips,
    required this.primaryColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Health Tips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => _buildTipCard(tip)),
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, String> tip) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip['title']!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tip['content']!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Share functionality placeholder
                },
                icon: Icon(Icons.share, color: primaryColor, size: 20),
                label: Text('Share', style: TextStyle(color: primaryColor)),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Save functionality placeholder
                },
                icon: Icon(Icons.bookmark_border, color: primaryColor, size: 20),
                label: Text('Save', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
