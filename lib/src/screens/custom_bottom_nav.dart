import 'package:flutter/material.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // List of colors for each tab
  final List<Color> _tabColors = [
    const Color(0xFF4CAF50), // Green for Dashboard
    const Color(0xFF2196F3), // Blue for Calendar
    const Color(0xFFFF9800), // Orange for Chats
    const Color(0xFF9C27B0), // Purple for AI
    const Color(0xFF607D8B), // Blue Grey for Profile
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final isSelected = widget.currentIndex == index;
              return _buildNavItem(
                index: index,
                isSelected: isSelected,
                color: _tabColors[index],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required bool isSelected, required Color color}) {
    // Define icons for each tab
    final List<IconData> icons = [
      Icons.dashboard_rounded,
      Icons.calendar_today_rounded,
      Icons.chat_bubble_rounded,
      Icons.smart_toy_rounded,
      Icons.person_rounded,
    ];

    // Define labels for each tab
    final List<String> labels = [
      "Dashboard",
      "Appointments",
      "Chats",
      "AI",
      "Profile",
    ];

    return GestureDetector(
      onTap: () {
        widget.onTap(index);
        _controller.reset();
        _controller.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? 1.0 + (_animation.value * 0.2) : 1.0,
                  child: child,
                );
              },
              child: Icon(
                icons[index],
                color: isSelected ? color : Colors.grey,
                size: isSelected ? 26 : 22,
              ),
            ),
            if (isSelected)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}