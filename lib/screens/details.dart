import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:async';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final List<String> options = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  late final List<FortuneItem> items;
  final StreamController<int> selectedController = StreamController<int>.broadcast();

  _DetailsScreenState() {
    items = options.map((option) => FortuneItem(child: Text(option))).toList();
  }

  int selected = 0;

  @override
  void dispose() {
    selectedController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Details'),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 300,
              child: FortuneWheel(
                items: items.map((item) => FortuneItem(
                  child: item.child,
                  style: FortuneItemStyle(
                    color: Colors.primaries[items.indexOf(item) % Colors.primaries.length],
                    borderColor: CupertinoColors.black,
                    borderWidth: 2.0,
                  ),
                )).toList(),
                selected: selectedController.stream,
              ),
            ),
            CupertinoButton(
              child: const Text('Spin'),
              onPressed: () {
                setState(() {
                  selected = (selected + 1) % options.length;
                  selectedController.add(selected);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}


