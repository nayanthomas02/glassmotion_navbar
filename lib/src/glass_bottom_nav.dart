// lib/src/glass_bottom_nav.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single item in the glass bottom nav.
class GlassNavItem {
  final IconData icon;
  final String label;
  final String? semanticLabel;
  final Widget? badge;

  const GlassNavItem({
    required this.icon,
    required this.label,
    this.semanticLabel,
    this.badge,
  });
}

/// Small Glass container helper that provides backdrop blur + translucent body.
/// Use this if you want a consistent "glass" appearance across elements.
class GlassContainer extends StatelessWidget {
  final BorderRadius? borderRadius;
  final Widget child;
  final double blurSigma;
  final Color? color;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurSigma = 10.0,
    this.color,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Use colorScheme.surface as the default base instead of the removed bottomAppBarColor
    final bg = color ?? Theme.of(context).colorScheme.surface.withOpacity(0.06);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.04),
                  width: 0.8,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// GlassMotionNavBar — customizable glassmorphic bottom nav with animated center FAB
class GlassMotionNavBar extends StatefulWidget {
  /// list of items (length must be odd and >= 3, center is reserved for FAB)
  final List<GlassNavItem> items;

  /// selected index (index relative to items)
  final int selectedIndex;

  /// called when a non-center item is tapped
  final ValueChanged<int> onItemTapped;

  /// called when center button is tapped
  final VoidCallback onCenterTap;

  /// center widget (if null, default add icon is shown)
  final Widget? centerWidget;

  /// main accent color for selected item + rimlight
  final Color? accentColor;

  /// inactive icon color
  final Color? inactiveColor;

  /// background color used for glass body (translucent)
  final Color? backgroundColor;

  /// height of navbar
  final double height;

  /// diameter of center button
  final double fabDiameter;

  /// horizontal padding around nav
  final double horizontalPadding;

  /// border radius of glass container
  final BorderRadius? borderRadius;

  /// whether to show labels
  final bool showLabels;

  /// label style override
  final TextStyle? labelStyle;

  /// duration for icon jump animation
  final Duration iconAnimationDuration;

  final bool enableHaptics;

  GlassMotionNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onCenterTap,
    this.centerWidget,
    this.accentColor,
    this.inactiveColor,
    this.backgroundColor,
    this.height = 64.0,
    this.fabDiameter = 64.0,
    this.horizontalPadding = 16.0,
    this.borderRadius,
    this.showLabels = true,
    this.labelStyle,
    this.iconAnimationDuration = const Duration(milliseconds: 320),
    this.enableHaptics = true,
  }) : assert(items.length >= 3 && items.length.isOdd,
            'items must be an odd number >= 3 (middle slot reserved for center button)');

  @override
  State<GlassMotionNavBar> createState() => _GlassMotionNavBarState();
}

class _GlassMotionNavBarState extends State<GlassMotionNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _centerCtrl;
  late final Animation<double> _centerScale;
  late final Animation<double> _centerRotation;

  @override
  void initState() {
    super.initState();
    _centerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _centerScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _centerCtrl, curve: Curves.easeOutBack),
    );

    _centerRotation = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(parent: _centerCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _centerCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCenterTap() async {
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    try {
      await _centerCtrl.forward();
      await _centerCtrl.reverse();
    } finally {
      widget.onCenterTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom;

    final navBarHeight = widget.height;
    final horizontalPadding = widget.horizontalPadding;
    final fabDiameter = widget.fabDiameter;
    final accent =
        widget.accentColor ?? Theme.of(context).colorScheme.secondary;
    final inactive = widget.inactiveColor ?? Colors.grey.shade400;
    final bg = widget.backgroundColor ??
        Theme.of(context).colorScheme.surface.withOpacity(0.02);

    final count = widget.items.length;
    final centerSlot = (count / 2).floor(); // index of center slot in items

    // IMPORTANT: return a normal widget (SafeArea) — DO NOT return Positioned here.
    // This makes the widget safe to use as bottomNavigationBar in Scaffold.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: 8.0 + bottomInset * 0.0,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // glass container for the nav body
            GlassContainer(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(18),
              color: bg,
              child: SizedBox(
                height: navBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(count, (i) {
                    // leave space for center FAB
                    if (i == centerSlot) return SizedBox(width: fabDiameter);

                    final isSelected = widget.selectedIndex == i;
                    final item = widget.items[i];

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (widget.enableHaptics) {
                            HapticFeedback.selectionClick();
                          }
                          widget.onItemTapped(i);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 6),
                          child: _AnimatedColumnIcon(
                            icon: item.icon,
                            label: item.label,
                            selected: isSelected,
                            accentColor: accent,
                            inactiveColor: inactive,
                            showLabel: widget.showLabels,
                            labelStyle: widget.labelStyle,
                            duration: widget.iconAnimationDuration,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // center FAB (embedded look) — this Positioned is inside the Stack (correct)
            Positioned(
              top: -fabDiameter * 0.28,
              child: AnimatedBuilder(
                animation: _centerCtrl,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _centerRotation.value,
                    child: Transform.scale(
                      scale: _centerScale.value,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _handleCenterTap,
                  child: SizedBox(
                    width: fabDiameter,
                    height: fabDiameter,
                    child: _buildCenterFab(accent, bg, fabDiameter),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(Color accent, Color bg, double fabDiameter) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ambient halo behind FAB
        Container(
          width: fabDiameter + 22,
          height: fabDiameter + 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [accent.withOpacity(0.06), Colors.transparent],
              center: const Alignment(-0.2, -0.2),
              radius: 0.9,
            ),
          ),
        ),

        // outer thin ring
        Container(
          width: fabDiameter + 6,
          height: fabDiameter + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withOpacity(0.06), width: 1.2),
          ),
        ),

        // subtle colored rimlight
        Container(
          width: fabDiameter + 10,
          height: fabDiameter + 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.2),
              radius: 0.85,
              colors: [
                accent.withOpacity(0.06),
                accent.withOpacity(0.03),
                Colors.transparent
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // glassmorphic main body (ClipOval + BackdropFilter)
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              width: fabDiameter,
              height: fabDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: Colors.white.withOpacity(0.06), width: 0.8),
              ),
            ),
          ),
        ),

        // glossy inner highlight
        Container(
          width: fabDiameter - 14,
          height: fabDiameter - 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.02)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // twin thin ring
        Container(
          width: fabDiameter - 8,
          height: fabDiameter - 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
          ),
        ),

        // center content
        widget.centerWidget ??
            const Icon(
              Icons.add,
              size: 28,
              color: Colors.white,
            ),

        // soft shadow 'notch' under button
        Positioned(
          bottom: -4,
          child: Container(
            width: fabDiameter * 0.9,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2))
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedColumnIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accentColor;
  final Color inactiveColor;
  final bool showLabel;
  final TextStyle? labelStyle;
  final Duration duration;

  const _AnimatedColumnIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.inactiveColor,
    required this.showLabel,
    this.labelStyle,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accentColor : inactiveColor;
    final double scale = selected ? 1.12 : 1.0;
    final double yOffset = selected ? -6.0 : 0.0;

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      transform: Matrix4.identity()..translate(0.0, yOffset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: scale),
            duration: duration,
            curve: Curves.elasticOut,
            builder: (context, s, child) {
              return Transform.scale(
                scale: s,
                child: Icon(icon, size: 20, color: color),
              );
            },
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: labelStyle ??
                  TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
