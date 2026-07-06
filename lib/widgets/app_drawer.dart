import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AppDrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  AppDrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class AppDrawer extends StatelessWidget {
  final String headerTitle;
  final String? headerSubtitle;
  final List<AppDrawerItem> items;
  final VoidCallback? onLogoutComplete;

  const AppDrawer({
    super.key,
    this.headerTitle = "Hotel Management",
    this.headerSubtitle,
    this.items = const [],
    this.onLogoutComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    headerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (headerSubtitle != null)
                    Text(
                      headerSubtitle!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items
                    .map(
                      (item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.title),
                        onTap: item.onTap,
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (onLogoutComplete != null) {
                  onLogoutComplete!();
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}