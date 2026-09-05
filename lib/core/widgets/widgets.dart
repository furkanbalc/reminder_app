import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.line, width: borderWidth),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(left: 4),
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text.toUpperCase(), style: AppText.label(context)),
    );
  }
}

class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? (activeColor ?? c.water) : c.toggleOff,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.height = 32,
    this.compact = false,
  });

  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.seg,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        spacing: 2,
        children: [
          for (var i = 0; i < items.length; i++) _segment(context, i, c),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, int i, AppColors c) {
    final on = i == selected;
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? c.card : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 7 : 9),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F1F2E).withValues(alpha: 0.12),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          items[i],
          style: AppText.body(
            context,
            size: compact ? 12 : 13,
            weight: FontWeight.w600,
            color: on ? c.ink : c.mute,
          ),
        ),
      ),
    );
    return compact ? child : Expanded(child: child);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.icon,
    this.height = 56,
    this.outlined = false,
    this.outlineColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double height;
  final bool outlined;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = textColor ?? Colors.white;
    return Material(
      color: outlined ? Colors.transparent : (color ?? c.water),
      borderRadius: BorderRadius.circular(height >= 60 ? 18 : 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height >= 60 ? 18 : 16),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor ?? c.line, width: 1.5),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (icon != null) Icon(icon, size: 22, color: fg),
              Text(
                label,
                style: outlined
                    ? AppText.body(
                        context,
                        size: 15,
                        weight: FontWeight.w600,
                        color: fg,
                      )
                    : AppText.display(
                        context,
                        size: height >= 60 ? 20 : 17,
                        weight: FontWeight.w600,
                        color: fg,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.selectedTextColor,
    this.height = 40,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = selected ? (selectedColor ?? c.chipSelected) : c.card;
    final fg = selected ? (selectedTextColor ?? c.onChipSelected) : c.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: selected ? bg : c.line),
        ),
        // widthFactor: Wrap içinde tam genişliğe yayılmasın, içeriğe göre daralsın.
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppText.body(
              context,
              size: 13,
              weight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.color,
    this.iconColor,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? iconColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: color ?? c.card,
      shape: CircleBorder(
        side: bordered ? BorderSide(color: c.line) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: iconColor ?? c.ink),
        ),
      ),
    );
  }
}

/// Ayarlar ve form ekranlarındaki satır.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.trailing,
    this.onTap,
    this.last = false,
    this.leading,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool last;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          spacing: 10,
          children: [
            ?leading,
            Expanded(
              child: Text(
                label,
                style: AppText.body(context, size: 15, weight: FontWeight.w500),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class ValueTrailing extends StatelessWidget {
  const ValueTrailing(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(
          text,
          style: AppText.body(
            context,
            size: 15,
            weight: FontWeight.w500,
            color: c.mute,
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 20, color: c.mute),
      ],
    );
  }
}

class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }
}

/// Alt sayfa (bottom sheet) için tutamak + başlık satırı.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      spacing: 18,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: c.toggleOff,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(title, style: AppText.display(context, size: 22)),
            ),
            CircleIconButton(
              icon: Icons.close_rounded,
              size: 36,
              color: c.seg,
              bordered: false,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
