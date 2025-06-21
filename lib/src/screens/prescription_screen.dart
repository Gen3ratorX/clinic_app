import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserPrescriptionScreen extends StatefulWidget {
  final String userId; // Patient's user ID to fetch their prescriptions
  const UserPrescriptionScreen({super.key, required this.userId});

  @override
  State<UserPrescriptionScreen> createState() => _UserPrescriptionScreenState();
}

class _UserPrescriptionScreenState extends State<UserPrescriptionScreen>
    with TickerProviderStateMixin {
  // == State Variables ==
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // == Color Scheme (Consistent with Doctor's Screen) ==
  final Color primaryColor = const Color(0xFF2E86AB);
  final Color accentColor = const Color(0xFF00BCD4);
  final Color backgroundColor = const Color(0xFFF0F8FF);
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF1A237E);
  final Color textSecondary = const Color(0xFF546E7A);
  final Color prescriptionColor = const Color(0xFF4CAF50); // Green for prescriptions
  final Color prescriptionAccent = const Color(0xFF81C784);

  // == Initialization ==
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchPrescriptions();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // == Data Fetching ==
  Future<void> _fetchPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Trigger a refresh to ensure latest data
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch prescriptions: $e';
        _isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot> _getPrescriptionHistory() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('prescriptions')
        .orderBy('prescribedAt', descending: true)
        .snapshots();
  }

  // == Prescription Status Update ==
  Future<void> _markAsCompleted(String prescriptionId, Map<String, dynamic> prescriptionData) async {
    try {
      final updatedData = {
        ...prescriptionData,
        'status': 'completed',
        'updatedAt': DateTime.now(),
      };

      // Update in patient's subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('prescriptions')
          .doc(prescriptionId)
          .update(updatedData);

      // Update in global prescriptions collection
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(prescriptionId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Prescription marked as completed!'),
            ],
          ),
          backgroundColor: prescriptionColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to update prescription: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // == UI Widgets ==
  Widget _buildPrescriptionCard(Map<String, dynamic> prescription, String prescriptionId) {
    final prescribedAt = (prescription['prescribedAt'] as Timestamp?)?.toDate();
    final status = prescription['status'] ?? 'active';
    final formattedDate = prescribedAt != null
        ? DateFormat('dd/MM/yyyy').format(prescribedAt)
        : 'Unknown Date';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: status == 'active'
                ? prescriptionColor.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: status == 'active'
                  ? prescriptionColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: status == 'active'
                    ? prescriptionColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: prescriptionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medication, color: prescriptionColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      prescription['medication'] ?? 'Unknown Medication',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? prescriptionColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: status == 'active' ? prescriptionColor : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Prescribed on: $formattedDate',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dosage: ${prescription['dosage'] ?? 'N/A'}',
                style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Frequency: ${prescription['frequency'] ?? 'N/A'}',
                style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${prescription['duration'] ?? 'N/A'}',
                style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Instructions: ${prescription['instructions'] ?? 'None'}',
                style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (prescription['notes'] != null && prescription['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${prescription['notes']}',
                  style: GoogleFonts.roboto(fontSize: 14, color: textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (status == 'active') ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsCompleted(prescriptionId, prescription),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'Mark as Completed',
                      style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: prescriptionColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      prescriptionColor.withOpacity(0.1),
                      prescriptionAccent.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: prescriptionColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Prescriptions',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You currently have no prescriptions.',
                style: GoogleFonts.roboto(fontSize: 16, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Prescriptions',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchPrescriptions,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading prescriptions...',
              style: GoogleFonts.roboto(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.roboto(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPrescriptions,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.roboto(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _getPrescriptionHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(prescriptionColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading prescriptions...',
                    style: GoogleFonts.roboto(color: textSecondary),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Error loading prescriptions: ${snapshot.error}',
                  style: GoogleFonts.roboto(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final prescriptions = snapshot.data!.docs;
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prescriptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final prescription = prescriptions[index].data() as Map<String, dynamic>;
                    final prescriptionId = prescriptions[index].id;
                    return _buildPrescriptionCard(prescription, prescriptionId);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}