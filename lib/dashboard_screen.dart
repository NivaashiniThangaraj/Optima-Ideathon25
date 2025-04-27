import 'package:flutter/material.dart';
import 'package:optima/orders_page.dart';
import 'package:optima/threshold_editor_page.dart';
import 'upload_blueprint_screen.dart';
import 'past_projects_screen.dart';
import 'dashboard_page.dart';
import 'map_screen.dart'; // Import the new DigitalTwinMapPage widget

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Add DigitalTwinMapPage to the widget options list
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardPage(),
    UploadBlueprintScreen(),
    OrdersPage(),
    PastProjectsScreen(),
    ThresholdEditorPage(),
    MapScreen(), // Add the new DigitalTwinMapPage here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OPTIMA"),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload Blueprints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Place Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Past Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),  // New icon for Digital Twin
            label: 'Digital Twin',  // New label for Digital Twin
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
