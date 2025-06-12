import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickActionsBar extends StatelessWidget {
  final Color primaryColor;
  final Color bgColor;
  final Function(String) onActionTap;

  const QuickActionsBar({
    super.key,
    required this.primaryColor,
    required this.bgColor,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionButton(Icons.calendar_today, 'Book Appointment'),
            const SizedBox(width: 12),
            _buildQuickActionButton(Icons.message, 'Message Nurse'),
            const SizedBox(width: 12),
            _buildQuickActionButton(Icons.favorite, 'Health Records'),
            const SizedBox(width: 12),
            _buildQuickActionButton(Icons.mic, 'Voice Command'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onActionTap(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
