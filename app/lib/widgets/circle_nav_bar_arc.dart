import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircleNavBar extends StatefulWidget {
  const CircleNavBar({
    required this.activeIndex,
    this.onTap,
    this.tabCurve = Curves.linearToEaseOut,
    this.iconCurve = Curves.linear,
    this.tabDurationMillSec = 500,
    this.iconDurationMillSec = 150,
    required this.activeIcons,
    required this.inactiveIcons,
    this.circleWidth = 60,
    required this.color,
    this.height = 75,
    this.circleColor,
    this.padding = EdgeInsets.zero,
    this.cornerRadius = BorderRadius.zero,
    this.shadowColor = Colors.transparent,
    this.circleShadowColor = Colors.transparent,
    this.elevation = 0,
    this.gradient,
    this.circleGradient,
    this.levels,
    this.activeLevelsStyle,
    this.inactiveLevelsStyle,
  })  : assert(circleWidth <= height, "circleWidth <= height"),
        assert(activeIcons.length == inactiveIcons.length,
            "activeIcons.length and inactiveIcons.length must be equal!"),
        assert(activeIcons.length > activeIndex,
            "activeIcons.length > activeIndex");

  final double height;
  final double circleWidth;
  final Color color;
  final Color? circleColor;
  final List<Widget> activeIcons;
  final List<Widget> inactiveIcons;
  final EdgeInsets padding;
  final BorderRadius cornerRadius;
  final Color shadowColor;
  final Color? circleShadowColor;
  final double elevation;
  final Gradient? gradient;
  final Gradient? circleGradient;
  final int activeIndex;
  final Curve tabCurve;
  final Curve iconCurve;
  final int tabDurationMillSec;
  final int iconDurationMillSec;
  final Function(int index)? onTap;
  final List<String>? levels;
  final TextStyle? activeLevelsStyle;
  final TextStyle? inactiveLevelsStyle;

  @override
  State<StatefulWidget> createState() => _CircleNavBarState();
}

class _CircleNavBarState extends State<CircleNavBar>
    with TickerProviderStateMixin {
  late AnimationController tabAc;
  late AnimationController activeIconAc;

  @override
  void initState() {
    super.initState();
    tabAc = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.tabDurationMillSec))
      ..addListener(() => setState(() {}))
      ..value = getPosition(widget.activeIndex);
    activeIconAc = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.iconDurationMillSec))
      ..addListener(() => setState(() {}))
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant CircleNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animation();
  }

  void _animation() {
    final nextPosition = getPosition(widget.activeIndex);
    tabAc.stop();
    tabAc.animateTo(nextPosition, curve: widget.tabCurve);
    activeIconAc.reset();
    activeIconAc.animateTo(1, curve: widget.iconCurve);
  }

  double getPosition(int i) {
    int itemCnt = widget.activeIcons.length;
    return i / itemCnt + (1 / itemCnt) / 2;
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: widget.padding,
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          CustomPaint(
            painter: _CircleBottomPainter(
              iconWidth: widget.circleWidth,
              color: widget.color,
              circleColor: widget.circleColor ?? widget.color,
              xOffsetPercent: tabAc.value,
              boxRadius: widget.cornerRadius,
              shadowColor: widget.shadowColor,
              circleShadowColor: widget.circleShadowColor ?? widget.shadowColor,
              elevation: widget.elevation,
              gradient: widget.gradient,
              circleGradient: widget.circleGradient ?? widget.gradient,
            ),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
            ),
          ),
          Row(
            children: widget.inactiveIcons.map((e) {
              int currentIndex = widget.inactiveIcons.indexOf(e);
              bool isActive = widget.activeIndex == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onTap?.call(currentIndex),
                  child: Column(
                    mainAxisAlignment: widget.levels != null &&
                            currentIndex < widget.levels!.length
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.center,
                    children: [
                      if (!isActive) e,
                      if (widget.levels != null &&
                          currentIndex < widget.levels!.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                          child: Text(
                            widget.levels![currentIndex],
                            style: isActive
                                ? widget.activeLevelsStyle
                                : widget.inactiveLevelsStyle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          Positioned(
            left: tabAc.value * deviceWidth -
                widget.circleWidth / 2 -
                tabAc.value * (widget.padding.left + widget.padding.right),
            top: (widget.height - widget.circleWidth) / 2,
            child: Opacity(
              opacity: activeIconAc.value,
              child: SizedBox(
                width: widget.circleWidth,
                height: widget.circleWidth,
                child: widget.activeIcons[widget.activeIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tabAc.dispose();
    activeIconAc.dispose();
    super.dispose();
  }
}

class _CircleBottomPainter extends CustomPainter {
  _CircleBottomPainter({
    required this.iconWidth,
    required this.color,
    required this.circleColor,
    required this.xOffsetPercent,
    required this.boxRadius,
    required this.shadowColor,
    required this.circleShadowColor,
    required this.elevation,
    this.gradient,
    this.circleGradient,
  });

  final Color color;
  final Color circleColor;
  final double iconWidth;
  final double xOffsetPercent;
  final BorderRadius boxRadius;
  final Color shadowColor;
  final Color circleShadowColor;
  final double elevation;
  final Gradient? gradient;
  final Gradient? circleGradient;

  static double getR(double circleWidth) {
    return circleWidth / 2 * 1.1;
  }

  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h / 2;
    final r = getR(iconWidth);
    final x = xOffsetPercent * w;
    final radius = r * 1.1;

    final backgroundPath = Path()
      ..moveTo(0, boxRadius.topLeft.y)
      ..quadraticBezierTo(0, 0, boxRadius.topLeft.x, 0)
      ..lineTo(w - boxRadius.topRight.x, 0)
      ..quadraticBezierTo(w, 0, w, boxRadius.topRight.y)
      ..lineTo(w, h - boxRadius.bottomRight.y)
      ..quadraticBezierTo(w, h, w - boxRadius.bottomRight.x, h)
      ..lineTo(boxRadius.bottomLeft.x, h)
      ..quadraticBezierTo(0, h, 0, h - boxRadius.bottomLeft.y)
      ..close();

    backgroundPath.addOval(
      Rect.fromCircle(
        center: Offset(x, centerY),
        radius: radius,
      ),
    );
    
    backgroundPath.fillType = PathFillType.evenOdd;

    // 影の描画
    if (elevation > 0) {
      canvas.drawPath(
        backgroundPath,
        Paint()
          ..color = shadowColor
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, convertRadiusToSigma(elevation))
      );
    }

    // 背景を描画
    final backgroundPaint = Paint()..color = color;
    if (gradient != null) {
      backgroundPaint.shader = gradient!.createShader(
        Rect.fromLTWH(0, 0, w, h)
      );
    }
    canvas.drawPath(backgroundPath, backgroundPaint);

    // 円形部分を描画
    final circlePaint = Paint()..color = circleColor;
    if (circleGradient != null) {
      circlePaint.shader = circleGradient!.createShader(
        Rect.fromCircle(
          center: Offset(x, centerY),
          radius: r,
        ),
      );
    }

    if (elevation > 0) {
      canvas.drawCircle(
        Offset(x, centerY),
       r,
        Paint()
          ..color = circleShadowColor
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, convertRadiusToSigma(elevation))
      );
    }

    canvas.drawCircle(
      Offset(x, centerY),
     r,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(_CircleBottomPainter oldDelegate) => 
    oldDelegate.color != color ||
    oldDelegate.circleColor != circleColor ||
    oldDelegate.iconWidth != iconWidth ||
    oldDelegate.xOffsetPercent != xOffsetPercent ||
    oldDelegate.boxRadius != boxRadius ||
    oldDelegate.shadowColor != shadowColor ||
    oldDelegate.circleShadowColor != circleShadowColor ||
    oldDelegate.elevation != elevation ||
    oldDelegate.gradient != gradient ||
    oldDelegate.circleGradient != circleGradient;
}
