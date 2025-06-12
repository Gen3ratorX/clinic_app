// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isError = false;
  bool _isLoading = true;

  // App colors (same as AIScreen)
  static const Color primaryColor = Color(0xFF00796B); // Olive green
  static const Color lightPrimaryColor = Color(0xFFAAB000);
  static const Color backgroundColor = Color(0xFFF8F8F0);
  static const Color userBubbleColor = Color(0xFF00796B);
  static const Color botBubbleColor = Color(0xFFEAEAD0);

  // Firebase and encryption
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserId;
  late String _recipientId; // Set dynamically based on provider
  late encrypt.Encrypter _encrypter;
  final _key = encrypt.Key.fromLength(32); // AES-256 key (store securely in production)
  final _iv = encrypt.IV.fromLength(16); // Initialization vector

  @override
  void initState() {
    super.initState();
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
        return;
      }
      _currentUserId = user.uid;

      // TODO: Set _recipientId dynamically (e.g., from provider selection)
      _recipientId = 'nurse_or_doctor_uid'; // Replace with actual provider ID

      // Initialize encrypter
      _encrypter = encrypt.Encrypter(encrypt.AES(_key));

      // Load messages
      _loadMessages();

      setState(() {
        _isError = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing messaging: $e');
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  void _loadMessages() {
    // Stream messages in real-time
    _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: _getConversationId())
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final encryptedText = data['text'] as String;
          final decryptedText = _encrypter.decrypt64(encryptedText, iv: _iv);
          _messages.add(ChatMessage(
            text: decryptedText,
            isUser: data['senderId'] == _currentUserId,
            timestamp: (data['timestamp'] as Timestamp).toDate(),
          ));
        }
      });
      _scrollToBottom();
    }, onError: (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _isError = true;
      });
    });
  }

  String _getConversationId() {
    // Generate a unique conversation ID based on user IDs
    final ids = [_currentUserId, _recipientId]..sort();
    return ids.join('_');
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text;
    _addMessage(messageText, true);
    _messageController.clear();

    setState(() {
      _isTyping = true;
      _isError = false;
    });

    try {
      // Encrypt message
      final encryptedText = _encrypter.encrypt(messageText, iv: _iv).base64;

      // Store in Firestore
      await _firestore.collection('messages').add({
        'conversationId': _getConversationId(),
        'senderId': _currentUserId,
        'recipientId': _recipientId,
        'text': encryptedText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Simulate nurse/doctor response (for demo purposes)
      // In production, this would be handled by the provider's app
      final responseText = 'Thank you for your message. A nurse will respond soon.';
      final encryptedResponse = _encrypter.encrypt(responseText, iv: _iv).base64;
      await _firestore.collection('messages').add({
        'conversationId': _getConversationId(),
        'senderId': _recipientId,
        'recipientId': _currentUserId,
        'text': encryptedResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      setState(() {
        _isError = true;
      });
      _addMessage('Error sending message. Please try again.', false);
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: lightPrimaryColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Secure Messaging',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                // TODO: Show chat info or provider details
              },
              tooltip: 'Chat info',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: backgroundColor,
          ),
          child: Column(
            children: [
              if (_isError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Connection error. Please check your network.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _initializeMessaging,
                        tooltip: 'Retry connection',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/images/Logo.png',
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Your Healthcare Chat',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    'Start a secure conversation with your nurse or doctor.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return MessageBubble(
                                message: message,
                                userBubbleColor: userBubbleColor,
                                botBubbleColor: botBubbleColor,
                              );
                            },
                          ),
              ),
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Icon(Icons.health_and_safety, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildTypingIndicator(),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(Icons.question_answer, color: primaryColor),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        const Text(
          'Typing',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(left: 2),
            child: _buildPulsingDot(
              delay: Duration(milliseconds: index * 300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingDot({required Duration delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Reused from AIScreen
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color userBubbleColor;
  final Color botBubbleColor;

  const MessageBubble({
    super.key,
    required this.message,
    required this.userBubbleColor,
    required this.botBubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: userBubbleColor,
              child: const Icon(Icons.health_and_safety, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: message.isUser ? userBubbleColor : botBubbleColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser)
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                        em: const TextStyle(fontStyle: FontStyle.italic),
                        a: TextStyle(color: userBubbleColor),
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        blockquote: TextStyle(
                          color: Colors.black54,
                          backgroundColor: Colors.grey.shade100,
                          fontSize: 16,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border(
                            left: BorderSide(
                              color: userBubbleColor.withOpacity(0.5),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser ? Colors.white.withOpacity(0.7) : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF4A6D00),
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}