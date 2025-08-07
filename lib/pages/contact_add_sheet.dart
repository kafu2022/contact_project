import 'package:flutter/material.dart';
import 'package:contact/models/contact.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:contact/db/database_helper.dart';


class ContactAddSheet extends StatefulWidget {
  final Function(Contact) onAdd;
  final Contact? initialContact;
  const ContactAddSheet({super.key, required this.onAdd, this.initialContact});

  @override
  ContactAddSheetState createState() => ContactAddSheetState();
}

class ContactAddSheetState extends State<ContactAddSheet> {
  final _formKey = GlobalKey<FormState>();

  String? name;
  String? phone;
  String? address;
  String? company;
  String? email;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialContact != null) {
      name = widget.initialContact!.name;
      phone = widget.initialContact!.phone;
      address = widget.initialContact!.address;
      company = widget.initialContact!.company;
      email = widget.initialContact!.email;
    }
  }

  Future<void> _pickImage() async {
    final currentContext = context;
    final source = await showModalBottomSheet<ImageSource>(
      context: currentContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('카메라로 찍기'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('앨범에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<List<Contact>> _getExistingContacts() async {
    return await DatabaseHelper.instance.getContacts();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.initialContact != null ? '연락처 수정' : '새로운 연락처',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                _imageFile != null
                    ? CircleAvatar(
                  radius: 40,
                  backgroundImage: FileImage(_imageFile!),
                )
                    : CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                TextButton(onPressed: _pickImage, child: Text('사진 추가')),
                SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: InputDecoration(labelText: '이름'),
                        onSaved: (value) => name = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력하세요.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: phone,
                        decoration: InputDecoration(labelText: '전화번호'),
                        keyboardType: TextInputType.phone,
                        onSaved: (value) => phone = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '전화번호를 입력하세요.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: address,
                        decoration: InputDecoration(labelText: '주소'),
                        onSaved: (value) => address = value,
                      ),
                      TextFormField(
                        initialValue: company,
                        decoration: InputDecoration(labelText: '소속'),
                        onSaved: (value) => company = value,
                      ),
                      TextFormField(
                        initialValue: email,
                        decoration: InputDecoration(labelText: '이메일'),
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (value) => email = value,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return '유효한 이메일을 입력하세요.';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('취소'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final currentContext = context;
                              if (_formKey.currentState?.validate() ?? false) {
                                _formKey.currentState?.save();
                                final trimmedName = name?.trim() ?? '';
                                final trimmedPhone = phone?.trim() ?? '';
                                // Check for duplicates
                                final existingContacts =
                                await _getExistingContacts();
                                final isDuplicate = existingContacts.any(
                                      (c) =>
                                  c.name == trimmedName &&
                                      c.phone == trimmedPhone &&
                                      (widget.initialContact == null ||
                                          c.id != widget.initialContact!.id),
                                );
                                if (isDuplicate) {
                                  ScaffoldMessenger.of(
                                    currentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '이미 동일한 이름과 전화번호의 연락처가 존재합니다.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final updatedContact = Contact(
                                  id:
                                  widget.initialContact?.id ??
                                      const Uuid().v4(),
                                  name: trimmedName,
                                  phone: trimmedPhone,
                                  address: address,
                                  company: company,
                                  email: email,
                                  imagePath:
                                  _imageFile?.path ??
                                      widget.initialContact?.imagePath,
                                );
                                widget.onAdd(updatedContact);
                                Navigator.pop(currentContext, updatedContact);
                              }
                            },
                            child: Text('완료'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}