import 'package:decidemate_pro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  final Future<void> Function()? onSignOut;
  const DashboardScreen({super.key, this.onSignOut});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final today = DateFormat.yMMMMd().format(DateTime.now());

    return isIOS ? _buildCupertinoScaffold(today) : _buildMaterialScaffold(today);
  }

  Widget _buildCupertinoScaffold(String today) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/icon.png', width: 30),
          ]),
        middle: const Text('DecideMate Pro'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.auth, (route) => false);
            }
          },
          child: const Icon(CupertinoIcons.square_arrow_right, size: 28, color: CupertinoColors.activeBlue),
        ),
      ),
      child: _buildBody(today),
    );
  }

  Widget _buildMaterialScaffold(String today) {
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
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black, // Material style color
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _buildBody(today),
    
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.add);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(String today) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome!', style: Theme.of(context).textTheme.headlineMedium),
          Text('Today is $today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildFeatureCard('All Choices', Icons.list),
                _buildFeatureCard('Quick Spin', Icons.rotate_right),
                _buildFeatureCard('Insights', Icons.insights),
                _buildFeatureCard('History', Icons.history),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon) {
    Color cardColor;
    switch (title) {
      case 'All Choices':
        cardColor = Colors.blueAccent;
        break;
      case 'Quick Spin':
        cardColor = Colors.greenAccent;
        
        break;
      case 'Insights':
        cardColor = Colors.orangeAccent;
        break;
      case 'History':
        cardColor = Colors.purpleAccent;
        break;
      default:
        cardColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () async {
        switch (title) {
          case 'All Choices':
            Navigator.pushNamed(context, Routes.home);
            break;
    case 'Quick Spin':
            // TODO: Implement Firestore logic for Quick Spin
            /* final randomResult = await FirebaseService().getRandomResultFromLastThree();
            if (randomResult != null) {
                Navigator.pushNamed(context, Routes.details, arguments: {'id': randomResult['id'].toString(), 'chooseFor': randomResult['chooseFor']});
            } else {
              
                SnackBar(content: Text('No recent spins available'));
              
            } */
            break;
          case 'Insights':
            Navigator.pushNamed(context, Routes.insights);
            break;
          case 'History':
            Navigator.pushNamed(context, Routes.history);
            break;
        }
      },
      child: Card(
        color: cardColor,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}