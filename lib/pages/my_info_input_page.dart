import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:contact/models/contact.dart';

class MyInfoInputPage extends StatefulWidget {
  final Function(Contact) onSubmit;

  const MyInfoInputPage({super.key, required this.onSubmit});

  @override
  MyInfoInputPageState createState() => MyInfoInputPageState();
}

class MyInfoInputPageState extends State<MyInfoInputPage> {
  final _formKey = GlobalKey<FormState>();
  String? name, phone, address, company, email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("내 정보 입력")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
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
                decoration: InputDecoration(labelText: '주소'),
                onSaved: (value) => address = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: '소속'),
                onSaved: (value) => company = value,
              ),
              TextFormField(
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
              ElevatedButton(
                onPressed: () async {
                  final currentContext = context;
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    Contact contact = Contact(
                      id: const Uuid().v4(),
                      name: name!.trim(),
                      phone: phone ?? '',
                      address: address,
                      company: company,
                      email: email,
                    );
                    try {
                      SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                      await prefs.setBool('isInitialized', true);
                      await prefs.setString(
                        'myInfo',
                        jsonEncode(contact.toMap()),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('내 정보 저장 실패: $e')),
                        );
                      }
                      return;
                    }
                    widget.onSubmit(contact);
                    Navigator.pop(currentContext);
                  }
                },
                child: Text("저장"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}