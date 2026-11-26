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

  // ---------------------------------------------------------------- terreno estilo diorama
  void _drawTerrain(Canvas c, Size size, bool hc) {
    final t = min(size.width / cols, size.height / rows);
    final ox = (size.width - t * cols) / 2, oy = (size.height - t * rows) / 2;
    final boardRect = Rect.fromLTWH(ox, oy, t * cols, t * rows);
    Offset p(double x, double y) => Offset(ox + (x + .5) * t, oy + (y + .5) * t);
    Rect tile(int x, int y) => Rect.fromLTWH(ox + x * t, oy + y * t, t, t);

    // Fundo externo escuro da floresta
    c.drawRect(Offset.zero & size, Paint()..color = hc ? Colors.black : const Color(0xFF0E1B11));

    // Gramado vivo estilo "Sir, We Have an Orc Problem" (sem grades quadriculadas)
    c.save();
    c.clipRect(boardRect);
    c.drawRect(
        boardRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hc
                ? const [Colors.black, Color(0xFF101010)]
                : const [Color(0xFF47883E), Color(0xFF397434), Color(0xFF2E632B)],
          ).createShader(boardRect));

    // Manchas orgânicas de relva e flores no vale
    if (!hc) {
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < cols; x++) {
          final h = Game.hash(x, y);
          final ctr = p(x.toDouble(), y.toDouble());
          if (h % 3 == 0) {
            c.drawCircle(
                ctr + Offset(((h % 19) - 9) * t * .03, ((h % 13) - 6) * t * .03),
                t * .65,
                Paint()..color = const Color(0x1874B84A));
          }
          if (!g.isPath(x, y) && !g.isScenery(x, y) && !g.isBastion(x, y)) {
            if (h % 5 == 0) {
              final grassP = Paint()
                ..color = const Color(0xFF245224)
                ..strokeWidth = 1.8
                ..strokeCap = StrokeCap.round;
              final b = ctr + Offset((h % 20 - 10) * t * .02, t * .15);
              c.drawLine(b, b + Offset(-t * .06, -t * .16), grassP);
              c.drawLine(b, b + Offset(t * .05, -t * .18), grassP);
            }
            if (h % 11 == 0) {
              c.drawCircle(
                  ctr + Offset(t * .18, -t * .14),
                  t * .055,
                  Paint()
                    ..color = [
                      const Color(0xFFFFF176),
                      const Color(0xFFF48FB1),
                      Colors.white
                    ][h % 3]);
            }
          }
        }
      }

      // Riacho medieval azul no lado direito passando sob a estrada
      final river = Path()
        ..moveTo(ox + 15.8 * t, oy - t * .2)
        ..cubicTo(
            ox + 14.9 * t, oy + 3.5 * t, ox + 16.6 * t, oy + 6.5 * t, ox + 15.4 * t, oy + rows * t + t * .2);
      c.drawPath(
          river,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = t * .75
            ..color = const Color(0xFF4A3D28));
      c.drawPath(
          river,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = t * .56
            ..color = const Color(0xFF2E86C1));
      c.drawPath(
          river,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = t * .20
            ..color = const Color(0x6685C1E9));
    }

    // Estrada orgânica contínua com curvas arredondadas (camadas de terra e pedra)
    final road = Path()..moveTo(p(Game.waypoints[0][0].toDouble(), Game.waypoints[0][1].toDouble()).dx - t * .4,
        p(Game.waypoints[0][0].toDouble(), Game.waypoints[0][1].toDouble()).dy);
    for (final wp in Game.waypoints) {
      final pt = p(wp[0].toDouble(), wp[1].toDouble());
      road.lineTo(pt.dx, pt.dy);
    }
    final endPt = p(Game.waypoints.last[0].toDouble(), Game.waypoints.last[1].toDouble());
    road.lineTo(endPt.dx + t * .4, endPt.dy);

    c.drawPath(
        road,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = t * 1.02
          ..color = hc ? Colors.white : const Color(0xFF4B331A));
    c.drawPath(
        road,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = t * .86
          ..color = hc ? Colors.white : const Color(0xFF936D40));
    c.drawPath(
        road,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = t * .68
          ..color = hc ? Colors.white : const Color(0xFFC49E66));
    if (!hc) {
      c.drawPath(
          road,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..strokeWidth = t * .32
            ..color = const Color(0x55E2C38E));
    }

    // Ponte de madeira sobre o riacho em (15..16, 8)
    if (!hc) {
      final br = Rect.fromCenter(center: p(15.65, 8.0), width: t * 1.25, height: t * 1.05);
      c.drawRRect(RRect.fromRectAndRadius(br, Radius.circular(t * .1)),
          Paint()..color = const Color(0xFF5D4037));
      for (var k = -2; k <= 2; k++) {
        c.drawLine(
            Offset(br.left + (k + 2.5) * (br.width / 5), br.top + t * .06),
            Offset(br.left + (k + 2.5) * (br.width / 5), br.bottom - t * .06),
            Paint()
              ..color = const Color(0xFF8D6E63)
              ..strokeWidth = t * .11);
      }
      c.drawLine(br.topLeft, br.topRight,
          Paint()..color = const Color(0xFF3E2723)..strokeWidth = t * .12);
      c.drawLine(br.bottomLeft, br.bottomRight,
          Paint()..color = const Color(0xFF3E2723)..strokeWidth = t * .12);
    }

    // Pedrinhas ao longo da estrada
    if (!hc) {
      for (final idx in g.pathTiles) {
        final x = idx % cols, y = idx ~/ cols;
        final h = Game.hash(x, y);
        if (h % 3 == 0) {
          c.drawCircle(
              p(x.toDouble(), y.toDouble()) + Offset(((h % 13) - 6) * t * .04, ((h % 9) - 4) * t * .04),
              t * .045,
              Paint()..color = const Color(0xFF7D5D37));
        }
      }
    }

    // Bastiões estratégicos (plataformas de pedra com runas douradas)
    for (final idx in Game.bastionTiles) {
      final x = idx % cols, y = idx ~/ cols;
      final pad = tile(x, y).deflate(t * .09);
      c.drawRRect(
          RRect.fromRectAndRadius(pad.translate(0, t * .05), Radius.circular(t * .22)),
          Paint()..color = const Color(0x55000000));
      c.drawRRect(
          RRect.fromRectAndRadius(pad, Radius.circular(t * .22)),
          Paint()..color = hc ? const Color(0xFF262626) : const Color(0xFF667063));
      c.drawRRect(
          RRect.fromRectAndRadius(pad.deflate(t * .07), Radius.circular(t * .16)),
          Paint()..color = hc ? const Color(0xFF181818) : const Color(0xFF4C7B3C));
      c.drawRRect(
          RRect.fromRectAndRadius(pad, Radius.circular(t * .22)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, t * .05)
            ..color = hc ? Colors.yellowAccent : const Color(0xCCFFD54F));
    }

    // Árvores e rochas nas bordas
    for (final idx in Game.sceneryTiles) {
      final x = idx % cols, y = idx ~/ cols;
      _scenery(c, tile(x, y), Game.hash(x, y), hc);
    }

    c.restore();

    // Moldura medieval do vale
    c.drawRect(
        boardRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = hc ? Colors.white : const Color(0xFF4E342E));
  }

  void _scenery(Canvas c, Rect r, int h, bool hc) {
    final t = r.width, ctr = r.center;
    if (h % 3 == 0) {
      c.drawOval(Rect.fromCenter(center: ctr + Offset(0, t * .18), width: t * .82, height: t * .42),
          Paint()..color = const Color(0x44000000));
      c.drawOval(Rect.fromCenter(center: ctr + Offset(0, t * .08), width: t * .74, height: t * .48),
          Paint()..color = hc ? Colors.white : const Color(0xFF6D7378));
      c.drawOval(
          Rect.fromCenter(center: ctr + Offset(-t * .1, 0), width: t * .42, height: t * .28),
          Paint()..color = hc ? Colors.grey : const Color(0xFF98A0A6));
    } else {
      c.drawOval(Rect.fromCenter(center: ctr + Offset(0, t * .32), width: t * .75, height: t * .34),
          Paint()..color = const Color(0x55000000));
      c.drawRect(Rect.fromCenter(center: ctr + Offset(0, t * .22), width: t * .18, height: t * .32),
          Paint()..color = const Color(0xFF4E342E));
      for (final o in const [
        Offset(-.2, -.02),
        Offset(.2, -.02),
        Offset(0, -.24),
        Offset(0, .02),
      ]) {
        c.drawCircle(
            ctr + Offset(o.dx * t, o.dy * t),
            t * .25,
            Paint()
              ..color = hc
                  ? Colors.white
                  : (o.dy < 0 ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20)));
      }
      if (!hc) {
        c.drawCircle(ctr + Offset(-t * .08, -t * .22), t * .13,
            Paint()..color = const Color(0xFF43A047));
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
              Rect.fromLTWH(rect.left + 1, rect.top + 1, (w - 2) * f, h - 2),
              Radius.circular(h / 2)),
          Paint()..color = col);
    }
    c.drawRRect(
        rr,
        Paint()
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

    // tochas nas curvas da estrada
    if (!hc) {
      for (var i = 0; i < Game.torches.length; i++) {
        final tp = p(Game.torches[i].dx, Game.torches[i].dy);
        final pulse = 0.8 + 0.2 * sin(g.time * 10 + i * 1.7);
        canvas.drawCircle(tp, t * .3 * pulse, Paint()..color = const Color(0x28FF9800));
        canvas.drawCircle(tp, t * .075, Paint()..color = const Color(0xFFFFB74D));
      }
    }

    // acampamento / portal sombrio dos orcs à esquerda
    final po = p(Game.portal.x.toDouble(), Game.portal.y.toDouble());
    canvas.drawCircle(po, t * .56, Paint()..color = const Color(0xFF280C4A));
    for (var i = 0; i < 3; i++) {
      final a = g.time * (1.5 + i * .6) * (i.isEven ? 1 : -1);
      canvas.drawArc(
          Rect.fromCircle(center: po, radius: t * (.18 + i * .12)),
          a,
          4.2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, t * .06)
            ..color = [
              const Color(0xFFE040FB),
              const Color(0xFFB388FF),
              const Color(0xFF7C4DFF),
            ][i]);
    }
    drawText(canvas, 'ORCS', po + Offset(0, -t * .72), max(10.0, t * .22),
        color: const Color(0xFFE040FB));

    // cidadela medieval fortificada à direita
    final co = p(Game.castle.x.toDouble(), Game.castle.y.toDouble());
    canvas.drawOval(Rect.fromCenter(center: co + Offset(0, t * .42), width: t * 1.35, height: t * .5),
        Paint()..color = const Color(0x55000000));
    final cr = Rect.fromCenter(center: co, width: t * 1.05, height: t * 1.0);
    canvas.drawRRect(RRect.fromRectAndRadius(cr, Radius.circular(t * .12)),
        Paint()..color = hc ? Colors.white : const Color(0xFF7D8597));
    for (var i = -1; i <= 1; i++) {
      canvas.drawRect(
          Rect.fromCenter(center: co + Offset(i * t * .34, -t * .54), width: t * .24, height: t * .24),
          Paint()..color = hc ? Colors.white : const Color(0xFF9AA3B5));
    }
    // Portão de madeira da cidadela
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: co + Offset(-t * .15, t * .18), width: t * .42, height: t * .52),
            Radius.circular(t * .2)),
        Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(
        co + Offset(t * .12, -t * .1), t * (.18 + .03 * sin(g.time * 3)),
        Paint()..color = const Color(0xFF00E5FF));
    _bar(canvas, co + Offset(0, -t * .84), t * 1.05, max(7.0, t * .13),
        g.lives / max(1, g.maxLives),
        fill: Colors.cyanAccent);

    // anel de alcance
    final focus = g.selected ?? g.towerAt(g.cx, g.cy);
    double? range;
    Offset? ringAt;
    if (g.menuOpen) {
      final baseR = specs[TKind.values[g.buildIdx]]!.range;
      range = baseR + (baseR > 1 && g.isBastion(g.cx, g.cy) ? 0.35 : 0.0);
      ringAt = p(g.cx.toDouble(), g.cy.toDouble());
    } else if (focus != null && g.armed == null) {
      range = g.rangeOf(focus);
      ringAt = p(focus.x, focus.y);
    }
    if (range != null && range > 0 && ringAt != null) {
      canvas.drawCircle(ringAt, range * t, Paint()..color = Colors.white.withValues(alpha: .1));
      canvas.drawCircle(
          ringAt,
          range * t,
          Paint()
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
        canvas.drawCircle(
            c + Offset((i - (tw.level - 1) / 2) * t * .15, t * .52),
            t * .05,
            Paint()..color = const Color(0xFFFFD54F));
      }
      _bar(canvas, c + Offset(0, -t * .64), t * .76, max(6.0, t * .1), tw.hp / tw.maxHp);
      if (tw == g.selected) {
        canvas.drawCircle(
            c,
            t * .52,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5
              ..color = Colors.white);
      }
    }

    // inimigos ordenados por Y para profundidade 2.5D
    final es = [...g.enemies]..sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    for (final e in es) {
      final c = p(e.pos.dx, e.pos.dy);
      final r = e.spec.size * t;
      drawEnemy(canvas, e.kind, c, r, g.time + e.off * 9);
      if (e.slowT > 0) canvas.drawCircle(c, r * 1.1, Paint()..color = const Color(0x554DD0E1));
      if (e.poisonT > 0) canvas.drawCircle(c, r * 1.1, Paint()..color = const Color(0x5576FF03));
      if (e.flash > 0) {
        canvas.drawCircle(c, r * 1.1, Paint()..color = Colors.white.withValues(alpha: .55));
      }
      if (e.spec.boss) {
        _bar(canvas, c + Offset(0, -r * 1.9), t * 1.5, 11, e.hp / e.maxHp);
      } else if (e.hp < e.maxHp) {
        _bar(canvas, c + Offset(0, -r * 1.5), max(14.0, r * 1.5), max(3.5, r * .25),
            e.hp / e.maxHp);
      }
    }

    // meteoros a caminho
    for (final im in g.impacts) {
      final c = p(im.pos.dx, im.pos.dy);
      final prog = 1 - im.delay / im.total;
      final r = spellRadius[Spell.meteor]! * (1 + .15 * g.lv('mslow')) * t;
      canvas.drawCircle(c, r,
          Paint()..color = Colors.redAccent.withValues(alpha: .12 + .1 * sin(g.time * 18)));
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.redAccent);
      final mp = c + Offset(-t * 1.2, -t * 3.5) * (1 - prog);
      canvas.drawLine(
          mp,
          mp + Offset(t * .5, t * 1.2),
          Paint()
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
        canvas.drawLine(
            a,
            b,
            Paint()
              ..color = s.color
              ..strokeWidth = 3.5
              ..strokeCap = StrokeCap.round);
      }
      if (s.splash > 0) {
        canvas.drawCircle(b, s.splash * t * (1.15 - .15 * k),
            Paint()..color = s.color.withValues(alpha: .28 * k));
        canvas.drawCircle(
            b,
            s.splash * t * (1.15 - .15 * k),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = s.color.withValues(alpha: .8 * k));
      }
    }

    final cp = p(g.cx.toDouble(), g.cy.toDouble());

    // feitiço armado
    final sp = g.armed;
    if (sp != null) {
      final r = spellRadius[sp]! * (1 + .15 * g.lv('mslow')) * t;
      final col = spellColor[sp]!;
      canvas.drawCircle(cp, r, Paint()..color = col.withValues(alpha: .18 + .06 * sin(g.time * 8)));
      canvas.drawCircle(
          cp,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = col);
      drawIcon(canvas, spellIcon[sp]!, cp, t * .6, col);
    }

    // pré-visualização da torre
    if (g.menuOpen) {
      canvas.saveLayer(null, Paint()..color = const Color(0x99FFFFFF));
      drawTower(canvas, TKind.values[g.buildIdx], cp, t * .33, g.time, shadow: false);
      canvas.restore();
    }
    final sel = g.selected;
    if (sel != null) {
      final ok = g.canPlace(sel.kind, g.cx, g.cy, ignore: sel);
      canvas.drawRRect(
          RRect.fromRectAndRadius(tile(g.cx, g.cy).deflate(2), Radius.circular(t * .14)),
          Paint()..color = (ok ? Colors.greenAccent : Colors.redAccent).withValues(alpha: .35));
      drawIcon(canvas, ok ? Icons.check_circle : Icons.cancel, cp, t * .55, Colors.white);
    }

    // cursor sutil e legível apenas no tile atual
    canvas.drawRRect(
        RRect.fromRectAndRadius(tile(g.cx, g.cy).deflate(2), Radius.circular(t * .14)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hc ? 5 : 3
          ..color = hc ? Colors.cyanAccent : const Color(0xCCFFE082));
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
