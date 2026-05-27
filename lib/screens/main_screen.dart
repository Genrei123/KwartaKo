import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cashbook/cashbook_screen.dart';
import 'cashbook/add_transaction_sheet.dart';
import 'dashboard/user_dashboard_screen.dart';
import 'projections/projections_screen.dart';
import 'settings/settings_screen.dart';
import '../features/auth/auth_service.dart';
import '../features/cashbook/cashbook_providers.dart';


class MainScreen extends ConsumerStatefulWidget {
  final AuthService authService;

  const MainScreen({Key? key, required this.authService}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabProvider);

    // 4 actual pages — indices 0, 1, 2, 3
    // The FAB in the center is NOT a tab.
    final pages = [
      const CashbookScreen(),        // 0
      const UserDashboardScreen(),    // 1
      const ProjectionsScreen(),      // 2
      SettingsScreen(authService: widget.authService), // 3
    ];

    // Clamp index so it never exceeds page count
    final safeIndex = currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(safeIndex),
          child: pages[safeIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ── Tab 0: Cashbook ──
                _NavItem(
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book_rounded,
                  label: 'Cashbook',
                  isActive: safeIndex == 0,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(0),
                ),

                // ── Tab 1: Dashboard ──
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: safeIndex == 1,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(1),
                ),

                // ── Central FAB: Add Transaction ──
                _CenterActionButton(onTap: _showAddTransaction),

                // ── Tab 2: Projections ──
                _NavItem(
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up_rounded,
                  label: 'Projections',
                  isActive: safeIndex == 2,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(2),
                ),

                // ── Tab 3: Settings ──
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: safeIndex == 3,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Central "+" Action Button ───────────────────────────────────────────────

class _CenterActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade400.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

// ─── Navigation Item ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Colors.green.shade400.withOpacity(0.12) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive
                    ? Colors.green.shade400
                    : Colors.white.withOpacity(0.35),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.green.shade400
                    : Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
