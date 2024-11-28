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
    try {
      final items = await _firebaseService.getDecisionsWithCounts();
      if (items.isEmpty) {
        await _firebaseService.insertDecision('sample_id', 'Sample Choose For');
        await _firebaseService.insertChoices('sample_id', ['Sample Choice 1', 'Sample Choice 2']);
        final updatedItems = await _firebaseService.getDecisionsWithCounts();
        setState(() {
          _decisions = updatedItems;
        });
      } else {
        setState(() {
          _decisions = items;
        });
      }
    } catch (e) {
      print('Error loading decisions: $e');
    }
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
      await _loadDecisions(); // Reload the list after deletion
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
          content: Text(
            'Are you sure you want to delete this item?',
            style: TextStyle(
              color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                ),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context),
                ),
              ),
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
              icon: Icon(
              CupertinoIcons.add_circled,
                color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
              ),
              onPressed: () {
              Navigator.pushNamed(context, Routes.add);
              },
            ),
            IconButton(
              icon: Icon(
              CupertinoIcons.trash,
                color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context),
              ),
              onPressed: () async {
              final bool? confirm = await showCupertinoDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: const Text('Clear Database'),
                  content: Text(
                    'Are you sure you want to clear the entire database?',
                    style: TextStyle(
                      color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
                    ),
                  ),
                  actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                    Navigator.of(context).pop(false);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                      ),
                    ),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () {
                    Navigator.of(context).pop(true);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context),
                      ),
                    ),
                  ),
                  ],
                );
                },
              );
              if (confirm == true) {
                await _firebaseService.clearDatabase();
                await _loadDecisions(); // Reload the list after clearing the database
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
                          color: CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CupertinoListTile(
                          title: GestureDetector(
                            child: Text(item['chooseFor'], style: TextStyle(color: CupertinoDynamicColor.resolve(CupertinoColors.white, context))),
                            onTap: () => Navigator.pushNamed(context, Routes.details, arguments: {'id': item['id'].toString(), 'chooseFor': item['chooseFor']}),
                          ),
                          trailing: GestureDetector(
                            child: FaIcon(FontAwesomeIcons.ellipsisV, color: CupertinoDynamicColor.resolve(CupertinoColors.white, context)),
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
                                      child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context),
                                      ),
                                      ),
                                    ),
                                    
                                    CupertinoActionSheetAction(
                                      onPressed: () async {
                                      Navigator.pop(context);
                                      await _confirmDeleteItem(index);
                                      },
                                      isDestructiveAction: true,
                                      child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context),
                                      ),
                                      ),
                                    ),
                                    
                                  ],
                                    cancelButton: CupertinoActionSheetAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                      color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
                                      ),
                                    ),
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