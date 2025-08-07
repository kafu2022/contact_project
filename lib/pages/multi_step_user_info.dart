import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart'; // Contact 클래스 참조

class MultiStepUserInfoPage extends StatefulWidget {
  final void Function(Contact) onComplete;
  const MultiStepUserInfoPage({super.key, required this.onComplete});

  @override
  State<MultiStepUserInfoPage> createState() => _MultiStepUserInfoPageState();
}

class _MultiStepUserInfoPageState extends State<MultiStepUserInfoPage> {
  final PageController _controller = PageController();
  int currentStep = 0;

  String? name, phone, address, company, email;
  File? imageFile;

  final picker = ImagePicker();

  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  void _next() {
    if (currentStep < 5) {
      setState(() => currentStep++);
      _controller.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Contact contact = Contact(
        id: const Uuid().v4(),
        name: name!,
        phone: phone!,
        address: address ?? '',
        company: company ?? '',
        email: email ?? '',
        imagePath: imageFile?.path,
      );
      widget.onComplete(contact);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
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
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() => imageFile = File(picked.path));
      }
    }
  }

  Widget _buildStepContent() {
    List<Widget> steps = [
      _inputStep(label: '이름', required: true, onSaved: (v) => name = v, stepIndex: 0),
      _inputStep(
        label: '전화번호',
        required: true,
        keyboard: TextInputType.phone,
        onSaved: (v) => phone = v,
        stepIndex: 1,
      ),
      _inputStep(label: '주소', onSaved: (v) => address = v, stepIndex: 2),
      _inputStep(label: '소속', onSaved: (v) => company = v, stepIndex: 3),
      _inputStep(
        label: '이메일',
        keyboard: TextInputType.emailAddress,
        onSaved: (v) => email = v,
        stepIndex: 4,
      ),
      _imageStep(),
    ];

    return steps[currentStep];
  }

  Widget _inputStep({
    required String label,
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    required void Function(String?) onSaved,
    required int stepIndex,
  }) {
    final controller = _controllers[stepIndex];
    final focusNode = _focusNodes[stepIndex];

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (stepIndex > 0) {
        FocusScope.of(context).requestFocus(focusNode);
      }
    });

    final stepFormKey = GlobalKey<FormState>();

    return Stack(
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: stepFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: required ? '$label' : '$label (선택사항)',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 2.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFd4d7ff),
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  keyboardType: keyboard,
                  validator: (val) {
                    if (required && (val == null || val.isEmpty)) {
                      return '필수 입력';
                    }
                    if (label == '이메일' && val != null && val.isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                      if (!emailRegex.hasMatch(val)) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                    }
                    return null;
                  },
                  onSaved: onSaved,
                ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFdcdefa),
                        ),
                        onPressed: () {
                          if (!(stepFormKey.currentState?.validate() ?? false)) return;
                          stepFormKey.currentState?.save();
                          _next();
                        },
                        child: Text('다음', style: TextStyle(color: Colors.black))
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('프로필 사진 선택 (선택사항)', style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
            child: imageFile == null ? Icon(Icons.person, size: 40) : null,
          ),
          TextButton(onPressed: _pickImage, child: Text('사진 선택')),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFdcdefa),
                ),
                onPressed: () {
                  final contact = Contact(
                    id: const Uuid().v4(),
                    name: name!,
                    phone: phone!,
                    address: address ?? '',
                    company: company ?? '',
                    email: email ?? '',
                    imagePath: imageFile?.path,
                  );
                  widget.onComplete(contact);
                },
                child: Text('완료', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _handleBack() async {
    if (currentStep > 0) {
      setState(() => currentStep--);
      await _controller.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text("계정 만들기"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (currentStep > 0) {
                setState(() => currentStep--);
                await _controller.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.deferToChild,
          child: PageView.builder(
            controller: _controller,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) => _buildStepContent(),
          ),
        ),
      ),
    );
  }
}
