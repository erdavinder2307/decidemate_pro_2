import 'package:flutter/material.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_GetStartedInfo> _pages = [
    _GetStartedInfo(
      title: 'Welcome to DecideMate Pro',
      description: 'Make smarter decisions with AI-powered insights and easy tracking.',
      image: Icons.lightbulb_outline,
    ),
    _GetStartedInfo(
      title: 'Track Your Choices',
      description: 'Log, review, and analyze your decisions to improve over time.',
      image: Icons.track_changes,
    ),
    _GetStartedInfo(
      title: 'Gain Insights',
      description: 'Visualize your decision patterns and get personalized suggestions.',
      image: Icons.insights,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final info = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(info.image, size: 120, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(height: 40),
                        Text(info.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Text(info.description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Theme.of(context).colorScheme.secondary : Colors.grey[400],
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GetStartedInfo {
  final String title;
  final String description;
  final IconData image;
  const _GetStartedInfo({required this.title, required this.description, required this.image});
}
