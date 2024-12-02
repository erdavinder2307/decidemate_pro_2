import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<String> _choices = [];
  Map<String, int> _choiceCounts = {};
  String _chooseFor = '';
  String _id = ''; // Add a variable to hold the unique identifier
  final BehaviorSubject<int> _controller = BehaviorSubject<int>();
  bool _isSpinning = false;
  int selectedChoice = 0;
  List choices = [];
  List results = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _id = arguments['id'] ?? ''; // Ensure _id is not null
      _chooseFor = arguments['chooseFor'] ?? ''; // Ensure chooseFor is not null
      _loadChoices();
    }
  }

  Future<void> _loadChoices() async {
     choices = await _firebaseService.getChoicesFor(_id); // Use the unique identifier
     results = await _firebaseService.getResultsFor(_id); // Fetch results for the decision
    setState(() {
      _choices = choices.map((choice) => choice['choice'] as String).toList();
      _choiceCounts = {
        for (var choice in choices)
          choice['choice'] as String: results.where((result) => result['choiceId'] == choice['id']).length
      };
      _choices.sort((a, b) => (_choiceCounts[b] ?? 0).compareTo(_choiceCounts[a] ?? 0)); // Sort choices by count
    });
  }

  Future<void> _incrementChoiceCount(String choice) async {
    await _firebaseService
        .incrementDecisionCount(_id); // Use the unique identifier
    setState(() {
      _choiceCounts[choice] = (_choiceCounts[choice] ?? 0) + 1;
    });
  }

  Future<void> _clearResults() async {
    await _firebaseService.clearResultsFor(_id); // Use the unique identifier
    _loadChoices();
  }

  Future<void> _confirmClearResults() async {
    final shouldClear = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Clear Results', style: TextStyle(color: CupertinoDynamicColor.resolve(CupertinoColors.label, context))),
          content: Text('Are you sure you want to clear all results?', style: TextStyle(color: CupertinoDynamicColor.resolve(CupertinoColors.secondaryLabel, context))),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel', style: TextStyle(color: CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context))),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            CupertinoDialogAction(
              child: Text('Clear', style: TextStyle(color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context))),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await _clearResults();
    }
  }

  @override
  void dispose() {
    _controller.close();
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
        middle: Text('Details'),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        left: true,
        top: true,
        right: true,
        bottom: true,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildMaterialPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        leading: BackButton(
          color: Theme.of(context).primaryColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        left: true,
        top: true,
        right: true,
        bottom: true,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Text('Choose For: $_chooseFor',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: _choices.length > 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: FortuneWheel(
                    animateFirst: false,
                    alignment: Alignment(
                      (2 * (0.5 - Random().nextDouble())).toDouble(),
                      (2 * (0.5 - Random().nextDouble())).toDouble(),
                    ),
                    styleStrategy: UniformStyleStrategy(),
                    physics: CircularPanPhysics(
                      duration: Duration(seconds: 1),
                      curve: Curves.decelerate,
                    ),
                    selected: _controller.stream,
                    items: [
                      for (var choice in _choices)
                        FortuneItem(
                          child: Text(choice,
                              style: TextStyle(
                                  color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
                                  fontSize: choice.length > 10 ? 14 : 18)),
                          style: FortuneItemStyle(
                            color: Colors.primaries[
                                _choices.indexOf(choice) %
                                    Colors.primaries.length],
                            borderColor: Colors.white,
                            borderWidth: 2,
                          ),
                        ),
                    ],
                    onAnimationEnd: () {
                      setState(() {
                        _isSpinning = false;

                        _controller.stream.first.then((selectedIndex) {
                          if (_choices.isNotEmpty) {
                            final selectedChoice = _choices[selectedIndex];
                            _incrementChoiceCount(selectedChoice);
                            var choiceId = choices.firstWhere((choice) => choice['choice'] == selectedChoice)['id'];
                            _firebaseService.insertResult(Uuid().v4(), _id, choiceId);
                          }
                        });
                      });
                    },
                    indicators: <FortuneIndicator>[
                      FortuneIndicator(
                        alignment: Alignment.topCenter,
                        child: TriangleIndicator(
                          color: const Color.fromARGB(255, 252, 211, 211),
                          elevation: 10,
                          width: 20,
                          height: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Text('Add more choices to spin the wheel',
                      style: TextStyle(fontSize: 18, color: CupertinoDynamicColor.resolve(CupertinoColors.secondaryLabel, context))),
                ),
        ),
        const SizedBox(height: 20),
        CupertinoButton(
          color: CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context),
          onPressed: _isSpinning
              ? null
              : () {
                  setState(() {
                    _isSpinning = true;
                  });
                  selectedChoice = Fortune.randomInt(0, _choices.length);
                  _controller.add(selectedChoice);
                },
          child: Text('Spin', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 20),
        Text('Results:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _choices.length,
            itemBuilder: (context, index) {
              final choice = _choices[index];
              final count = _choiceCounts[choice] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text('$choice', style: TextStyle(fontSize: 18)),
                  trailing: Text('$count',
                      style: TextStyle(fontSize: 18, color: CupertinoDynamicColor.resolve(CupertinoColors.label, context))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        CupertinoButton(
          color: CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context),
          onPressed: _confirmClearResults,
          child: Text('Clear Results', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
