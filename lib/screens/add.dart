import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:decidemate_pro/services/firebase_service.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chooseForController = TextEditingController();
  final List<Map<String, TextEditingController>> _choices = [];
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _chooseForController.dispose();
    for (var choice in _choices) {
      choice['choice']?.dispose();
    }
    super.dispose();
  }

  void _addChoice() {
    setState(() {
      _choices.add({
        'choice': TextEditingController(),
      });
    });
  }

  void _saveChoices() async {
    if (_formKey.currentState?.validate() ?? false) {
      final chooseFor = _chooseForController.text;
      final choices = _choices.map((choice) => choice['choice']?.text).where((text) => text != null).cast<String>().toList();
      await _firebaseService.insertChoices(chooseFor, choices);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        middle: const Text('Add Item'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: CupertinoScrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  CupertinoTextFormFieldRow(
                    controller: _chooseForController,
                    placeholder: 'Choose for:',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _choices.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _choices[index]['choice'],
                            placeholder: 'Enter choice',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a choice';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  CupertinoButton.filled(
                    child: const Text('Add Choice'),
                    onPressed: _addChoice,
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    child: const Text('Save All'),
                    onPressed: _saveChoices,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}