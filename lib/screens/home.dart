import 'package:decidemate_pro/main.dart';
import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _decisions = [];

  @override
  void initState() {
    super.initState();
    _loadDecisions();
  }

  Future<void> _loadDecisions() async {
    final items = await _firebaseService.getDecisionsWithCounts();
    setState(() {
      _decisions = items;
    });
  }

  Future<void> _editItem(int index) async {
    final item = _decisions[index];
    Navigator.pushNamed(context, Routes.edit, arguments: {'id': item['id'], 'chooseFor': item['chooseFor']});
  }

  Future<void> _deleteItem(int index) async {
    final item = _decisions[index];
    final id = item['id'] as String?;
    if (id != null) {
      await _firebaseService.deleteDecision(id);
      await _loadDecisions();
    } else {
      // Handle the case where id is null
      print('Error: id is null');
    }
  }

  Future<void> _confirmDeleteItem(int index) async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await _deleteItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Image.asset('assets/icon/icon.png', width: 30),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.add_circled),
              onPressed: () {
                Navigator.pushNamed(context, Routes.add);
              },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.trash),
              onPressed: () async {
                final bool? confirm = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoAlertDialog(
                      title: const Text('Clear Database'),
                      content: const Text('Are you sure you want to clear the entire database?'),
                      actions: <CupertinoDialogAction>[
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text('Cancel'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true) {
                  await _firebaseService.clearDatabase();
                  await _loadDecisions();
                }
              },
            ),
          ],
        ),
        middle: const Text('DecideMate Pro'),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          child: CupertinoScrollbar(
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  onRefresh: _loadDecisions,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _decisions[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: EdgeInsets.only(bottom: index == _decisions.length - 1 ? 20 : 10, left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3497FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CupertinoListTile(
                          title: GestureDetector(
                            child: Text(item['chooseFor'], style: const TextStyle(color: CupertinoColors.white)),
                            onTap: () => Navigator.pushNamed(context, Routes.details, arguments: {'id': item['id'].toString(), 'chooseFor': item['chooseFor']}),
                          ),
                          trailing: GestureDetector(
                            child: FaIcon(FontAwesomeIcons.ellipsisV, color: CupertinoColors.white),
                            onTap: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (BuildContext context) => CupertinoActionSheet(
                                  actions: <CupertinoActionSheetAction>[
                                    CupertinoActionSheetAction(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _editItem(index);
                                      },
                                      child: const Text('Edit'),
                                    ),
                                    CupertinoActionSheetAction(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _confirmDeleteItem(index);
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
                    childCount: _decisions.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}