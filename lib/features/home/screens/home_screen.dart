import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _placeholderTabs = ['Pausas', 'Rutinas', 'Bloqueos'];

  Widget _buildTab(int index) {
    if (index == 0) return const DashboardTab();
    return Center(
      child: Text(
        _placeholderTabs[index - 1],
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 28,
          color: PausaColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        bottom: false,
        child: _buildTab(_selectedIndex),
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
