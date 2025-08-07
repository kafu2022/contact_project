import 'package:flutter/material.dart';
import 'pages/contact_home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '연락처',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const ContactHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
