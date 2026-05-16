import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/sms_service.dart';
import 'package:ft_hangouts/l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  ChatScreen({required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load messages — combines SQLite + real SMS inbox
  void _loadMessages() async {
    // Step 1: read real SMS from Android inbox
    final smsList = await SmsService.readSms(phone: widget.contact.phone);

    // Step 2: sync them into our SQLite DB
    for (final sms in smsList) {
      final body = sms['body'] as String;
      final isSent = sms['isSent'] as int;
      final date = sms['date'] as int;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        date,
      ).toIso8601String();

      // Check if this message already exists in DB
      final exists = await DatabaseHelper.instance.messageExists(
        contactId: widget.contact.id!,
        body: body,
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

    // Step 3: load all messages from DB for display
    final msgs = await DatabaseHelper.instance.getMessages(widget.contact.id!);
    setState(() => _messages = msgs);
    _scrollToBottom();
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
      await DatabaseHelper.instance.insertMessage(
        Message(
          contactId: widget.contact.id!,
          body: text,
          isSent: 1,
          timestamp: DateTime.now().toIso8601String(),
        ),
      );
      _controller.clear();
      _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send — check SMS permissions'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _sending = false);
  }

  String _formatTime(String timestamp) {
    final dt = DateTime.parse(timestamp);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 18,
              child: Text(
                widget.contact.name[0].toUpperCase(),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contact.name, style: TextStyle(fontSize: 16)),
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
                              'No messages yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'Send the first message!',
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
                        hintText: AppLocalizations.of(context)!.typeMessage,
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
            bottomLeft: isSent ? Radius.circular(16) : Radius.circular(4),
            bottomRight: isSent ? Radius.circular(4) : Radius.circular(16),
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
