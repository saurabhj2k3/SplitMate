import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final double fontSize;

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 36,
    this.fontSize = 14,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getBackgroundColor(String name) {
    final colors = [
      const Color(0xFF176B5B), // Deep Teal
      const Color(0xFF2E6F40), // Forest Green
      const Color(0xFF2C5E7A), // Steel Blue
      const Color(0xFF6B4E71), // Plum
      const Color(0xFF8C5E32), // Warm Amber
      const Color(0xFF4A6B62), // Sage
    ];
    final hash = name.codeUnits.fold(0, (sum, char) => sum + char);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final bg = _getBackgroundColor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: bg.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
