import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game.dart';
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
const _panel = Color(0xFF1F1636);
const _accent = Color(0xFFFFC857);
const _purple = Color(0xFF7C4DFF);

BoxDecoration _box(Game g, {Color? border, Color? fill, double radius = 10}) => BoxDecoration(
      color: g.highContrast ? Colors.black : (fill ?? _panel),
      border: Border.all(
          color: g.highContrast ? Colors.white : (border ?? const Color(0xFF5B3FA0)), width: 2),
      borderRadius: BorderRadius.circular(radius),
    );

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
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
            data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(game.textScale)),
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
      {this.enabled = true, this.badge = false, this.color});
  final Game g;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled, badge;
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: _box(g, border: color ?? _purple, fill: const Color(0xFF2A1F4A)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 20, color: color ?? Colors.white),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                if (badge) const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.circle, size: 10, color: Colors.amberAccent),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.color, this.text, this.label);
  final IconData icon;
  final Color color;
  final String text, label;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $text',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ]),
      );
}

List<Widget> _resStats(Game g) => [
      for (final r in Res.values)
        _Stat(resIcon[r]!, resColor[r]!, '${g.res[r] ?? 0}', resName[r]!),
      _Stat(Icons.favorite, Colors.redAccent, '${g.lives}', 'Vidas'),
      _Stat(Icons.auto_awesome, _accent, '${g.essence}', 'Essência arcana'),
    ];

class _CostRow extends StatelessWidget {
  const _CostRow(this.g, this.cost);
  final Game g;
  final Map<Res, int> cost;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, children: [
        for (final e in cost.entries)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(resIcon[e.key], size: 17,
                color: (g.res[e.key] ?? 0) >= e.value ? resColor[e.key] : Colors.redAccent),
            const SizedBox(width: 3),
            Text('${e.value}',
                style: TextStyle(
                    fontSize: 16,
                    color: (g.res[e.key] ?? 0) >= e.value ? Colors.white : Colors.redAccent)),
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
            child: Text(title!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: g.mi == i ? _accent.withValues(alpha: .25) : Colors.white10,
                  border: Border.all(color: g.mi == i ? _accent : Colors.transparent, width: 3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(items[i].$2,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: g.mi == i ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          ),
        const SizedBox(height: 4),
        const Text('↑↓ escolher • Enter confirmar • Esc voltar', style: TextStyle(fontSize: 13)),
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
                const Text('Tower defense mágico em tempo real',
                    style: TextStyle(fontSize: 18, color: Colors.white70)),
                const SizedBox(height: 14),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final k in [TKind.fire, TKind.frost, TKind.bolt, TKind.arcane])
                    SpriteIcon.tower(k, size: 64),
                  const SizedBox(width: 24),
                  for (final k in [EKind.orc, EKind.orc, EKind.brute, EKind.troll])
                    SpriteIcon.enemy(k, size: 64),
                ]),
                const SizedBox(height: 14),
                _MenuPanel(g, null),
                const SizedBox(height: 12),
                Wrap(spacing: 24, children: [
                  _Stat(Icons.auto_awesome, _accent, '${g.essence}', 'Essência arcana'),
                  _Stat(Icons.flag, Colors.lightBlueAccent, '${g.bestWave}', 'Melhor onda'),
                ]),
                const SizedBox(height: 6),
                const Text('Gaste a essência arcana na Árvore de Habilidades: ela vale para as próximas partidas.',
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
      (Icons.construction, 'Preparação e Batalha: entre as ondas você tem 45 segundos para construir. Aperte N (ou o botão) para começar a batalha antes.'),
      (Icons.add_circle, 'Construir: clique ou Enter num terreno livre e escolha uma torre. Clique numa torre para pegá-la e clique em outro lugar para movê-la. U melhora (até o nível 3) e Del vende.'),
      (Icons.shield, 'Golems e Ents bloqueiam a trilha e seguram a horda. As outras torres ficam ao lado dela.'),
      (Icons.bolt, 'Feitiços (teclas 1, 2 e 3 ou os botões): escolha, leve o cursor ao alvo e confirme. Usam mana, que se recupera sozinha.'),
      (Icons.hardware, 'Mina dos Anões (tecla M): é um lugar separado. Envie anões para ouro, madeira, armas e cristais, contrate mais anões e melhore as minas.'),
      (Icons.auto_awesome, 'Árvore de Habilidades (tecla K ou menu): gaste a essência arcana. Ela é ganha ao vencer ondas e chefes e vale para sempre.'),
      (Icons.warning, 'Chefes aparecem nas ondas 5, 10 e 15. Se um deles chegar à Cidadela, você perde 5 vidas.'),
      (Icons.accessibility_new, 'Acessibilidade: H alto contraste, T tamanho do texto, tudo jogável só com teclado ou só com mouse.'),
    ];
    return _backdrop(
      g,
      Center(
        child: FittedBox(
          child: Container(
            width: 860,
            padding: const EdgeInsets.all(20),
            decoration: _box(g, border: _accent, radius: 14),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Como Jogar', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(l.$1, color: _accent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.$2, style: const TextStyle(fontSize: 17, height: 1.3))),
                  ]),
                ),
              const SizedBox(height: 10),
              Center(child: _Btn(g, Icons.arrow_back, 'Voltar (Esc)', () => g.act(GameAction.cancel))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ======================================================== árvore de habilidades
const _branchColors = [
  Color(0xFF9CFF6B), Color(0xFFB388FF), Color(0xFFFF8A65), Color(0xFF4DD0E1), Color(0xFFFFD54F),
];

class _TreeScreen extends StatelessWidget {
  const _TreeScreen(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final sk = branches[g.tb].skills[g.tt];
    final state = g.lv(sk.id) >= sk.max
        ? 'Nível máximo'
        : !g.unlocked(g.tb, g.tt)
            ? 'Bloqueada: compre a habilidade de cima primeiro'
            : g.canBuySkill(g.tb, g.tt)
                ? 'Enter ou clique para comprar por ${sk.cost} de essência'
                : 'Essência insuficiente (custa ${sk.cost})';
    return _backdrop(
      g,
      Center(
        child: FittedBox(
          child: Container(
            width: 1120,
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.account_tree, color: _accent, size: 32),
                const SizedBox(width: 10),
                const Text('Árvore de Habilidades',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const Spacer(),
                _Stat(Icons.auto_awesome, _accent, '${g.essence}', 'Essência arcana'),
                const SizedBox(width: 16),
                _Btn(g, Icons.arrow_back, 'Voltar (Esc)', () => g.act(GameAction.cancel)),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var b = 0; b < branches.length; b++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(children: [
                        Text(branches[b].name,
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.bold, color: _branchColors[b])),
                        const SizedBox(height: 6),
                        for (var t = 0; t < 4; t++) ...[
                          if (t > 0)
                            Icon(Icons.arrow_downward, size: 16,
                                color: g.unlocked(b, t) ? _branchColors[b] : Colors.white24),
                          _SkillNode(g, b, t),
                        ],
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: _box(g, border: _branchColors[g.tb]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${sk.name} — nível ${g.lv(sk.id)}/${sk.max}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(sk.desc, style: const TextStyle(fontSize: 17)),
                  Text(state, style: const TextStyle(fontSize: 15, color: _accent)),
                  const Text('Setas: navegar • Enter: comprar • Esc: voltar',
                      style: TextStyle(fontSize: 13, color: Colors.white60)),
                ]),
              ),
            ]),
          ),
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
    final sel = g.tb == b && g.tt == t;
    final open = g.unlocked(b, t);
    final maxed = lvl >= s.max;
    final border = sel ? Colors.yellowAccent : maxed ? Colors.greenAccent : open ? _branchColors[b] : Colors.white24;
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
            color: g.highContrast ? Colors.black : (sel ? const Color(0xFF3A2A66) : _panel),
            border: Border.all(color: g.highContrast ? (sel ? Colors.cyanAccent : Colors.white) : border, width: sel ? 4 : 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Semantics(
            label: '${s.name}, nível $lvl de ${s.max}. ${s.desc}',
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: open ? Colors.white : Colors.white38)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < s.max; i++)
                  Icon(i < lvl ? Icons.circle : Icons.circle_outlined, size: 14,
                      color: i < lvl ? _accent : Colors.white54),
              ]),
              const SizedBox(height: 4),
              open
                  ? Text(maxed ? 'MÁXIMO' : 'Custo: ${s.cost}',
                      style: TextStyle(fontSize: 13, color: maxed ? Colors.greenAccent : Colors.white70))
                  : const Icon(Icons.lock, size: 16, color: Colors.white38),
            ]),
          ),
        ),
      ),
    );
  }
}

// ================================================================== mina
class _MineScreen extends StatelessWidget {
  const _MineScreen(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final status = g.runState == RunState.build
        ? 'Preparação: ${g.countdown.ceil()}s para a próxima onda'
        : 'Batalha em andamento! Onda ${g.wave} • ${g.enemies.length + g.queue.length} inimigos • ${g.lives} vidas';
    return _backdrop(
      g,
      Center(
        child: FittedBox(
          child: Container(
            width: 1000,
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const SizedBox(width: 4),
                const SpriteIcon.dwarf(size: 46),
                const SizedBox(width: 8),
                const Text('Mina dos Anões',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const Spacer(),
                _Btn(g, Icons.account_tree, 'Habilidades (K)', () => g.act(GameAction.skills),
                    badge: g.essence > 0),
                const SizedBox(width: 8),
                _Btn(g, Icons.arrow_back, 'Voltar ao campo (Esc)', () => g.act(GameAction.cancel)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 22, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
                  children: _resStats(g)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: _box(g, border: g.runState == RunState.battle ? Colors.redAccent : _purple),
                child: Row(children: [
                  Icon(g.runState == RunState.battle ? Icons.warning : Icons.hourglass_bottom,
                      color: g.runState == RunState.battle ? Colors.redAccent : _accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(status, style: const TextStyle(fontSize: 16))),
                  if (g.runState == RunState.build)
                    _Btn(g, Icons.play_arrow, 'Iniciar batalha (N)', () => g.act(GameAction.skipWave)),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('Anões: ${g.dwarves}/${g.dwarfCap} • livres: ${g.idleDwarves}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _Btn(g, Icons.person_add, 'Contratar anão (Enter) — ${g.recruitCost} ouro',
                    g.recruitDwarf, enabled: g.dwarves < g.dwarfCap),
              ]),
              const SizedBox(height: 6),
              for (var i = 0; i < g.sites.length; i++) _SiteCard(g, i),
              const SizedBox(height: 6),
              if (g.messageTime > 0)
                Text(g.message, style: const TextStyle(fontSize: 16, color: _accent)),
              const Text('↑↓ escolher a mina • ←/→ tirar ou enviar anão • Enter contratar • U melhorar a mina',
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
            child: SizedBox(width: 300, height: 100, child: CustomPaint(painter: MineScenePainter(g, i))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(resIcon[s.res], color: resColor[s.res], size: 22),
                const SizedBox(width: 6),
                Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              Text('Anões: ${s.workers}/5 • Nível ${s.level}/3',
                  style: const TextStyle(fontSize: 16)),
              Text('Produção: +${rate.toStringAsFixed(1)} ${resName[s.res]} por segundo',
                  style: const TextStyle(fontSize: 15, color: Colors.white70)),
            ]),
          ),
          _Btn(g, Icons.remove, '', () => g.removeWorker(i), enabled: s.workers > 0),
          const SizedBox(width: 6),
          _Btn(g, Icons.add, '', () => g.addWorker(i), enabled: g.idleDwarves > 0 && s.workers < 5),
          const SizedBox(width: 10),
          _Btn(g, Icons.upgrade, s.level >= 3 ? 'Máximo' : 'Melhorar ${g.siteUpgradeCost(s)}',
              () => g.upgradeSite(i), enabled: s.level < 3, color: _accent),
        ]),
      ),
    );
  }
}

// ================================================================= campo
class _Battle extends StatelessWidget {
  const _Battle(this.g, this.painter);
  final Game g;
  final BoardPainter painter;

  @override
  Widget build(BuildContext context) {
    final over = g.runState == RunState.won || g.runState == RunState.lost;
    return Column(children: [
      _TopBar(g),
      if (g.boss != null) _BossBar(g, g.boss!),
      Expanded(
        child: Stack(children: [
          Positioned.fill(child: _Board(g, painter)),
          if (g.menuOpen && !over && !g.pauseMenu)
            Center(child: FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: _BuildMenu(g)))),
          if (g.pauseMenu) Center(child: FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: _MenuPanel(g, 'Pausa')))),
          if (over) Center(child: FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: _ResultCard(g)))),
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
    final info = g.runState == RunState.build
        ? 'Preparação: ${g.countdown.ceil()}s'
        : 'Onda ${g.wave}/$totalWaves • ${g.enemies.length + g.queue.length} inimigos';
    return Container(
      color: g.highContrast ? Colors.black : const Color(0xFF1A1230),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 20, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ..._resStats(g),
          _Stat(Icons.flag, Colors.lightBlueAccent, info, 'Onda'),
          _Btn(g, Icons.play_arrow, 'Iniciar batalha (N)', () => g.act(GameAction.skipWave),
              enabled: g.runState == RunState.build, color: Colors.greenAccent),
          _Btn(g, Icons.hardware, 'Mina (M)', () => g.act(GameAction.mine)),
          _Btn(g, Icons.account_tree, 'Habilidades (K)', () => g.act(GameAction.skills),
              badge: g.essence > 0),
          _Btn(g, Icons.menu, 'Menu (Esc)', () => g.act(GameAction.pause)),
        ]),
        if (g.messageTime > 0)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(g.message,
                style: TextStyle(fontSize: 16, color: g.highContrast ? Colors.yellow : _accent)),
          ),
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
          SpriteIcon.enemy(e.kind, size: 40),
          const SizedBox(width: 10),
          Text('CHEFE: ${e.spec.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (e.hp / e.maxHp).clamp(0.0, 1.0),
                minHeight: 16,
                backgroundColor: Colors.black54,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${e.hp.round()} / ${e.maxHp.round()}', style: const TextStyle(fontSize: 15)),
        ]),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) => Container(
        color: g.highContrast ? Colors.black : const Color(0xFF1A1230),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.infoLine(), style: const TextStyle(fontSize: 15, color: Colors.white)),
          const SizedBox(height: 4),
          Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Semantics(
              label: 'Mana ${g.mana.floor()} de ${g.maxMana.round()}',
              child: SizedBox(
                width: 200,
                child: Stack(alignment: Alignment.center, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: g.mana / g.maxMana, minHeight: 22,
                        backgroundColor: Colors.black54, color: const Color(0xFF448AFF)),
                  ),
                  Text('Mana ${g.mana.floor()}/${g.maxMana.round()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            for (var i = 0; i < Spell.values.length; i++) _SpellBtn(g, Spell.values[i], i + 1),
          ]),
          const SizedBox(height: 3),
          const Text(
              'Mouse: esquerdo constrói/seleciona/move, direito cancela • Teclado: setas, Enter, Esc, 1-3 feitiços, '
              'U melhora, Del vende, Q/E alterna torre, H contraste, T texto',
              style: TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      );
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: on ? spellColor[s]!.withValues(alpha: .35) : const Color(0xFF2A1F4A),
                border: Border.all(color: on ? Colors.white : spellColor[s]!, width: on ? 3 : 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(spellIcon[s], color: spellColor[s], size: 22),
                const SizedBox(width: 6),
                Text('$n  ${spellName[s]}  (${spellCost[s]})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
    return Container(
      width: 580,
      padding: const EdgeInsets.all(14),
      decoration: _box(g, border: _accent, radius: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Construir torre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        for (final k in TKind.values)
          MouseRegion(
            onHover: (_) => g.buildHover(k.index),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => g.buildClick(k.index),
              child: Semantics(
                selected: k == sel,
                enabled: g.canBuild(k),
                label: specs[k]!.name,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: k == sel ? _accent.withValues(alpha: .25) : null,
                    border: Border.all(color: k == sel ? Colors.yellowAccent : Colors.transparent, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    SpriteIcon.tower(k, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(specs[k]!.name,
                          style: TextStyle(
                              fontSize: 18,
                              color: g.canPlace(k, g.cx, g.cy) ? Colors.white : Colors.white38,
                              decoration: g.canPlace(k, g.cx, g.cy) ? null : TextDecoration.lineThrough)),
                    ),
                    _CostRow(g, specs[k]!.cost),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(sp.desc, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        if (sp.dmg > 0)
          Text('Dano ${sp.dmg.toStringAsFixed(0)} • Alcance ${sp.range} • Vida ${sp.hp.round()}',
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const Text('↑↓ escolher • Enter/clique construir • Esc voltar', style: TextStyle(fontSize: 13)),
      ]),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.g);
  final Game g;
  @override
  Widget build(BuildContext context) {
    final won = g.runState == RunState.won;
    return Container(
      width: 520,
      padding: const EdgeInsets.all(22),
      decoration: _box(g, border: won ? Colors.greenAccent : Colors.redAccent, radius: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(won ? 'Vitória!' : 'Derrota',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                color: won ? Colors.greenAccent : Colors.redAccent)),
        const SizedBox(height: 8),
        Text(won ? 'Você derrotou as $totalWaves ondas e salvou o reino!'
                 : 'A Cidadela caiu na onda ${g.wave}.',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        _Stat(Icons.auto_awesome, _accent, '+${g.lastGain} de essência arcana', 'Essência ganha'),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _Btn(g, Icons.replay, 'Jogar de novo (Enter)', () => g.act(GameAction.confirm), color: Colors.greenAccent),
          _Btn(g, Icons.account_tree, 'Habilidades', () => g.activate('tree'), badge: g.essence > 0),
          _Btn(g, Icons.home, 'Menu (Esc)', () => g.act(GameAction.cancel)),
        ]),
      ]),
    );
  }
}
