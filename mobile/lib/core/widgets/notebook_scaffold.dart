import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotebookScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showGrid;

  const NotebookScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: showGrid
          ? Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: NotebookGridPainter(),
                  ),
                ),
                body,
              ],
            )
          : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class NotebookGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEEEBE1)
      ..strokeWidth = 1;

    const gridSize = 24.0;

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw red notebook margin line on the left
    final marginPaint = Paint()
      ..color = const Color(0xFFFF8B8B).withValues(alpha: 0.45)
      ..strokeWidth = 1.5;

    const marginX = 80.0;
    if (size.width > 400) {
      canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
