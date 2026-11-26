import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game.dart';
import 'game.dart' as realm;
import 'input.dart';
import 'painter.dart';
import 'visuals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RealmApp());
}

class RealmApp extends StatelessWidget {
  const RealmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mestre, Temos um Problema de Orcs!',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const GameScreen(),
      );
}

const _bg = Color(0xFF120D22);
const _panel = Color(0xFF1E1635);
const _accent = Color(0xFFFFC857);
const _purple = Color(0xFF7C4DFF);

BoxDecoration _box(Game g, {Color? border, Color? fill, double radius = 10}) =>
    BoxDecoration(
      color: g.highContrast ? Colors.black : (fill ?? _panel),
      border: Border.all(
          color: g.highContrast
              ? Colors.white
              : (border ?? const Color(0xFF5B3FA0)),
          width: 2),
      borderRadius: BorderRadius.circular(radius),
    );

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final game = Game();
  late final InputManager input = InputManager(game.act);
  late final BoardPainter painter = BoardPainter(game);
  late final Ticker ticker;
  final focus = FocusNode();
  Duration last = Duration.zero;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((d) {
      final dt = ((d - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      last = d;
      input.update(dt);
      game.update(dt);
    })
      ..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    final a = InputManager.keyMap[e.logicalKey];
    if (a == null) return KeyEventResult.ignored;
    if (e is KeyDownEvent) {
      input.setPressed(a, true);
    } else if (e is KeyUpEvent) {
      input.setPressed(a, false);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: ListenableBuilder(
        listenable: game,
        builder: (ctx, _) {
          final body = switch (game.screen) {
            Screen.main => _MainMenu(game),
            Screen.help => _Help(game),
            Screen.tree => _TreeScreen(game),
            Screen.mine => _MineScreen(game),
            Screen.battle => _Battle(game, painter),
          };
          return MediaQuery(
            data: MediaQuery.of(ctx)
                .copyWith(textScaler: TextScaler.linear(game.textScale)),
            child: Scaffold(
              backgroundColor: game.highContrast ? Colors.black : _bg,
              body: SafeArea(child: body),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================ componentes
class _Btn extends StatelessWidget {
  const _Btn(this.g, this.icon, this.label, this.onTap,
      {this.enabled = true,
      this.badge = false,
      this.color,
      this.compact = false});
  final Game g;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled, badge, compact;
  final Color? color;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1 : .45,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12, vertical: compact ? 4 : 7),
              decoration: _box(g,
                  border: color ?? _purple, fill: const Color(0xFF2A1F4A)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: compact ? 15 : 19, color: color ?? Colors.white),
                if (label.isNotEmpty) ...[
                  SizedBox(width: compact ? 4 : 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: compact ? 12.5 : 15,
                          fontWeight: FontWeight.bold)),
                ],
                if (badge)
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child:
                        Icon(Icons.circle, size: 9, color: Colors.amberAccent),
                  ),
              ]),
            ),
          ),
        ),
      );
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.icon, this.color, this.text, this.label);
  final IconData icon;
  final Color color;
  final String text, label;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $text',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF261C42),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: .45), width: 1.2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 5),
            Text(text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}

List<Widget> _resStats(Game g) => [
      for (final r in Res.values)
        _StatPill(resIcon[r]!, resColor[r]!, '${g.res[r] ?? 0}', resName[r]!),
      _StatPill(Icons.favorite, Colors.redAccent, '${g.lives}/${g.maxLives}',
          'Vidas'),
      _StatPill(Icons.auto_awesome, _accent, '${g.essence}', 'Essência arcana'),
    ];

class _CostRow extends StatelessWidget {
  const _CostRow(this.g, this.cost);
  final Game g;
  final Map<Res, int> cost;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, children: [
        for (final e in cost.entries)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(resIcon[e.key],
                size: 15,
                color: (g.res[e.key] ?? 0) >= e.value
                    ? resColor[e.key]
                    : Colors.redAccent),
            const SizedBox(width: 2),
            Text('${e.value}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: (g.res[e.key] ?? 0) >= e.value
                        ? Colors.white
                        : Colors.redAccent)),
          ]),
      ]);
}

Widget _backdrop(Game g, Widget child) => Container(
      decoration: BoxDecoration(
        gradient: g.highContrast
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF241046), Color(0xFF0B0816)]),
        color: g.highContrast ? Colors.black : null,
      ),
      child: child,
    );

// ============================================================ menu principal
class _MenuPanel extends StatelessWidget {
  const _MenuPanel(this.g, this.title);
  final Game g;
  final String? title;
  @override
  Widget build(BuildContext context) {
    final items = g.menuItems();
    return Container(
      width: 440,
      padding: const EdgeInsets.all(16),
      decoration: _box(g, border: _accent, radius: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title!,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
        for (var i = 0; i < items.length; i++)
          MouseRegion(
            onHover: (_) => g.menuHover(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => g.menuClick(i),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: g.mi == i
                      ? _accent.withValues(alpha: .25)
                      : Colors.white10,
                  border: Border.all(
                      color: g.mi == i ? _accent : Colors.transparent,
                      width: 3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(items[i].$2,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            g.mi == i ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          ),
        const SizedBox(height: 4),
        const Text('↑↓ escolher • Enter confirmar • Esc voltar',
            style: TextStyle(fontSize: 13)),
      ]),
    );
  }
}

class _MainMenu extends StatelessWidget {
  const _MainMenu(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) => _backdrop(
        g,
        Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Mestre, Temos um',
                    style: TextStyle(fontSize: 26, color: Colors.white70)),
                const Text('PROBLEMA DE ORCS!',
                    style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                        shadows: [Shadow(color: _purple, blurRadius: 18)])),
                const SizedBox(height: 4),
                const Text('Tower Defense Roguelite • Modo Infinito',
                    style: TextStyle(fontSize: 18, color: Colors.white70)),
                const SizedBox(height: 14),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final k in [
                    TKind.arrow,
                    TKind.golem,
                    TKind.fire,
                    TKind.arcane
                  ])
                    SpriteIcon.tower(k, size: 62),
                  const SizedBox(width: 24),
                  for (final k in [
                    EKind.orc,
                    EKind.shaman,
                    EKind.brute,
                    EKind.troll
                  ])
                    SpriteIcon.enemy(k, size: 62),
                ]),
                const SizedBox(height: 14),
                _MenuPanel(g, null),
                const SizedBox(height: 12),
                Wrap(spacing: 16, children: [
                  _StatPill(Icons.auto_awesome, _accent, '${g.essence}',
                      'Essência arcana'),
                  _StatPill(Icons.flag, Colors.lightBlueAccent,
                      'Onda ${g.bestWave}', 'Recorde'),
                  _StatPill(
                      Icons.shield,
                      Colors.greenAccent,
                      '${g.unlockedTowers.length}/${TKind.values.length}',
                      'Torres'),
                ]),
                const SizedBox(height: 6),
                const Text(
                    'A horda é implacável! Sobreviva o máximo que puder e gaste essência em melhorias e novas torres.',
                    style: TextStyle(fontSize: 13, color: Colors.white60)),
              ]),
            ),
          ),
        ),
      );
}

class _Help extends StatelessWidget {
  const _Help(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    const lines = <(IconData, String)>[
      (
        Icons.map,
        'Mapa Tático e Bastiões: a horda avança do acampamento Orc até a Cidadela. Os bastiões com borda dourada dão +0,35 de alcance.'
      ),
      (
        Icons.add_circle,
        'Construir e Mover: clique num espaço livre do mapa para construir. Clique numa torre para pegá-la e clique em outro local para movê-la.'
      ),
      (
        Icons.shield,
        'Bloqueadores e Torres: Golems e Ents ficam na estrada segurando os orcs; voadores (Morcegos, Espectros, Dragões) passam por cima!'
      ),
      (
        Icons.hardware,
        'Zona dos Anões (painel direito): separada do combate! Envie anões para Ouro, Madeira, Pedra e Cristal continuamente.'
      ),
      (
        Icons.all_inclusive,
        'Modo Infinito: as ondas não têm fim e escalam em força, com Chefes a cada 5 ondas.'
      ),
      (
        Icons.auto_awesome,
        'Roguelite (K): ao perder, você mantém a Essência Arcana para comprar melhorias permanentes e desbloquear novas torres.'
      ),
    ];
    return _backdrop(
      g,
      Center(
        child: FittedBox(
          child: Container(
            width: 860,
            padding: const EdgeInsets.all(20),
            decoration: _box(g, border: _accent, radius: 14),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Como Jogar',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(l.$1, color: _accent, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(l.$2,
                                    style: const TextStyle(
                                        fontSize: 16, height: 1.3))),
                          ]),
                    ),
                  const SizedBox(height: 10),
                  Center(
                      child: _Btn(g, Icons.arrow_back, 'Voltar (Esc)',
                          () => g.act(GameAction.cancel))),
                ]),
          ),
        ),
      ),
    );
  }
}

// ======================================= árvore de habilidades & desbloqueios
const _branchColors = [
  Color(0xFF9CFF6B),
  Color(0xFFB388FF),
  Color(0xFFFF8A65),
  Color(0xFF4DD0E1),
  Color(0xFFFFD54F),
];

class _TreeScreen extends StatelessWidget {
  const _TreeScreen(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    return _backdrop(
      g,
      Center(
        child: FittedBox(
          child: Container(
            width: 1140,
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: _accent, size: 30),
                const SizedBox(width: 10),
                const Text('Progressão Roguelite',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                _Btn(g, Icons.account_tree, 'Melhorias Permanentes',
                    () => g.setTreeTab(TreeTab.upgrades),
                    color: g.treeTab == TreeTab.upgrades ? _accent : _purple),
                const SizedBox(width: 10),
                _Btn(
                    g,
                    Icons.castle,
                    'Desbloquear Torres (${g.unlockedTowers.length}/${TKind.values.length})',
                    () => g.setTreeTab(TreeTab.towers),
                    color: g.treeTab == TreeTab.towers ? _accent : _purple),
                const Spacer(),
                _StatPill(Icons.auto_awesome, _accent, '${g.essence}',
                    'Essência arcana'),
                const SizedBox(width: 14),
                _Btn(g, Icons.arrow_back, 'Voltar (Esc)',
                    () => g.act(GameAction.cancel)),
              ]),
              const SizedBox(height: 14),
              if (g.treeTab == TreeTab.upgrades)
                _upgradesView()
              else
                _towersView(),
              if (g.messageTime > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(g.message,
                      style: const TextStyle(fontSize: 15, color: _accent)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _upgradesView() {
    final sk = branches[g.tb].skills[g.tt];
    final cost = g.skillCost(sk);
    final state = g.lv(sk.id) >= sk.max
        ? 'Nível máximo atingido'
        : !g.unlocked(g.tb, g.tt)
            ? 'Bloqueada: compre a melhoria de cima primeiro'
            : g.canBuySkill(g.tb, g.tt)
                ? 'Enter ou clique para aprimorar por $cost de essência'
                : 'Essência insuficiente (custa $cost)';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var b = 0; b < branches.length; b++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(children: [
                Text(branches[b].name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _branchColors[b])),
                const SizedBox(height: 6),
                for (var t = 0; t < 4; t++) ...[
                  if (t > 0)
                    Icon(Icons.arrow_downward,
                        size: 16,
                        color: g.unlocked(b, t)
                            ? _branchColors[b]
                            : Colors.white24),
                  _SkillNode(g, b, t),
                ],
              ]),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _box(g, border: _branchColors[g.tb]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${sk.name} — nível ${g.lv(sk.id)}/${sk.max}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(sk.desc, style: const TextStyle(fontSize: 17)),
          Text(state, style: const TextStyle(fontSize: 15, color: _accent)),
          const Text(
              'Setas: navegar • Enter: comprar • Q/E: alternar aba • Esc: voltar',
              style: TextStyle(fontSize: 13, color: Colors.white60)),
        ]),
      ),
    ]);
  }

  Widget _towersView() {
    final list = g.unlockableTowers;
    final sel = list[min(g.ut, list.length - 1)];
    final sp = specs[sel]!;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < list.length; i++)
            _TowerUnlockCard(g, list[i], i == g.ut, () {
              g.ut = i;
              g.unlockTower(list[i]);
            }),
        ],
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _box(g, border: _accent),
        child: Row(children: [
          SpriteIcon.tower(sel, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  '${sp.name} — ${g.isTowerUnlocked(sel) ? "DESBLOQUEADA" : "Custa ${sp.unlockCost} Essência"}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(sp.desc, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Row(children: [
                const Text('Custo em batalha: ',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                _CostRow(g, sp.cost),
              ]),
            ]),
          ),
          if (!g.isTowerUnlocked(sel))
            _Btn(g, Icons.lock_open, 'Desbloquear (${sp.unlockCost}✨)',
                () => g.unlockTower(sel),
                enabled: g.canUnlockTower(sel), color: _accent),
        ]),
      ),
    ]);
  }
}

class _TowerUnlockCard extends StatelessWidget {
  const _TowerUnlockCard(this.g, this.k, this.sel, this.onTap);
  final Game g;
  final TKind k;
  final bool sel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sp = specs[k]!;
    final unlocked = g.isTowerUnlocked(k);
    final can = g.canUnlockTower(k);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => g.ut = g.unlockableTowers.indexOf(k),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 245,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: g.highContrast
                ? Colors.black
                : (unlocked
                    ? const Color(0xFF1F382E)
                    : (sel ? const Color(0xFF3A2A66) : _panel)),
            border: Border.all(
                color: sel
                    ? Colors.yellowAccent
                    : unlocked
                        ? Colors.greenAccent
                        : can
                            ? _accent
                            : Colors.white24,
                width: sel ? 3 : 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            SpriteIcon.tower(k, size: 52),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sp.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                      unlocked
                          ? 'Desbloqueada ✔'
                          : 'Desbloquear: ${sp.unlockCost} Essência',
                      style: TextStyle(
                          fontSize: 13,
                          color: unlocked
                              ? Colors.greenAccent
                              : can
                                  ? _accent
                                  : Colors.white60,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(sp.onPath ? 'Na trilha (Bloqueio)' : 'Fora da trilha',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SkillNode extends StatelessWidget {
  const _SkillNode(this.g, this.b, this.t);
  final Game g;
  final int b, t;
  @override
  Widget build(BuildContext context) {
    final s = branches[b].skills[t];
    final lvl = g.lv(s.id);
    final cost = g.skillCost(s);
    final sel = g.tb == b && g.tt == t;
    final open = g.unlocked(b, t);
    final maxed = lvl >= s.max;
    final border = sel
        ? Colors.yellowAccent
        : maxed
            ? Colors.greenAccent
            : open
                ? _branchColors[b]
                : Colors.white24;
    return MouseRegion(
      onHover: (_) => g.treeHover(b, t),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => g.treeClick(b, t),
        child: Container(
          width: double.infinity,
          height: 92,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: g.highContrast
                ? Colors.black
                : (sel ? const Color(0xFF3A2A66) : _panel),
            border: Border.all(
                color: g.highContrast
                    ? (sel ? Colors.cyanAccent : Colors.white)
                    : border,
                width: sel ? 4 : 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Semantics(
            label: '${s.name}, nível $lvl de ${s.max}. ${s.desc}',
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: open ? Colors.white : Colors.white38)),
              const SizedBox(height: 4),
              if (s.max <= 5)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < s.max; i++)
                    Icon(i < lvl ? Icons.circle : Icons.circle_outlined,
                        size: 13, color: i < lvl ? _accent : Colors.white54),
                ])
              else
                Text('Nível $lvl',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _accent)),
              const SizedBox(height: 4),
              open
                  ? Text(maxed ? 'MÁXIMO' : 'Custo: $cost ✨',
                      style: TextStyle(
                          fontSize: 13,
                          color: maxed ? Colors.greenAccent : Colors.white70))
                  : const Icon(Icons.lock, size: 16, color: Colors.white38),
            ]),
          ),
        ),
      ),
    );
  }
}

// ================================================================== mina (tela cheia)
class _MineScreen extends StatelessWidget {
  const _MineScreen(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final status = g.runState == RunState.build
        ? 'Preparação: ${g.countdown.ceil()}s para a Onda ${g.wave + 1}'
        : 'Batalha em andamento! Onda ${g.wave} • ${g.enemies.length + g.queue.length} inimigos';
    return _backdrop(
      g,
      Center(
        child: FittedBox(
          child: Container(
            width: 1020,
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const SpriteIcon.dwarf(size: 46),
                const SizedBox(width: 8),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zona dos Anões — Coleta Contínua',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('Área protegida e separada do campo de batalha',
                          style:
                              TextStyle(fontSize: 13, color: Colors.white70)),
                    ]),
                const Spacer(),
                _Btn(g, Icons.auto_awesome, 'Melhorias (K)',
                    () => g.act(GameAction.skills),
                    badge: g.essence > 0),
                const SizedBox(width: 8),
                _Btn(g, Icons.arrow_back, 'Voltar à batalha (Esc)',
                    () => g.act(GameAction.cancel)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 6, children: _resStats(g)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: _box(g,
                    border: g.runState == RunState.battle
                        ? Colors.redAccent
                        : _purple),
                child: Row(children: [
                  Icon(
                      g.runState == RunState.battle
                          ? Icons.warning
                          : Icons.hourglass_bottom,
                      color: g.runState == RunState.battle
                          ? Colors.redAccent
                          : _accent),
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          Text(status, style: const TextStyle(fontSize: 16))),
                  if (g.runState == RunState.build)
                    _Btn(g, Icons.play_arrow, 'Iniciar onda (N)',
                        () => g.act(GameAction.skipWave)),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text(
                    'Anões: ${g.dwarves}/${g.dwarfCap} • livres: ${g.idleDwarves}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _Btn(
                    g,
                    Icons.person_add,
                    'Contratar anão (Enter) — ${g.recruitCost} ouro',
                    g.recruitDwarf,
                    enabled: g.dwarves < g.dwarfCap),
              ]),
              const SizedBox(height: 6),
              for (var i = 0; i < g.sites.length; i++) _SiteCard(g, i),
              const SizedBox(height: 6),
              if (g.messageTime > 0)
                Text(g.message,
                    style: const TextStyle(fontSize: 16, color: _accent)),
              const Text(
                  '↑↓ escolher local • ←/→ remover ou enviar anão • Enter contratar • U melhorar mina',
                  style: TextStyle(fontSize: 13, color: Colors.white60)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard(this.g, this.i);
  final Game g;
  final int i;
  @override
  Widget build(BuildContext context) {
    final s = g.sites[i];
    final sel = g.ms == i;
    final rate = s.workers * s.perWorker * g.gatherMult;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => g.ms = i,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: _box(g, border: sel ? Colors.yellowAccent : _purple),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
                width: 300,
                height: 94,
                child: CustomPaint(painter: MineScenePainter(g, i))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(resIcon[s.res], color: resColor[s.res], size: 22),
                const SizedBox(width: 6),
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              Text('Anões: ${s.workers}/5 • Nível ${s.level}/4',
                  style: const TextStyle(fontSize: 16)),
              Text(
                  'Produção contínua: +${rate.toStringAsFixed(1)} ${resName[s.res]}/s',
                  style: const TextStyle(fontSize: 15, color: Colors.white70)),
            ]),
          ),
          _Btn(g, Icons.remove, '', () => g.removeWorker(i),
              enabled: s.workers > 0),
          const SizedBox(width: 6),
          _Btn(g, Icons.add, '', () => g.addWorker(i),
              enabled: g.idleDwarves > 0 && s.workers < 5),
          const SizedBox(width: 10),
          _Btn(
              g,
              Icons.upgrade,
              s.level >= 4 ? 'Máximo' : 'Melhorar ${g.siteUpgradeCost(s)}',
              () => g.upgradeSite(i),
              enabled: s.level < 4,
              color: _accent),
        ]),
      ),
    );
  }
}

// ================================================================= campo (interface limpa)
class _Battle extends StatelessWidget {
  const _Battle(this.g, this.painter);
  final Game g;
  final BoardPainter painter;

  @override
  Widget build(BuildContext context) {
    final over = g.runState == RunState.lost;
    return Column(children: [
      _TopBar(g),
      if (g.boss != null) _BossBar(g, g.boss!),
      Expanded(
        child: Row(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: _Board(g, painter)),
              if (g.messageTime > 0)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xDD1A1230),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accent, width: 1.5),
                        ),
                        child: Text(g.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    g.highContrast ? Colors.yellow : _accent)),
                      ),
                    ),
                  ),
                ),
              if (g.menuOpen && !over && !g.pauseMenu)
                Center(
                    child: FittedBox(
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _BuildMenu(g)))),
              if (g.pauseMenu)
                Center(
                    child: FittedBox(
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _MenuPanel(g, 'Pausa')))),
              if (over)
                Center(
                    child: FittedBox(
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _ResultCard(g)))),
            ]),
          ),
          _DwarfSidePanel(g),
        ]),
      ),
      _BottomBar(g),
    ]);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final waveLabel = g.runState == RunState.build
        ? 'Prep ${g.countdown.ceil()}s • Próx: Onda ${g.wave + 1}'
        : 'Onda ${g.wave} • ${g.enemies.length + g.queue.length} inimigos';
    return Container(
      color: g.highContrast ? Colors.black : const Color(0xFF1A1230),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(
          child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._resStats(g),
                _StatPill(Icons.all_inclusive, Colors.lightBlueAccent,
                    waveLabel, 'Onda'),
              ]),
        ),
        const SizedBox(width: 8),
        if (g.runState == RunState.build) ...[
          _Btn(g, Icons.play_arrow, 'Iniciar Onda (N)',
              () => g.act(GameAction.skipWave),
              color: Colors.greenAccent, compact: true),
          const SizedBox(width: 6),
        ],
        _Btn(g, Icons.auto_awesome, 'Melhorias (K)',
            () => g.act(GameAction.skills),
            badge: g.essence > 0, color: _accent, compact: true),
        const SizedBox(width: 6),
        _Btn(g, Icons.menu, 'Menu', () => g.act(GameAction.pause),
            compact: true),
      ]),
    );
  }
}

class _BossBar extends StatelessWidget {
  const _BossBar(this.g, this.e);
  final Game g;
  final Enemy e;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF2A0E14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(children: [
          SpriteIcon.enemy(e.kind, size: 32),
          const SizedBox(width: 10),
          Text('CHEFE: ${e.spec.name}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent)),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (e.hp / e.maxHp).clamp(0.0, 1.0),
                minHeight: 14,
                backgroundColor: Colors.black54,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${e.hp.round()} / ${e.maxHp.round()}',
              style: const TextStyle(fontSize: 14)),
        ]),
      );
}

/// Painel lateral dedicado e separado da área de combate para coleta contínua dos anões.
class _DwarfSidePanel extends StatelessWidget {
  const _DwarfSidePanel(this.g);
  final Game g;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: g.highContrast ? Colors.black : const Color(0xFF171228),
        border: Border(
          left: BorderSide(
              color: g.highContrast ? Colors.white : _accent, width: 2.5),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const SpriteIcon.dwarf(size: 32),
          const SizedBox(width: 6),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ZONA DOS ANÕES',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _accent)),
              Text('Coleta fora de combate',
                  style: TextStyle(fontSize: 11, color: Colors.white60)),
            ]),
          ),
          _Btn(g, Icons.open_in_full, '', () => g.act(GameAction.mine),
              compact: true),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: _box(g, fill: const Color(0xFF231B3D)),
          child: Row(children: [
            Expanded(
              child: Text(
                  'Anões: ${g.dwarves}/${g.dwarfCap}\nLivres: ${g.idleDwarves}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            _Btn(g, Icons.person_add, '+1 (${g.recruitCost}🪙)', g.recruitDwarf,
                enabled: g.dwarves < g.dwarfCap, color: _accent, compact: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: g.sites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (_, i) => _SideMineCard(g, i),
          ),
        ),
      ]),
    );
  }
}

class _SideMineCard extends StatelessWidget {
  const _SideMineCard(this.g, this.i);
  final Game g;
  final int i;

  @override
  Widget build(BuildContext context) {
    final s = g.sites[i];
    final rate = s.workers * s.perWorker * g.gatherMult;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: _box(g,
          fill: const Color(0xFF211A3A),
          border: resColor[s.res]!.withValues(alpha: .65)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: 52,
              height: 36,
              child:
                  CustomPaint(painter: MineScenePainter(g, i, compact: true)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(resIcon[s.res], size: 14, color: resColor[s.res]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(resName[s.res]!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ]),
              Text('+${rate.toStringAsFixed(1)}/s • Nv ${s.level}/4',
                  style:
                      const TextStyle(fontSize: 11.5, color: Colors.white70)),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _Btn(g, Icons.remove, '', () => g.removeWorker(i),
              enabled: s.workers > 0, compact: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${s.workers}/5',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          _Btn(g, Icons.add, '', () => g.addWorker(i),
              enabled: g.idleDwarves > 0 && s.workers < 5, compact: true),
          const Spacer(),
          _Btn(
              g,
              Icons.upgrade,
              s.level >= 4 ? 'Máx' : '${g.siteUpgradeCost(s)}',
              () => g.upgradeSite(i),
              enabled: s.level < 4,
              color: _accent,
              compact: true),
        ]),
      ]),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final sel = g.selected ?? g.towerAt(g.cx, g.cy);
    return Container(
      color: g.highContrast ? Colors.black : const Color(0xFF1A1230),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Flexible(
              child: Text(g.infoLine(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (sel != null) ...[
              const SizedBox(width: 10),
              if (sel.level < 3) ...[
                _Btn(g, Icons.upgrade, 'Melhorar (${g.upgradeCost(sel)})',
                    g.upgradeSelected,
                    color: _accent, compact: true),
                const SizedBox(width: 6),
              ],
              _Btn(g, Icons.sell, 'Vender', g.sellSelected,
                  color: Colors.redAccent, compact: true),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: 'Mana ${g.mana.floor()} de ${g.maxMana.round()}',
          child: SizedBox(
            width: 140,
            child: Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: g.mana / g.maxMana,
                    minHeight: 22,
                    backgroundColor: Colors.black54,
                    color: const Color(0xFF448AFF)),
              ),
              Text('Mana ${g.mana.floor()}/${g.maxMana.round()}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        for (var i = 0; i < Spell.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _SpellBtn(g, Spell.values[i], i + 1),
        ],
      ]),
    );
  }
}

class _SpellBtn extends StatelessWidget {
  const _SpellBtn(this.g, this.s, this.n);
  final Game g;
  final Spell s;
  final int n;
  @override
  Widget build(BuildContext context) {
    final ok = g.mana >= spellCost[s]!;
    final on = g.armed == s;
    return Semantics(
      button: true,
      label: '${spellName[s]}, custa ${spellCost[s]} de mana. ${spellDesc[s]}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => g.armSpell(s),
          child: Opacity(
            opacity: ok ? 1 : .5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: on
                    ? spellColor[s]!.withValues(alpha: .35)
                    : const Color(0xFF2A1F4A),
                border: Border.all(
                    color: on ? Colors.white : spellColor[s]!,
                    width: on ? 3 : 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(spellIcon[s], color: spellColor[s], size: 18),
                const SizedBox(width: 5),
                Text('$n ${spellName[s]} (${spellCost[s]})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board(this.g, this.painter);
  final Game g;
  final BoardPainter painter;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final t = min(c.maxWidth / cols, c.maxHeight / rows);
        final ox = (c.maxWidth - t * cols) / 2;
        final oy = (c.maxHeight - t * rows) / 2;
        (int, int)? tileAt(Offset o) {
          final x = ((o.dx - ox) / t).floor();
          final y = ((o.dy - oy) / t).floor();
          if (x < 0 || y < 0 || x >= cols || y >= rows) return null;
          return (x, y);
        }

        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          onHover: (e) {
            final tl = tileAt(e.localPosition);
            if (tl != null) g.hoverTile(tl.$1, tl.$2);
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              if (e.buttons == kSecondaryMouseButton) {
                g.act(GameAction.cancel);
                return;
              }
              final tl = tileAt(e.localPosition);
              if (tl != null) g.clickTile(tl.$1, tl.$2);
            },
            child: CustomPaint(painter: painter, size: Size.infinite),
          ),
        );
      });
}

class _BuildMenu extends StatelessWidget {
  const _BuildMenu(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final sel = TKind.values[g.buildIdx];
    final sp = specs[sel]!;
    final unlocked = g.isTowerUnlocked(sel);
    final unlockedList = TKind.values.where(g.isTowerUnlocked).toList();
    final lockedList =
        TKind.values.where((k) => !g.isTowerUnlocked(k)).toList();

    return Container(
      width: 560,
      padding: const EdgeInsets.all(14),
      decoration: _box(g, border: _accent, radius: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Expanded(
            child: Text('Construir Torre',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _Btn(g, Icons.close, 'Fechar (Esc)', () => g.act(GameAction.cancel),
              compact: true),
        ]),
        const SizedBox(height: 8),
        for (final k in unlockedList) _buildRow(k, sel),
        if (lockedList.isNotEmpty) ...[
          const Divider(color: Colors.white24),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final k in lockedList)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock, size: 13, color: Colors.amberAccent),
                    const SizedBox(width: 4),
                    Text('${specs[k]!.name} (${specs[k]!.unlockCost}✨)',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _Btn(g, Icons.auto_awesome, 'Desbloquear torres em Melhorias (K)',
              () {
            g.menuOpen = false;
            g.setTreeTab(TreeTab.towers);
            g.activate('tree');
          }, color: _accent, compact: true),
        ],
        const SizedBox(height: 6),
        Text(
            unlocked
                ? sp.desc
                : '${sp.desc} (Desbloqueie por ${sp.unlockCost} Essência em K)',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: unlocked ? Colors.white : Colors.amberAccent)),
      ]),
    );
  }

  Widget _buildRow(TKind k, TKind sel) {
    final sp = specs[k]!;
    final placeOk = g.canPlace(k, g.cx, g.cy);
    return MouseRegion(
      onHover: (_) => g.buildHover(k.index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => g.buildClick(k.index),
        child: Semantics(
          selected: k == sel,
          enabled: g.canBuild(k),
          label: sp.name,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: k == sel ? _accent.withValues(alpha: .25) : null,
              border: Border.all(
                  color: k == sel ? Colors.yellowAccent : Colors.transparent,
                  width: 2.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              SpriteIcon.tower(k, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sp.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: placeOk ? Colors.white : Colors.white38,
                              decoration:
                                  placeOk ? null : TextDecoration.lineThrough)),
                      if (!placeOk)
                        Text(
                            sp.onPath
                                ? 'Requer estar na trilha'
                                : 'Requer estar fora da trilha',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.redAccent)),
                    ]),
              ),
              _CostRow(g, sp.cost),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 540,
      padding: const EdgeInsets.all(22),
      decoration: _box(g, border: Colors.redAccent, radius: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('A CIDADELA CAIU!',
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent)),
        const SizedBox(height: 6),
        Text(
            'Você resistiu até a onda ${g.wave} (Recorde: ${g.bestWave}) e abateu ${g.kills} inimigos.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _box(g, border: _accent, fill: const Color(0xFF281D46)),
          child: Column(children: [
            const Text('ESSÊNCIA ARCANA MANTIDA (ROGUELITE)',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: _accent)),
            const SizedBox(height: 6),
            Text('Ondas & Chefes na partida: +${g.runEssence}',
                style: const TextStyle(fontSize: 15)),
            Text('Bônus de resistência (onda ${g.wave}): +${g.lastWaveGain}',
                style: const TextStyle(fontSize: 15)),
            Text(
                'Bônus de abates + sucata de recursos: +${g.lastKillGain + g.lastSalvageGain}',
                style: const TextStyle(fontSize: 15)),
            const Divider(color: Colors.white24),
            _StatPill(
                Icons.auto_awesome,
                _accent,
                '+${g.lastTotalGain} ganhos (Saldo total: ${g.essence})',
                'Essência total'),
          ]),
        ),
        const SizedBox(height: 16),
        Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Btn(g, Icons.auto_awesome, 'Melhorias & Torres (K)', () {
                g.setTreeTab(TreeTab.towers);
                g.activate('tree');
              }, badge: g.essence > 0, color: _accent),
              _Btn(g, Icons.replay, 'Nova Tentativa (Enter)',
                  () => g.act(GameAction.confirm),
                  color: Colors.greenAccent),
              _Btn(g, Icons.home, 'Menu (Esc)', () => g.act(GameAction.cancel)),
            ]),
      ]),
    );
  }
}
