import 'package:decidemate_pro/main.dart';
import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _chooseForItems = [];

  @override
  void initState() {
    super.initState();
    _loadChooseForItems();
  }

  Future<void> _loadChooseForItems() async {
    final items = await _firebaseService.getChooseForItems();
    setState(() {
      _chooseForItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const Icon(CupertinoIcons.sidebar_left),
        trailing: IconButton(
          icon: const Icon(CupertinoIcons.add_circled),
          onPressed: () {
            Navigator.pushNamed(context, Routes.add);
          },
        ),
        middle: const Text('DecideMate Pro'),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          child: ListView.builder(
            itemCount: _chooseForItems.length,
            itemBuilder: (context, index) {
              final item = _chooseForItems[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3497FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoListTile(
                  title: GestureDetector(
                    child: Text(item['chooseFor'], style: const TextStyle(color: CupertinoColors.white)),
                    onTap: () => Navigator.pushNamed(context, Routes.details),
                  ),
                  trailing: GestureDetector(
                    child: const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.white),
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (BuildContext context) => CupertinoActionSheet(
                          actions: <CupertinoActionSheetAction>[
                            CupertinoActionSheetAction(
                              onPressed: () {
                                // Add your edit code here!
                                Navigator.pushNamed(context, Routes.edit);
                              },
                              child: const Text('Edit'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                // Add your delete code here!
                                Navigator.pop(context);
                              },
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}