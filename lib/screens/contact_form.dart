import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/contact.dart';

class ContactForm extends StatefulWidget {
  final Contact? contact; // null = create mode, not null = edit mode
  ContactForm({this.contact});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  // Controllers hold the text inside each input field
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill all fields with existing data
    if (_isEditing) {
      _nameCtrl.text = widget.contact!.name;
      _phoneCtrl.text = widget.contact!.phone;
      _emailCtrl.text = widget.contact!.email;
      _addressCtrl.text = widget.contact!.address;
      _noteCtrl.text = widget.contact!.note;
    }
  }

  @override
  void dispose() {
    // Always clean up controllers when screen closes
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    // Check all validators pass before saving
    if (!_formKey.currentState!.validate()) return;

    final contact = Contact(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );

    if (_isEditing) {
      // Update existing contact — keep same id
      await DatabaseHelper.instance.updateContact(
        contact.copyWith(id: widget.contact!.id),
      );
    } else {
      // Insert new contact
      await DatabaseHelper.instance.insertContact(contact);
    }

    // Pop back to HomeScreen and signal a refresh
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Big avatar circle at top
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.indigo,
                child: Text(
                  _nameCtrl.text.isNotEmpty
                      ? _nameCtrl.text[0].toUpperCase()
                      : '?',
                  style: TextStyle(fontSize: 36, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 24),

            _buildField(
              controller: _nameCtrl,
              label: 'Name',
              icon: Icons.person,
              required: true,
              onChanged: (_) => setState(() {}), // update avatar letter
            ),
            _buildField(
              controller: _phoneCtrl,
              label: 'Phone',
              icon: Icons.phone,
              required: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone is required';
                }
                // only digits, spaces, +, -, ()
                final phoneRegex = RegExp(r'^[+\d\s\-()]+$');
                if (!phoneRegex.hasMatch(value.trim())) {
                  return 'Enter a valid phone number';
                }
                if (value.trim().length < 6) {
                  return 'Phone number too short';
                }
                return null;
              },
            ),
            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null; // optional
                final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            _buildField(
              controller: _addressCtrl,
              label: 'Address',
              icon: Icons.location_on,
            ),
            _buildField(
              controller: _noteCtrl,
              label: 'Note',
              icon: Icons.note,
              maxLines: 3,
            ),

            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(Icons.save),
              label: Text(_isEditing ? 'Update Contact' : 'Save Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable field builder — avoids repeating the same code 5 times
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
        ),
        validator: validator ?? (required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null),
      ),
    );
  }
}