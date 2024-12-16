import 'package:decidemate_pro/screens/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:decidemate_pro/common/categories.dart';

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
  final String _id = Uuid().v4(); // Generate a unique identifier
  Category? _selectedCategory; // Change to Category enum

  @override
  void initState() {
    super.initState();
    // Ensure at least two choices are visible by default
    if (_choices.length < 2) {
      for (int i = _choices.length; i < 2; i++) {
        _addChoice();
      }
    }
  }

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

  void _deleteChoice(int index) {
    setState(() {
      _choices[index]['choice']?.dispose();
      _choices.removeAt(index);
    });
  }

  Future<void> _saveChoices() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_choices.length < 2) {
        _showValidationError('Please add at least two choices');
        return;
      }
      final chooseFor = _chooseForController.text;
      final existingItems = await _firebaseService.getDecisions();
      if (existingItems.any((item) => item['chooseFor'] == chooseFor)) {
        _showValidationError('An entry with this "Choose For" already exists.');
        return;
      }
      final choices = _choices.map((choice) => choice['choice']?.text).where((text) => text != null).cast<String>().toList();
      await _firebaseService.insertDecision(_id, chooseFor, category: _selectedCategory?.toString().split('.').last); // Use enum name
      await _firebaseService.insertChoices(_id, choices); // Pass the unique identifier along with choices
      Navigator.push(context, CupertinoPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  void _showValidationError(String message) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Validation Error'),
            content: Text(message),
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
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showCategoryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedCategory = Category.values[index];
                    });
                  },
                  children: Category.values.map((Category category) {
                    return Text(category.toString().split('.').last);
                  }).toList(),
                ),
              ),
              CupertinoButton(
                child: const Text('Done', style: TextStyle(color: CupertinoColors.activeBlue)),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context),
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
                crossAxisAlignment: CrossAxisAlignment.start, // Align fields with labels
                children: <Widget>[
                  const Text('Choose For:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  CupertinoTextFormFieldRow(
                    controller: _chooseForController,
                    placeholder: 'Choose for:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                  ),
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  CupertinoButton(
                    onPressed: _showCategoryPicker,
                    child: Text(
                      _selectedCategory?.toString().split('.').last ?? 'Select category',
                      style: const TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Choices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
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
                                    color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
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
                              if (index >= 2) // Allow deletion only for choices beyond the first two
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _deleteChoice(index),
                                  child: Icon(CupertinoIcons.delete, color: CupertinoDynamicColor.resolve(CupertinoColors.destructiveRed, context)),
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
                        child: Icon(CupertinoIcons.add_circled, size: 28, color: CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)),
                      ),
                      CupertinoButton(
                        onPressed: _saveChoices,
                        child: Icon(CupertinoIcons.check_mark_circled, size: 28, color: CupertinoDynamicColor.resolve(CupertinoColors.activeGreen, context)),
                      ),
                    ],
                  ),
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
        title: const Text('Add Item'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align fields with labels
                children: <Widget>[
                  const Text('Choose For:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextFormField(
                    controller: _chooseForController,
                    decoration: InputDecoration(
                      hintText: 'Choose for:',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                  ),
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    items: Category.values.map((Category category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.toString().split('.').last, style: const TextStyle(color: CupertinoColors.activeBlue)),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Select category',
                      hintStyle: TextStyle(
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Choices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
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
                                child: TextFormField(
                                  controller: _choices[index]['choice'],
                                  decoration: InputDecoration(
                                    hintText: 'Enter choice',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
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
                              if (index >= 2) // Allow deletion only for choices beyond the first two
                                IconButton(
                                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                  onPressed: () => _deleteChoice(index),
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
                        icon: Icon(Icons.add_circle, size: 28, color: Theme.of(context).colorScheme.primary),
                        onPressed: _addChoice,
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle, size: 28, color: Theme.of(context).colorScheme.secondary),
                        onPressed: _saveChoices,
                      ),
                    ],
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