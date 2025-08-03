import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'analytics_dashboard.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboard(),
    AnalyticsDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600
        ),
        unselectedLabelStyle:  TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home,color:Color.fromARGB(255, 4, 204, 240),),
            label: 'Admin',


          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics,color:Color.fromARGB(255, 4, 204, 240),),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
