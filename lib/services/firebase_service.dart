import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> insertDecision(String id, String chooseFor, {String? category}) async {
    await _firestore.collection('decisions').doc(id).set({
      'chooseFor': chooseFor,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> insertChoices(String decisionId, List<String> choices) async {
    final batch = _firestore.batch();
    final choicesCollection = _firestore.collection('choices');
    for (var choice in choices) {
      final docRef = choicesCollection.doc();
      batch.set(docRef, {
        'choice': choice ?? '',
        'decisionId': decisionId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> incrementDecisionCount(String id) async {
    final docRef = _firestore.collection('decisions').doc(id);
    await docRef.update({'count': FieldValue.increment(1)});
  }

  Future<void> deleteDecision(String id) async {
    // Delete decision
    await _firestore.collection('decisions').doc(id).delete();
    // Delete related choices
    final choices = await _firestore.collection('choices').where('decisionId', isEqualTo: id).get();
    for (var doc in choices.docs) {
      await doc.reference.delete();
    }
    // Delete related results
    final results = await _firestore.collection('results').where('decisionId', isEqualTo: id).get();
    for (var doc in results.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateChoices(String decisionId, List<String> choices) async {
    // Delete old choices
    final oldChoices = await _firestore.collection('choices').where('decisionId', isEqualTo: decisionId).get();
    for (var doc in oldChoices.docs) {
      await doc.reference.delete();
    }
    // Add new choices
    await insertChoices(decisionId, choices);
  }

  Future<List<Map<String, dynamic>>> getDecisions() async {
    final snapshot = await _firestore.collection('decisions').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getChoicesFor(String decisionId) async {
    final snapshot = await _firestore.collection('choices').where('decisionId', isEqualTo: decisionId).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> insertResult(String id, String decisionId, String choiceId) async {
    await _firestore.collection('results').doc(id).set({
      'decisionId': decisionId,
      'choiceId': choiceId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getResultsFor(String decisionId) async {
    final snapshot = await _firestore.collection('results').where('decisionId', isEqualTo: decisionId).orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> clearResultsFor(String decisionId) async {
    final results = await _firestore.collection('results').where('decisionId', isEqualTo: decisionId).get();
    for (var doc in results.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<Map<String, dynamic>>> getDecisionsWithCounts() async {
    final decisions = await _firestore.collection('decisions').get();
    List<Map<String, dynamic>> result = [];
    for (var doc in decisions.docs) {
      final resultsSnapshot = await _firestore.collection('results').where('decisionId', isEqualTo: doc.id).get();
      result.add({'id': doc.id, ...doc.data(), 'count': resultsSnapshot.size});
    }
    return result;
  }

  Future<void> clearDatabase() async {
    // Delete all documents in decisions, choices, and results collections
    for (final collection in ['decisions', 'choices', 'results']) {
      final snapshot = await _firestore.collection(collection).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> updateDecision(String id, String chooseFor, {String? category}) async {
    await _firestore.collection('decisions').doc(id).update({
      'chooseFor': chooseFor ?? '',
      'category': category,
    });
  }

  Future<List<Map<String, dynamic>>> getDecisionHistory() async {
    final results = await _firestore.collection('results').orderBy('timestamp', descending: true).get();
    List<Map<String, dynamic>> history = [];
    for (var resultDoc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(resultDoc['decisionId']).get();
      history.add({
        'chooseFor': decision['chooseFor'],
        'choiceId': resultDoc['choiceId'],
        'timestamp': resultDoc['timestamp'],
      });
    }
    return history;
  }

  Future<List<Map<String, dynamic>>> getSpinHistory() async {
    final results = await _firestore.collection('results').orderBy('timestamp', descending: true).get();
    List<Map<String, dynamic>> history = [];
    for (var resultDoc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(resultDoc['decisionId']).get();
      history.add({
        'chooseFor': decision['chooseFor'],
        'choiceId': resultDoc['choiceId'],
        'timestamp': resultDoc['timestamp'],
      });
    }
    return history;
  }

  Future<List<Map<String, dynamic>>> getDecisionHistoryWithCounts() async {
    final results = await _firestore.collection('results').orderBy('timestamp', descending: true).get();
    Map<String, int> counts = {};
    List<Map<String, dynamic>> history = [];
    for (var resultDoc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(resultDoc['decisionId']).get();
      final key = '${decision['chooseFor']}_${resultDoc['choiceId']}_${resultDoc['timestamp']}';
      counts[key] = (counts[key] ?? 0) + 1;
      history.add({
        'chooseFor': decision['chooseFor'],
        'choiceId': resultDoc['choiceId'],
        'timestamp': resultDoc['timestamp'],
        'count': counts[key],
      });
    }
    return history;
  }

  Future<List<Map<String, dynamic>>> getLastThreeSpinResults() async {
    final results = await _firestore.collection('results').orderBy('timestamp', descending: true).limit(3).get();
    List<Map<String, dynamic>> lastThree = [];
    for (var resultDoc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(resultDoc['decisionId']).get();
      lastThree.add({'decision': decision.data(), ...resultDoc.data()});
    }
    return lastThree;
  }

  Future<Map<String, dynamic>?> getRandomResultFromLastThree() async {
    final lastThree = await getLastThreeSpinResults();
    if (lastThree.isNotEmpty) {
      lastThree.shuffle();
      return lastThree.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getFilteredSpinHistory({String? searchQuery, String? timeRange, String? category}) async {
    Query query = _firestore.collection('results');
    if (timeRange != null) {
      DateTime now = DateTime.now();
      DateTime startDate;
      switch (timeRange) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, 1);
          break;
        default:
          startDate = DateTime(1970);
      }
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    final results = await query.orderBy('timestamp', descending: true).get();
    List<Map<String, dynamic>> filtered = [];
    for (var resultDoc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(resultDoc['decisionId']).get();
      final choice = await _firestore.collection('choices').doc(resultDoc['choiceId']).get();
      if ((searchQuery == null ||
              (decision['chooseFor']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (choice['choice']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false)) &&
          (category == null || (decision['category'] == category))) {
        filtered.add({
          'decisionId': resultDoc['decisionId'],
          'choice': choice['choice'],
          'chooseFor': decision['chooseFor'],
          'choiceId': resultDoc['choiceId'],
          'timestamp': resultDoc['timestamp'],
          'category': decision['category'],
        });
      }
    }
    return filtered;
  }

  Future<Map<String, dynamic>?> getChoiceWithHighestCount(String decisionId) async {
    final results = await _firestore.collection('results').where('decisionId', isEqualTo: decisionId).get();
    Map<String, int> counts = {};
    for (var doc in results.docs) {
      final choiceId = doc['choiceId'];
      counts[choiceId] = (counts[choiceId] ?? 0) + 1;
    }
    if (counts.isNotEmpty) {
      final maxEntry = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final choiceDoc = await _firestore.collection('choices').doc(maxEntry.key).get();
      return {'choice': choiceDoc['choice'], 'count': maxEntry.value};
    }
    return null;
  }

  Future<Map<String, dynamic>?> getChoiceWithRecentResult(String decisionId) async {
    final results = await _firestore.collection('results').where('decisionId', isEqualTo: decisionId).orderBy('timestamp', descending: true).limit(1).get();
    if (results.docs.isNotEmpty) {
      final doc = results.docs.first;
      final choiceDoc = await _firestore.collection('choices').doc(doc['choiceId']).get();
      return {'choice': choiceDoc['choice'], 'timestamp': doc['timestamp']};
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSpinFrequencyByList() async {
    final results = await _firestore.collection('results').get();
    Map<String, int> freq = {};
    for (var doc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(doc['decisionId']).get();
      final listName = decision['chooseFor'];
      freq[listName] = (freq[listName] ?? 0) + 1;
    }
    return freq.entries.map((e) => {'list_name': e.key, 'spin_count': e.value}).toList();
  }

  Future<List<Map<String, dynamic>>> getOutcomeDistribution(String listName) async {
    final decisions = await _firestore.collection('decisions').where('chooseFor', isEqualTo: listName).get();
    if (decisions.docs.isEmpty) return [];
    final decisionId = decisions.docs.first.id;
    final results = await _firestore.collection('results').where('decisionId', isEqualTo: decisionId).get();
    Map<String, int> outcomeCounts = {};
    for (var doc in results.docs) {
      final choiceDoc = await _firestore.collection('choices').doc(doc['choiceId']).get();
      final outcome = choiceDoc['choice'];
      outcomeCounts[outcome] = (outcomeCounts[outcome] ?? 0) + 1;
    }
    return outcomeCounts.entries.map((e) => {'outcome': e.key, 'count': e.value}).toList();
  }

  Future<List<Map<String, dynamic>>> getSpinFrequencyTrends() async {
    final results = await _firestore.collection('results').get();
    Map<String, int> trends = {};
    for (var doc in results.docs) {
      final timestamp = doc['timestamp'];
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        trends[dateStr] = (trends[dateStr] ?? 0) + 1;
      }
    }
    return trends.entries.map((e) => {'date': e.key, 'spin_count': e.value}).toList();
  }

  Future<Map<String, dynamic>> getKeyMetrics() async {
    final results = await _firestore.collection('results').get();
    final totalSpins = results.size;
    Map<String, int> listCounts = {};
    Map<String, int> outcomeCounts = {};
    for (var doc in results.docs) {
      final decision = await _firestore.collection('decisions').doc(doc['decisionId']).get();
      final listName = decision['chooseFor'];
      listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      final choiceDoc = await _firestore.collection('choices').doc(doc['choiceId']).get();
      final outcome = choiceDoc['choice'];
      outcomeCounts[outcome] = (outcomeCounts[outcome] ?? 0) + 1;
    }
    final mostUsedList = listCounts.entries.isNotEmpty ? listCounts.entries.reduce((a, b) => a.value > b.value ? a : b) : null;
    final mostFrequentOutcome = outcomeCounts.entries.isNotEmpty ? outcomeCounts.entries.reduce((a, b) => a.value > b.value ? a : b) : null;
    return {
      'totalSpins': totalSpins,
      'mostUsedList': mostUsedList != null ? {'chooseFor': mostUsedList.key, 'count': mostUsedList.value} : null,
      'mostFrequentOutcome': mostFrequentOutcome != null ? {'choice': mostFrequentOutcome.key, 'count': mostFrequentOutcome.value} : null,
    };
  }
}
