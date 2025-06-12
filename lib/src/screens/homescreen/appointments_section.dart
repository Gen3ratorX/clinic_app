import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentsSection extends StatelessWidget {
  final Color primaryColor;
  final Color bgColor;
  final VoidCallback onBookNew;
  final Function(Map<String, dynamic> appt, String action)? onAction;

  const AppointmentsSection({
    super.key,
    required this.primaryColor,
    required this.bgColor,
    required this.onBookNew,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = userSnapshot.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('userId', isEqualTo: user.uid)
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final appointments = snapshot.data?.docs ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                if (appointments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'No appointments booked.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  )
                else
                  ...appointments.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildAppointmentCard(
                      appt: {
                        ...data,
                        'id': doc.id,
                        'date': (data['date'] as Timestamp).toDate(),
                      },
                    );
                  }),

                const SizedBox(height: 12),
                _buildBookNewAppointmentCard(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard({required Map<String, dynamic> appt}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appt['nurse'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appt['status'] == 'Confirmed'
                      ? primaryColor.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appt['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: appt['status'] == 'Confirmed'
                        ? primaryColor
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            appt['specialty'],
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                DateFormat('EEE, MMM d').format(appt['date']),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                appt['time'],
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => onAction?.call(appt, 'reschedule'),
                child: Text('Reschedule', style: TextStyle(color: primaryColor)),
              ),
              TextButton(
                onPressed: () => onAction?.call(appt, 'cancel'),
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookNewAppointmentCard() {
    return GestureDetector(
      onTap: onBookNew,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 24, color: bgColor),
            const SizedBox(width: 8),
            Text(
              'Book New Appointment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: bgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
