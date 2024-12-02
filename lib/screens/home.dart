import 'package:decidemate_pro/main.dart';
import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io' show Platform;

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
    return Platform.isIOS ? _buildCupertino(context) : _buildMaterial(context);
  }

  Widget _buildCupertino(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Image.asset('assets/icon/icon.png', width: 30),
        middle: const Text('DecideMate Pro'),
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

  Widget _buildMaterial(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/icon.png', width: 30),
            const SizedBox(width: 10),
            const Text('DecideMate Pro'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            onPressed: () {
              Navigator.pushNamed(context, Routes.add);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Clear Database'),
                    content: const Text('Are you sure you want to clear the entire database?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
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
                await _loadDecisions(); // Reload the list after clearing the database
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          child: Scrollbar(
            child: RefreshIndicator(
              onRefresh: _loadDecisions,
              child: ListView.builder(
                itemCount: _decisions.length,
                itemBuilder: (context, index) {
                  final item = _decisions[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: EdgeInsets.only(bottom: index == _decisions.length - 1 ? 20 : 10, left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkTheme ? Colors.black26 : Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: GestureDetector(
                        child: Text(item['chooseFor'], style: TextStyle(color: theme.colorScheme.onSurface)),
                        onTap: () => Navigator.pushNamed(context, Routes.details, arguments: {'id': item['id'].toString(), 'chooseFor': item['chooseFor']}),
                      ),
                      trailing: GestureDetector(
                        child: FaIcon(FontAwesomeIcons.ellipsisV, color: theme.colorScheme.onSurface),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(Icons.edit, color: theme.colorScheme.onSurface),
                                    title: Text('Edit', style: TextStyle(color: theme.colorScheme.onSurface)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _editItem(index);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.delete, color: theme.colorScheme.error),
                                    title: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _confirmDeleteItem(index);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.cancel, color: theme.colorScheme.onSurface),
                                    title: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface)),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}