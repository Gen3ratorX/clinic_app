import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue[600],
              indicatorWeight: 3,
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Select Department'),
          SizedBox(height: 15),
          _buildDepartmentGrid(),
          SizedBox(height: 25),
          if (selectedDepartment.isNotEmpty) ...[
            _buildSectionTitle('Available Doctors'),
            SizedBox(height: 15),
            _buildDoctorsList(),
            SizedBox(height: 25),
          ],
          if (selectedDoctor.isNotEmpty) ...[
            _buildSectionTitle('Select Date'),
            SizedBox(height: 15),
            _buildDateSelector(),
            SizedBox(height: 25),
            _buildSectionTitle('Available Time Slots'),
            SizedBox(height: 15),
            _buildTimeSlots(),
            SizedBox(height: 30),
            _buildBookButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Next Appointment'),
          SizedBox(height: 15),
          _buildNextAppointmentCard(),
          SizedBox(height: 25),
          _buildSectionTitle('All Upcoming'),
          SizedBox(height: 15),
          _buildUpcomingAppointmentsList(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Recent Appointments'),
          SizedBox(height: 15),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              selectedDoctor = ''; // Reset doctor selection
              selectedTimeSlot = ''; // Reset time selection
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getDepartmentIcon(department),
                  size: 40,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                ),
                SizedBox(height: 10),
                Text(
                  department,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.blue[600] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorsList() {
    final doctors = _getDoctorsForDepartment(selectedDepartment);

    return Column(
      children: doctors.map((doctor) {
        final isSelected = selectedDoctor == doctor['name'];

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              selectedDoctor = doctor['name']?? '';
              selectedTimeSlot = ''; // Reset time selection
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isSelected ? Colors.blue[100] : Colors.grey[100],
                  child: Icon(
                    Icons.person,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name']?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[600] : Colors.grey[800],
                        ),
                      ),
                      Text(
                        doctor['specialty']?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 5),
                          Text(
                            doctor['rating']?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                          SizedBox(width: 5),
                          Text(
                            doctor['experience']?? '',
                            style: TextStyle(
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
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue[600],
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = selectedDate.day == date.day &&
              selectedDate.month == date.month &&
              selectedDate.year == date.year;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                selectedDate = date;
                selectedTimeSlot = ''; // Reset time selection
              });
            },
            child: Container(
              width: 70,
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  Text(
                    _getMonthName(date.month),
                    style: TextStyle(
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
    );
  }

  Widget _buildTimeSlots() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final isSelected = selectedTimeSlot == timeSlot;
        final isAvailable = _isTimeSlotAvailable(timeSlot);

        return GestureDetector(
          onTap: isAvailable ? () {
            HapticFeedback.lightImpact();
            setState(() {
              selectedTimeSlot = timeSlot;
            });
          } : null,
          child: Container(
            decoration: BoxDecoration(
              color: !isAvailable
                  ? Colors.grey[100]
                  : isSelected
                  ? Colors.blue[600]
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !isAvailable
                    ? Colors.grey[300]!
                    : isSelected
                    ? Colors.blue[600]!
                    : Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Text(
                timeSlot,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !isAvailable
                      ? Colors.grey[400]
                      : isSelected
                      ? Colors.white
                      : Colors.grey[700],
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
          backgroundColor: Colors.blue[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: canBook ? 5 : 0,
        ),
        child: Text(
          'Book Appointment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNextAppointmentCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
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
                child: Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Sarah Johnson',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cardiologist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Today, June 9, 2025',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                '2:30 PM - 3:00 PM',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Reschedule'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsList() {
    final upcomingAppointments = [
      {
        'doctor': 'Dr. Michael Chen',
        'specialty': 'Dermatologist',
        'date': 'June 10, 2025',
        'time': '10:00 AM',
        'type': 'Consultation',
      },
      {
        'doctor': 'Dr. Emily Davis',
        'specialty': 'Neurologist',
        'date': 'June 12, 2025',
        'time': '3:30 PM',
        'type': 'Follow-up',
      },
    ];

    return Column(
      children: upcomingAppointments.map((appointment) {
        return Container(
          margin: EdgeInsets.only(bottom: 15),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
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
                    backgroundColor: Colors.blue[50],
                    child: Icon(Icons.person, color: Colors.blue[600]),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['doctor']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          appointment['specialty']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      appointment['type']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    appointment['date']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    appointment['time']!,
                    style: TextStyle(
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
  }

  Widget _buildHistoryList() {
    final historyAppointments = [
      {
        'doctor': 'Dr. Robert Wilson',
        'specialty': 'General Medicine',
        'date': 'May 15, 2025',
        'time': '11:00 AM',
        'status': 'Completed',
      },
      {
        'doctor': 'Dr. Lisa Anderson',
        'specialty': 'Orthopedics',
        'date': 'April 28, 2025',
        'time': '2:15 PM',
        'status': 'Completed',
      },
      {
        'doctor': 'Dr. James Brown',
        'specialty': 'Cardiology',
        'date': 'April 10, 2025',
        'time': '9:30 AM',
        'status': 'Cancelled',
      },
    ];

    return Column(
      children: historyAppointments.map((appointment) {
        final isCompleted = appointment['status'] == 'Completed';

        return Container(
          margin: EdgeInsets.only(bottom: 15),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['doctor']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          appointment['specialty']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      appointment['status']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.green[600] : Colors.red[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    appointment['date']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    appointment['time']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (isCompleted) ...[
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {},
                  child: Text('View Report'),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
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

  List<Map<String, String>> _getDoctorsForDepartment(String department) {
    // Mock data - replace with Firebase data
    switch (department) {
      case 'Cardiology':
        return [
          {
            'name': 'Dr. Sarah Johnson',
            'specialty': 'Cardiologist',
            'rating': '4.8 (120 reviews)',
            'experience': '15 years',
          },
          {
            'name': 'Dr. James Wilson',
            'specialty': 'Cardiac Surgeon',
            'rating': '4.9 (95 reviews)',
            'experience': '20 years',
          },
        ];
      case 'Dermatology':
        return [
          {
            'name': 'Dr. Michael Chen',
            'specialty': 'Dermatologist',
            'rating': '4.7 (88 reviews)',
            'experience': '12 years',
          },
        ];
      default:
        return [];
    }
  }

  bool _isTimeSlotAvailable(String timeSlot) {
    // Mock availability logic - replace with real data
    final unavailableSlots = ['10:30 AM', '02:30 PM'];
    return !unavailableSlots.contains(timeSlot);
  }

  String _getDayName(int weekday) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _bookAppointment() {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Appointment Booked!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your appointment has been successfully scheduled.'),
              SizedBox(height: 15),
              Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Doctor: $selectedDoctor'),
              Text('Department: $selectedDepartment'),
              Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              Text('Time: $selectedTimeSlot'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Switch to upcoming tab
                _tabController.animateTo(1);
                // Reset selections
                setState(() {
                  selectedDepartment = '';
                  selectedDoctor = '';
                  selectedTimeSlot = '';
                });
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}