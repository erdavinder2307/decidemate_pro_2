import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:decidemate_pro/screens/home.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chooseForController = TextEditingController();
  final List<Map<String, TextEditingController>> _choices = [];
  final FirebaseService _firebaseService = FirebaseService();
  late String _id; // Declare a variable to hold the unique identifier

  @override
  void initState() {
    super.initState();
    // Remove the listener from initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _id = arguments['id'] ?? ''; // Ensure _id is not null
      final chooseFor = arguments['chooseFor'] ?? ''; // Ensure chooseFor is not null
      if (_chooseForController.text != chooseFor) {
        _chooseForController.text = chooseFor;
        _loadChoices();
      }
    }
  }

  Future<void> _loadChoices() async {
    if (_id.isEmpty) return;
    final choices = await _firebaseService.getChoicesFor(_id); // Use the unique identifier
    setState(() {
      _choices.clear();
      for (var choice in choices) {
        final controller = TextEditingController(text: choice['choice']);
        controller.addListener(() {
          _choices[choices.indexOf(choice)]['choice'] = controller;
        });
        _choices.add({
          'choice': controller,
        });
      }
    });
  }

  Future<void> _updateChoices() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_choices.length < 2) {
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text('Validation Error'),
                content: Text('Please add at least two choices'),
                actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: TextStyle(color: CupertinoColors.activeBlue)),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least two choices')),
          );
        }
        return;
      }
      final chooseFor = _chooseForController.text;
      final choices = _choices.map((choice) => choice['choice']?.text).where((text) => text != null).cast<String>().toList();
      await _firebaseService.updateDecision(_id, chooseFor); // Update the chooseFor field
      await _firebaseService.updateChoices(_id, choices); // Use the unique identifier along with choices
      Navigator.push(context, CupertinoPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  void _deleteChoice(int index) {
    setState(() {
      _choices[index]['choice']?.dispose();
      _choices.removeAt(index);
    });
  }

  void _addChoice() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(() {
        _choices[_choices.length - 1]['choice'] = controller;
      });
      _choices.add({
        'choice': controller,
      });
    });
  }

  @override
  void dispose() {
    _chooseForController.removeListener(_loadChoices);
    _chooseForController.dispose();
    for (var choice in _choices) {
      choice['choice']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? _buildCupertinoPage(context)
        : _buildMaterialPage(context);
  }

  Widget _buildCupertinoPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: true,
        automaticallyImplyMiddle: true,
        middle: Text('Edit', style: TextStyle(color: CupertinoDynamicColor.resolve(CupertinoColors.label, context))),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: CupertinoScrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose For:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _chooseForController,
                    placeholder: 'Choose for:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _choices.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoTextFormFieldRow(
                                  controller: _choices[index]['choice'],
                                  placeholder: 'Enter choice',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: CupertinoDynamicColor.resolve(CupertinoColors.label, context)
                                  ),
                                  textCapitalization: TextCapitalization.sentences,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a choice';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _deleteChoice(index),
                                child: Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoDynamicColor.resolve(CupertinoColors.destructiveRed, context)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        onPressed: _addChoice,
                        child: const Icon(
                          CupertinoIcons.add_circled,
                          size: 28,
                          color: CupertinoColors.activeBlue
                        ),
                      ),
                      CupertinoButton(
                        onPressed: _updateChoices,
                        child: const Icon(
                          CupertinoIcons.check_mark_circled,
                          size: 28,
                          color: CupertinoColors.activeGreen
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose For:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                TextFormField(
                  controller: _chooseForController,
                  decoration: const InputDecoration(
                    hintText: 'Choose for:',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _choices.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _choices[index]['choice'],
                                decoration: const InputDecoration(
                                  hintText: 'Enter choice',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a choice';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteChoice(index),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _addChoice,
                      icon: const Icon(
                        Icons.add_circle,
                        size: 28,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: _updateChoices,
                      icon: const Icon(
                        Icons.check_circle,
                        size: 28,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}