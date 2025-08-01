import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class CircleNavBar extends StatefulWidget {
  const CircleNavBar({
    required this.activeIndex,
    this.onTap,
    this.tabCurve = Curves.easeOutCirc,
    this.iconCurve = Curves.easeOutCubic,
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
    this.blurSigmaX = 10,
    this.blurSigmaY = 10,
    this.backgroundOpacity = .2,
    this.borderColor,
    this.borderWidth = 2.0,
  })  : assert(circleWidth <= height, "circleWidth <= height"),
        assert(activeIcons.length == inactiveIcons.length,
            "activeIcons.length and inactiveIcons.length must be equal!"),
        assert(activeIcons.length > activeIndex,
            "activeIcons.length > activeIndex"),
        super();

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

  final double blurSigmaX;
  final double blurSigmaY;
  final double backgroundOpacity;
  final Color? borderColor;
  final double borderWidth;

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
      duration: Duration(milliseconds: widget.tabDurationMillSec),
    )
      ..addListener(() => setState(() {}))
      ..value = getPosition(widget.activeIndex);

    activeIconAc = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.iconDurationMillSec),
    )
      ..addListener(() => setState(() {}))
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant CircleNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      final nextPos = getPosition(widget.activeIndex);
      tabAc
        ..stop()
        ..animateTo(nextPos, curve: widget.tabCurve);
      activeIconAc
        ..reset()
        ..animateTo(1, curve: widget.iconCurve);
    }
  }

  double getPosition(int i) {
    final itemCnt = widget.activeIcons.length;
    return i / itemCnt + (1 / itemCnt) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: widget.padding,
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: widget.cornerRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: widget.cornerRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurSigmaX,
                  sigmaY: widget.blurSigmaY,
                ),
                child: Container(
                  color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: _CircleBottomPainter(
              iconWidth: widget.circleWidth,
              color: widget.color,
              circleColor: widget.circleColor ?? widget.color,
              xOffsetPercent: tabAc.value,
              cornerRadius: widget.cornerRadius,
              elevation: widget.elevation,
              gradient: widget.gradient,
              circleGradient: widget.circleGradient ?? widget.gradient,
              borderColor: widget.borderColor ??
                  Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withOpacity(0.3),
              borderWidth: widget.borderWidth,
            ),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
            ),
          ),
          Row(
            children: widget.inactiveIcons.map((e) {
              final idx = widget.inactiveIcons.indexOf(e);
              final isActive = widget.activeIndex == idx;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onTap?.call(idx),
                  child: Column(
                    mainAxisAlignment:
                        widget.levels != null && idx < widget.levels!.length
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.center,
                    children: [
                      if (!isActive) e,
                      if (widget.levels != null && idx < widget.levels!.length)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 5.0, bottom: 5.0),
                          child: Text(
                            widget.levels![idx],
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
    required this.cornerRadius,
    required this.elevation,
    this.gradient,
    this.circleGradient,
    required this.borderColor,
    required this.borderWidth,
  });

  final Color color;
  final Color circleColor;
  final double iconWidth;
  final double xOffsetPercent;
  final BorderRadius cornerRadius;
  final double elevation;
  final Gradient? gradient;
  final Gradient? circleGradient;
  final Color borderColor;
  final double borderWidth;

  static double getR(double circleWidth) => circleWidth / 2 * 1.2;
  static double convertRadiusToSigma(double radius) =>
      radius * 0.57735 + 1.5;

  static Rect _getGradientRect(Size size,
      {bool isCircle = false, Offset? center, double scale = 1.0}) {
    if (isCircle && center != null) {
      return Rect.fromCircle(
        center: center,
        radius: math.max(size.width, size.height) * scale / 2,
      );
    }
    final w = size.width * scale, h = size.height * scale;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: w,
      height: h,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final x = xOffsetPercent * w;
    final r = getR(iconWidth);

    final tl = math.max(cornerRadius.topLeft.x, cornerRadius.topLeft.y);
    final tr = math.max(cornerRadius.topRight.x, cornerRadius.topRight.y);
    final br = math.max(cornerRadius.bottomRight.x, cornerRadius.bottomRight.y);
    final bl = math.max(cornerRadius.bottomLeft.x, cornerRadius.bottomLeft.y);

    final path = Path()
      ..moveTo(0, tl)
      ..arcTo(Rect.fromLTWH(0, 0, tl * 2, tl * 2), math.pi, math.pi / 2, false)
      ..lineTo(w - tr, 0)
      ..arcTo(Rect.fromLTWH(w - tr * 2, 0, tr * 2, tr * 2), -math.pi / 2,
          math.pi / 2, false)
      ..lineTo(w, h - br)
      ..arcTo(Rect.fromLTWH(w - br * 2, h - br * 2, br * 2, br * 2), 0,
          math.pi / 2, false)
      ..lineTo(bl, h)
      ..arcTo(Rect.fromLTWH(0, h - bl * 2, bl * 2, bl * 2), math.pi / 2,
          math.pi / 2, false)
      ..close()
      ..addOval(Rect.fromCircle(center: Offset(x, h / 2), radius: r * 1.15))
      ..fillType = PathFillType.evenOdd;

    final paint = Paint()..color = color;
    if (gradient != null) {
      paint.shader = gradient!.createShader(_getGradientRect(size));
    }

    Paint? circlePaint;
    if (circleColor != color || circleGradient != null) {
      circlePaint = Paint()..color = circleColor;
      if (circleGradient != null) {
        circlePaint.shader = circleGradient!.createShader(
          _getGradientRect(
            Size(r * 2, r * 2),
            isCircle: true,
            center: Offset(x, h / 2),
          ),
        );
      }
    }

    canvas.drawPath(path, paint);

    final circleFill = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, h / 2), radius: r));
    canvas.drawPath(circleFill, circlePaint ?? paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, borderPaint);
    canvas.drawPath(circleFill, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CircleBottomPainter old) =>
      old.color != color ||
      old.circleColor != circleColor ||
      old.xOffsetPercent != xOffsetPercent ||
      old.cornerRadius != cornerRadius ||
      // old.shadowColor != shadowColor ||
      // old.circleShadowColor != circleShadowColor ||
      old.elevation != elevation ||
      old.gradient != gradient ||
      old.circleGradient != circleGradient ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}
