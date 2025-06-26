import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_report_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  String selectedTimeSlot = '';
  String selectedDepartment = '';
  String selectedDoctor = '';
  String selectedDoctorId = '';
  String symptoms = ''; // For symptoms input
  bool _isLoadingDoctors = false;
  bool _isLoadingAppointments = true;
  List<Map<String, dynamic>> doctors = [];
  User? _currentUser;
  Map<String, bool> timeSlotAvailability = {};
  DateTime? filterDate; // For filtering Upcoming/History tabs

  final List<String> departments = [
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'General Medicine',
  ];

  final List<String> timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFirebase();
    _initializeFCM();
    _setupLocalNotifications(); // Call it here (no await needed)

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'appointments_channel',
              'Appointment Notifications',
              channelDescription: 'For doctor appointment alerts',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _currentUser = FirebaseAuth.instance.currentUser;
      setState(() {
        _isLoadingAppointments = _currentUser == null;
      });
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view appointments.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingAppointments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing: $e')),
      );
    }
  }


  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> _initializeFCM() async {
    try {
      await messaging.requestPermission();

      final fcmToken = await messaging.getToken();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'fcmToken': fcmToken,
        });
      }
    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E86AB),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DoctorSearchDelegate(doctors: doctors),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2E86AB),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2E86AB),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Book New'),
                Tab(text: 'Upcoming'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookNewTab(),
          _buildUpcomingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildBookNewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Select Department'),
          const SizedBox(height: 15),
          _buildDepartmentGrid(),
          const SizedBox(height: 25),
          if (selectedDepartment.isNotEmpty) ...[
            _buildSectionTitle('Available Doctors'),
            const SizedBox(height: 15),
            _buildDoctorsList(),
            const SizedBox(height: 25),
          ],
          if (selectedDoctor.isNotEmpty) ...[
            _buildSectionTitle('Select Date'),
            const SizedBox(height: 15),
            _buildDateSelector(),
            const SizedBox(height: 25),
            _buildSectionTitle('Available Time Slots'),
            const SizedBox(height: 15),
            _buildTimeSlots(),
            const SizedBox(height: 25),
            _buildSectionTitle('Symptoms (Optional)'),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'Describe your symptoms',
                labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
              maxLength: 500,
              onChanged: (value) => symptoms = value,
            ),
            const SizedBox(height: 30),
            _buildBookButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Filter by Date'),
          const SizedBox(height: 15),
          _buildPatientDateFilter(),
          const SizedBox(height: 25),
          _buildSectionTitle('Next Appointment'),
          const SizedBox(height: 15),
          _buildNextAppointmentCard(),
          const SizedBox(height: 25),
          _buildSectionTitle('All Upcoming'),
          const SizedBox(height: 15),
          _buildUpcomingAppointmentsList(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Filter by Date'),
          const SizedBox(height: 15),
          _buildPatientDateFilter(),
          const SizedBox(height: 25),
          _buildSectionTitle('Recent Appointments'),
          const SizedBox(height: 15),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      itemCount: departments.length,
      itemBuilder: (context, index) {
        final department = departments[index];
        final isSelected = selectedDepartment == department;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              selectedDepartment = department;
              selectedDoctor = '';
              selectedDoctorId = '';
              selectedTimeSlot = '';
              symptoms = '';
              timeSlotAvailability.clear();
              _loadDoctors(department);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2E86AB).withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getDepartmentIcon(department),
                  size: 40,
                  color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[600],
                ),
                const SizedBox(height: 10),
                Text(
                  department,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadDoctors(String department) async {
    setState(() {
      _isLoadingDoctors = true;
      doctors = [];
    });
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('doctors')
          .where('specialization', isEqualTo: department)
          .where('role', isEqualTo: 'doctor')
          .get();
      setState(() {
        doctors = snapshot.docs.map((doc) {
          return {
            'id': doc.id, // Ensure this is the doctor's uid
            'uid': doc.id, // Explicitly store uid for clarity
            'name': doc['name'] as String,
            'specialty': doc['specialization'] as String,
            'rating': '4.8 (120 reviews)', // Mock rating
            'experience': '10+ years', // Mock experience
            'phone': doc['phone'] as String,
            'email': doc['email'] as String,
            'licenseNumber': doc['licenseNumber'] as String,
          };
        }).toList();
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDoctors = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: $e')),
      );
    }
  }

  Widget _buildDoctorsList() {
    if (_isLoadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }
    if (doctors.isEmpty) {
      return Center(
        child: Text(
          'No doctors available for this department.',
          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: doctors.map((doctor) {
        final isSelected = selectedDoctor == doctor['name'];

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              selectedDoctor = doctor['name']!;
              selectedDoctorId = doctor['uid']!; // Use uid explicitly
              selectedTimeSlot = '';
              symptoms = '';
              timeSlotAvailability.clear();
              _checkTimeSlotAvailability();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2E86AB).withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isSelected ? const Color(0xFF2E86AB).withOpacity(0.1) : Colors.grey[100],
                  child: Icon(
                    Icons.person,
                    color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name']!,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF2E86AB) : const Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        doctor['specialty']!,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            doctor['rating']!,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                          const SizedBox(width: 5),
                          Text(
                            doctor['experience']!,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2E86AB),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E86AB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E86AB),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      if (picked.isBefore(DateTime(now.year, now.month, now.day))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot book appointments in the past.')),
        );
        return;
      }
      HapticFeedback.lightImpact();
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = '';
        timeSlotAvailability.clear();
        _checkTimeSlotAvailability();
      });
    }
  }

  Widget _buildDateSelector() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _selectDate(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E86AB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Select Date with Calendar',
            style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 30,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = selectedDate.day == date.day &&
                  selectedDate.month == date.month &&
                  selectedDate.year == date.year;

              return GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  if (date.isBefore(DateTime(now.year, now.month, now.day))) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot book appointments in the past.')),
                    );
                    return;
                  }
                  HapticFeedback.lightImpact();
                  setState(() {
                    selectedDate = date;
                    selectedTimeSlot = '';
                    timeSlotAvailability.clear();
                    _checkTimeSlotAvailability();
                  });
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2E86AB) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        _getMonthName(date.month),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _checkTimeSlotAvailability() async {
    if (selectedDoctorId.isEmpty) return;

    setState(() {
      timeSlotAvailability = {for (var slot in timeSlots) slot: false};
    });

    try {
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: selectedDoctorId)
          .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final bookedSlots = snapshot.docs
          .map((doc) => doc['timeSlot'] as String)
          .toSet();

      setState(() {
        timeSlotAvailability = {
          for (var slot in timeSlots)
            slot: !bookedSlots.contains(slot) &&
                (!isToday || _isTimeSlotAvailable(slot, now))
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability: $e')),
      );
    }
  }

  bool _isTimeSlotAvailable(String timeSlot, DateTime now) {
    final format = DateFormat('hh:mm a');
    final slotTime = format.parse(timeSlot);
    final slotDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      slotTime.hour + (timeSlot.contains('PM') && slotTime.hour != 12 ? 12 : 0),
      slotTime.minute,
    );
    return slotDateTime.isAfter(now);
  }

  Widget _buildTimeSlots() {
    if (timeSlotAvailability.isEmpty && selectedDoctorId.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final isSelected = selectedTimeSlot == timeSlot;
        final isAvailable = timeSlotAvailability[timeSlot] ?? false;

        return GestureDetector(
          onTap: isAvailable
              ? () {
            HapticFeedback.lightImpact();
            setState(() {
              selectedTimeSlot = timeSlot;
            });
          }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: !isAvailable
                  ? Colors.grey[100]
                  : isSelected
                  ? const Color(0xFF2E86AB)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !isAvailable
                    ? Colors.grey[300]!
                    : isSelected
                    ? const Color(0xFF2E86AB)
                    : Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Text(
                timeSlot,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !isAvailable
                      ? Colors.grey[400]
                      : isSelected
                      ? Colors.white
                      : const Color(0xFF1A237E),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookButton() {
    final canBook = selectedDepartment.isNotEmpty &&
        selectedDoctor.isNotEmpty &&
        selectedTimeSlot.isNotEmpty;

    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canBook ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E86AB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: canBook ? 5 : 0,
        ),
        child: Text(
          'Book Appointment',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDateFilter() {
    final isSelected = filterDate != null;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: filterDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF2E86AB),
                      ),
                    ),
                    child: child!,
                  ),
                );
                setState(() => filterDate = date);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E86AB).withOpacity(0.08) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filterDate == null
                          ? 'Select Date'
                          : DateFormat('MMMM d, yyyy').format(filterDate!),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF2E86AB) : const Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: TextButton.icon(
              onPressed: () => setState(() => filterDate = null),
              icon: const Icon(Icons.clear, size: 14, color: Color(0xFFE53E3E)),
              label: Text(
                'Clear',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53E3E),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNextAppointmentCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUpcomingAppointmentsStream(limit: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.roboto(fontSize: 14)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No upcoming appointments.',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
            ),
          );
        }

        final appointment = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final date = (appointment['date'] as Timestamp).toDate();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00C853), Color(0xFF00E676)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['doctorName'],
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appointment['department'],
                          style: GoogleFonts.roboto(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('MMMM d, yyyy').format(date),
                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    appointment['timeSlot'],
                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rescheduleAppointment(snapshot.data!.docs.first.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00C853),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Reschedule',
                        style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelAppointment(snapshot.data!.docs.first.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUpcomingAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.roboto(fontSize: 14)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No upcoming appointments.',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final appointment = doc.data() as Map<String, dynamic>;
            final date = (appointment['date'] as Timestamp).toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF2E86AB).withOpacity(0.1),
                        child: const Icon(Icons.person, color: Color(0xFF2E86AB)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['doctorName'],
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              appointment['department'],
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E86AB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          appointment['type'] ?? 'Consultation',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: const Color(0xFF2E86AB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(date),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        appointment['timeSlot'],
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getHistoryAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.roboto(fontSize: 14)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No appointment history.',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final appointment = doc.data() as Map<String, dynamic>;
            final date = (appointment['date'] as Timestamp).toDate();
            final isCompleted = appointment['status'] == 'completed';

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[100],
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['doctorName'],
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              appointment['department'],
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          appointment['status'].toString().toUpperCase(),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: isCompleted ? Colors.green[600] : Colors.red[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(date),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        appointment['timeSlot'],
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _viewReport(doc.id),
                      child: Text(
                        'View Report',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF2E86AB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getUpcomingAppointmentsStream({int? limit}) {
    Query query = _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _currentUser?.uid)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('date');

    if (filterDate != null) {
      final startOfDay = Timestamp.fromDate(filterDate!);
      final endOfDay = Timestamp.fromDate(filterDate!.add(const Duration(days: 1)));
      query = query
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot> _getHistoryAppointmentsStream() {
    Query query = _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _currentUser?.uid)
        .where('status', whereIn: ['completed', 'canceled'])
        .orderBy('date', descending: true);

    if (filterDate != null) {
      final startOfDay = Timestamp.fromDate(filterDate!);
      final endOfDay = Timestamp.fromDate(filterDate!.add(const Duration(days: 1)));
      query = query
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay);
    }

    return query.snapshots();
  }

  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'Cardiology':
        return Icons.favorite;
      case 'Dermatology':
        return Icons.face;
      case 'Neurology':
        return Icons.psychology;
      case 'Orthopedics':
        return Icons.accessibility;
      case 'Pediatrics':
        return Icons.child_care;
      case 'General Medicine':
        return Icons.local_hospital;
      default:
        return Icons.medical_services;
    }
  }

  String _getDayName(int weekday) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
  void _bookAppointment() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book an appointment.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    print('Booking appointment with doctorId: $selectedDoctorId');

    String? newAppointmentId;

    try {
      await _firestore.runTransaction((transaction) async {
        final slotQuery = await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: selectedDoctorId)
            .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
            .where('timeSlot', isEqualTo: selectedTimeSlot)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        print('Slot query docs: ${slotQuery.docs.length}');
        if (slotQuery.docs.isNotEmpty) {
          throw Exception('Time slot already booked.');
        }

        final newDoc = _firestore.collection('appointments').doc();
        newAppointmentId = newDoc.id;
        print('New Appointment ID: $newAppointmentId');

        final appointment = {
          'userId': _currentUser!.uid,
          'doctorId': selectedDoctorId,
          'doctorName': selectedDoctor,
          'department': selectedDepartment,
          'date': Timestamp.fromDate(selectedDate),
          'timeSlot': selectedTimeSlot,
          'status': 'pending',
          'type': 'Consultation',
          'symptoms': symptoms.isNotEmpty ? symptoms : null,
          'createdAt': Timestamp.now(),
        };

        transaction.set(newDoc, appointment);
      });

      // Send notification to doctor's tokens
      final tokensSnapshot = await _firestore
          .collection('doctors')
          .doc(selectedDoctorId)
          .collection('tokens')
          .get();

      String userName = 'a patient';
      bool notificationSent = false;

      try {
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final firstName = data?['firstName'] ?? '';
          final lastName = data?['lastName'] ?? '';
          userName = '$firstName $lastName'.trim();
          if (userName.isEmpty) userName = 'a patient';
        }
      } catch (e) {
        print('Error fetching user name from Firestore: $e');
      }

      if (tokensSnapshot.docs.isNotEmpty) {
        for (var tokenDoc in tokensSnapshot.docs) {
          final doctorFcmToken = tokenDoc.data()['fcmToken'];
          try {
            await _firestore.collection('notifications').add({
              'title': 'New Appointment',
              'to': doctorFcmToken,
              'userId': _currentUser!.uid,
              'processed': false,
              'data': {
                'route': '/doctor-appointments',
                'appointmentId': newAppointmentId,
                'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              },
              'timestamp': FieldValue.serverTimestamp(),
            });
            print('✅ Notification added for token: $doctorFcmToken');
            notificationSent = true;
          } catch (e) {
            print('❌ Error adding notification for token $doctorFcmToken: $e');
          }
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 28),
                const SizedBox(width: 10),
                Text(
                  'Appointment Booked!',
                  style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your appointment has been successfully scheduled.', style: GoogleFonts.roboto(fontSize: 14)),
                const SizedBox(height: 15),
                Text('Details:', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Doctor: $selectedDoctor', style: GoogleFonts.roboto(fontSize: 14)),
                Text('Department: $selectedDepartment', style: GoogleFonts.roboto(fontSize: 14)),
                Text('Date: ${DateFormat('MMMM d, yyyy').format(selectedDate)}', style: GoogleFonts.roboto(fontSize: 14)),
                Text('Time: $selectedTimeSlot', style: GoogleFonts.roboto(fontSize: 14)),
                if (symptoms.isNotEmpty)
                  Text('Symptoms: $symptoms', style: GoogleFonts.roboto(fontSize: 14)),
                if (!notificationSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Note: The doctor has not enabled notifications.',
                      style: GoogleFonts.roboto(fontSize: 14, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _tabController.animateTo(1);
                  setState(() {
                    selectedDepartment = '';
                    selectedDoctor = '';
                    selectedDoctorId = '';
                    selectedTimeSlot = '';
                    symptoms = '';
                    timeSlotAvailability.clear();
                  });
                },
                child: Text('OK', style: GoogleFonts.roboto(color: const Color(0xFF2E86AB))),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('❌ Booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e. Please try again.')),
      );
    }
  }

  void _rescheduleAppointment(String appointmentId) async {
    try {
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment not found.')),
        );
        return;
      }
      final data = doc.data()!;
      setState(() {
        selectedDepartment = data['department'];
        selectedDoctor = data['doctorName'];
        selectedDoctorId = data['doctorId'];
        selectedDate = (data['date'] as Timestamp).toDate();
        selectedTimeSlot = data['timeSlot'];
        symptoms = data['symptoms'] ?? '';
        timeSlotAvailability.clear();
        _loadDoctors(selectedDepartment).then((_) => _checkTimeSlotAvailability());
      });
      _tabController.animateTo(0);
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'canceled',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment: $e')),
      );
    }
  }

  void _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Appointment', style: GoogleFonts.roboto(fontSize: 18)),
        content: Text(
          'Are you sure you want to cancel this appointment?',
          style: GoogleFonts.roboto(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: GoogleFonts.roboto(color: const Color(0xFF2E86AB))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes', style: GoogleFonts.roboto(color: const Color(0xFFE53E3E))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'canceled',
        'updatedAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling appointment: $e')),
      );
    }
  }

  void _viewReport(String appointmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserReportsScreen()),
    );
  }
}

class DoctorSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> doctors;

  DoctorSearchDelegate({required this.doctors});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = doctors
        .where((doc) =>
    doc['name'].toLowerCase().contains(query.toLowerCase()) ||
        doc['specialty'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2E86AB).withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: Color(0xFF2E86AB),
            ),
          ),
          title: Text(
            doc['name'],
            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            doc['specialty'],
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
          onTap: () {
            close(context, null);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = doctors
        .where((doc) =>
    doc['name'].toLowerCase().contains(query.toLowerCase()) ||
        doc['specialty'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2E86AB).withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: Color(0xFF2E86AB),
            ),
          ),
          title: Text(
            doc['name'],
            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            doc['specialty'],
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
          onTap: () {
            close(context, null);
          },
        );
      },
    );
  }
}