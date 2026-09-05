import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [HomeScreen(), RemindersScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: _BottomNav(
        index: index,
        onTap: (i) => ref.read(tabIndexProvider.notifier).set(i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.water_drop_outlined, Icons.water_drop_rounded, 'Su'),
    (Icons.checklist_rounded, Icons.checklist_rounded, 'Hatırlatıcılar'),
    (Icons.tune_rounded, Icons.tune_rounded, 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++) _item(context, i, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, AppColors c) {
    final on = i == index;
    final (icon, activeIcon, label) = _items[i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: on ? c.waterSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(on ? activeIcon : icon, size: 22, color: on ? c.waterDeep : c.mute),
            ),
            Text(
              label,
              style: AppText.body(context, size: 11, weight: FontWeight.w600, color: on ? c.waterDeep : c.mute),
            ),
          ],
        ),
      ),
    );
  }
}
