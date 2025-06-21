import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  _UserReportsScreenState createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  User? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _doctorNameCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser == null) {
        _showSnackBar('Please sign in to view your reports.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error initializing: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.roboto(fontSize: 14)),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _preloadDoctorNames(List<QueryDocumentSnapshot> appointmentDocs) async {
    final doctorIds = appointmentDocs
        .map((e) => (e.data() as Map<String, dynamic>)['doctorId'])
        .whereType<String>()
        .toSet();

    final futures = doctorIds
        .where((id) => !_doctorNameCache.containsKey(id))
        .map((id) async {
      try {
        final doc = await _firestore.collection('doctors').doc(id).get();
        _doctorNameCache[id] = doc.exists ? doc['name'] ?? 'Unknown Doctor' : 'Unknown Doctor';
      } catch (_) {
        _doctorNameCache[id] = 'Unknown Doctor';
      }
    });

    await Future.wait(futures);
  }

  Future<String> _getDoctorName(String doctorId) async {
    return _doctorNameCache[doctorId] ?? 'Unknown Doctor';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please sign in to view your reports.',
            style: GoogleFonts.roboto(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search by doctor or date...',
            hintStyle: GoogleFonts.roboto(color: Colors.white70),
            border: InputBorder.none,
          ),
        )
            : Text(
          'My Medical Reports',
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
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            tooltip: _isSearching ? 'Cancel Search' : 'Search Reports',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildReportsList(),
    );
  }

  Widget _buildReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('userId', isEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.roboto(fontSize: 14)),
          );
        }

        final appointmentDocs = snapshot.data!.docs;

        return FutureBuilder<List<Widget>>(
          future: _fetchAllReports(appointmentDocs),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No reports found.',
                      style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medical Reports',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...reports,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Widget>> _fetchAllReports(List<QueryDocumentSnapshot> appointmentDocs) async {
    await _preloadDoctorNames(appointmentDocs);

    List<Future<List<Widget>>> futures = [];

    for (var appointmentDoc in appointmentDocs) {
      final appointmentId = appointmentDoc.id;
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;

      final future = _firestore
          .collection('appointments')
          .doc(appointmentId)
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get()
          .then((reportSnap) async {
        List<Widget> widgets = [];

        for (var reportDoc in reportSnap.docs) {
          final report = reportDoc.data() as Map<String, dynamic>;
          final widget = await _buildReportItem(
            appointmentData,
            report,
            appointmentId,
            reportDoc.id,
          );
          widgets.add(widget);
        }

        return widgets;
      });

      futures.add(future);
    }

    final nested = await Future.wait(futures);
    return nested.expand((e) => e).toList();
  }

  Future<Widget> _buildReportItem(Map<String, dynamic> appointment, Map<String, dynamic> report, String appointmentId, String reportId) async {
    final doctorId = appointment['doctorId']?.toString() ?? '';
    final doctorName = await _getDoctorName(doctorId);
    final createdAt = (report['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final hasAttachment = report['attachmentUrl'] != null;

    return ReportItem(
      appointment: appointment,
      report: report,
      child: Container(
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
                  radius: 25,
                  backgroundColor: const Color(0xFF2E86AB).withOpacity(0.1),
                  child: const Icon(Icons.person, color: Color(0xFF2E86AB)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. $doctorName',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        appointment['type']?.toString() ?? 'Consultation',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                  DateFormat('MMMM d, yyyy').format(createdAt),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  appointment['timeSlot']?.toString() ?? 'N/A',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report['title']?.toString() ?? 'Medical Report',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            if (report['content']?.toString().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                report['content'],
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[800]),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hasAttachment) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openAttachment(report['attachmentUrl']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E86AB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_present, size: 14, color: const Color(0xFF2E86AB)),
                      const SizedBox(width: 4),
                      Text(
                        report['attachmentName']?.toString() ?? 'Attachment',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xFF2E86AB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        HapticFeedback.selectionClick();
      } else {
        _showSnackBar('Could not open attachment', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening attachment: $e', isError: true);
    }
  }
}

class ReportItem extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> report;
  final Widget child;

  const ReportItem({
    super.key,
    required this.appointment,
    required this.report,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
