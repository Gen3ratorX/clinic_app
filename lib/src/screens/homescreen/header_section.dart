import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HeaderSection extends StatefulWidget {
  final int notificationCount;
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final Color primaryColor;
  final Color bgColor;
  final Color lightPrimaryColor;
  final Color accentColor;
  final int interactionCount;

  const HeaderSection({
    super.key,
    required this.notificationCount,
    required this.onProfileTap,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.primaryColor,
    required this.bgColor,
    required this.lightPrimaryColor,
    required this.accentColor,
    required this.interactionCount,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  String firstName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserFirstName();
  }

  Future<void> _fetchUserFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('firstName')) {
        setState(() {
          firstName = doc['firstName'];
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  LinearGradient _getDynamicGradient() {
    final hour = DateTime.now().hour;
    return LinearGradient(
      colors: [
        hour < 17 ? widget.primaryColor : widget.accentColor,
        hour < 17 ? widget.lightPrimaryColor : widget.primaryColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  double _getDynamicShadowOpacity() {
    return 0.1 + (widget.interactionCount * 0.02).clamp(0.1, 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: _getDynamicGradient(),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_getDynamicShadowOpacity()),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onProfileTap();
            },
            child: CircleAvatar(
              radius: 26,
              backgroundColor: widget.bgColor,
              child: Text(
                firstName.isNotEmpty ? firstName[0] : '',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $firstName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.bgColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your health, your priority.',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.bgColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: widget.bgColor, size: 26),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onSearchTap();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: widget.bgColor, size: 26),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onNotificationTap();
                },
              ),
              if (widget.notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
