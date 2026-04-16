import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/tracked_products_provider.dart';
import '../providers/recent_searches_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class AppDrawer extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onScrollToTrending;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onScrollToTrending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final trackedCount = ref.watch(
      trackedProductsProvider.select(
        (async) => async.maybeWhen(
          data: (items) => items.length,
          orElse: () => 0,
        ),
      ),
    );

    return Drawer(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Premium User Header ──
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(AppColors.primary), Color(AppColors.primaryDark)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.name?.isNotEmpty ?? false)
                      ? user!.name![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.primary),
                  ),
                ),
              ),
              accountName: Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                user?.email ?? 'user@example.com',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // ── Scrollable body to prevent overflow ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Navigation
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    selected: selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(0);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_rounded,
                    label: 'Tracked Products',
                    trailing: trackedCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$trackedCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                    selected: selectedIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(2);
                    },
                  ),

                  const Divider(height: 1),

                  // ── Smart Features ──
                  _SectionHeader(label: 'SMART FEATURES'),
                  _DrawerItem(
                    icon: Icons.notifications_active_rounded,
                    label: 'Price Alerts',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/price-alerts');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.smart_toy_rounded,
                    label: 'AI Assistant',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/chat');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_rounded,
                    label: 'Deal of the Day',
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(0);
                      // Scroll to trending section after a brief layout frame
                      if (onScrollToTrending != null) {
                        Future.delayed(const Duration(milliseconds: 300), onScrollToTrending);
                      }
                    },
                  ),

                  const Divider(height: 1),

                  // ── Settings ──
                  _SectionHeader(label: 'SETTINGS'),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notification Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _showNotificationSettings(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Clear Search History',
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Search History'),
                          content: const Text(
                              'This will remove all your recent searches. Continue?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(recentSearchesProvider.notifier).clearHistory();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Search history cleared')),
                          );
                        }
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    label: isDark ? 'Light Mode' : 'Dark Mode',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                      activeColor: const Color(AppColors.primary),
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),

            // ── Footer: Logout + Version (always at bottom, never overflows) ──
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                ref.read(currentUserProvider.notifier).logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'SmartSaving v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool priceDrops = true;
            bool targetAlerts = true;
            bool dealOfDay = false;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Notification Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Price Drop Alerts'),
                    subtitle:
                        const Text('Get notified when prices drop significantly'),
                    value: priceDrops,
                    activeColor: const Color(AppColors.primary),
                    onChanged: (val) => setModalState(() => priceDrops = val),
                  ),
                  SwitchListTile(
                    title: const Text('Target Price Alerts'),
                    subtitle: const Text(
                        'Alert when product reaches your target price'),
                    value: targetAlerts,
                    activeColor: const Color(AppColors.primary),
                    onChanged: (val) => setModalState(() => targetAlerts = val),
                  ),
                  SwitchListTile(
                    title: const Text('Daily Deal Digest'),
                    subtitle:
                        const Text('Receive a daily summary of best deals'),
                    value: dealOfDay,
                    activeColor: const Color(AppColors.primary),
                    onChanged: (val) => setModalState(() => dealOfDay = val),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ??
            (selected ? const Color(AppColors.primary) : Colors.grey[700]),
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: textColor ??
              (selected ? const Color(AppColors.primary) : null),
          fontSize: 14,
        ),
      ),
      trailing: trailing,
      selected: selected,
      selectedTileColor: const Color(AppColors.primary).withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
