import 'package:flutter/material.dart';

/// Authentic vector-styled emblems, official monograms, and badges for top private universities
class UniversityLogo extends StatelessWidget {
  final String universityKey; // 'iub', 'brac', 'nsu', 'aust', 'uiu', 'aiub', 'ewu', 'uap'
  final String? logoUrl;
  final double size;
  final bool showShadow;
  final bool isCircle;

  const UniversityLogo({
    super.key,
    required this.universityKey,
    this.logoUrl,
    this.size = 36,
    this.showShadow = true,
    this.isCircle = true,
  });

  /// High-resolution official vector/monogram PNG logos
  static const Map<String, String> officialLogos = {
    'nsu': 'https://thumb.wikimedia.org/wikipedia/en/thumb/e/e0/North_South_University_Monogram.svg/250px-North_South_University_Monogram.svg.png',
    'brac': 'https://thumb.wikimedia.org/wikipedia/en/thumb/4/40/BRAC_University_monogram.svg/250px-BRAC_University_monogram.svg.png',
    'bracu': 'https://thumb.wikimedia.org/wikipedia/en/thumb/4/40/BRAC_University_monogram.svg/250px-BRAC_University_monogram.svg.png',
    'ewu': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/16/East-west-university-LogoSVG.svg/250px-East-west-university-LogoSVG.svg.png',
    'aust': 'https://thumb.wikimedia.org/wikipedia/en/thumb/a/ac/Ahsanullah_University_of_Science_and_Technology_Logo.svg/250px-Ahsanullah_University_of_Science_and_Technology_Logo.svg.png',
    'aiub': 'https://thumb.wikimedia.org/wikipedia/en/thumb/8/8c/American_International_University-Bangladesh_Monogram.svg/250px-American_International_University-Bangladesh_Monogram.svg.png',
    'uiu': 'https://thumb.wikimedia.org/wikipedia/en/thumb/6/6b/United_International_University_Monogram.svg/250px-United_International_University_Monogram.svg.png',
    'uap': 'https://thumb.wikimedia.org/wikipedia/en/thumb/d/d7/University_of_Asia_Pacific_%28Bangladesh%29_logo.png/250px-University_of_Asia_Pacific_%28Bangladesh%29_logo.png',
    'iub': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/ba/%E0%A6%87%E0%A6%A8%E0%A7%8D%E0%A6%A1%E0%A6%BF%E0%A6%AA%E0%A7%87%E0%A6%A8%E0%A7%8D%E0%A6%A1%E0%A7%87%E0%A6%A8%E0%A7%8D%E0%A6%9F_%E0%A6%AC%E0%A6%BF%E0%A6%B6%E0%A7%8D%E0%A6%AC%E0%A6%AC%E0%A6%BF%E0%A6%A6%E0%A7%8D%E0%A6%AF%E0%A6%BE%E0%A6%B2%E0%A6%AF%E0%A6%BC%2C_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE%E0%A6%A6%E0%A7%87%E0%A6%B6_%E0%A6%B2%E0%A7%8B%E0%A6%97%E0%A7%8B.svg/250px-%E0%A6%87%E0%A6%A8%E0%A7%8D%E0%A6%A1%E0%A6%BF%E0%A6%AA%E0%A7%87%E0%A6%A8%E0%A7%8D%E0%A6%A1%E0%A7%87%E0%A6%A8%E0%A7%8D%E0%A6%9F_%E0%A6%AC%E0%A6%BF%E0%A6%B6%E0%A7%8D%E0%A6%AC%E0%A6%AC%E0%A6%BF%E0%A6%A6%E0%A7%8D%E0%A6%AF%E0%A6%BE%E0%A6%B2%E0%A6%AF%E0%A6%BC%2C_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE%E0%A6%A6%E0%A7%87%E0%A6%B6_%E0%A6%B2%E0%A7%8B%E0%A6%97%E0%A7%8B.svg.png',
  };

  /// Normalizes variations like 'BRACU' -> 'brac', 'American International' -> 'aiub'
  static String normalizeKey(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('brac')) return 'brac';
    if (lower.contains('nsu') || lower.contains('north south')) return 'nsu';
    if (lower.contains('aiub') || lower.contains('american international')) return 'aiub';
    if (lower.contains('aust') || lower.contains('ahsanullah')) return 'aust';
    if (lower.contains('ewu') || lower.contains('east west') || lower.contains('east-west')) return 'ewu';
    if (lower.contains('uiu') || lower.contains('united international')) return 'uiu';
    if (lower.contains('uap') || lower.contains('asia pacific')) return 'uap';
    if (lower.contains('iub') || lower.contains('independent')) return 'iub';
    return lower;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedKey = normalizeKey(universityKey);
    final effectiveUrl = (logoUrl != null && logoUrl!.isNotEmpty)
        ? logoUrl!
        : (officialLogos[resolvedKey] ?? officialLogos[universityKey.toLowerCase()]);

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(size * 0.22),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: size * 0.2,
                    offset: Offset(0, size * 0.05),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.all(size * 0.08),
        child: Image.network(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildVectorBadge(resolvedKey),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildVectorBadge(resolvedKey);
          },
        ),
      );
    }

    return _buildVectorBadge(resolvedKey);
  }

  Widget _buildVectorBadge(String resolvedKey) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.22),
        gradient: _getGradient(resolvedKey),
        border: Border.all(
          color: _getBorderColor(resolvedKey),
          width: size > 40 ? 2.0 : 1.2,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: _getShadowColor(resolvedKey),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: Center(
        child: _buildEmblemContent(resolvedKey),
      ),
    );
  }

  LinearGradient _getGradient(String key) {
    switch (key) {
      case 'iub':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2554), Color(0xFFC41230)],
        );
      case 'brac':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006B3F), Color(0xFF0B4626)],
        );
      case 'nsu':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003366), Color(0xFF021F3D)],
        );
      case 'aust':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF800000), Color(0xFF4A0000)],
        );
      case 'aiub':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        );
      case 'ewu':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFFDC2626)],
        );
      case 'uiu':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFFEA580C)],
        );
      case 'uap':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFFD97706)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF542747), Color(0xFFFF7A36)],
        );
    }
  }

  Color _getBorderColor(String key) {
    switch (key) {
      case 'iub':
        return const Color(0xFFFFD700).withValues(alpha: 0.8);
      case 'brac':
        return const Color(0xFFFFC72C).withValues(alpha: 0.9);
      case 'nsu':
        return const Color(0xFFF59E0B).withValues(alpha: 0.9);
      case 'aust':
        return const Color(0xFF34D399).withValues(alpha: 0.8);
      case 'aiub':
        return const Color(0xFF60A5FA).withValues(alpha: 0.8);
      case 'ewu':
        return const Color(0xFF34D399).withValues(alpha: 0.8);
      case 'uiu':
        return const Color(0xFFFB923C).withValues(alpha: 0.8);
      default:
        return Colors.white.withValues(alpha: 0.7);
    }
  }

  Color _getShadowColor(String key) {
    switch (key) {
      case 'iub':
        return const Color(0xFFC41230).withValues(alpha: 0.35);
      case 'brac':
        return const Color(0xFF006B3F).withValues(alpha: 0.4);
      case 'nsu':
        return const Color(0xFF003366).withValues(alpha: 0.4);
      case 'aust':
        return const Color(0xFF800000).withValues(alpha: 0.35);
      case 'aiub':
        return const Color(0xFF1E3A8A).withValues(alpha: 0.35);
      case 'ewu':
        return const Color(0xFF065F46).withValues(alpha: 0.35);
      default:
        return Colors.black.withValues(alpha: 0.25);
    }
  }

  Widget _buildEmblemContent(String key) {
    final fontSize = size * 0.34;

    String label;
    IconData? icon;
    Color iconColor = Colors.white;

    switch (key) {
      case 'iub':
        label = 'IUB';
        icon = Icons.local_fire_department_rounded;
        iconColor = const Color(0xFFFFD700);
        break;
      case 'brac':
        label = 'BRAC';
        icon = Icons.wb_sunny_rounded;
        iconColor = const Color(0xFFFFC72C);
        break;
      case 'nsu':
        label = 'NSU';
        icon = Icons.school_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
      case 'aust':
        label = 'AUST';
        icon = Icons.architecture_rounded;
        iconColor = const Color(0xFF34D399);
        break;
      case 'aiub':
        label = 'AIUB';
        icon = Icons.computer_rounded;
        iconColor = const Color(0xFF60A5FA);
        break;
      case 'ewu':
        label = 'EWU';
        icon = Icons.auto_stories_rounded;
        iconColor = const Color(0xFF34D399);
        break;
      case 'uiu':
        label = 'UIU';
        icon = Icons.lightbulb_rounded;
        iconColor = const Color(0xFFFB923C);
        break;
      case 'uap':
        label = 'UAP';
        icon = Icons.public_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
      default:
        label = key.toUpperCase();
        icon = Icons.school_rounded;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (size >= 32)
            Icon(
              icon,
              size: size * 0.26,
              color: iconColor,
            ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size >= 32 ? fontSize * 0.72 : fontSize * 0.88,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
