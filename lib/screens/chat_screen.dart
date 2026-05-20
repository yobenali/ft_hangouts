import 'dart:async';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/sms_service.dart';
import 'package:ft_hangouts/l10n/app_localizations.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _sending = false;
  Timer? _refreshTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkForNewMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Called ONCE on open — syncs inbox then loads DB
  Future<void> _initialLoad() async {
    await _syncFromInbox();
    await _refreshFromDb();
  }

  // Sync SMS inbox into SQLite with proper deduplication
  Future<void> _syncFromInbox() async {
    final smsList = await SmsService.readSms(phone: widget.contact.phone);
    for (final sms in smsList) {
      final body = sms['body'] as String;
      final isSent = sms['isSent'] as int;
      final date = sms['date'] as int;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(date).toIso8601String();

      final exists = await DatabaseHelper.instance.messageExists(
        contactId: widget.contact.id!,
        body: body,
        isSent: isSent,
        timestamp: timestamp,
      );

      if (!exists) {
        await DatabaseHelper.instance.insertMessage(
          Message(
            contactId: widget.contact.id!,
            body: body,
            isSent: isSent,
            timestamp: timestamp,
          ),
        );
      }
    }
  }

  // Read from DB only — no inbox sync, no flicker
  Future<void> _refreshFromDb() async {
    final msgs =
        await DatabaseHelper.instance.getMessages(widget.contact.id!);
    if (!mounted) return;
    setState(() => _messages = msgs);
    if (msgs.length > _lastMessageCount) {
      _lastMessageCount = msgs.length;
      _scrollToBottom();
    }
    _lastMessageCount = msgs.length;
  }

  // Called every 5s — only updates UI if something changed
  Future<void> _checkForNewMessages() async {
    final before = _messages.length;
    await _syncFromInbox();
    final msgs =
        await DatabaseHelper.instance.getMessages(widget.contact.id!);
    if (!mounted) return;
    if (msgs.length != before) {
      setState(() => _messages = msgs);
      _scrollToBottom();
      _lastMessageCount = msgs.length;
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    final success = await SmsService.sendSms(
      phone: widget.contact.phone,
      message: text,
    );

    if (success) {
      // Save directly to DB — never re-synced from inbox
      await DatabaseHelper.instance.insertMessage(
        Message(
          contactId: widget.contact.id!,
          body: text,
          isSent: 1,
          timestamp: DateTime.now().toIso8601String(),
        ),
      );
      _controller.clear();
      await _refreshFromDb();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedSend),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _sending = false);
  }

  String _formatTime(String timestamp) {
    final dt = DateTime.parse(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 18,
              backgroundImage: widget.contact.photoPath != null
                  ? FileImage(File(widget.contact.photoPath!))
                  : null,
              child: widget.contact.photoPath == null
                  ? Text(
                      widget.contact.name[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : null,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.name,
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  widget.contact.phone,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Message List ─────────────────────────────
            Expanded(
              child: RepaintBoundary(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              l10n.noMessages,
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              l10n.sendFirst,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isSent = msg.isSent == 1;
                          return _buildBubble(msg, isSent);
                        },
                      ),
              ),
            ),

            // ── Input Bar ────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  _sending
                      ? CircularProgressIndicator()
                      : CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Message msg, bool isSent) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isSent ? 60 : 0,
          right: isSent ? 0 : 60,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSent ? Colors.indigo : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft:
                isSent ? Radius.circular(16) : Radius.circular(4),
            bottomRight:
                isSent ? Radius.circular(4) : Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isSent
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(msg.timestamp),
              style: TextStyle(
                color: isSent ? Colors.white60 : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}