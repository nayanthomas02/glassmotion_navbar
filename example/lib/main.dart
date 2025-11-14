import 'package:flutter/material.dart';
import 'package:glassmotion_navbar/glassmotion_navbar.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassMotionNav Demo',
      theme: ThemeData.light(),
      home: const DemoHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int selected = 0;

  static const fiveItems = <GlassNavItem>[
    GlassNavItem(icon: Icons.home_rounded, label: 'Home'),
    GlassNavItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
    GlassNavItem(icon: Icons.search_rounded, label: 'Discover'),
    GlassNavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
    GlassNavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GlassMotionNav Demo')),
      body: Center(
        child: Text(
          'Selected: ${fiveItems[selected].label}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: GlassMotionNavBar(
        items: fiveItems,
        selectedIndex: selected,
        onItemTapped: (i) => setState(() => selected = i),
        onCenterTap: () => {},
        accentColor: Colors.purpleAccent,
        inactiveColor: Colors.grey.shade500,
        backgroundColor: Colors.black.withOpacity(0.04),
      ),
    );
  }
}
