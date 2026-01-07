import 'package:flutter/material.dart';

class KyteLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const KyteLogo({
    super.key,
    this.width = 100,
    this.height = 36,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: KyteLogoPainter(color: color),
      ),
    );
  }
}

class KyteLogoPainter extends CustomPainter {
  final Color color;
  static const double _vbW = 125;
  static const double _vbH = 42;

  KyteLogoPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vbW;
    final sy = size.height / _vbH;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.30435);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path p1 = Path()
      ..moveTo(38.215 * sx, 15.4471 * sy)
      ..lineTo(20.4166 * sx, 33.2484 * sy)
      ..lineTo(20.4122 * sx, 33.244 * sy)
      ..lineTo(20.4078 * sx, 33.2484 * sy)
      ..lineTo(2.60938 * sx, 15.4471 * sy)
      ..lineTo(11.5086 * sx, 6.54649 * sy)
      ..lineTo(20.4122 * sx, 15.4515 * sy)
      ..lineTo(29.3158 * sx, 6.54649 * sy)
      ..close();

    Path p2 = Path()
      ..moveTo(76.8529 * sx, 28.4342 * sy)
      ..lineTo(82.0344 * sx, 9.60344 * sy)
      ..lineTo(88.4419 * sx, 9.60344 * sy)
      ..lineTo(80.6105 * sx, 38.087 * sy)
      ..lineTo(74.2029 * sx, 38.087 * sy)
      ..lineTo(76.3783 * sx, 30.1749 * sy)
      ..lineTo(71.2364 * sx, 30.1749 * sy)
      ..lineTo(65.5012 * sx, 9.60344 * sy)
      ..lineTo(72.3043 * sx, 9.60344 * sy)
      ..close();

    Path p3 = Path()
      ..moveTo(49.9379 * sx, 17.5484 * sy)
      ..lineTo(56.7784 * sx, 9.60344 * sy)
      ..lineTo(65.1063 * sx, 9.60344 * sy)
      ..lineTo(57.1079 * sx, 18.8932 * sy)
      ..lineTo(65.7243 * sx, 30.1749 * sy)
      ..lineTo(57.7833 * sx, 30.1749 * sy)
      ..lineTo(49.9379 * sx, 19.9028 * sy)
      ..lineTo(49.9379 * sx, 30.1659 * sy)
      ..lineTo(43.6094 * sx, 30.1659 * sy)
      ..lineTo(43.6094 * sx, 4.06442 * sy)
      ..lineTo(49.9379 * sx, 2.08696 * sy)
      ..close();

    Path p4 = Path()
      ..moveTo(99.1993 * sx, 9.60344 * sy)
      ..lineTo(104.143 * sx, 9.60344 * sy)
      ..lineTo(104.143 * sx, 15.1419 * sy)
      ..lineTo(99.1993 * sx, 15.1419 * sy)
      ..lineTo(99.1993 * sx, 30.1749 * sy)
      ..lineTo(92.8709 * sx, 30.1749 * sy)
      ..lineTo(92.8709 * sx, 15.1419 * sy)
      ..lineTo(88.9156 * sx, 15.1419 * sy)
      ..lineTo(88.9156 * sx, 9.60344 * sy)
      ..lineTo(92.8709 * sx, 9.60344 * sy)
      ..lineTo(92.8709 * sx, 4.06498 * sy)
      ..lineTo(99.1993 * sx, 2.08696 * sy)
      ..close();

    Path p5 = Path()
      ..moveTo(120.351 * sx, 15.1419 * sy)
      ..lineTo(111.371 * sx, 15.1419 * sy)
      ..lineTo(111.371 * sx, 17.5155 * sy)
      ..lineTo(117.651 * sx, 17.5155 * sy)
      ..lineTo(116.344 * sx, 22.2628 * sy)
      ..lineTo(111.371 * sx, 22.2628 * sy)
      ..lineTo(111.371 * sx, 24.6364 * sy)
      ..lineTo(121.87 * sx, 24.6364 * sy)
      ..lineTo(120.346 * sx, 30.1749 * sy)
      ..lineTo(105.042 * sx, 30.1749 * sy)
      ..lineTo(105.042 * sx, 9.60344 * sy)
      ..lineTo(121.87 * sx, 9.60344 * sy)
      ..close();

    final shadowDy = 0.521739 * sy;

    void drawWithShadow(Path path) {
      canvas.save();
      canvas.translate(0, shadowDy);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
      canvas.drawPath(path, fillPaint);
    }

    drawWithShadow(p1);
    drawWithShadow(p2);
    drawWithShadow(p3);
    drawWithShadow(p4);
    drawWithShadow(p5);
  }

  @override
  bool shouldRepaint(covariant KyteLogoPainter oldDelegate) => oldDelegate.color != color;
}

