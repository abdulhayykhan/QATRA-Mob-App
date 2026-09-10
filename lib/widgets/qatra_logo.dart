import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable QATRA logo component using media/logo.png
class QatraLogo extends StatelessWidget {
  final double size;
  final bool withBackground;
  final double padding;

  const QatraLogo({
    super.key,
    this.size = 32,
    this.withBackground = true,
    this.padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      'media/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (padding > 0) {
      image = Padding(
        padding: EdgeInsets.all(padding),
        child: image,
      );
    }

    if (!withBackground) {
      return image;
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: image,
      ),
    );
  }
}

/// Standardized branded AppBar header with media/logo.png and QATRA title
class QatraBrandHeader extends StatelessWidget {
  final double logoSize;
  final double fontSize;

  const QatraBrandHeader({
    super.key,
    this.logoSize = 28,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        QatraLogo(size: logoSize),
        const SizedBox(width: 8),
        Text(
          'QATRA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            letterSpacing: 1.2,
            color: AppColors.primaryDarkRed,
          ),
        ),
      ],
    );
  }
}
