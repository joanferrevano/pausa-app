import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/bottom_nav.dart';
import '../../pausas/screens/pausas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _placeholderTabs = ['Rutinas', 'Bloqueos'];

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const DashboardTab();
      case 1:
        return const PausasScreen();
      default:
        return Center(
          child: Text(
            _placeholderTabs[index - 2],
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              color: PausaColors.textSecondary,
            ),
          ),
        );
    }
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
