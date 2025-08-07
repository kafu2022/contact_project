import 'package:flutter/material.dart';
import 'package:contact/db/database_helper.dart';
import 'dart:io';
import 'package:contact/models/contact.dart';
import 'package:contact/pages/contact_add_sheet.dart';

class ContactDetailPage extends StatefulWidget {
  final Contact contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late Contact contact;

  @override
  void initState() {
    super.initState();
    contact = widget.contact;
  }

  String _formatPhoneNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      if (digits.startsWith('02')) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
      } else {
        return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
      }
    } else {
      return number;
    }
  }

  Future<void> _persistContactUpdate(Contact updatedContact) async {
    try {
      await DatabaseHelper.instance.updateContact(updatedContact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연락처 저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final currentContext = context;
              final updatedContact = await showModalBottomSheet<Contact>(
                context: currentContext,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => ContactAddSheet(
                  initialContact: contact,
                  onAdd: (updatedContact) {
                    Navigator.pop(context, updatedContact);
                  },
                ),
              );
              if (updatedContact != null) {
                setState(() {
                  contact = updatedContact;
                });
                await _persistContactUpdate(updatedContact);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('연락처가 수정되었습니다.')),
                  );
                }
                // Navigator.pushAndRemoveUntil(
                //   currentContext,
                //   MaterialPageRoute(
                //     builder: (_) =>
                //         ContactDetailPage(contact: updatedContact),
                //   ),
                //       (route) => route.isFirst,
                // );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: contact.imagePath != null
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(backgroundColor: Colors.black),
                          body: Center(
                            child: Image.file(File(contact.imagePath!)),
                          ),
                        ),
                      ),
                    );
                  }
                      : null,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: contact.imagePath != null
                        ? FileImage(File(contact.imagePath!))
                        : null,
                    child: contact.imagePath == null
                        ? Text(
                      contact.name.substring(0, 1),
                      style: const TextStyle(fontSize: 24),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "전화번호",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPhoneNumber(contact.phone),
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 16),

          const Text(
            "주소",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(contact.address ?? '', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),

          const Text(
            "소속",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(contact.company ?? '', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),

          const Text(
            "E-mail",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(contact.email ?? '', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
