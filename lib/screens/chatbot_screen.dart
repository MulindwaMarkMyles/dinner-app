import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitializing = true;
  bool _isLoadingHistory = false;
  bool _isSending = false;

  String? _sessionId;
  int? _activeConversationId;

  List<ChatbotConversationSummary> _conversations = [];
  List<ChatbotMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final sessionId = await _getOrCreateSessionId();
      if (!mounted) return;

      setState(() {
        _sessionId = sessionId;
      });

      await _loadConversations(selectLatest: true);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (!mounted) return;
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadConversations({bool selectLatest = false}) async {
    if (_sessionId == null || _sessionId!.isEmpty) return;

    try {
      final conversations = await _apiService.listChatbotConversations(
        sessionId: _sessionId!,
      );

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
      });

      if (selectLatest && conversations.isNotEmpty) {
        await _loadHistory(conversations.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  Future<void> _loadHistory(int conversationId) async {
    if (_sessionId == null || _sessionId!.isEmpty) return;

    setState(() => _isLoadingHistory = true);

    try {
      final history = await _apiService.getChatbotConversationHistory(
        conversationId: conversationId,
        sessionId: _sessionId,
      );

      if (!mounted) return;

      setState(() {
        _activeConversationId = history.conversationId;
        _messages = history.messages;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sessionId == null || _isSending) return;

    FocusScope.of(context).unfocus();
    _messageController.clear();

    setState(() {
      _isSending = true;
      _messages.add(ChatbotMessage(role: 'user', content: message));
    });
    _scrollToBottom();

    try {
      final response = await _apiService.sendChatbotMessage(
        message: message,
        conversationId: _activeConversationId,
        sessionId: _sessionId,
      );

      if (!mounted) return;

      setState(() {
        _activeConversationId = response.conversationId;
        _messages.add(
          ChatbotMessage(role: 'assistant', content: response.message),
        );
      });

      await _loadConversations();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  Future<String> _getOrCreateSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'chatbot_session_id';

    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generateUuidV4();
    await prefs.setString(key, generated);
    return generated;
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');

    return [
      bytes.sublist(0, 4).map(toHex).join(),
      bytes.sublist(4, 6).map(toHex).join(),
      bytes.sublist(6, 8).map(toHex).join(),
      bytes.sublist(8, 10).map(toHex).join(),
      bytes.sublist(10, 16).map(toHex).join(),
    ].join('-');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceAll('Exception: ', ''),
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _startNewConversation() {
    if (_isSending || _isLoadingHistory) return;

    setState(() {
      _activeConversationId = null;
      _messages = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'New conversation started',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CHATBOT ASSISTANT',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isInitializing ? null : _startNewConversation,
            icon: const Icon(
              Icons.add_comment_rounded,
              color: MyApp.primaryBlue,
            ),
            tooltip: 'New conversation',
          ),
          IconButton(
            onPressed: _isInitializing ? null : () => _loadConversations(),
            icon: const Icon(Icons.refresh_rounded, color: MyApp.primaryBlue),
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : Column(
              children: [
                _buildConversationStrip(),
                Expanded(
                  child: _isLoadingHistory
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : _buildMessages(),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildConversationStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: _conversations.isEmpty
          ? Text(
              'Start a conversation by sending your first message.',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _conversations.map((conversation) {
                  final isSelected = conversation.id == _activeConversationId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isSelected,
                      selectedColor: MyApp.primaryBlue.withOpacity(0.15),
                      side: BorderSide(
                        color: isSelected
                            ? MyApp.primaryBlue
                            : Colors.grey.shade300,
                      ),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected
                            ? MyApp.primaryBlue
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _loadHistory(conversation.id),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MyApp.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 40,
                  color: MyApp.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ask anything about lunch, dinner, drinks, or attendees.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isSending && index == _messages.length) {
          return _buildThinkingBubble();
        }

        final message = _messages[index];
        final isUser = message.role.toLowerCase() == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? MyApp.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUser
                  ? null
                  : Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildMessageContent(message.content, isUser),
          ),
        );
      },
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MyApp.primaryBlue.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking...',
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String content, bool isUser) {
    if (isUser) {
      return Text(
        content,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          height: 1.35,
        ),
      );
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      shrinkWrap: true,
      fitContent: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(color: Colors.black87, fontSize: 14, height: 1.35),
        strong: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        listBullet: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 14,
          height: 1.35,
        ),
        blockquote: GoogleFonts.inter(
          color: Colors.grey.shade700,
          fontSize: 14,
          height: 1.35,
        ),
        code: GoogleFonts.robotoMono(color: Colors.black87, fontSize: 13),
        tableHead: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        tableBody: GoogleFonts.inter(color: Colors.black87, fontSize: 13),
        tableBorder: TableBorder.all(color: Colors.grey.shade300),
        tableCellsPadding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey.shade400 : MyApp.primaryBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
