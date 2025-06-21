import 'package:clinic_app/src/screens/appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_report_screen.dart';
import 'prescription_screen.dart';
import 'chat/chat_list_screen.dart';

class QuickActionsBar extends StatefulWidget {
  final Color primaryColor;
  final Color bgColor;
  final Function(String) onActionTap;
  final String currentUserId;
  final String userType;

  const QuickActionsBar({
    super.key,
    required this.primaryColor,
    required this.bgColor,
    required this.onActionTap,
    required this.currentUserId,
    required this.userType,
  });

  @override
  State<QuickActionsBar> createState() => _QuickActionsBarState();
}

class _QuickActionsBarState extends State<QuickActionsBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _pressedAction;
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;
  double _maxScrollExtent = 0.0;

  final List<Map<String, dynamic>> _actions = [
    {
      'icon': Icons.analytics_rounded,
      'label': 'Reports',
      'description': 'View medical reports',
      'color': Colors.blue,
    },
    {
      'icon': Icons.medical_services_rounded,
      'label': 'Prescriptions',
      'description': 'Manage prescriptions',
      'color': Colors.green,
    },
    {
      'icon': Icons.event_available_rounded,
      'label': 'Appointments',
      'description': 'Schedule & view appointments',
      'color': Colors.orange,
    },
    {
      'icon': Icons.chat_bubble_rounded,
      'label': 'Message Doctor',
      'description': 'Chat with your doctor',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollPosition = _scrollController.offset;
      _maxScrollExtent = _scrollController.position.maxScrollExtent;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Access your healthcare tools instantly',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(10),
                  thickness: 4,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _actions.map((action) {
                        final index = _actions.indexOf(action);
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _actions.length - 1 ? 12 : 0,
                          ),
                          child: _buildQuickActionButton(action),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_maxScrollExtent > 0) _buildScrollIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(Map<String, dynamic> action) {
    final isPressed = _pressedAction == action['label'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleActionTap(action),
          onTapDown: (_) => setState(() => _pressedAction = action['label']),
          onTapUp: (_) => setState(() => _pressedAction = null),
          onTapCancel: () => setState(() => _pressedAction = null),
          borderRadius: BorderRadius.circular(16),
          splashColor: action['color'].withOpacity(0.1),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.bgColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isPressed
                    ? action['color'].withOpacity(0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: action['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        action['icon'],
                        color: action['color'],
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    if (action['label'] == 'Message Doctor')
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  action['label'],
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: widget.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action['description'],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleActionTap(Map<String, dynamic> action) {
    HapticFeedback.mediumImpact();
    widget.onActionTap(action['label']);
    _navigateToScreen(action['label']);
  }

  void _navigateToScreen(String label) {
    Widget? screen;
    switch (label) {
      case 'Reports':
        screen = const UserReportsScreen();
        break;
      case 'Prescriptions':
        screen = UserPrescriptionScreen(userId: widget.currentUserId);
        break;
      case 'Appointments':
        screen = const AppointmentScreen();
        break;
      case 'Message Doctor':
        screen = ChatListScreen(
          currentUserId: widget.currentUserId,
          userType: widget.userType,
        );
        break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => screen!,
          transitionsBuilder: (_, animation, __, child) {
            final tween = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    }
  }

  Widget _buildScrollIndicator() {
    final width = MediaQuery.of(context).size.width - 64;
    final contentWidth = (_actions.length * 172.0);
    final indicatorWidth = (width / contentWidth) * width;
    final indicatorPosition =
        (_scrollPosition / _maxScrollExtent) * (width - indicatorWidth);

    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: indicatorPosition,
            child: Container(
              width: indicatorWidth,
              height: 4,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
