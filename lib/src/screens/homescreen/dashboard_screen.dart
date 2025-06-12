import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'header_section.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Enhanced theme colors
  final Color primaryColor = const Color(0xFF4A90E2);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color lightPrimaryColor = const Color(0xFF74B9FF);
  final Color accentColor = const Color(0xFF00B894);
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF2D3748);
  final Color textSecondary = const Color(0xFF718096);

  final int notificationCount = 3;
  final int interactionCount = 5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HeaderSection(
                notificationCount: notificationCount,
                onProfileTap: () {},
                onSearchTap: () {},
                onNotificationTap: () {},
                primaryColor: primaryColor,
                bgColor: bgColor,
                lightPrimaryColor: lightPrimaryColor,
                accentColor: accentColor,
                interactionCount: interactionCount,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildWelcomeCard(),
                  _buildQuickActions(),
                  _buildHealthOverview(),
                  _buildUpcomingAppointments(),
                  _buildRecentActivity(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Health Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re doing great! Keep up the healthy habits and stay on track.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: primaryColor,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Book Appt',
        'color': const Color(0xFF4A90E2),
        'bgColor': const Color(0xFFE3F2FD),
      },
      {
        'icon': Icons.assignment_rounded,
        'label': 'Lab Results',
        'color': const Color(0xFF00B894),
        'bgColor': const Color(0xFFE0F2F1),
      },
      {
        'icon': Icons.medication_rounded,
        'label': 'Prescriptions',
        'color': const Color(0xFF9B59B6),
        'bgColor': const Color(0xFFF3E5F5),
      },
      {
        'icon': Icons.emergency_rounded,
        'label': 'Emergency',
        'color': const Color(0xFFE74C3C),
        'bgColor': const Color(0xFFFFEBEE),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140, // Adjust height to match card size
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(
                  icon: action['icon'] as IconData,
                  label: action['label'] as String,
                  color: action['color'] as Color,
                  bgColor: action['bgColor'] as Color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 120, // fixed width for horizontal scroll
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildVitalCard(
                      'Heart Rate',
                      '72',
                      'bpm',
                      Icons.favorite_rounded,
                      const Color(0xFFE74C3C),
                      const Color(0xFFFFEBEE),
                    ),
                    const SizedBox(width: 16),
                    _buildVitalCard(
                      'Blood Pressure',
                      '120/80',
                      'mmHg',
                      Icons.opacity_rounded,
                      const Color(0xFF4A90E2),
                      const Color(0xFFE3F2FD),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildVitalCard(
                      'Weight',
                      '165',
                      'lbs',
                      Icons.monitor_weight_rounded,
                      const Color(0xFF00B894),
                      const Color(0xFFE0F2F1),
                    ),
                    const SizedBox(width: 16),
                    _buildVitalCard(
                      'Temperature',
                      '98.6',
                      '°F',
                      Icons.thermostat_rounded,
                      const Color(0xFFFF9800),
                      const Color(0xFFFFF3E0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(
      String label,
      String value,
      String unit,
      IconData icon,
      Color color,
      Color bgColor,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAppointmentCard(
            doctor: 'Dr. Sarah Johnson',
            specialty: 'Cardiologist',
            time: 'Today, 2:30 PM',
            type: 'Follow-up',
            avatar: 'SJ',
            color: const Color(0xFF4A90E2),
          ),
          const SizedBox(height: 12),
          _buildAppointmentCard(
            doctor: 'Dr. Michael Chen',
            specialty: 'Dermatologist',
            time: 'Tomorrow, 10:00 AM',
            type: 'Consultation',
            avatar: 'MC',
            color: const Color(0xFF00B894),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String doctor,
    required String specialty,
    required String time,
    required String type,
    required String avatar,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              avatar,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.check_circle_rounded,
                  title: 'Lab results available',
                  subtitle: 'Blood work completed',
                  time: '2 hours ago',
                  color: const Color(0xFF00B894),
                ),
                const Divider(height: 32),
                _buildActivityItem(
                  icon: Icons.medication_rounded,
                  title: 'Prescription refilled',
                  subtitle: 'Metformin 500mg',
                  time: '1 day ago',
                  color: const Color(0xFF4A90E2),
                ),
                const Divider(height: 32),
                _buildActivityItem(
                  icon: Icons.event_available_rounded,
                  title: 'Appointment confirmed',
                  subtitle: 'Dr. Sarah Johnson',
                  time: '2 days ago',
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}