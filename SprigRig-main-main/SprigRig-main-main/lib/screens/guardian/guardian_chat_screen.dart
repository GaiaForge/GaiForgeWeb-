import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/zone.dart';
import '../../models/guardian/guardian_action.dart';
import '../../services/guardian/guardian_service.dart';
import '../../services/guardian/guardian_advisor_service.dart';
import '../../services/guardian/guardian_context_builder.dart';
import '../../services/guardian/guardian_action_service.dart';
import '../../widgets/common/sprigrig_background.dart';
import '../../widgets/common/sprigrig_keyboard.dart';
import '../../widgets/cards/glass_card.dart';

class GuardianChatScreen extends StatefulWidget {
  final Zone zone;

  const GuardianChatScreen({super.key, required this.zone});

  @override
  State<GuardianChatScreen> createState() => _GuardianChatScreenState();
}

class _GuardianChatScreenState extends State<GuardianChatScreen> {
  final GuardianAdvisorService _advisor = GuardianAdvisorService();
  final GuardianActionService _actionService = GuardianActionService();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _inputText = '';
  GuardianAction? _pendingAction;

  @override
  void initState() {
    super.initState();
    _addSystemMessage('Guardian online. How can I help with ${widget.zone.name}?');
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _inputText = '';
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Build context
      final builder = GuardianContextBuilder(widget.zone.id!);
      final context = await builder.build();

      // Get advice
      final response = await _advisor.getAdvice(context, text);

      if (response.success) {
        setState(() {
          _messages.add(ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: DateTime.now(),
          ));

          if (response.suggestedAction != null) {
            _pendingAction = response.suggestedAction;
          }
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Error: ${response.message}',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeAction(GuardianAction action) async {
    final result = await _actionService.executeAction(action);
    
    setState(() {
      _messages.add(ChatMessage(
        text: result.success 
          ? '✓ ${result.message}'
          : '✗ ${result.message}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: !result.success,
      ));
      _pendingAction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Guardian - ${widget.zone.name}', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SprigrigBackground(
        primaryColor: Colors.deepPurple,
        child: SafeArea(
          child: Column(
            children: [
              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Pending action confirmation
              if (_pendingAction != null)
                _buildActionConfirmation(_pendingAction!),

              // Input area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: message.isUser ? 48 : 0,
          right: message.isUser ? 0 : 48,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser 
            ? Colors.purpleAccent.withOpacity(0.3)
            : message.isError
              ? Colors.red.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isUser 
              ? Colors.purpleAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12, right: 48),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.purpleAccent,
              ),
            ),
            SizedBox(width: 12),
            Text('Guardian is thinking...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionConfirmation(GuardianAction action) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Action Requested', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text(action.description, style: TextStyle(color: Colors.white)),
          SizedBox(height: 4),
          Text(action.reasoning, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _pendingAction = null),
                child: Text('Deny', style: TextStyle(color: Colors.white54)),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _executeAction(action),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                child: Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          // Text display
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              _inputText.isEmpty ? 'Ask Guardian something...' : _inputText,
              style: TextStyle(
                color: _inputText.isEmpty ? Colors.white38 : Colors.white,
              ),
            ),
          ),
          
          // Keyboard
          SprigrigKeyboard(
            onKeyPressed: (key) => setState(() => _inputText += key),
            onDelete: () => setState(() {
              if (_inputText.isNotEmpty) {
                _inputText = _inputText.substring(0, _inputText.length - 1);
              }
            }),
            onSpace: () => setState(() => _inputText += ' '),
          ),
          
          SizedBox(height: 12),
          
          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _sendMessage(_inputText),
              icon: Icon(Icons.send),
              label: Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
