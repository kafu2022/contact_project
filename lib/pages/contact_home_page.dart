import 'package:flutter/material.dart';
import 'package:contact/pages/contact_detail_page.dart';
import 'package:contact/pages/contact_add_sheet.dart';
import 'package:contact/pages/multi_step_user_info.dart';
import 'package:contact/models/contact.dart';
import 'package:contact/db/database_helper.dart';
import 'dart:io';

class ContactHomePage extends StatefulWidget {
  const ContactHomePage({super.key});
  @override
  State<ContactHomePage> createState() => _ContactHomePageState();
}

class _ContactHomePageState extends State<ContactHomePage> {
  // Moved _showMultiStepInfoPage inside _ContactHomePageState
  void _showMultiStepInfoPage() async {
    final updatedInfo = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (context) => MultiStepUserInfoPage(
          onComplete: (contact) async {
            try {
              await DatabaseHelper.instance.saveMyInfo(contact);
              Navigator.pop(context, contact);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('내 정보 저장 실패: $e')));
              }
            }
          },
        ),
      ),
    );
    if (updatedInfo != null && mounted) {
      setState(() {
        myInfo = updatedInfo;
        isFirstLaunch = false;
      });
    }
  }

  final List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  bool isFirstLaunch = true;
  Contact? myInfo;

  late final TextEditingController _searchController;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    isFirstLaunch = !(await DatabaseHelper.instance.isInitialized());

    myInfo = await DatabaseHelper.instance.getMyInfo();
    contacts.addAll(await DatabaseHelper.instance.getContacts());

    final storedQuery = await DatabaseHelper.instance.getSearchQuery() ?? "";
    _searchController.text = storedQuery;
    await _filterContacts(storedQuery);
    setState(() {});

    if (isFirstLaunch) {
      await DatabaseHelper.instance.setInitialized(true);
      Future.delayed(Duration.zero, () {
        _showMultiStepInfoPage();
      });
    }
  }

  /// 연락처 사전식 정렬 + 검색어 저장
  Future<void> _filterContacts(String query) async {
    final currentContext = context;
    try {
      await DatabaseHelper.instance.saveSearchQuery(query);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          currentContext,
        ).showSnackBar(SnackBar(content: Text('검색어 저장 실패: $e')));
      }
    }

    setState(() {
      filteredContacts =
          contacts.where((contact) {
            final lowerQuery = query.toLowerCase();
            return (_getInitials(contact.name).contains(lowerQuery) ||
                    contact.name.toLowerCase().contains(lowerQuery)) ||
                (contact.phone.toLowerCase().contains(lowerQuery)) ||
                ((contact.address ?? '').toLowerCase().contains(lowerQuery)) ||
                ((contact.company ?? '').toLowerCase().contains(lowerQuery)) ||
                ((contact.email ?? '').toLowerCase().contains(lowerQuery));
          }).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    });
  }

  String _getInitials(String text) {
    const initials = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
    ];
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0xAC00 && code <= 0xD7A3) {
        final index = ((code - 0xAC00) ~/ (21 * 28));
        buffer.write(initials[index]);
      }
    }
    return buffer.toString();
  }

  /// 검색창
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _filterContacts,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: '검색',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      ),
    );
  }

  /// 사용자 연락처 정보
  Widget _buildMyCard() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade200,
        backgroundImage:
            (myInfo?.imagePath != null && myInfo!.imagePath!.isNotEmpty)
            ? FileImage(File(myInfo!.imagePath!))
            : null,
        child: (myInfo?.imagePath == null || myInfo!.imagePath!.isEmpty)
            ? Text(myInfo?.name.substring(0, 1) ?? '이름')
            : null,
      ),
      title: Text(myInfo?.name ?? '사용자'),
      subtitle: Text('내 카드'),
      onTap: () async {
        if (myInfo != null) {
          final updated = await Navigator.push<Contact>(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailPage(contact: myInfo!),
            ),
          );

          if (updated != null && mounted) {
            setState(() {
              myInfo = updated;
            });
            await DatabaseHelper.instance.saveMyInfo(myInfo!);
          }
        }
      },
    );
  }

  /// 연락처 리스트 (초성별 그룹핑 및 인덱스바)
  Widget _buildContactList() {
    _sectionKeys.clear();

    Map<String, List<Contact>> grouped = {};
    for (var contact in filteredContacts) {
      String initial = _getInitialConsonant(contact.name);
      if (!grouped.containsKey(initial)) {
        grouped[initial] = [];
      }
      grouped[initial]!.add(contact);
    }

    List<String> initials = grouped.keys.toList()..sort();
    List<Widget> widgets = [];

    for (var initial in initials) {
      final key = GlobalKey();
      _sectionKeys[initial] = key;

      widgets.add(
        Padding(
          key: key,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                initial,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double dashWidth = 8.0;
                    double dashSpace = 4.0;
                    int count =
                        (constraints.maxWidth / (dashWidth)).floor() - 2;

                    /// 초성 구분선
                    if (count < 1) count = 1;
                    return SizedBox(
                      height: 16,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: double.infinity,
                        child: Row(
                          children: List.generate(count, (_) {
                            return Padding(
                              padding: EdgeInsets.only(right: dashSpace),
                              child: Text(
                                '-',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      /// 삭제 효과 및 경고
      for (int i = 0; i < grouped[initial]!.length; i++) {
        final contact = grouped[initial]![i];
        widgets.add(
          Dismissible(
            key: ValueKey(contact.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              final currentContext = context;
              return await showDialog<bool>(
                    context: currentContext,
                    builder: (context) => AlertDialog(
                      title: Text(contact.name),
                      content: Text('삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('확인'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (direction) async {
              final currentContext = context;
              debugPrint("삭제됨: ${contact.name}");
              // Delete image file if exists
              if (contact.imagePath != null && contact.imagePath!.isNotEmpty) {
                final imgFile = File(contact.imagePath!);
                if (await imgFile.exists()) {
                  try {
                    await imgFile.delete();
                  } catch (_) {}
                }
              }
              contacts.remove(contact);
              try {
                await DatabaseHelper.instance.deleteContact(contact.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    currentContext,
                  ).showSnackBar(SnackBar(content: Text('연락처 삭제 저장 실패: $e')));
                }
              }
              if (mounted) {
                setState(() {});
              }
              // Refresh filtered list
              _filterContacts(_searchController.text);
            },
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: 0.5,
                horizontal: 16.0,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name),
                  if (_searchController.text.isNotEmpty)
                    Builder(
                      builder: (_) {
                        final query = _searchController.text.toLowerCase();
                        if (query.isEmpty) return SizedBox.shrink();
                        final matches = <String>[
                          if ((contact.phone).toLowerCase().contains(query))
                            contact.phone,
                          if (((contact.address ?? '')).toLowerCase().contains(
                            query,
                          ))
                            contact.address ?? '',
                          if (((contact.company ?? '')).toLowerCase().contains(
                            query,
                          ))
                            contact.company ?? '',
                          if (((contact.email ?? '')).toLowerCase().contains(
                            query,
                          ))
                            contact.email ?? '',
                        ];
                        if (matches.isEmpty) return SizedBox.shrink();
                        final match = matches.first;
                        final matchIndex = match.toLowerCase().indexOf(query);
                        if (matchIndex == -1) {
                          return Text(
                            match,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          );
                        }
                        return RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            children: [
                              TextSpan(text: match.substring(0, matchIndex)),
                              TextSpan(
                                text: match.substring(
                                  matchIndex,
                                  matchIndex + query.length,
                                ),
                                style: TextStyle(color: Colors.blue),
                              ),
                              TextSpan(
                                text: match.substring(
                                  matchIndex + query.length,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              onTap: () async {
                final currentContext = context;
                final originalContact = contact;
                final updatedContact = await Navigator.push<Contact>(
                  currentContext,
                  MaterialPageRoute(
                    builder: (context) =>
                        ContactDetailPage(contact: originalContact),
                  ),
                );

                if (updatedContact != null && mounted) {
                  final index = contacts.indexWhere(
                    (c) => c.id == originalContact.id,
                  );
                  if (index != -1) {
                    setState(() {
                      contacts[index] = updatedContact;
                      contacts.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );
                      _filterContacts(_searchController.text);
                    });
                    try {
                      await DatabaseHelper.instance.updateContact(
                        updatedContact,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('연락처 저장 실패: $e')),
                        );
                      }
                    }
                    Future.delayed(Duration.zero, () {
                      Navigator.push(
                        currentContext,
                        MaterialPageRoute(
                          builder: (context) =>
                              ContactDetailPage(contact: updatedContact),
                        ),
                      );
                    });
                  }
                }
              },
            ),
          ),
        );
        if (i != grouped[initial]!.length - 1) {
          widgets.add(Divider(height: 0));
        }
      }
    }
    return Expanded(
      child: Stack(
        children: [
          ListView(controller: _scrollController, children: widgets),
          Positioned(
            right: 7,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: initials.map((initial) {
                return GestureDetector(
                  onTap: () {
                    final key = _sectionKeys[initial];
                    if (key != null) {
                      Scrollable.ensureVisible(
                        key.currentContext!,
                        duration: Duration(milliseconds: 100),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(initial, style: TextStyle(fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitialConsonant(String name) {
    if (name.isEmpty) return '#';
    final char = name.codeUnitAt(0);
    if (char >= 0xAC00 && char <= 0xD7A3) {
      int choIndex = ((char - 0xAC00) ~/ (21 * 28));
      const initials = [
        'ㄱ',
        'ㄲ',
        'ㄴ',
        'ㄷ',
        'ㄸ',
        'ㄹ',
        'ㅁ',
        'ㅂ',
        'ㅃ',
        'ㅅ',
        'ㅆ',
        'ㅇ',
        'ㅈ',
        'ㅉ',
        'ㅊ',
        'ㅋ',
        'ㅌ',
        'ㅍ',
        'ㅎ',
      ];
      return initials[choIndex];
    } else {
      return name[0].toUpperCase();
    }
  }

  /// 상단 앱바
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '연락처 (${filteredContacts.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              final currentContext = context;
              showModalBottomSheet(
                context: currentContext,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => ContactAddSheet(
                  onAdd: (newContact) async {
                    setState(() {
                      contacts.add(newContact);
                      contacts.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );
                      filteredContacts = List.from(contacts);
                    });
                    try {
                      await DatabaseHelper.instance.insertContact(newContact);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('연락처 저장 실패: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Divider(),
          _buildMyCard(),
          const SizedBox(height: 7),
          _buildContactList(),
        ],
      ),
    );
  }
}
