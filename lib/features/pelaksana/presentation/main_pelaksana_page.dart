import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/pelaksana/presentation/screens/pelaksana_home_page.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_list_screen.dart';
import 'package:infrast/features/pelaksana/presentation/screens/riwayat_screen.dart';
import 'package:infrast/features/pelaksana/presentation/screens/profil_screen.dart'; // TAMBAHAN: Import ProfilScreen

class MainPelaksanaPage extends StatefulWidget {
  const MainPelaksanaPage({super.key});

  @override
  State<MainPelaksanaPage> createState() => _MainPelaksanaPageState();
}

class _MainPelaksanaPageState extends State<MainPelaksanaPage> {
  int _currentIndex = 0;

  void _onSwitchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List dibuat di dalam build() agar callback selalu update
    final List<Widget> pages = [
      PelaksanaHomePage(
        onOpenLaporan: () => _onSwitchTab(1),
      ),
      const TugasListScreen(),
      const RiwayatScreen(), 
      const ProfilScreen(), // UBAH: Placeholder diganti ProfilScreen
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Beranda', 0),
              _buildNavItem(Icons.assignment_outlined, 'Laporan', 1),
              _buildNavItem(Icons.history_rounded, 'Riwayat', 2),
              _buildNavItem(Icons.person_outline, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onSwitchTab(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}