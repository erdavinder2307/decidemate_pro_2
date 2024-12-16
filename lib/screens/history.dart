import 'package:decidemate_pro/services/firebase_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';
import 'package:decidemate_pro/common/categories.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _history = [];
  String _searchQuery = '';
  String _timeRange = 'All';
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _firebaseService.getFilteredSpinHistory(
        searchQuery: _searchQuery,
        timeRange: _timeRange == 'All' ? null : _timeRange,
        category: _selectedCategory == Category.All ? null : _selectedCategory?.toString().split('.').last, // Show all records if category is "All"
      );
      setState(() {
        _history = history;
      });
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadHistory();
  }

  void _onTimeRangeChanged(String? value) {
    setState(() {
      _timeRange = value ?? 'All';
    });
    _loadHistory();
  }

  void _onCategoryChanged(Category? value) {
    setState(() {
      _selectedCategory = value;
    });
    _loadHistory();
  }

  void _showDetailView(Map<String, dynamic> item) async {
    final highestCountChoice = await _firebaseService.getChoiceWithHighestCount(item['choiceId']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailView(item: item, highestCountChoice: highestCountChoice),
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Invalid date';
    final dateTime = DateTime.tryParse(timestamp);
    if (dateTime == null) return 'Invalid date';
    if (Platform.isIOS) {
      return DateFormat.yMMMMd('en_US').add_jm().format(dateTime);
    } else {
      return DateFormat.yMMMMd().add_jm().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertino(context) : _buildMaterial(context);
  }

  Widget _buildCupertino(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.activeBlue,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        middle: const Text('Decision History'),
        backgroundColor: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoSearchTextField(
            onChanged: _onSearchChanged,
            backgroundColor: isDarkMode ? CupertinoColors.darkBackgroundGray : CupertinoColors.lightBackgroundGray,
          ),
          _buildCupertinoFilters(isDarkMode),
          Expanded(
            child: _history.isEmpty
                ? Center(child: Text('No history available', style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                     
                            return CupertinoListTile(
                              title: Text(item['chooseFor'] ?? '', style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                              subtitle: Text(item['choice'] ?? '', 
                                style: TextStyle(color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2),
                              ),
                              trailing: Text(_formatDate(item['timestamp'] ?? ''), style: TextStyle(color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
                            );
                          
                       
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision History'),
       
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          _buildMaterialFilters(isDarkMode),
          Expanded(
            child: _history.isEmpty
                ? Center(child: Text('No history available', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      
                            return ListTile(
                              title: Text(item['chooseFor'] ?? '', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                              subtitle: Text(item['choice'] ?? '', 
                                style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
                              ),
                              trailing: Text(_formatDate(item['timestamp'] ?? ''), style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54)),
                            );
                          
                       
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoFilters(bool isDarkMode) {
    return Row(
      children: [
        CupertinoButton(
          child: Text('Time Range: $_timeRange', style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
          onPressed: () => _showCupertinoPicker(
            context,
            ['All', 'Today', 'This Week', 'Last Month'],
            _timeRange,
            (value) => setState(() {
              _timeRange = value ?? 'All';
              _loadHistory();
            }),
          ),
        ),
        CupertinoButton(
          child: Text('Category: ${_selectedCategory?.toString().split('.').last ?? 'All'}', style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
          onPressed: () => _showCupertinoPicker(
            context,
            Category.values.map((category) => category.toString().split('.').last).toList(),
            _selectedCategory?.toString().split('.').last ?? 'All',
            (value) => _onCategoryChanged(Category.values.firstWhere((category) => category.toString().split('.').last == value, orElse: () => Category.Others)),
          ),
        ),
      ],
    );
  }

  void _showCupertinoPicker(BuildContext context, List<String> options, String selectedValue, ValueChanged<String?> onSelected) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
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
                    onSelected(options[index]);
                  },
                  children: options.map((String value) {
                    return Center(child: Text(value));
                  }).toList(),
                ),
              ),
              CupertinoButton(
                child: const Text('Done' , style: TextStyle(color:  CupertinoColors.activeBlue )),
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

  Widget _buildMaterialFilters(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Material(
          color: isDarkMode ? Colors.black : Colors.white,
          child: DropdownButton<String>(
            value: _timeRange,
            items: ['All', 'Today', 'This Week', 'Last Month']
                .map((value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _timeRange = value ?? 'All';
              _loadHistory();
            }),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
          ),
        ),
        Material(
          color: isDarkMode ? Colors.black : Colors.white,
          child: DropdownButton<Category>(
            value: _selectedCategory,
            items: Category.values
                .map((category) => DropdownMenuItem<Category>(
                      value: category,
                      child: Text(category.toString().split('.').last, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    ))
                .toList(),
            onChanged: _onCategoryChanged,
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
          ),
        ),
      ],
    );
  }
}

class DetailView extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? highestCountChoice;

  const DetailView({required this.item, this.highestCountChoice});

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertino(context) : _buildMaterial(context);
  }

  Widget _buildCupertino(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Detail View'),
        backgroundColor: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List Name: ${item['chooseFor']}', style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
            Text('Result: ${item['choice']}', style: TextStyle(color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
            Text('Date: ${item['timestamp']}', style: TextStyle(color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
            if (highestCountChoice != null)
              Text('Most Chosen: ${highestCountChoice!['choice']} (${highestCountChoice!['count']} times)', style: TextStyle(color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
            // Add more details as needed
          ],
        ),
      ),
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail View'),
        backgroundColor: isDarkMode ? Colors.black : Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List Name: ${item['chooseFor']}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            Text('Result: ${item['choice']}', style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54)),
            Text('Date: ${item['timestamp']}', style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54)),
            if (highestCountChoice != null)
              Text('Most Chosen: ${highestCountChoice!['choice']} (${highestCountChoice!['count']} times)', style: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54)),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}