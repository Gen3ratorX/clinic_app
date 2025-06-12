// // ignore_for_file: deprecated_member_use

// import 'package:flutter/material.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

// class AIScreen extends StatefulWidget {
//   const AIScreen({super.key});

//   @override
//   State<AIScreen> createState() => _AIScreenState();
// }

// class _AIScreenState extends State<AIScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<ChatMessage> _messages = [];
//   bool _isTyping = false;
//   bool _isError = false;
//   late GenerativeModel _model;
//   late ChatSession _chatSession;

//   // App colors
//   static const Color primaryColor = Color(0xFF00796B); // Olive green
//   static const Color lightPrimaryColor = Color(0xFFAAB000);
//   static const Color backgroundColor = Color(0xFFF8F8F0);
//   static const Color userBubbleColor = Color(0xFF00796B);
//   static const Color botBubbleColor = Color(0xFFEAEAD0);

//   // For storing chat history
//   static const String _chatHistoryKey = 'chat_history';

//   @override
//   void initState() {
//     super.initState();
//     _initializeGemini();
//     _loadChatHistory();
//   }

//   Future<void> _initializeGemini() async {
//     try {
//       // Replace with your actual Gemini API key
//       const apiKey = 'AIzaSyDrznC8SvZI3zgHBDQKGLtXPQ1HHY5aoJ4';

//       // Initialize the model with health focus
//       _model = GenerativeModel(
//         model: 'gemini-2.0-flash',
//         apiKey: apiKey,
//         generationConfig: GenerationConfig(
//           temperature: 0.7,
//           topK: 40,
//           topP: 0.95,
//           maxOutputTokens: 1024,
//         ),
//         safetySettings: [
//           SafetySetting(
//               HarmCategory.dangerousContent,
//               HarmBlockThreshold.medium
//           ),
//           SafetySetting(
//               HarmCategory.harassment,
//               HarmBlockThreshold.medium
//           ),
//           SafetySetting(
//               HarmCategory.hateSpeech,
//               HarmBlockThreshold.medium
//           ),
//         ],
//       );

//       // Initialize chat session with health-specific system prompt using positional arguments
//       final initialPrompt = Content(
//         'user',
//         [
//           TextPart(
//             'You are a helpful healthcare assistant. Provide accurate information about health topics, while clearly stating when medical advice should be sought from a healthcare professional. Never claim to diagnose or treat conditions. Always emphasize the importance of consulting qualified medical professionals for personalized advice. Use simple, clear language and cite reliable sources when appropriate.',
//           )
//         ],
//       );

//       final initialResponse = Content(
//         'model',
//         [
//           TextPart(
//             "I'll serve as your healthcare information assistant. I can provide general health information and educational content, but I'll always clarify when consulting a healthcare professional is necessary. I won't diagnose conditions or provide personalized treatment advice. I'll use clear language and reference trustworthy sources when relevant. How can I help with your health questions today?",
//           )
//         ],
//       );

//       _chatSession = _model.startChat(
//         history: [initialPrompt, initialResponse],
//       );

//       setState(() {
//         _isError = false;
//       });
//     } catch (e) {
//       debugPrint('Error initializing Gemini: $e');
//       setState(() {
//         _isError = true;
//       });
//     }
//   }

//   Future<void> _loadChatHistory() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final chatHistory = prefs.getStringList(_chatHistoryKey);

//       if (chatHistory != null && chatHistory.isNotEmpty) {
//         setState(() {
//           for (int i = 0; i < chatHistory.length; i += 2) {
//             final isUser = chatHistory[i] == 'user';
//             final messageText = i + 1 < chatHistory.length ? chatHistory[i + 1] : '';

//             _messages.add(ChatMessage(
//               text: messageText,
//               isUser: isUser,
//               timestamp: DateTime.now(),
//             ));
//           }
//         });
//       } else {
//         _addBotMessage("Hello! I'm your healthcare assistant. I can provide general health information and answer questions. How can I help you today?");
//       }
//     } catch (e) {
//       debugPrint('Error loading chat history: $e');
//     }
//   }

//   Future<void> _saveChatHistory() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final chatHistory = <String>[];

//       for (final message in _messages) {
//         chatHistory.add(message.isUser ? 'user' : 'bot');
//         chatHistory.add(message.text);
//       }

//       await prefs.setStringList(_chatHistoryKey, chatHistory);
//     } catch (e) {
//       debugPrint('Error saving chat history: $e');
//     }
//   }

//   void _addMessage(String text, bool isUser) {
//     setState(() {
//       _messages.add(ChatMessage(
//         text: text,
//         isUser: isUser,
//         timestamp: DateTime.now(),
//       ));
//     });

//     _saveChatHistory();
//     _scrollToBottom();
//   }

//   void _addBotMessage(String text) {
//     _addMessage(text, false);
//   }

//   void _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     final messageText = _messageController.text;
//     _addMessage(messageText, true);
//     _messageController.clear();

//     setState(() {
//       _isTyping = true;
//       _isError = false;
//     });

//     try {
//       final userMessage = Content(
//         'user',
//         [TextPart(messageText)],
//       );

//       final response = await _chatSession.sendMessage(userMessage);

//       final responseText = response.text;

//       if (responseText != null) {
//         _addBotMessage(responseText);
//       } else {
//         _addBotMessage("I'm sorry, I couldn't generate a response. Please try again.");
//       }
//     } catch (e) {
//       setState(() {
//         _isError = true;
//       });
//       _addBotMessage("I'm sorry, there was an error processing your request. Please try again later.");
//       debugPrint('Error sending message to Gemini: $e');
//       // Attempt to reinitialize the chat session
//       _initializeGemini();
//     } finally {
//       setState(() {
//         _isTyping = false;
//       });
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   void _clearChat() async {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clear Conversation', style: TextStyle(color: primaryColor)),
//         content: const Text('Are you sure you want to clear this conversation?'),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);

//               setState(() {
//                 _messages.clear();
//               });

//               try {
//                 final prefs = await SharedPreferences.getInstance();
//                 await prefs.remove(_chatHistoryKey);

//                 // Re-initialize chat session
//                 _initializeGemini();

//                 _addBotMessage("Hello! I'm your healthcare assistant. I can provide general health information and answer questions. How can I help you today?");
//               } catch (e) {
//                 debugPrint('Error clearing chat history: $e');
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryColor,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text('Clear'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: ThemeData(
//         primaryColor: primaryColor,
//         colorScheme: ColorScheme.light(
//           primary: primaryColor,
//           secondary: lightPrimaryColor,
//         ),
//         scaffoldBackgroundColor: backgroundColor,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: primaryColor,
//           foregroundColor: Colors.white,
//           elevation: 0,
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: primaryColor,
//             foregroundColor: Colors.white,
//           ),
//         ),
//       ),
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text(
//             'Pent Click AI',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//             ),
//           ),
//           centerTitle: true,
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.delete_outline),
//               onPressed: _clearChat,
//               tooltip: 'Clear conversation',
//             ),
//           ],
//         ),
//         body: Container(
//           decoration: const BoxDecoration(
//             color: backgroundColor,
//           ),
//           child: Column(
//             children: [
//               if (_isError)
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   color: Colors.red.shade100,
//                   child: Row(
//                     children: [
//                       const Icon(Icons.error_outline, color: Colors.red),
//                       const SizedBox(width: 8),
//                       const Expanded(
//                         child: Text(
//                           'Connection error. Check your API key or network connection.',
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.refresh, color: Colors.red),
//                         onPressed: _initializeGemini,
//                         tooltip: 'Retry connection',
//                       ),
//                     ],
//                   ),
//                 ),
//               Expanded(
//                 child: _messages.isEmpty
//                     ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: primaryColor.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Image.asset(
//                           'assets/images/Logo.png', // Replace with your asset
//                           height: 100,
//                           width: 100,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       const Text(
//                         'Your Health Assistant',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 40),
//                         child: Text(
//                           'Ask me anything about health topics. I can provide general information while respecting medical boundaries.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.black54,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           _messageController.text = "What are some tips for better sleep?";
//                           _sendMessage();
//                         },
//                         icon: const Icon(Icons.lightbulb_outline),
//                         label: const Text("Try a sample question"),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//                     : ListView.builder(
//                   controller: _scrollController,
//                   padding: const EdgeInsets.all(16),
//                   itemCount: _messages.length,
//                   itemBuilder: (context, index) {
//                     final message = _messages[index];
//                     return MessageBubble(
//                       message: message,
//                       userBubbleColor: userBubbleColor,
//                       botBubbleColor: botBubbleColor,
//                     );
//                   },
//                 ),
//               ),
//               if (_isTyping)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     children: [
//                       const SizedBox(
//                         width: 40,
//                         height: 40,
//                         child: CircleAvatar(
//                           backgroundColor: primaryColor,
//                           child: Icon(Icons.health_and_safety, color: Colors.white),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       _buildTypingIndicator(),
//                     ],
//                   ),
//                 ),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       spreadRadius: 1,
//                       offset: const Offset(0, -2),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: 'Ask a health question...',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(24),
//                             borderSide: BorderSide.none,
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey.shade100,
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 14,
//                           ),
//                           prefixIcon: const Icon(Icons.question_answer, color: primaryColor),
//                         ),
//                         textCapitalization: TextCapitalization.sentences,
//                         minLines: 1,
//                         maxLines: 5,
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Material(
//                       color: primaryColor,
//                       borderRadius: BorderRadius.circular(24),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(24),
//                         onTap: _sendMessage,
//                         child: Container(
//                           padding: const EdgeInsets.all(14),
//                           child: const Icon(
//                             Icons.send_rounded,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTypingIndicator() {
//     return Row(
//       children: [
//         const Text(
//           'Typing',
//           style: TextStyle(
//             color: Colors.grey,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(width: 8),
//         ...List.generate(
//           3,
//               (index) => Container(
//             margin: EdgeInsets.only(left: 2),
//             child: _buildPulsingDot(
//               delay: Duration(milliseconds: index * 300),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPulsingDot({required Duration delay}) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: const Duration(milliseconds: 900),
//       curve: Curves.easeInOut,
//       builder: (context, value, child) {
//         return Container(
//           width: 6,
//           height: 6,
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.3 + (value * 0.7)),
//             shape: BoxShape.circle,
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// class ChatMessage {
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;

//   ChatMessage({
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//   });
// }

// class MessageBubble extends StatelessWidget {
//   final ChatMessage message;
//   final Color userBubbleColor;
//   final Color botBubbleColor;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.userBubbleColor,
//     required this.botBubbleColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!message.isUser) ...[
//             CircleAvatar(
//               backgroundColor: userBubbleColor,
//               child: const Icon(Icons.health_and_safety, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//           ],
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               decoration: BoxDecoration(
//                 color: message.isUser ? userBubbleColor : botBubbleColor,
//                 borderRadius: BorderRadius.circular(18).copyWith(
//                   bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
//                   bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 5,
//                     spreadRadius: 1,
//                     offset: const Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Use Markdown for bot messages to support formatting
//                   if (!message.isUser)
//                     MarkdownBody(
//                       data: message.text,
//                       styleSheet: MarkdownStyleSheet(
//                         p: TextStyle(
//                           color: Colors.black87,
//                           fontSize: 16,
//                           height: 1.4,
//                         ),
//                         strong: const TextStyle(fontWeight: FontWeight.bold),
//                         em: const TextStyle(fontStyle: FontStyle.italic),
//                         a: TextStyle(color: userBubbleColor),
//                         h1: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                         h2: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                         blockquote: TextStyle(
//                           color: Colors.black54,
//                           backgroundColor: Colors.grey.shade100,
//                           fontSize: 16,
//                         ),
//                         blockquoteDecoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(4),
//                           border: Border(
//                             left: BorderSide(
//                               color: userBubbleColor.withOpacity(0.5),
//                               width: 4,
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//                   else
//                     Text(
//                       message.text,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         height: 1.4,
//                       ),
//                     ),
//                   const SizedBox(height: 6),
//                   Text(
//                     _formatTime(message.timestamp),
//                     style: TextStyle(
//                       color: message.isUser ? Colors.white.withOpacity(0.7) : Colors.black45,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (message.isUser) const SizedBox(width: 12),
//           if (message.isUser)
//             const CircleAvatar(
//               backgroundColor: Color(0xFF4A6D00),
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//         ],
//       ),
//     );
//   }

//   String _formatTime(DateTime dateTime) {
//     final hour = dateTime.hour.toString().padLeft(2, '0');
//     final minute = dateTime.minute.toString().padLeft(2, '0');
//     return '$hour:$minute';
//   }
// }

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isError = false;
  bool _isLoading = true; // Added to handle initialization
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // App colors
  static const Color primaryColor = Color(0xFF00796B); // Olive green
  static const Color lightPrimaryColor = Color(0xFFAAB000);
  static const Color backgroundColor = Color(0xFFF8F8F0);
  static const Color userBubbleColor = Color(0xFF00796B);
  static const Color botBubbleColor = Color(0xFFEAEAD0);

  // For storing chat history
  static const String _chatHistoryKey = 'chat_history';

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadChatHistory();
  }

  Future<void> _initializeGemini() async {
    try {
      // Replace with your actual Gemini API key
      const apiKey = 'AIzaSyDrznC8SvZI3zgHBDQKGLtXPQ1HHY5aoJ4';

      // Initialize the model with health focus
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(
              HarmCategory.dangerousContent,
              HarmBlockThreshold.medium
          ),
          SafetySetting(
              HarmCategory.harassment,
              HarmBlockThreshold.medium
          ),
          SafetySetting(
              HarmCategory.hateSpeech,
              HarmBlockThreshold.medium
          ),
        ],
      );

      // Initialize chat session with only the system prompt, no initial response
      final initialPrompt = Content(
        'user',
        [
          TextPart(
            'You are a helpful healthcare assistant. Provide accurate information about health topics, while clearly stating when medical advice should be sought from a healthcare professional. Never claim to diagnose or treat conditions. Always emphasize the importance of consulting qualified medical professionals for personalized advice. Use simple, clear language and cite reliable sources when appropriate.',
          )
        ],
      );

      _chatSession = _model.startChat(
        history: [initialPrompt], // Only include the system prompt
      );

      setState(() {
        _isError = false;
        _isLoading = false; // Initialization complete
      });
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistory = prefs.getStringList(_chatHistoryKey);

      if (chatHistory != null && chatHistory.isNotEmpty) {
        setState(() {
          for (int i = 0; i < chatHistory.length; i += 2) {
            final isUser = chatHistory[i] == 'user';
            final messageText = i + 1 < chatHistory.length ? chatHistory[i + 1] : '';

            _messages.add(ChatMessage(
              text: messageText,
              isUser: isUser,
              timestamp: DateTime.now(),
            ));
          }
        });
      }
      setState(() {
        _isLoading = false; // History loaded
      });
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistory = <String>[];

      for (final message in _messages) {
        chatHistory.add(message.isUser ? 'user' : 'bot');
        chatHistory.add(message.text);
      }

      await prefs.setStringList(_chatHistoryKey, chatHistory);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });

    _saveChatHistory();
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    _addMessage(text, false);
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
      final userMessage = Content(
        'user',
        [TextPart(messageText)],
      );

      final response = await _chatSession.sendMessage(userMessage);

      final responseText = response.text;

      if (responseText != null) {
        _addBotMessage(responseText);
      } else {
        _addBotMessage("I'm sorry, I couldn't generate a response. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isError = true;
      });
      _addBotMessage("I'm sorry, there was an error processing your request. Please try again later.");
      debugPrint('Error sending message to Gemini: $e');
      // Attempt to reinitialize the chat session
      _initializeGemini();
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

  void _clearChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation', style: TextStyle(color: primaryColor)),
        content: const Text('Are you sure you want to clear this conversation?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _messages.clear();
              });

              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_chatHistoryKey);

                // Re-initialize chat session
                _initializeGemini();
              } catch (e) {
                debugPrint('Error clearing chat history: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
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
            'Pent Click AI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
              tooltip: 'Clear conversation',
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
                          'Connection error. Check your API key or network connection.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _initializeGemini,
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
                                    'assets/images/Logo.png', // Ensure this path is correct
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Your Health Assistant',
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
                                    'Ask me anything about health topics. I can provide general information while respecting medical boundaries.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Set the sample question and send it only when clicked
                                    setState(() {
                                      _messageController.text = "What are some tips for better sleep?";
                                    });
                                    _sendMessage();
                                  },
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: const Text("Try a sample question"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          hintText: 'Ask a health question...',
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
                  // Use Markdown for bot messages to support formatting
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