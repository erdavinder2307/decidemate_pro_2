import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: true,
        automaticallyImplyMiddle: true,
        middle: Text('Edit'),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: CupertinoColors.activeBlue),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                    // Remove the onChanged listener to prevent clearing choices
                    // onChanged: (value) {
                    //   _loadChoices();
                    // },
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
                                  style: TextStyle(fontSize: 16, color: CupertinoColors.black),
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
                                child: Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed),
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
                        child: const Icon(CupertinoIcons.add_circled, size: 28, color: CupertinoColors.activeBlue),
                      ),
                      CupertinoButton(
                        onPressed: _updateChoices,
                        child: const Icon(CupertinoIcons.check_mark_circled, size: 28, color: CupertinoColors.activeGreen),
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
}