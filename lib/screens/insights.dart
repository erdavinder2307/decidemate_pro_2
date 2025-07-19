import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late FirebaseService _firebaseService;
  String _selectedList = '';
  String _selectedTimeRange = 'All-Time';
  DateTime? _selectedStartDate;
    DateTime? _selectedEndDate;
  Map<String, dynamic>? _keyMetrics;
  List<Map<String, dynamic>> _spinFrequencyByList = [];
  List<Map<String, dynamic>> _outcomeDistribution = [];
  List<Map<String, dynamic>> _spinFrequencyTrends = [];

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _fetchData();
  }

  Future<void> _fetchData() async {
    final keyMetrics = await _firebaseService.getKeyMetrics();
    final spinFrequencyByList = await _firebaseService.getSpinFrequencyByList();
    final outcomeDistribution = await _firebaseService.getOutcomeDistribution(_selectedList);
    final spinFrequencyTrends = await _firebaseService.getSpinFrequencyTrends();

    setState(() {
      _keyMetrics = keyMetrics;
      _spinFrequencyByList = spinFrequencyByList;
      _outcomeDistribution = outcomeDistribution;
      _spinFrequencyTrends = spinFrequencyTrends;
    });
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return isIOS
        ? CupertinoPageScaffold(
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
            child: _buildBody(isDarkMode, isIOS),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('Insights'),
            ),
            body: _buildBody(isDarkMode, isIOS),
          );
  }

  Widget _buildBody(bool isDarkMode, bool isIOS) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildKeyMetrics(),
          _buildDateRangeSelector(isIOS),
          Expanded(child: _buildBarChart(isDarkMode)),
          Expanded(child: _buildPieChart(isDarkMode)),
          Expanded(child: _buildLineChart(isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    if (_keyMetrics == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Text('Total Spins: ${_keyMetrics!['totalSpins'].toString()}'),
        Text('Most Used List: ${_keyMetrics!['mostUsedList']?['chooseFor'] ?? 'N/A'}'),
        Text('Most Frequent Outcome: ${_keyMetrics!['mostFrequentOutcome']?['choice'] ?? 'N/A'}'),
      ],
    );
  }

  Widget _buildDateRangeSelector(bool isIOS) {
    return isIOS
        ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            CupertinoButton(
              child: Text(
              _selectedStartDate != null
                ? 'Start Date: ${_selectedStartDate!.toLocal()}'.split(' ')[0]
                : 'Start Date',
              style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
              showCupertinoModalPopup(
                context: context,
                builder: (_) => Container(
                height: 250,
                color: Color.fromARGB(255, 255, 255, 255),
                child: Column(
                  children: [
                  Expanded(
                    child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    onDateTimeChanged: (val) {
                      setState(() {
                      _selectedStartDate = val;
                      _selectedTimeRange = 'Custom';
                      _fetchData();
                      });
                    },
                    ),
                  ),
                  CupertinoButton(
                    child: Text('Done', style: TextStyle(color: CupertinoColors.activeBlue)),
                    onPressed: () {
                    Navigator.pop(context);
                    },
                  ),
                  ],
                ),
                ),
              );
              },
            ),
            CupertinoButton(
              child: Text(
              _selectedEndDate != null
                ? 'End Date: ${_selectedEndDate!.toLocal()}'.split(' ')[0]
                : 'End Date',
              style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
              showCupertinoModalPopup(
                context: context,
                builder: (_) => Container(
                height: 250,
                color: Color.fromARGB(255, 255, 255, 255),
                child: Column(
                  children: [
                  Expanded(
                    child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    onDateTimeChanged: (val) {
                      setState(() {
                      // Update the selected date range and fetch new data
                      _selectedTimeRange = 'Custom';
                      _fetchData();
                      });
                    },
                    ),
                  ),
                  CupertinoButton(
                    child: Text('Done', style: TextStyle(color: CupertinoColors.activeBlue)),
                    onPressed: () {
                    Navigator.pop(context);
                    },
                  ),
                  ],
                ),
                ),
              );
              },
            ),
          ],
        )
          
        : DropdownButton<String>(
            value: _selectedTimeRange,
            items: ['Today', 'Last Week', 'Last Month', 'All-Time']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedTimeRange = newValue!;
              });
            },
          );
  }

  Widget _buildBarChart(bool isDarkMode) {
    if (_spinFrequencyByList.isEmpty) {
      return Center(child: Text('No data available'));
    }

    return BarChart(
      BarChartData(
        barGroups: _spinFrequencyByList
          .map((data) => BarChartGroupData(
              x: _spinFrequencyByList.indexOf(data),
              barRods: [
              BarChartRodData(
                toY: (data['spin_count'] ?? 0).toDouble(),
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              ],
            ))
          .toList(),
      ),
    );
  }

  Widget _buildPieChart(bool isDarkMode) {
    if (_outcomeDistribution.isEmpty) {
      return Center(child: Text('No data available'));
    }

    return PieChart(
      PieChartData(
        sections: _outcomeDistribution
            .map((data) => PieChartSectionData(
                  value: data['count'],
                  title: data['outcome'],
                  color: isDarkMode ? Colors.white : Colors.black,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLineChart(bool isDarkMode) {
    if (_spinFrequencyTrends.isEmpty) {
      return Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _spinFrequencyTrends
                .map((data) => FlSpot(
                      DateTime.parse(data['date'] ?? DateTime.now().toString()).millisecondsSinceEpoch
                          .toDouble(),
                      double.parse((data['spin_count'].toDouble()).toStringAsFixed(1)),
                    ))
                .toList(),
            isCurved: true,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }
}