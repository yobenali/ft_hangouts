import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/contact.dart';
import 'contact_form.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Contact> _contacts = [];
  Color _headerColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // Load all contacts from the database
  void _loadContacts() async {
    final list = await DatabaseHelper.instance.getContacts();
    setState(() => _contacts = list);
  }

  // Delete contact with confirmation dialog
  void _deleteContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteContact(contact.id!);
      _loadContacts();
    }
  }

  // Navigate to create or edit contact form
  void _openForm({Contact? contact}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactForm(contact: contact),
      ),
    );
    // If form saved something, refresh the list
    if (result == true) _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ft_hangouts'),
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
        actions: [
          // Color picker menu
          PopupMenuButton<Color>(
            icon: Icon(Icons.palette),
            onSelected: (color) {
              setState(() => _headerColor = color);
            },
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
      // Show message if no contacts yet
      body: _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No contacts yet',
                      style: TextStyle(color: Colors.grey, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first contact',
                      style: TextStyle(color: Colors.grey)),
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
                    // Circle with first letter of name
                    leading: CircleAvatar(
                      backgroundColor: _headerColor,
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                    // Tap → go to chat (Step 6)
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(contact: contact),
                        ),
                      );
                    },
                    // Long press → edit or delete
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom +
                                MediaQuery.of(context).padding.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              onTap: () {
                                Navigator.pop(context);
                                _openForm(contact: contact);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete',
                                  style: TextStyle(color: Colors.red)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: _headerColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}