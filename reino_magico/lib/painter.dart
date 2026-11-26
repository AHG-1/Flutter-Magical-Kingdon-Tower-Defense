import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'game.dart';
import 'visuals.dart';

class BoardPainter extends CustomPainter {
  BoardPainter(this.g) : super(repaint: g);
  final Game g;

  ui.Picture? _terrain;
  Size? _tSize;
  bool? _tHc;

  // ---------------------------------------------------------------- terreno
  void _drawTerrain(Canvas c, Size size, bool hc) {
    final t = min(size.width / cols, size.height / rows);
    final ox = (size.width - t * cols) / 2, oy = (size.height - t * rows) / 2;
    c.drawRect(Offset.zero & size, Paint()..color = hc ? Colors.black : const Color(0xFF0F1A12));
    Rect tile(int x, int y) => Rect.fromLTWH(ox + x * t, oy + y * t, t, t);

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final h = Game.hash(x, y);
        final r = tile(x, y);
        if (g.isPath(x, y)) {
          c.drawRect(r, Paint()..color = hc ? Colors.white : (h % 2 == 0 ? const Color(0xFFB69362) : const Color(0xFFAE8B5A)));
          // bordas onde a trilha encontra a grama
          final edge = Paint()
            ..color = hc ? Colors.black : const Color(0xFF6F5530)
            ..strokeWidth = max(2.0, t * .06);
          if (y == 0 || !g.isPath(x, y - 1)) c.drawLine(r.topLeft, r.topRight, edge);
          if (y == rows - 1 || !g.isPath(x, y + 1)) c.drawLine(r.bottomLeft, r.bottomRight, edge);
          if (x == 0 || !g.isPath(x - 1, y)) c.drawLine(r.topLeft, r.bottomLeft, edge);
          if (x == cols - 1 || !g.isPath(x + 1, y)) c.drawLine(r.topRight, r.bottomRight, edge);
          if (!hc && h % 5 == 0) {
            c.drawCircle(r.topLeft + Offset(t * ((h >> 3) % 80 / 100 + .1), t * ((h >> 7) % 80 / 100 + .1)),
                t * .04, Paint()..color = const Color(0xFF8A6D43));
          }
        } else {
          final base = hc
              ? (h % 2 == 0 ? const Color(0xFF000000) : const Color(0xFF101010))
              : [const Color(0xFF3F7D40), const Color(0xFF3A7439), const Color(0xFF448545)][h % 3];
          c.drawRect(r, Paint()..color = base);
          if (!hc && h % 4 == 0) {
            final p = Paint()
              ..color = const Color(0xFF2D5E30)
              ..strokeWidth = 1.5;
            final b = r.topLeft + Offset(t * .3 + (h % 40) / 100 * t, t * .6);
            c.drawLine(b, b + Offset(-t * .05, -t * .14), p);
            c.drawLine(b, b + Offset(t * .05, -t * .16), p);
          }
          if (!hc && h % 11 == 0) {
            c.drawCircle(r.center + Offset(t * .18, t * .15), t * .05,
                Paint()..color = [Colors.pinkAccent, Colors.yellowAccent, Colors.white][h % 3]);
          }
          if (g.isScenery(x, y)) _scenery(c, r, h, hc);
        }
        c.drawRect(r, Paint()
          ..style = PaintingStyle.stroke
          ..color = hc ? Colors.white24 : const Color(0x14000000));
      }
    }
    c.drawRect(Rect.fromLTWH(ox, oy, t * cols, t * rows), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = hc ? Colors.white : const Color(0xFF2B1B4D));
  }

  void _scenery(Canvas c, Rect r, int h, bool hc) {
    final t = r.width, ctr = r.center;
    if (h % 3 == 0) {
      // rocha
      c.drawOval(Rect.fromCenter(center: ctr + Offset(0, t * .1), width: t * .7, height: t * .45),
          Paint()..color = hc ? Colors.white : const Color(0xFF8D8D8D));
      c.drawOval(Rect.fromCenter(center: ctr + Offset(-t * .1, t * .02), width: t * .4, height: t * .3),
          Paint()..color = hc ? Colors.grey : const Color(0xFFAAAAAA));
    } else {
      // árvore
      c.drawRect(Rect.fromCenter(center: ctr + Offset(0, t * .25), width: t * .14, height: t * .3),
          Paint()..color = const Color(0xFF5D4037));
      for (final o in [const Offset(-.2, -.02), const Offset(.2, -.02), const Offset(0, -.2), const Offset(0, .05)]) {
        c.drawCircle(ctr + Offset(o.dx * t, o.dy * t), t * .22,
            Paint()..color = hc ? Colors.white : (o.dy < 0 ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20)));
      }
    }
  }

  // ------------------------------------------------------------------ barras
  void _bar(Canvas c, Offset center, double w, double h, double frac, {Color? fill}) {
    final f = frac.clamp(0.0, 1.0);
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    c.drawRRect(rr, Paint()..color = const Color(0xDD000000));
    final col = fill ??
        (f > .5
            ? Color.lerp(Colors.yellow, Colors.greenAccent, (f - .5) * 2)!
            : Color.lerp(Colors.redAccent, Colors.yellow, f * 2)!);
    if (f > 0) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left + 1, rect.top + 1, (w - 2) * f, h - 2), Radius.circular(h / 2)),
          Paint()..color = col);
    }
    c.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = g.highContrast ? Colors.white : Colors.white70);
  }

  // ------------------------------------------------------------------- pintura
  @override
  void paint(Canvas canvas, Size size) {
    final hc = g.highContrast;
    if (_terrain == null || _tSize != size || _tHc != hc) {
      final rec = ui.PictureRecorder();
      _drawTerrain(Canvas(rec), size, hc);
      _terrain = rec.endRecording();
      _tSize = size;
      _tHc = hc;
    }
    canvas.drawPicture(_terrain!);

    final t = min(size.width / cols, size.height / rows);
    final ox = (size.width - t * cols) / 2, oy = (size.height - t * rows) / 2;
    Offset p(double x, double y) => Offset(ox + (x + .5) * t, oy + (y + .5) * t);
    Rect tile(int x, int y) => Rect.fromLTWH(ox + x * t, oy + y * t, t, t);

    // portal
    final po = p(Game.portal.x.toDouble(), Game.portal.y.toDouble());
    canvas.drawCircle(po, t * .5, Paint()..color = const Color(0xFF2B0F4D));
    for (var i = 0; i < 3; i++) {
      final a = g.time * (1.5 + i * .6) * (i.isEven ? 1 : -1);
      canvas.drawArc(Rect.fromCircle(center: po, radius: t * (.18 + i * .11)), a, 4.2, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, t * .06)
            ..color = [const Color(0xFFE040FB), const Color(0xFFB388FF), const Color(0xFF7C4DFF)][i]);
    }
    // cidadela
    final co = p(Game.castle.x.toDouble(), Game.castle.y.toDouble());
    final cr = Rect.fromCenter(center: co, width: t * .9, height: t * .9);
    canvas.drawRRect(RRect.fromRectAndRadius(cr, Radius.circular(t * .1)),
        Paint()..color = hc ? Colors.white : const Color(0xFF8A8FA3));
    for (var i = -1; i <= 1; i++) {
      canvas.drawRect(Rect.fromCenter(center: co + Offset(i * t * .3, -t * .5), width: t * .2, height: t * .2),
          Paint()..color = hc ? Colors.white : const Color(0xFF8A8FA3));
    }
    canvas.drawCircle(co, t * (.2 + .03 * sin(g.time * 3)), Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(co, t * .3, Paint()..color = const Color(0x4400E5FF));
    _bar(canvas, co + Offset(0, -t * .78), t * .9, max(7.0, t * .12), g.lives / 20, fill: Colors.cyanAccent);

    // anel de alcance
    final focus = g.selected ?? g.towerAt(g.cx, g.cy);
    double? range;
    Offset? ringAt;
    if (g.menuOpen) {
      range = specs[TKind.values[g.buildIdx]]!.range;
      ringAt = p(g.cx.toDouble(), g.cy.toDouble());
    } else if (focus != null && g.armed == null) {
      range = g.rangeOf(focus);
      ringAt = p(focus.x, focus.y);
    }
    if (range != null && range > 0 && ringAt != null) {
      canvas.drawCircle(ringAt, range * t, Paint()..color = Colors.white.withValues(alpha: .1));
      canvas.drawCircle(ringAt, range * t, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = hc ? Colors.white : Colors.white60);
    }

    // torres
    final ts = [...g.towers]..sort((a, b) => a.y.compareTo(b.y));
    for (final tw in ts) {
      final c = p(tw.x, tw.y);
      final moving = tw.moving;
      if (moving) canvas.saveLayer(null, Paint()..color = const Color(0x88FFFFFF));
      drawTower(canvas, tw.kind, c, t * .33, g.time);
      if (moving) canvas.restore();
      for (var i = 0; i < tw.level; i++) {
        canvas.drawCircle(c + Offset((i - (tw.level - 1) / 2) * t * .14, t * .5), t * .045,
            Paint()..color = const Color(0xFFFFD54F));
      }
      _bar(canvas, c + Offset(0, -t * .62), t * .75, max(6.0, t * .1), tw.hp / tw.maxHp);
      if (tw == g.selected) {
        canvas.drawCircle(c, t * .5, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.white);
      }
    }

    // inimigos
    for (final e in g.enemies) {
      final c = p(e.pos.dx, e.pos.dy);
      final r = e.spec.size * t;
      drawEnemy(canvas, e.kind, c, r, g.time + e.off * 9);
      if (e.slowT > 0) canvas.drawCircle(c, r * 1.1, Paint()..color = const Color(0x554DD0E1));
      if (e.poisonT > 0) canvas.drawCircle(c, r * 1.1, Paint()..color = const Color(0x5576FF03));
      if (e.flash > 0) canvas.drawCircle(c, r * 1.1, Paint()..color = Colors.white.withValues(alpha: .55));
      if (e.spec.boss) {
        _bar(canvas, c + Offset(0, -r * 1.9), t * 1.5, 11, e.hp / e.maxHp);
      } else if (e.hp < e.maxHp) {
        _bar(canvas, c + Offset(0, -r * 1.5), max(14.0, r * 1.5), max(3.5, r * .25), e.hp / e.maxHp);
      }
    }

    // meteoros a caminho
    for (final im in g.impacts) {
      final c = p(im.pos.dx, im.pos.dy);
      final prog = 1 - im.delay / im.total;
      final r = spellRadius[Spell.meteor]! * (1 + .25 * g.lv('msplash')) * t;
      canvas.drawCircle(c, r, Paint()..color = Colors.redAccent.withValues(alpha: .12 + .1 * sin(g.time * 18)));
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.redAccent);
      final mp = c + Offset(-t * 1.2, -t * 3.5) * (1 - prog);
      canvas.drawLine(mp, mp + Offset(t * .5, t * 1.2), Paint()
        ..color = const Color(0xAAFF9800)
        ..strokeWidth = t * .2
        ..strokeCap = StrokeCap.round);
      canvas.drawCircle(mp, t * .25, Paint()..color = const Color(0xFFFF6D00));
      canvas.drawCircle(mp, t * .13, Paint()..color = const Color(0xFFFFEB3B));
    }

    // tiros e efeitos
    for (final s in g.shots) {
      final a = p(s.from.dx, s.from.dy), b = p(s.to.dx, s.to.dy);
      final k = (s.life / s.total).clamp(0.0, 1.0);
      if ((a - b).distance > 1) {
        canvas.drawLine(a, b, Paint()
          ..color = s.color
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
      }
      if (s.splash > 0) {
        canvas.drawCircle(b, s.splash * t * (1.15 - .15 * k), Paint()..color = s.color.withValues(alpha: .28 * k));
        canvas.drawCircle(b, s.splash * t * (1.15 - .15 * k), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = s.color.withValues(alpha: .8 * k));
      }
    }

    final cp = p(g.cx.toDouble(), g.cy.toDouble());

    // feitiço armado: mostra a área
    final sp = g.armed;
    if (sp != null) {
      final r = spellRadius[sp]! * (1 + .25 * g.lv('msplash')) * t;
      final col = spellColor[sp]!;
      canvas.drawCircle(cp, r, Paint()..color = col.withValues(alpha: .18 + .06 * sin(g.time * 8)));
      canvas.drawCircle(cp, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = col);
      drawIcon(canvas, spellIcon[sp]!, cp, t * .6, col);
    }

    // pré-visualização do que será colocado
    if (g.menuOpen) {
      canvas.saveLayer(null, Paint()..color = const Color(0x99FFFFFF));
      drawTower(canvas, TKind.values[g.buildIdx], cp, t * .33, g.time);
      canvas.restore();
    }
    final sel = g.selected;
    if (sel != null) {
      final ok = g.canPlace(sel.kind, g.cx, g.cy, ignore: sel);
      canvas.drawRect(tile(g.cx, g.cy), Paint()..color = (ok ? Colors.greenAccent : Colors.redAccent).withValues(alpha: .35));
      drawIcon(canvas, ok ? Icons.check_circle : Icons.cancel, cp, t * .55, Colors.white);
    }

    // cursor
    canvas.drawRect(tile(g.cx, g.cy).deflate(1), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hc ? 6 : 4
      ..color = hc ? Colors.cyanAccent : Colors.yellowAccent);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
