import 'package:flutter/material.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;

  @override
  void initState() {
    super.initState();

    // Add a listener to detect scroll position.
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.offset >= _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        setState(() {
          _hasScrolledToEnd = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _acceptTerms() {
    Navigator.pop(context, true); // Return true to indicate acceptance.
  }

  @override
  Widget build(BuildContext context) {
    final String termsText = '''
        Welcome to the Terms and Conditions for our Health App at Pentecost University Clinic. This app is designed to enhance communication between patients and nurses, assist with appointment scheduling, and provide health tips through an AI chatbot.

        1. **Responsibility**: Users are expected to use this app responsibly. Any misuse may lead to termination of service.
        2. **Data Handling**: Patient data will be handled in accordance with our strict privacy policies.
        3. **AI Chatbot**: The AI chatbot is provided for informational purposes and should not replace professional medical advice.
        
        ${List.generate(30, (index) => 'Clause ${index + 1}: Additional details on policies.').join('\n')}
    ''';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF00796B), // Olive Green
        title: const Text('Terms & Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  termsText,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: (_hasScrolledToEnd || (!_scrollController.hasClients || _scrollController.position.maxScrollExtent == 0))
                  ? _acceptTerms
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B), // Olive Green
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Accept', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),

            if (!_hasScrolledToEnd && _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Please scroll to the bottom and accept these terms to proceed.',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
