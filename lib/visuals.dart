import 'dart:math';
import 'package:flutter/material.dart';
import 'game.dart';

// ------------------------------------------------------------------ ícones
const resIcon = {
  Res.gold: Icons.monetization_on,
  Res.wood: Icons.park,
  Res.stone: Icons.landscape,
  Res.crystal: Icons.diamond,
};
const resColor = {
  Res.gold: Color(0xFFFFC107),
  Res.wood: Color(0xFF66BB6A),
  Res.stone: Color(0xFFB0BEC5),
  Res.crystal: Color(0xFF4DD0E1),
};
const spellIcon = {
  Spell.meteor: Icons.local_fire_department,
  Spell.frost: Icons.ac_unit,
  Spell.storm: Icons.bolt,
};
const spellColor = {
  Spell.meteor: Color(0xFFFF7043),
  Spell.frost: Color(0xFF4DD0E1),
  Spell.storm: Color(0xFFFFEB3B),
};

final Map<String, TextPainter> _tpCache = {};

void drawIcon(Canvas c, IconData icon, Offset ctr, double size, Color color) {
  final key = '${icon.codePoint}|${size.round()}|${color.hashCode}';
  final tp = _tpCache.putIfAbsent(
      key,
      () => TextPainter(
          text: TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                  fontFamily: icon.fontFamily,
                  package: icon.fontPackage,
                  fontSize: size,
                  color: color)),
          textDirection: TextDirection.ltr)
        ..layout());
  tp.paint(c, ctr - Offset(tp.width / 2, tp.height / 2));
}

void drawText(Canvas c, String s, Offset ctr, double size,
    {Color color = Colors.white, FontWeight weight = FontWeight.bold}) {
  final key = 'T$s|${size.round()}|${color.hashCode}|$weight';
  final tp = _tpCache.putIfAbsent(
      key,
      () => TextPainter(
          text: TextSpan(
              text: s,
              style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
          textDirection: TextDirection.ltr)
        ..layout());
  tp.paint(c, ctr - Offset(tp.width / 2, tp.height / 2));
}

// -------------------------------------------------------- pincel relativo
class _S {
  _S(this.cv, this.o, this.r);
  final Canvas cv;
  final Offset o;
  final double r;
  static const _edge = Color(0xDD111111);

  Offset p(double x, double y) => Offset(o.dx + x * r, o.dy + y * r);
  Paint _fill(Color c) => Paint()..color = c;
  Paint get _stroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, r * .085)
    ..color = _edge
    ..strokeJoin = StrokeJoin.round;

  void shadow(double y, double w, double h) {
    cv.drawOval(
        Rect.fromCenter(center: p(0, y), width: w * r, height: h * r),
        Paint()..color = const Color(0x55000000));
  }

  void circle(double x, double y, double rad, Color c, {bool edge = true}) {
    cv.drawCircle(p(x, y), rad * r, _fill(c));
    if (edge) cv.drawCircle(p(x, y), rad * r, _stroke);
  }

  void oval(double x, double y, double w, double h, Color c, {bool edge = true}) {
    final rect = Rect.fromCenter(center: p(x, y), width: w * r, height: h * r);
    cv.drawOval(rect, _fill(c));
    if (edge) cv.drawOval(rect, _stroke);
  }

  void poly(List<double> xy, Color c, {bool edge = true}) {
    final first = p(xy[0], xy[1]);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 2; i < xy.length; i += 2) {
      final q = p(xy[i], xy[i + 1]);
      path.lineTo(q.dx, q.dy);
    }
    path.close();
    cv.drawPath(path, _fill(c));
    if (edge) cv.drawPath(path, _stroke);
  }

  void mirror(List<double> xy, Color c) {
    poly(xy, c);
    poly([
      for (var i = 0; i < xy.length; i += 2) ...[-xy[i], xy[i + 1]]
    ], c);
  }

  void line(double x1, double y1, double x2, double y2, Color c, [double w = .12]) {
    cv.drawLine(
        p(x1, y1),
        p(x2, y2),
        Paint()
          ..color = c
          ..strokeWidth = max(1.5, w * r)
          ..strokeCap = StrokeCap.round);
  }

  void ring(double x, double y, double w, double h, Color c, [double sw = .1]) {
    cv.drawOval(
        Rect.fromCenter(center: p(x, y), width: w * r, height: h * r),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, sw * r)
          ..color = c);
  }

  void eyes(double y, Color c, {double dx = .24, double rad = .09}) {
    circle(-dx, y, rad, c, edge: false);
    circle(dx, y, rad, c, edge: false);
  }
}

const _wood = Color(0xFF6D4C41);
const _steel = Color(0xFFB0BEC5);
const _skin = Color(0xFFF0C8A0);

// ------------------------------------------------------------------ TORRES
void drawTower(Canvas cv, TKind k, Offset o, double r, double t, {bool shadow = true}) {
  final s = _S(cv, o, r);
  if (shadow) s.shadow(.95, 2.2, .85);
  s.oval(0, .82, 1.9, .75, const Color(0xFF6E6760));
  s.oval(0, .72, 1.5, .55, const Color(0xFF9E958C), edge: false);
  final fl = sin(t * 9) * .12;
  switch (k) {
    case TKind.arrow:
      s.poly([-.48, .75, -.38, -.55, .38, -.55, .48, .75], const Color(0xFF8D6E63));
      s.poly([-.75, -.5, .75, -.5, 0, -1.42], const Color(0xFF2E7D32));
      s.circle(0, -.1, .17, const Color(0xFF3E2723));
      s.cv.drawArc(
          Rect.fromCenter(center: s.p(.8, -.05), width: r * .8, height: r * 1.4),
          -pi / 2,
          pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, r * .12)
            ..color = const Color(0xFFD7B98E));
      s.poly([0, -1.4, 0, -1.8, .48, -1.6], const Color(0xFFFFEB3B));
    case TKind.fire:
      s.poly([-.5, .75, -.4, -.35, .4, -.35, .5, .75], const Color(0xFF8E2B2B));
      s.oval(0, -.4, 1.25, .45, const Color(0xFF4E342E));
      s.poly([-.35, -.45, -.25, -1.0 - fl, 0, -.8, .18, -1.45 - fl, .35, -.45],
          const Color(0xFFFF6F00));
      s.poly([-.15, -.45, 0, -.95 - fl, .15, -.45], const Color(0xFFFFEB3B), edge: false);
    case TKind.frost:
      s.poly([-.45, .75, -.35, -.35, .35, -.35, .45, .75], const Color(0xFF4A78A8));
      s.poly([0, -1.75, .48, -.95, 0, -.3, -.48, -.95], const Color(0xFF80DEEA));
      s.line(0, -1.5, 0, -.5, Colors.white70, .06);
      s.circle(.55, -1.2 + fl, .09, Colors.white, edge: false);
    case TKind.bolt:
      s.poly([-.45, .75, -.35, -.3, .35, -.3, .45, .75], const Color(0xFF5E4B8B));
      s.line(-.55, -.1, .55, -.1, const Color(0xFFB39DDB), .1);
      s.circle(0, -.8, .58 + fl * .5, const Color(0x55FFEB3B), edge: false);
      s.circle(0, -.8, .38, const Color(0xFFFFEB3B));
      s.line(-.12, -1.0, .08, -.8, Colors.white, .07);
      s.line(.08, -.8, -.08, -.6, Colors.white, .07);
    case TKind.arcane:
      s.poly([-.38, .75, -.25, -.9, 0, -1.25, .25, -.9, .38, .75], const Color(0xFF4527A0));
      s.line(0, .5, 0, -.8, const Color(0xFFE040FB), .05);
      s.circle(0, -1.5 + fl * .6, .45, const Color(0x55E040FB), edge: false);
      s.circle(0, -1.5 + fl * .6, .28, const Color(0xFFE040FB));
      s.ring(0, -1.5 + fl * .6, 1.15, .42, const Color(0xAAB388FF), .06);
    case TKind.cannon:
      s.oval(0, .3, 1.6, 1.0, const Color(0xFF546E7A));
      s.poly([.1, -.1, 1.35, -.82, 1.55, -.4, .3, .35], const Color(0xFF37474F));
      s.circle(1.45, -.6, .22, const Color(0xFF111111));
      s.circle(-.45, .62, .38, const Color(0xFF5D4037));
      s.circle(-.45, .62, .13, _steel);
      s.circle(-.1, .15, .16, const Color(0xFF00E5FF), edge: false);
    case TKind.poison:
      s.oval(0, .25, 1.5, 1.2, const Color(0xFF263238));
      s.oval(0, -.2, 1.45, .5, const Color(0xFF455A64));
      s.oval(0, -.2, 1.1, .32, const Color(0xFF76FF03));
      s.circle(-.2, -.45 - fl, .13, const Color(0xFFB2FF59), edge: false);
      s.circle(.25, -.55 + fl, .1, const Color(0xFFB2FF59), edge: false);
      s.line(-.5, .8, -.6, 1.0, const Color(0xFF263238), .15);
      s.line(.5, .8, .6, 1.0, const Color(0xFF263238), .15);
    case TKind.golem:
      s.oval(-1.05, .15, .55, 1.05, const Color(0xFF616161));
      s.oval(1.05, .15, .55, 1.05, const Color(0xFF616161));
      s.oval(0, .3, 1.65, 1.4, const Color(0xFF757575));
      s.circle(0, -.64, .58, const Color(0xFF8D8D8D));
      s.eyes(-.64, const Color(0xFFFFEB3B), dx: .2, rad: .1);
      s.line(-.3, .1, -.1, .6, Colors.black54, .05);
      s.circle(0, .25, .2, const Color(0xFF00E5FF), edge: false);
    case TKind.ent:
      s.line(-.7, .3, -1.35, -.3, _wood, .16);
      s.line(.7, .3, 1.35, -.3, _wood, .16);
      s.circle(-1.4, -.35, .27, const Color(0xFF4CAF50));
      s.circle(1.4, -.35, .27, const Color(0xFF4CAF50));
      s.oval(0, .3, 1.5, 1.9, _wood);
      s.circle(-.6, -.7, .55, const Color(0xFF388E3C));
      s.circle(.6, -.7, .55, const Color(0xFF388E3C));
      s.circle(0, -1.0, .65, const Color(0xFF4CAF50));
      s.circle(0, -.5, .5, const Color(0xFF43A047));
      s.eyes(-.05, const Color(0xFFFFEB3B), rad: .12);
      s.line(-.25, .4, .25, .4, const Color(0xFF3E2723), .09);
    case TKind.shrine:
      s.poly([-.7, .75, -.5, -.05, .5, -.05, .7, .75], const Color(0xFFECE7DA));
      s.poly([-.25, -.05, -.2, -.9, .2, -.9, .25, -.05], const Color(0xFFD7CFBF));
      s.ring(0, -1.2, 1.0, .35, const Color(0xFFFFEB3B), .1);
      s.circle(0, -.55, .3 + fl * .3, const Color(0x6669F0AE), edge: false);
      s.line(0, -.72, 0, -.38, const Color(0xFF00C853), .1);
      s.line(-.17, -.55, .17, -.55, const Color(0xFF00C853), .1);
  }
}

// ---------------------------------------------------------------- INIMIGOS (estilo Sir, We Have an Orc Problem)
void drawEnemy(Canvas cv, EKind k, Offset o, double r, double t, {bool animate = true}) {
  final flying = especs[k]!.flying;
  final bob = animate ? (flying ? sin(t * 7) * .16 : sin(t * 11).abs() * -.14) : 0.0;
  final base = _S(cv, o, r);
  if (animate) {
    base.shadow(flying ? 1.15 : .85, flying ? 1.5 : 1.9, flying ? .5 : .7);
  }
  final s = _S(cv, o + Offset(0, bob * r), r);

  switch (k) {
    case EKind.orc:
      _cartoonOrc(s, const Color(0xFF5FA634), const Color(0xFF6D4C41), helmet: true, weapon: true);
    case EKind.goblin:
      s.oval(0, .48, 1.05, .85, const Color(0xFF5D4037));
      s.mirror([.5, -.28, 1.48, -.85, .45, .12], const Color(0xFF8BC34A));
      s.circle(0, -.18, .72, const Color(0xFF9CCC65));
      s.line(-.4, -.45, -.1, -.28, Colors.black87, .1);
      s.line(.4, -.45, .1, -.28, Colors.black87, .1);
      s.eyes(-.2, const Color(0xFFFF1744), rad: .13);
      s.line(.85, .6, 1.15, -.55, _steel, .1);
    case EKind.shaman:
      _cartoonOrc(s, const Color(0xFF689F38), const Color(0xFF512DA8));
      s.line(1.05, .9, 1.15, -1.15, _wood, .12);
      s.circle(1.15, -1.25, .28, const Color(0xFF76FF03));
      s.poly([-.58, -.72, -.35, -1.3, 0, -.95, .35, -1.3, .58, -.72], const Color(0xFFFF8F00));
    case EKind.kingOrc:
      s.poly([-1.0, -.3, 1.0, -.3, 1.3, 1.25, -1.3, 1.25], const Color(0xFFB71C1C));
      _cartoonOrc(s, const Color(0xFF3E8E29), const Color(0xFF4E342E), weapon: true);
      s.poly([-.55, -.8, -.55, -1.45, -.28, -1.08, 0, -1.55, .28, -1.08, .55, -1.45, .55, -.8],
          const Color(0xFFFFC107));
      s.circle(0, -1.0, .12, const Color(0xFFE53935), edge: false);
    case EKind.wolf:
      final stride = animate ? sin(t * 14) * .22 : 0.0;
      s.line(-.6, .55, -.6 - stride, 1.05, const Color(0xFF37474F), .15);
      s.line(.45, .55, .45 + stride, 1.05, const Color(0xFF37474F), .15);
      s.poly([-.9, .1, -1.6, -.35, -1.0, .4], const Color(0xFF455A64));
      s.oval(0, .25, 1.95, 1.0, const Color(0xFF546E7A));
      s.circle(.88, -.05, .52, const Color(0xFF607D8B));
      s.oval(1.32, .08, .62, .34, const Color(0xFF455A64));
      s.poly([.55, -.4, .7, -1.05, .95, -.4], const Color(0xFF455A64));
      s.circle(1.0, -.15, .1, const Color(0xFFFF1744), edge: false);
    case EKind.bat:
      final f = sin(t * 16) * .48;
      s.mirror([.2, 0, 1.65, -.65 + f, 1.3, .1, .9, .5, .2, .4], const Color(0xFF5E35B1));
      s.oval(0, .1, .72, .92, const Color(0xFF311B92));
      s.eyes(-.05, const Color(0xFFFF1744), dx: .15, rad: .09);
    case EKind.skeleton:
      s.oval(0, .5, .95, 1.1, const Color(0xFF263238));
      for (final y in [.2, .5, .8]) {
        s.line(-.4, y, .4, y, const Color(0xFFECEFF1), .09);
      }
      s.circle(0, -.3, .62, const Color(0xFFECEFF1));
      s.circle(-.22, -.3, .18, Colors.black);
      s.circle(.22, -.3, .18, Colors.black);
      s.circle(-.22, -.3, .06, const Color(0xFFFF5252), edge: false);
      s.circle(.22, -.3, .06, const Color(0xFFFF5252), edge: false);
      s.line(1.0, .9, 1.15, -.8, _steel, .11);
    case EKind.brute:
      s.oval(0, .48, 1.8, 1.25, const Color(0xFF4E342E));
      s.circle(-0.85, -.05, .36, const Color(0xFF78909C));
      s.circle(0.85, -.05, .36, const Color(0xFF78909C));
      s.circle(0, -.28, .72, const Color(0xFF689F38));
      s.line(-.45, -.52, -.1, -.36, Colors.black87, .12);
      s.line(.45, -.52, .1, -.36, Colors.black87, .12);
      s.eyes(-.25, const Color(0xFFFFEB3B), rad: .11);
      s.oval(0, -.68, 1.55, .64, const Color(0xFF78909C));
      s.mirror([.7, -.75, 1.28, -1.4, .5, -.95], Colors.white);
      s.circle(-1.05, .48, .6, const Color(0xFF8D6E63));
      s.circle(-1.05, .48, .22, _steel);
      s.line(1.05, -.85, .88, .9, _wood, .13);
      s.poly([1.05, -.95, 1.62, -.72, 1.5, -.1, 1.0, -.3], _steel);
    case EKind.wraith:
      s.poly([-.7, -.1, .7, -.1, .95, 1.0, .5, .65, .2, 1.1, -.2, .65, -.5, 1.1, -.95, 1.0],
          const Color(0xCC90CAF9));
      s.circle(0, -.2, .72, const Color(0xCCB3E5FC));
      s.circle(-.26, -.25, .17, Colors.black87, edge: false);
      s.circle(.26, -.25, .17, Colors.black87, edge: false);
      s.circle(-.26, -.25, .07, const Color(0xFF00E5FF), edge: false);
      s.circle(.26, -.25, .07, const Color(0xFF00E5FF), edge: false);
    case EKind.troll:
      _troll(s, const Color(0xFF5D7D53), const Color(0xFF759467));
    case EKind.elderTroll:
      _troll(s, const Color(0xFF455A64), const Color(0xFF546E7A));
      s.mirror([.35, -.85, .75, -1.6, .15, -.95], const Color(0xFFECEFF1));
      s.circle(-.55, .1, .18, const Color(0xFF00E5FF), edge: false);
      s.circle(.55, .3, .14, const Color(0xFF00E5FF), edge: false);
      s.circle(-1.0, -.05, .4, const Color(0xFF558B2F));
      s.circle(1.0, -.05, .4, const Color(0xFF558B2F));
    case EKind.dragon:
      final fd = sin(t * 5) * .5;
      s.poly([-.3, 0, -1.9, -1.3 + fd, -1.6, -.3, -1.3, .1, -.9, -.1], const Color(0xFFB71C1C));
      s.poly([.1, 0, 1.0, -1.5 + fd, .9, -.3, .5, -.1], const Color(0xFFB71C1C));
      s.poly([-.9, .4, -2.0, .85, -1.9, .5, -.9, .1], const Color(0xFF7F0000));
      s.oval(0, .3, 1.8, 1.1, const Color(0xFF8E1B1B));
      s.oval(0, .55, 1.0, .6, const Color(0xFFFFCC80));
      s.circle(.95, -.35, .52, const Color(0xFF7F0000));
      s.oval(1.4, -.25, .65, .38, const Color(0xFF8E1B1B));
      s.poly([.8, -.8, 1.0, -1.5, 1.15, -.75], const Color(0xFFFFE0B2));
      s.circle(1.05, -.5, .11, const Color(0xFFFFEB3B), edge: false);
      s.poly([1.7, -.35, 2.3, -.5, 2.0, -.2, 2.4, 0, 1.7, -.1],
          const Color(0xFFFF9800), edge: false);
  }
}

void _cartoonOrc(_S s, Color skin, Color cloth, {bool helmet = false, bool weapon = false}) {
  s.oval(0, .52, 1.42, 1.04, cloth);
  s.mirror([.58, -.25, 1.12, -.55, .55, .08], skin);
  s.circle(0, -.18, .76, skin);
  if (helmet) {
    s.oval(0, -.68, 1.32, .52, const Color(0xFF78909C));
    s.mirror([.52, -.7, .85, -1.15, .36, -.85], Colors.white);
  }
  s.line(-.46, -.48, -.1, -.33, Colors.black87, .12);
  s.line(.46, -.48, .1, -.33, Colors.black87, .12);
  s.eyes(-.22, const Color(0xFFFFEB3B), rad: .11);
  // Presas salientes estilo cartoon
  s.poly([-.34, .24, -.15, .24, -.24, -.06], Colors.white, edge: false);
  s.poly([.34, .24, .15, .24, .24, -.06], Colors.white, edge: false);
  if (weapon) {
    s.line(.95, .75, 1.15, -.65, _wood, .12);
    s.poly([1.02, -.68, 1.45, -.52, 1.38, -.1, 1.0, -.25], _steel);
  }
}

void _troll(_S s, Color body, Color head) {
  s.oval(0, .5, 1.98, 1.42, body);
  s.oval(0, .65, 1.1, .8, head, edge: false);
  s.circle(0, -.35, .68, head);
  s.eyes(-.38, const Color(0xFFFFEB3B), rad: .11);
  s.poly([-.3, .05, -.15, .05, -.22, -.2], Colors.white);
  s.poly([.3, .05, .15, .05, .22, -.2], Colors.white);
  s.line(1.15, -.9, .95, .95, _wood, .22);
  s.circle(1.15, -.95, .4, const Color(0xFF5D4037));
}

// ------------------------------------------------------------ ANÃO (mina)
void drawDwarf(Canvas cv, Offset o, double r, double t) {
  final s = _S(cv, o, r);
  final a = sin(t * 7) * .7;
  final tip = Offset(.55 + sin(a + .3) * 1.1, .2 - cos(a + .3) * 1.1);
  s.line(.55, .25, tip.dx, tip.dy, _wood, .1);
  s.poly([tip.dx - .45, tip.dy + .05, tip.dx + .45, tip.dy - .1, tip.dx + .4, tip.dy + .15],
      _steel);
  s.oval(0, .5, 1.5, 1.1, const Color(0xFF8D6E63));
  s.circle(0, -.3, .58, _skin);
  s.poly([-.55, -.1, .55, -.1, .45, .6, 0, .95, -.45, .6], const Color(0xFFE67E22));
  s.eyes(-.3, Colors.black87, rad: .07);
  s.oval(0, -.68, 1.2, .55, const Color(0xFFFFC107));
  s.circle(0, -.9, .13, Colors.white70, edge: false);
}

// ----------------------------------------------------------------- widgets
class SpriteIcon extends StatelessWidget {
  const SpriteIcon.tower(this.tower, {super.key, this.size = 44})
      : enemy = null,
        dwarf = false;
  const SpriteIcon.enemy(this.enemy, {super.key, this.size = 44})
      : tower = null,
        dwarf = false;
  const SpriteIcon.dwarf({super.key, this.size = 44})
      : tower = null,
        enemy = null,
        dwarf = true;
  final TKind? tower;
  final EKind? enemy;
  final bool dwarf;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SpritePainter(tower, enemy, dwarf)),
      );
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.t, this.e, this.d);
  final TKind? t;
  final EKind? e;
  final bool d;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (t != null) {
      drawTower(canvas, t!, c + Offset(0, size.height * .05), size.width * .26, 0, shadow: false);
    }
    if (e != null) {
      drawEnemy(canvas, e!, c, size.width * .22, 0, animate: false);
    }
    if (d) drawDwarf(canvas, c, size.width * .26, 0);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.t != t || old.e != e || old.d != d;
}

/// Cena animada de cada local de mineração.
class MineScenePainter extends CustomPainter {
  MineScenePainter(this.g, this.i, {this.compact = false}) : super(repaint: g);
  final Game g;
  final int i;
  final bool compact;

  @override
  void paint(Canvas c, Size size) {
    final site = g.sites[i];
    final w = size.width, h = size.height;
    final bg = switch (site.res) {
      Res.gold => const [Color(0xFF4E342E), Color(0xFF2B1B16)],
      Res.wood => const [Color(0xFF2E5E34), Color(0xFF173A20)],
      Res.stone => const [Color(0xFF455A64), Color(0xFF1F2A30)],
      Res.crystal => const [Color(0xFF1A237E), Color(0xFF0B0F3A)],
    };
    c.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bg)
              .createShader(Offset.zero & size));

    final rnd = Random(i * 31 + 7);
    final props = compact ? 5 : 9;
    for (var k = 0; k < props; k++) {
      final x = rnd.nextDouble() * w, y = h * (.15 + rnd.nextDouble() * .52);
      switch (site.res) {
        case Res.gold:
          c.drawCircle(Offset(x, y), compact ? 3 : 4 + rnd.nextDouble() * 4,
              Paint()..color = const Color(0xFFFFC107));
        case Res.wood:
          c.drawRect(
              Rect.fromCenter(
                  center: Offset(x, y + 6), width: compact ? 4 : 6, height: compact ? 12 : 24),
              Paint()..color = const Color(0xFF5D4037));
          c.drawCircle(Offset(x, y - 4), compact ? 7 : 14,
              Paint()..color = const Color(0xFF2E7D32));
        case Res.stone:
          c.drawOval(
              Rect.fromCenter(
                  center: Offset(x, y), width: compact ? 12 : 22, height: compact ? 8 : 14),
              Paint()..color = const Color(0xFF90A4AE));
        case Res.crystal:
          final sc = compact ? .55 : 1.0;
          final p = Path()
            ..moveTo(x, y - 18 * sc)
            ..lineTo(x + 8 * sc, y)
            ..lineTo(x, y + 8 * sc)
            ..lineTo(x - 8 * sc, y)
            ..close();
          c.drawPath(p, Paint()..color = const Color(0xFF4DD0E1).withValues(alpha: .75));
      }
    }
    c.drawRect(Rect.fromLTWH(0, h * .80, w, h * .20), Paint()..color = const Color(0xAA000000));
    if (site.workers == 0) {
      drawText(c, compact ? '0' : 'Sem anões', Offset(w / 2, h * .48), compact ? 11 : 16,
          color: Colors.white60);
      return;
    }
    final shown = compact ? min(2, site.workers) : site.workers;
    for (var k = 0; k < shown; k++) {
      final x = compact ? w * (.30 + .38 * k) : w * (.14 + .17 * k);
      drawDwarf(c, Offset(x, h * .64), h * (compact ? .24 : .17), g.time + k * .8);
      final pop = (g.time * .85 + k * .3) % 1.0;
      drawIcon(
          c,
          resIcon[site.res]!,
          Offset(x + (compact ? 4 : 8), h * .34 - pop * h * .2),
          compact ? 12 : 18,
          resColor[site.res]!.withValues(alpha: 1 - pop));
    }
  }

  @override
  bool shouldRepaint(covariant MineScenePainter old) => true;
}
