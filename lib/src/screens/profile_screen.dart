import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Data model for user profile
class UserProfile {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String address;
  final String weight;
  final String height;
  final String bloodGroup;
  final String gender;
  final DateTime dateOfBirth;
  final List<EmergencyContact> emergencyContacts;
  final List<String> allergies;
  final List<String> conditions;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.address,
    required this.weight,
    required this.height,
    required this.bloodGroup,
    required this.gender,
    required this.dateOfBirth,
    required this.emergencyContacts,
    required this.allergies,
    required this.conditions,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.smsNotifications,
  });

  // Convert UserProfile to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'weight': weight,
      'height': height,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
      'allergies': allergies,
      'conditions': conditions,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
    };
  }

  // Create UserProfile from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      weight: data['weight'] ?? '',
      height: data['height'] ?? '',
      bloodGroup: data['bloodGroup'] ?? 'O+',
      gender: data['gender'] ?? 'Female',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(1990, 3, 15),
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
          ?.map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      allergies: List<String>.from(data['allergies'] ?? []),
      conditions: List<String>.from(data['conditions'] ?? []),
      pushNotifications: data['pushNotifications'] ?? true,
      emailNotifications: data['emailNotifications'] ?? true,
      smsNotifications: data['smsNotifications'] ?? false,
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> data) {
    return EmergencyContact(
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? '',
    );
  }
}

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _headerController;

  // Controllers for text fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  String _selectedBloodGroup = 'O+';
  String _selectedGender = 'Female';
  DateTime _selectedDate = DateTime(1990, 3, 15);

  // Sample data
  List<EmergencyContact> emergencyContacts = [];
  List<String> allergies = [];
  List<String> conditions = [];
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeFirebaseAndData();

    _headerController.forward();
    _fabController.forward();
  }

  Future<void> _initializeFirebaseAndData() async {
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        await _loadUserProfile();
      } else {
        // Handle unauthenticated user
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view your profile.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing profile: $e')),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        final userProfile = UserProfile.fromMap(doc.data() as Map<String, dynamic>);
        setState(() {
          _firstNameController = TextEditingController(text: userProfile.firstName);
          _lastNameController = TextEditingController(text: userProfile.lastName);
          _phoneController = TextEditingController(text: userProfile.phone);
          _emailController = TextEditingController(text: userProfile.email);
          _addressController = TextEditingController(text: userProfile.address);
          _weightController = TextEditingController(text: userProfile.weight);
          _heightController = TextEditingController(text: userProfile.height);
          _selectedBloodGroup = userProfile.bloodGroup;
          _selectedGender = userProfile.gender;
          _selectedDate = userProfile.dateOfBirth;
          emergencyContacts = userProfile.emergencyContacts;
          allergies = userProfile.allergies;
          conditions = userProfile.conditions;
          pushNotifications = userProfile.pushNotifications;
          emailNotifications = userProfile.emailNotifications;
          smsNotifications = userProfile.smsNotifications;
          _isLoading = false;
        });
      } else {
        // Initialize with default values if no document exists
        _initializeDefaultControllers();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  void _initializeDefaultControllers() {
    _firstNameController = TextEditingController(text: "Sarah");
    _lastNameController = TextEditingController(text: "Johnson");
    _phoneController = TextEditingController(text: "+1 234-567-8900");
    _emailController = TextEditingController(text: "sarah.johnson@email.com");
    _addressController = TextEditingController(text: "123 Main St, City, State 12345");
    _weightController = TextEditingController(text: "65 kg");
    _heightController = TextEditingController(text: "170 cm");
    emergencyContacts = [
      EmergencyContact(name: "John Doe", phone: "+1 234-567-8900", relationship: "Spouse"),
      EmergencyContact(name: "Jane Smith", phone: "+1 234-567-8901", relationship: "Sister"),
    ];
    allergies = ["Penicillin", "Shellfish", "Peanuts"];
    conditions = ["Hypertension", "Diabetes Type 2"];
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
          ),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saveProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildProfileHeader()
                .animate()
                .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildPersonalInformation()
                      .animate()
                      .slideX(begin: -0.3, duration: 700.ms, curve: Curves.easeOutCubic)
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  _buildEmergencyContacts()
                      .animate()
                      .slideX(begin: 0.3, duration: 700.ms, curve: Curves.easeOutCubic)
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),
                  _buildMedicalInformation()
                      .animate()
                      .slideX(begin: -0.3, duration: 700.ms, curve: Curves.easeOutCubic)
                      .fadeIn(delay: 600.ms),
                  const SizedBox(height: 24),
                  _buildNotificationSettings()
                      .animate()
                      .slideX(begin: 0.3, duration: 700.ms, curve: Curves.easeOutCubic)
                      .fadeIn(delay: 800.ms),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: () => _showQuickActions(context),
          backgroundColor: const Color(0xFF667EEA),
          elevation: 8,
          label: const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          icon: const Icon(Icons.flash_on, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : ''}${_lastNameController.text.isNotEmpty ? _lastNameController.text[0] : ''}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Handle profile picture change
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${_firstNameController.text} ${_lastNameController.text}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Patient ID: ${_currentUser?.uid ?? 'PAT-2024-001'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _buildModernSection(
      title: 'Personal Information',
      icon: Icons.person_rounded,
      iconColor: const Color(0xFF667EEA),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernDropdownField(
                  label: 'Gender',
                  value: _selectedGender,
                  items: ['Male', 'Female', 'Other'],
                  icon: Icons.wc_outlined,
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: TextEditingController(text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                  label: 'Date of Birth',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return _buildModernSection(
      title: 'Emergency Contacts',
      icon: Icons.emergency_rounded,
      iconColor: const Color(0xFFE53E3E),
      child: Column(
        children: [
          ...emergencyContacts.asMap().entries.map((entry) {
            return _buildEmergencyContactCard(entry.value)
                .animate()
                .slideY(begin: 0.3, duration: 400.ms, delay: (entry.key * 100).ms)
                .fadeIn(delay: (entry.key * 100).ms);
          }),
          const SizedBox(height: 16),
          _buildModernButton(
            onPressed: _addEmergencyContact,
            icon: Icons.add_rounded,
            label: 'Add Emergency Contact',
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editEmergencyContact(contact),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFE53E3E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.phone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          contact.relationship,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      setState(() => emergencyContacts.remove(contact));
                      _saveProfile(); // Save to Firestore after deletion
                    } else if (value == 'edit') {
                      _editEmergencyContact(contact);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalInformation() {
    return _buildModernSection(
      title: 'Medical Information',
      icon: Icons.medical_services_rounded,
      iconColor: const Color(0xFF10B981),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _weightController,
                  label: 'Weight',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _heightController,
                  label: 'Height',
                  icon: Icons.height_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernDropdownField(
            label: 'Blood Group',
            value: _selectedBloodGroup,
            items: ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'],
            icon: Icons.bloodtype_rounded,
            onChanged: (val) => setState(() {
              _selectedBloodGroup = val!;
              _saveProfile(); // Save to Firestore on change
            }),
          ),
          const SizedBox(height: 24),
          _buildMedicalCard(
            title: 'Allergies',
            items: allergies,
            onAdd: _addAllergy,
            emptyText: 'No allergies recorded',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),
          _buildMedicalCard(
            title: 'Medical Conditions',
            items: conditions,
            onAdd: _addCondition,
            emptyText: 'No conditions recorded',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required String emptyText,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Material(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAdd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        items.isEmpty
            ? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Text(
                emptyText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _buildModernChip(item, items, color)).toList(),
        ),
      ],
    );
  }

  Widget _buildModernChip(String item, List<String> list, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => list.remove(item));
            _saveProfile(); // Save to Firestore after removal
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.close_rounded, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildModernSection(
      title: 'Notification Settings',
      icon: Icons.notifications_rounded,
      iconColor: const Color(0xFF8B5CF6),
      child: Column(
        children: [
          _buildModernSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: pushNotifications,
            onChanged: (value) {
              setState(() => pushNotifications = value);
              _saveProfile(); // Save to Firestore on change
            },
            icon: Icons.notifications_active_rounded,
          ),
          _buildModernSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: emailNotifications,
            onChanged: (value) {
              setState(() => emailNotifications = value);
              _saveProfile(); // Save to Firestore on change
            },
            icon: Icons.email_rounded,
          ),
          _buildModernSwitchTile(
            title: 'SMS Notifications',
            subtitle: 'Receive notifications via text message',
            value: smsNotifications,
            onChanged: (value) {
              setState(() => smsNotifications = value);
              _saveProfile(); // Save to Firestore on change
            },
            icon: Icons.sms_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.05),
                  iconColor.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF667EEA), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF667EEA), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600)),
      )).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        )
            : null,
        color: isPrimary ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : Colors.grey[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _saveProfile(); // Save to Firestore on change
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.medical_information_rounded,
                    label: 'Medical Records',
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Appointments',
                    color: const Color(0xFF667EEA),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.emergency_rounded,
                    label: 'Emergency',
                    color: const Color(0xFFE53E3E),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share Profile',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addEmergencyContact() {
    String name = '';
    String phone = '';
    String relationship = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Emergency Contact',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              onChanged: (value) => name = value,
              label: 'Name',
              hint: 'Enter contact name',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              onChanged: (value) => phone = value,
              label: 'Phone',
              hint: 'Enter phone number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              onChanged: (value) => relationship = value,
              label: 'Relationship',
              hint: 'Enter relationship',
              icon: Icons.family_restroom_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (name.isNotEmpty && phone.isNotEmpty && relationship.isNotEmpty) {
                    setState(() {
                      emergencyContacts.add(EmergencyContact(
                        name: name,
                        phone: phone,
                        relationship: relationship,
                      ));
                    });
                    _saveProfile(); // Save to Firestore after addition
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editEmergencyContact(EmergencyContact contact) {
    String name = contact.name;
    String phone = contact.phone;
    String relationship = contact.relationship;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Emergency Contact',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              onChanged: (value) => name = value,
              label: 'Name',
              hint: 'Enter contact name',
              icon: Icons.person_rounded,
              initialValue: contact.name,
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              onChanged: (value) => phone = value,
              label: 'Phone',
              hint: 'Enter phone number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              initialValue: contact.phone,
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              onChanged: (value) => relationship = value,
              label: 'Relationship',
              hint: 'Enter relationship',
              icon: Icons.family_restroom_rounded,
              initialValue: contact.relationship,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (name.isNotEmpty && phone.isNotEmpty && relationship.isNotEmpty) {
                    setState(() {
                      final index = emergencyContacts.indexOf(contact);
                      emergencyContacts[index] = EmergencyContact(
                        name: name,
                        phone: phone,
                        relationship: relationship,
                      );
                    });
                    _saveProfile(); // Save to Firestore after edit
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required Function(String) onChanged,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? initialValue,
  }) {
    return TextField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      controller: initialValue != null ? TextEditingController(text: initialValue) : null,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _addAllergy() {
    String newAllergy = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Allergy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: _buildDialogTextField(
          onChanged: (value) => newAllergy = value,
          label: 'Allergy',
          hint: 'Enter allergy',
          icon: Icons.warning_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (newAllergy.isNotEmpty) {
                    setState(() => allergies.add(newAllergy));
                    _saveProfile(); // Save to Firestore after addition
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addCondition() {
    String newCondition = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Medical Condition',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: _buildDialogTextField(
          onChanged: (value) => newCondition = value,
          label: 'Medical Condition',
          hint: 'Enter medical condition',
          icon: Icons.medical_services_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (newCondition.isNotEmpty) {
                    setState(() => conditions.add(newCondition));
                    _saveProfile(); // Save to Firestore after addition
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your profile.')),
      );
      return;
    }

    try {
      final userProfile = UserProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        weight: _weightController.text,
        height: _heightController.text,
        bloodGroup: _selectedBloodGroup,
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
        emergencyContacts: emergencyContacts,
        allergies: allergies,
        conditions: conditions,
        pushNotifications: pushNotifications,
        emailNotifications: emailNotifications,
        smsNotifications: smsNotifications,
      );

      await _firestore.collection('users').doc(_currentUser!.uid).set(
        userProfile.toMap(),
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile saved successfully!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }
}