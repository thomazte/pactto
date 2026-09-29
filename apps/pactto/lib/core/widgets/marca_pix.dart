import 'dart:math' as math;

import 'package:flutter/material.dart';

class MarcaPix extends StatelessWidget {
  const MarcaPix({
    super.key,
    this.tamanho = 16,
    this.cor = const Color(0xFF32BCAD),
  });

  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(tamanho), painter: _PixPainter(cor));
  }
}

class _PixPainter extends CustomPainter {
  const _PixPainter(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = cor;
    final lado = size.shortestSide;
    canvas.translate(lado / 2, lado / 2);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawPath(
        Path()
          ..moveTo(0, -lado * 0.46)
          ..lineTo(lado * 0.18, -lado * 0.22)
          ..lineTo(0, -lado * 0.10)
          ..lineTo(-lado * 0.18, -lado * 0.22)
          ..close(),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PixPainter anterior) => anterior.cor != cor;
}
