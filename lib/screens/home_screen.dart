import 'package:flutter/material.dart';
import 'package:ft_hangouts/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_helper.dart';
import '../models/contact.dart';
import 'contact_form.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Contact> _contacts = [];
  Color _headerColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadContacts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveLastSeen();
    }

    if (state == AppLifecycleState.resumed) {
      _showLastSeen();
    }
  }

  Future<void> _saveLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_seen', DateTime.now().toIso8601String());
  }

  Future<void> _showLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString('last_seen');

    if (savedTime == null || !mounted) return;

    final dateTime = DateTime.parse(savedTime);
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _headerColor,
          elevation: 8,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.lastSeen(time),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _loadContacts() async {
    final list = await DatabaseHelper.instance.getContacts();
    setState(() => _contacts = list);
  }

  void _deleteContact(Contact contact) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteConfirm(contact.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteContact(contact.id!);
      _loadContacts();
    }
  }

  void _openForm({Contact? contact}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContactForm(contact: contact)),
    );
    if (result == true) _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<Color>(
            icon: Icon(Icons.palette),
            onSelected: (color) => setState(() => _headerColor = color),
            itemBuilder: (_) => [
              PopupMenuItem(value: Colors.indigo, child: Text('Indigo')),
              PopupMenuItem(value: Colors.teal, child: Text('Teal')),
              PopupMenuItem(value: Colors.red, child: Text('Red')),
              PopupMenuItem(value: Colors.orange, child: Text('Orange')),
              PopupMenuItem(value: Colors.purple, child: Text('Purple')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _contacts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      l10n.noContacts,
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(l10n.addFirst, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (_, i) {
                  final contact = _contacts[i];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _headerColor,
                        child: Text(
                          contact.name[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(contact: contact),
                        ),
                      ),
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom +
                                  MediaQuery.of(context).padding.bottom,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text(l10n.edit),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _openForm(contact: contact);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    l10n.delete,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteContact(contact);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: _headerColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
