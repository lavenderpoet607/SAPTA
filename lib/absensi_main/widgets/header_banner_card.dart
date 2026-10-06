import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'analog_clock.dart';

class HeaderBannerCard extends StatelessWidget {
  final String userName;
  final String? title;
  final String? subtitle;
  final IconData? subtitleIcon;
  final String? badgeText;
  final String? avatarText;
  final IconData? avatarIcon;
  final String? imageAsset;
  final bool showAnalogClock;
  final List<Color>? gradientColors;
  final VoidCallback? onEdit;
  final VoidCallback? onRefresh;
  final bool avatarOnLeft;

  const HeaderBannerCard({
    super.key,
    required this.userName,
    this.title,
    this.subtitle,
    this.subtitleIcon,
    this.badgeText,
    this.avatarText,
    this.avatarIcon,
    this.imageAsset,
    this.showAnalogClock = false,
    this.gradientColors,
    this.onEdit,
    this.onRefresh,
    this.avatarOnLeft = false,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('userName', userName));
    properties.add(StringProperty('title', title, defaultValue: null));
    properties.add(StringProperty('subtitle', subtitle, defaultValue: null));
    properties.add(FlagProperty('showAnalogClock', value: showAnalogClock, ifTrue: 'Jam Analog Tampil', ifFalse: 'Tanpa Jam'));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onEdit', onEdit));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onRefresh', onRefresh));
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ?? const [Color(0xFF1E3A8A), Color(0xFF2563EB)];

    Widget avatarWidget = showAnalogClock
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const AnalogClock(
              size: 42,
              showNumbers: true,
              showDigital: true,
            ),
          )
        : Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      imageAsset!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  )
                : avatarText != null && avatarText!.isNotEmpty
                ? Text(
                    avatarText!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    avatarIcon ?? Icons.badge_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
          );

    Widget textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (subtitleIcon != null) ...[
                Icon(subtitleIcon, size: 13, color: Colors.white70),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (badgeText != null && badgeText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (avatarOnLeft) ...[avatarWidget, const SizedBox(width: 14)],
          Expanded(child: textColumn),
          if (!avatarOnLeft) ...[const SizedBox(width: 14), avatarWidget],
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Muat ulang data',
            ),
          ],
        ],
      ),
    );
  }
}
