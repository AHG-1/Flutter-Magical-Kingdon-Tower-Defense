import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reino_magico/game.dart';
import 'package:reino_magico/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Ajuste de Mapa e Layout', () {
    test('Trilha bem definida sem obstruções nos bastiões estratégicos', () {
      final g = Game(loadStorage: false);
      expect(g.pathLength, 39);
      expect(g.isPortal(Game.portal.x, Game.portal.y), isTrue);
      expect(g.isCastle(Game.castle.x, Game.castle.y), isTrue);

      for (final idx in Game.bastionTiles) {
        final x = idx % cols;
        final y = idx ~/ cols;
        expect(g.isPath(x, y), isFalse, reason: 'Bastião ($x,$y) não deve estar na trilha');
        expect(g.isScenery(x, y), isFalse, reason: 'Bastião ($x,$y) não deve ter cenário');
        expect(g.canPlace(TKind.arrow, x, y), isTrue);
      }

      final normalTower = Tower(TKind.arrow, 2, 2, 2, 2, 80);
      final bastionTower = Tower(TKind.arrow, 6, 5, 6, 5, 80);
      expect(g.rangeOf(bastionTower), closeTo(g.rangeOf(normalTower) + 0.35, 1e-6));
    });

    test('Bloqueadores ficam na trilha e torres à distância ficam fora', () {
      final g = Game(loadStorage: false);
      expect(g.canPlace(TKind.golem, 4, 5), isTrue);
      expect(g.canPlace(TKind.arrow, 4, 5), isFalse);
      expect(g.canPlace(TKind.golem, 6, 5), isFalse);
      expect(g.canPlace(TKind.arrow, 6, 5), isTrue);
    });
  });

  group('2. Área Separada de Coleta (Anões)', () {
    test('Anões coletam ouro, madeira, pedra e cristal continuamente', () {
      final g = Game(loadStorage: false)..startRun();
      expect(g.sites.map((s) => s.res).toList(),
          [Res.gold, Res.wood, Res.stone, Res.crystal]);

      final initWood = g.res[Res.wood]!;
      final initStone = g.res[Res.stone]!;
      final initCrystal = g.res[Res.crystal]!;

      // Contrata 1 anão (55 ouro) para Pedra e move temporariamente 1 para Cristal
      g.recruitDwarf();
      g.addWorker(2); // Pedra
      g.removeWorker(1); // Tira da madeira após início e move para cristal
      g.addWorker(3); // Cristal

      for (var i = 0; i < 120; i++) {
        g.update(0.05);
      }
      // Agora com mais ouro acumulado, contrata mais um anão para madeira
      g.addWorker(1);
      if (g.idleDwarves == 0 && (g.res[Res.gold] ?? 0) >= g.recruitCost) {
        g.recruitDwarf();
        g.addWorker(1);
      }
      for (var i = 0; i < 120; i++) {
        g.update(0.05);
      }

      expect(g.res[Res.gold]!, greaterThan(40));
      expect(g.res[Res.wood]!, greaterThan(initWood));
      expect(g.res[Res.stone]!, greaterThan(initStone));
      expect(g.res[Res.crystal]!, greaterThan(initCrystal));
    });
  });

  group('3. Sistema de Ondas Infinitas (Endless Mode)', () {
    test('Ondas escalam infinitamente além da onda 15 com chefes a cada 5 ondas', () {
      final g = Game(loadStorage: false)..startRun();

      for (var w = 1; w <= 25; w++) {
        g.runState = RunState.build;
        g.startBattle();
        expect(g.wave, w);
        expect(g.queue.isNotEmpty, isTrue);
        if (w % 5 == 0) {
          final hasBoss = g.queue.any((e) => especs[e]!.boss);
          expect(hasBoss, isTrue, reason: 'Onda $w deveria conter chefe');
        }
        g.queue.clear();
        g.enemies.clear();
      }
      expect(g.wave, 25);
      expect(g.runState, RunState.build);
    });
  });

  group('4. Progressão Roguelite (Meta-Progressão)', () {
    test('Início desafiador, derrota concede essência e desbloqueia torres/upgrades', () {
      final g = Game(loadStorage: false)..startRun();
      expect(g.lives, 10);
      expect(g.unlockedTowers.length, 3);
      expect(g.isTowerUnlocked(TKind.frost), isFalse);

      // Força derrota na onda 3
      g.wave = 3;
      g.kills = 50;
      g.lives = 1;
      g.enemies.add(Enemy(EKind.orc, 1, 1, 0, 0)..s = g.pathLength + 0.1);
      g.update(0.05);

      expect(g.runState, RunState.lost);
      expect(g.essence, greaterThan(0));

      // Compra desbloqueio da Torre de Gelo e upgrade de Muralha Real
      g.essence = 10;
      g.unlockTower(TKind.frost);
      expect(g.isTowerUnlocked(TKind.frost), isTrue);

      g.treeClick(2, 0); // Muralha Real (+3 vidas máximas)
      expect(g.lv('clives'), 1);

      // Próxima partida mantém torre desbloqueada e vidas extras
      g.startRun();
      expect(g.lives, 13);
      expect(g.isTowerUnlocked(TKind.frost), isTrue);
    });
  });

  group('5. Interface Gráfica (Smoke Test)', () {
    testWidgets('Tela principal, batalha com Zona dos Anões e tela de melhorias renderizam sem erro',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const RealmApp());
      await tester.pump();
      expect(find.text('PROBLEMA DE ORCS!'), findsOneWidget);

      await tester.tap(find.text('Nova expedição'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('ZONA DOS ANÕES'), findsOneWidget);
      expect(find.text('Iniciar Onda (N)'), findsOneWidget);

      await tester.tap(find.text('Melhorias (K)'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Progressão Roguelite'), findsOneWidget);
    });
  });
}
