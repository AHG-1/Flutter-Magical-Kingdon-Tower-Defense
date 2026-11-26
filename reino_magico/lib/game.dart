import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'input.dart';

const int cols = 20, rows = 11, totalWaves = 15;
const bossWaves = {5, 10, 15};

enum Screen { main, tree, mine, help, battle }

enum RunState { build, battle, won, lost }

// ------------------------------------------------------------------ recursos
enum Res { gold, wood, arms, crystal }

const resName = {
  Res.gold: 'Ouro',
  Res.wood: 'Madeira',
  Res.arms: 'Armas',
  Res.crystal: 'Cristal',
};

// -------------------------------------------------------------------- torres
enum TKind { arrow, fire, frost, bolt, arcane, cannon, poison, golem, ent, shrine }

enum Role { ranged, magic, melee, support }

class TSpec {
  const TSpec({
    required this.name,
    required this.desc,
    required this.cost,
    required this.hp,
    required this.role,
    this.range = 0,
    this.dmg = 0,
    this.cd = 1,
    this.splash = 0,
    this.slow = 0,
    this.heal = 0,
    this.regen = 0,
    this.chain = 0,
    this.poison = 0,
    this.onPath = false,
  });
  final String name, desc;
  final Map<Res, int> cost;
  final double hp, range, dmg, cd, splash, slow, heal, regen, poison;
  final int chain;
  final Role role;
  final bool onPath;
}

const specs = <TKind, TSpec>{
  TKind.arrow: TSpec(
      name: 'Torre Élfica', desc: 'Dispara flechas muito rápido.',
      cost: {Res.gold: 35, Res.wood: 15}, hp: 70, role: Role.ranged,
      range: 3.6, dmg: 9, cd: .45),
  TKind.fire: TSpec(
      name: 'Torre de Fogo', desc: 'Bolas de fogo que explodem em área.',
      cost: {Res.gold: 60, Res.crystal: 4}, hp: 60, role: Role.magic,
      range: 3.0, dmg: 20, cd: 1.4, splash: 1.2),
  TKind.frost: TSpec(
      name: 'Torre de Gelo', desc: 'Congela e deixa a horda lenta.',
      cost: {Res.gold: 55, Res.crystal: 4}, hp: 60, role: Role.magic,
      range: 3.0, dmg: 6, cd: .9, splash: .9, slow: .4),
  TKind.bolt: TSpec(
      name: 'Torre de Raios', desc: 'Relâmpago que salta entre inimigos.',
      cost: {Res.gold: 80, Res.crystal: 6}, hp: 60, role: Role.magic,
      range: 3.2, dmg: 16, cd: 1.1, chain: 3),
  TKind.arcane: TSpec(
      name: 'Orbe Arcano', desc: 'Alcance enorme. Mira o inimigo mais forte.',
      cost: {Res.gold: 110, Res.crystal: 10}, hp: 60, role: Role.magic,
      range: 5.5, dmg: 90, cd: 2.2),
  TKind.cannon: TSpec(
      name: 'Canhão Rúnico', desc: 'Tiro pesado. Fura metade da armadura.',
      cost: {Res.gold: 90, Res.arms: 25, Res.wood: 15}, hp: 90, role: Role.ranged,
      range: 4.2, dmg: 55, cd: 2.2, splash: 1.0),
  TKind.poison: TSpec(
      name: 'Torre Venenosa', desc: 'Veneno que corrói a horda com o tempo.',
      cost: {Res.gold: 50, Res.wood: 20, Res.crystal: 2}, hp: 60, role: Role.magic,
      range: 3.0, dmg: 4, cd: 1.0, splash: .8, poison: 8),
  TKind.golem: TSpec(
      name: 'Golem de Pedra', desc: 'Bloqueia a trilha e segura a horda.',
      cost: {Res.gold: 45, Res.arms: 15}, hp: 700, role: Role.melee,
      range: .9, dmg: 20, cd: .9, regen: 3, onPath: true),
  TKind.ent: TSpec(
      name: 'Ent Guardião', desc: 'Bloqueador que se regenera rápido.',
      cost: {Res.gold: 40, Res.wood: 40}, hp: 500, role: Role.melee,
      range: .9, dmg: 12, cd: 1.2, regen: 8, onPath: true),
  TKind.shrine: TSpec(
      name: 'Altar de Cura', desc: 'Cura as torres e guardiões ao redor.',
      cost: {Res.gold: 55, Res.wood: 20, Res.crystal: 4}, hp: 90, role: Role.support,
      range: 2.6, heal: 16, cd: 1.5),
};

// ----------------------------------------------------------------- inimigos
enum EKind {
  orc, goblin, wolf, bat, skeleton, brute, wraith, troll, //
  kingOrc, elderTroll, dragon
}

class ESpec {
  const ESpec({
    required this.name,
    required this.hp,
    required this.speed,
    required this.dmg,
    required this.reward,
    required this.size,
    this.armor = 0,
    this.phys = 1,
    this.regen = 0,
    this.flying = false,
    this.boss = false,
  });
  final String name;
  final double hp, speed, dmg, size, armor, phys, regen;
  final int reward;
  final bool flying, boss;
}

const especs = <EKind, ESpec>{
  EKind.orc: ESpec(name: 'Orc', hp: 30, speed: .85, dmg: 4, reward: 2, size: .27),
  EKind.goblin: ESpec(name: 'Goblin', hp: 15, speed: 1.3, dmg: 3, reward: 1, size: .2),
  EKind.wolf: ESpec(name: 'Lobo Sombrio', hp: 28, speed: 1.6, dmg: 5, reward: 3, size: .27),
  EKind.bat: ESpec(
      name: 'Morcego', hp: 14, speed: 2.0, dmg: 3, reward: 2, size: .22, flying: true),
  EKind.skeleton: ESpec(
      name: 'Esqueleto', hp: 55, speed: .8, dmg: 6, reward: 4, size: .27, armor: 2),
  EKind.brute: ESpec(
      name: 'Orc Bruto', hp: 130, speed: .7, dmg: 10, reward: 8, size: .33, armor: 5),
  EKind.wraith: ESpec(
      name: 'Espectro', hp: 60, speed: 1.1, dmg: 6, reward: 6, size: .3, phys: .4, flying: true),
  EKind.troll: ESpec(
      name: 'Troll', hp: 260, speed: .5, dmg: 18, reward: 20, size: .38, armor: 2, regen: 4),
  EKind.kingOrc: ESpec(
      name: 'Rei Orc', hp: 1800, speed: .45, dmg: 30, reward: 150, size: .55, armor: 4, boss: true),
  EKind.elderTroll: ESpec(
      name: 'Troll Ancião', hp: 4500, speed: .4, dmg: 50, reward: 300, size: .6,
      armor: 8, regen: 12, boss: true),
  EKind.dragon: ESpec(
      name: 'Dragão Sombrio', hp: 8000, speed: .4, dmg: 0, reward: 600, size: .58,
      armor: 5, flying: true, boss: true),
};

// ---------------------------------------------------------------- feitiços
enum Spell { meteor, frost, storm }

const spellName = {
  Spell.meteor: 'Meteoro',
  Spell.frost: 'Nova Gélida',
  Spell.storm: 'Tempestade',
};
const spellDesc = {
  Spell.meteor: 'Um meteoro cai e explode em área grande.',
  Spell.frost: 'Congela e machuca todos na área.',
  Spell.storm: 'Raios atingem até 8 inimigos na área.',
};
const spellCost = {Spell.meteor: 45, Spell.frost: 30, Spell.storm: 40};
const spellRadius = {Spell.meteor: 2.0, Spell.frost: 3.0, Spell.storm: 3.5};

// ---------------------------------------------------- árvore de habilidades
class Skill {
  const Skill(this.id, this.name, this.desc, this.cost, this.max);
  final String id, name, desc;
  final int cost, max;
}

class Branch {
  const Branch(this.name, this.skills);
  final String name;
  final List<Skill> skills;
}

const branches = <Branch>[
  Branch('Armas Físicas', [
    Skill('pdmg', 'Flechas Afiadas', '+12% de dano de Torres Élficas e Canhões por nível.', 1, 3),
    Skill('pspd', 'Mãos Ágeis', '+8% de cadência de Torres Élficas e Canhões por nível.', 1, 3),
    Skill('prng', 'Olhar de Águia', '+0,4 de alcance de Torres Élficas e Canhões por nível.', 2, 2),
    Skill('pcrt', 'Golpe Crítico', '20% de chance de dano dobrado nas torres físicas.', 3, 1),
  ]),
  Branch('Magia', [
    Skill('mdmg', 'Poder Arcano', '+12% de dano das torres mágicas por nível.', 1, 3),
    Skill('mslow', 'Gelo Profundo', '+8% de lentidão da Torre de Gelo por nível.', 1, 3),
    Skill('mchain', 'Raio Persistente', '+1 salto do relâmpago por nível.', 2, 2),
    Skill('msplash', 'Explosão Ampliada', '+25% de área das torres mágicas.', 3, 1),
  ]),
  Branch('Guardiões', [
    Skill('ghp', 'Pele de Pedra', '+20% de vida de Golems e Ents por nível.', 1, 3),
    Skill('gdmg', 'Fúria de Guerra', '+15% de dano de Golems e Ents por nível.', 1, 3),
    Skill('gregen', 'Regeneração', '+2 de vida por segundo por nível.', 2, 2),
    Skill('gthorn', 'Espinhos', 'Inimigos que atacam seus guardiões levam 8 de dano.', 3, 1),
  ]),
  Branch('Feitiços', [
    Skill('smana', 'Reservatório', '+25 de mana máxima por nível.', 1, 3),
    Skill('sregen', 'Fluxo Arcano', '+1,5 de mana por segundo por nível.', 1, 3),
    Skill('spower', 'Poder dos Feitiços', '+15% de dano dos feitiços por nível.', 2, 2),
    Skill('sdouble', 'Chuva de Meteoros', 'O Meteoro lança 2 meteoros extras ao redor.', 3, 1),
  ]),
  Branch('Anões e Ouro', [
    Skill('egspd', 'Picaretas Fortes', '+20% de velocidade de coleta por nível.', 1, 3),
    Skill('ecap', 'Alojamento', '+2 vagas para anões por nível.', 1, 3),
    Skill('ekill', 'Saque de Guerra', '+20% de ouro por inimigo derrotado por nível.', 2, 2),
    Skill('estart', 'Tesouro Real', '+50 de ouro ao começar e +50 ao vencer cada onda.', 3, 1),
  ]),
];

// ------------------------------------------------------------------ entidades
class Tower {
  Tower(this.kind, this.x, this.y, this.tx, this.ty, this.maxHp) : hp = maxHp;
  final TKind kind;
  double x, y, hp, maxHp, cd = 0;
  int tx, ty, level = 1;
  Offset get pos => Offset(x, y);
  TSpec get spec => specs[kind]!;
  bool get moving => (x - tx).abs() > .02 || (y - ty).abs() > .02;
}

class Enemy {
  Enemy(this.kind, double scale, this.off)
      : hp = especs[kind]!.hp * scale,
        maxHp = especs[kind]!.hp * scale;
  final EKind kind;
  final double off; // deslocamento lateral na trilha (a horda não anda em fila)
  double s = 0, hp, maxHp, atk = 0, slowT = 0, slowAmt = 0, flash = 0, special = 5;
  double poisonT = 0, poisonDps = 0;
  Offset pos = Offset.zero;
  bool escaped = false;
  ESpec get spec => especs[kind]!;
}

class Shot {
  Shot(this.from, this.to, this.color, this.splash, [this.life = .18]) : total = life;
  final Offset from, to;
  final Color color;
  final double splash, total;
  double life;
}

class Impact {
  Impact(this.pos, this.delay) : total = delay;
  final Offset pos;
  final double total;
  double delay;
}

class MineSite {
  MineSite(this.name, this.res, this.rate);
  final String name;
  final Res res;
  final double rate; // por anão por segundo
  int workers = 0, level = 1;
  double get perWorker => rate * (1 + .4 * (level - 1));
}

// --------------------------------------------------------------------- jogo
class Game extends ChangeNotifier {
  // ---- mapa
  static const waypoints = <List<int>>[
    [0, 5], [4, 5], [4, 2], [9, 2], [9, 8], [14, 8], [14, 4], [19, 4],
  ];
  static const portal = (x: 0, y: 5);
  static const castle = (x: 19, y: 4);

  late final List<double> _cum = _buildCum();
  late final double pathLength = _cum.last;
  late final Set<int> pathTiles = _buildPathTiles();
  late final Set<int> sceneryTiles = _buildScenery();

  List<double> _buildCum() {
    final c = <double>[0];
    for (var i = 1; i < waypoints.length; i++) {
      final a = waypoints[i - 1], b = waypoints[i];
      c.add(c.last + (b[0] - a[0]).abs() + (b[1] - a[1]).abs());
    }
    return c;
  }

  Set<int> _buildPathTiles() {
    final s = <int>{};
    for (var i = 1; i < waypoints.length; i++) {
      final a = waypoints[i - 1], b = waypoints[i];
      final dx = (b[0] - a[0]).sign, dy = (b[1] - a[1]).sign;
      var x = a[0], y = a[1];
      s.add(y * cols + x);
      while (x != b[0] || y != b[1]) {
        x += dx;
        y += dy;
        s.add(y * cols + x);
      }
    }
    return s;
  }

  static int hash(int x, int y) => (((x * 73856093) ^ (y * 19349663)) & 0x7fffffff);

  Set<int> _buildScenery() {
    final s = <int>{};
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (!isPath(x, y) && hash(x, y) % 100 < 12) s.add(y * cols + x);
      }
    }
    return s;
  }

  /// Posição na trilha com deslocamento lateral [off].
  Offset pathPos(double s, [double off = 0]) {
    final d = max(0.0, s);
    for (var i = 1; i < _cum.length; i++) {
      if (d <= _cum[i] || i == _cum.length - 1) {
        final a = waypoints[i - 1], b = waypoints[i];
        final len = _cum[i] - _cum[i - 1];
        final t = min(1.0, (d - _cum[i - 1]) / len);
        final dx = (b[0] - a[0]) / len, dy = (b[1] - a[1]) / len;
        return Offset(a[0] + (b[0] - a[0]) * t - dy * off,
            a[1] + (b[1] - a[1]) * t + dx * off);
      }
    }
    return Offset(waypoints.last[0].toDouble(), waypoints.last[1].toDouble());
  }

  bool isPath(int x, int y) => pathTiles.contains(y * cols + x);
  bool isScenery(int x, int y) => sceneryTiles.contains(y * cols + x);
  bool isPortal(int x, int y) => x == portal.x && y == portal.y;
  bool isCastle(int x, int y) => x == castle.x && y == castle.y;

  // ---- progresso permanente (continua entre partidas)
  int essence = 3, bestWave = 0, lastGain = 0;
  final Map<String, int> skillLv = {};

  // ---- partida
  final _rnd = Random();
  bool runActive = false;
  RunState runState = RunState.build;
  List<Tower> towers = [];
  List<Enemy> enemies = [];
  List<Shot> shots = [];
  List<Impact> impacts = [];
  Map<Res, int> res = {};
  final Map<Res, double> _frac = {};
  int lives = 20, wave = 0, cx = 7, cy = 4, dwarves = 2;
  double countdown = 45, spawnTimer = 0, spawnGap = .3, mana = 100, time = 0;
  List<EKind> queue = [];
  List<MineSite> sites = [];
  Spell? armed;
  Tower? selected;
  bool menuOpen = false;
  int buildIdx = 0;

  // ---- interface
  Screen screen = Screen.main, returnTo = Screen.main;
  bool pauseMenu = false;
  int mi = 0, ms = 0, tb = 0, tt = 0;
  String message = '';
  double messageTime = 0;
  bool highContrast = false;
  double textScale = 1.0;
  static const _scales = [1.0, 1.25, 1.5, 1.8];

  // ------------------------------------------------------------------ util
  void _announce(String m) {
    final view = PlatformDispatcher.instance.implicitView;
    if (view != null) SemanticsService.sendAnnouncement(view, m, TextDirection.ltr);
  }

  void say(String m) {
    message = m;
    messageTime = 5;
    _announce(m);
  }

  int lv(String id) => skillLv[id] ?? 0;

  // ------------------------------------------------- atributos com habilidades
  double dmgOf(Tower t) {
    var m = 1.0;
    switch (t.spec.role) {
      case Role.ranged:
        m += .12 * lv('pdmg');
      case Role.magic:
        m += .12 * lv('mdmg');
      case Role.melee:
        m += .15 * lv('gdmg');
      case Role.support:
    }
    return t.spec.dmg * m * (1 + .35 * (t.level - 1));
  }

  double cdOf(Tower t) {
    var c = t.spec.cd / (1 + .1 * (t.level - 1));
    if (t.spec.role == Role.ranged) c /= 1 + .08 * lv('pspd');
    return c;
  }

  double rangeOf(Tower t) =>
      t.spec.range +
      (t.spec.role == Role.ranged ? .4 * lv('prng') : 0) +
      (t.spec.range > 1 ? .25 * (t.level - 1) : 0);
  double splashOf(Tower t) =>
      t.spec.splash * (t.spec.role == Role.magic ? 1 + .25 * lv('msplash') : 1);
  double maxHpFor(TKind k, int level) =>
      specs[k]!.hp * (specs[k]!.role == Role.melee ? 1 + .2 * lv('ghp') : 1) *
      (1 + .25 * (level - 1));
  double regenOf(Tower t) =>
      t.spec.role == Role.melee ? t.spec.regen + 2.0 * lv('gregen') : 0;
  double slowOf(Tower t) => min(.85, t.spec.slow + .08 * lv('mslow'));
  double healOf(Tower t) => t.spec.heal * (1 + .35 * (t.level - 1));
  int chainOf(Tower t) => t.spec.chain + lv('mchain');
  double get gatherMult => 1 + .2 * lv('egspd');
  double get goldMult => 1 + .2 * lv('ekill');
  double get maxMana => 100.0 + 25 * lv('smana');
  double get manaRegen => 4.0 + 1.5 * lv('sregen');
  int get dwarfCap => 8 + 2 * lv('ecap');
  int get idleDwarves => dwarves - sites.fold(0, (a, s) => a + s.workers);
  int upgradeCost(Tower t) =>
      (specs[t.kind]!.cost[Res.gold]! * (.8 + .4 * (t.level - 1))).round();
  int get recruitCost => 30 + 15 * dwarves;
  int siteUpgradeCost(MineSite s) => 60 * s.level;

  Enemy? get boss {
    for (final e in enemies) {
      if (e.spec.boss) return e;
    }
    return null;
  }

  // ---------------------------------------------------------------- consultas
  Tower? towerAt(int x, int y) {
    for (final t in towers) {
      if (t.tx == x && t.ty == y) return t;
    }
    return null;
  }

  bool afford(Map<Res, int> cost) =>
      cost.entries.every((e) => (res[e.key] ?? 0) >= e.value);

  bool canPlace(TKind k, int x, int y, {Tower? ignore}) {
    if (isCastle(x, y) || isPortal(x, y) || isScenery(x, y)) return false;
    final here = towers.where((t) => t != ignore && t.tx == x && t.ty == y);
    if (here.isNotEmpty) return false;
    return specs[k]!.onPath || !isPath(x, y);
  }

  bool canBuild(TKind k) => canPlace(k, cx, cy) && afford(specs[k]!.cost);

  String describeTile(int x, int y) {
    final b = StringBuffer('Coluna ${x + 1}, linha ${y + 1}. ');
    if (isCastle(x, y)) b.write('Cidadela. ');
    if (isPortal(x, y)) b.write('Portal dos orcs. ');
    if (isPath(x, y)) b.write('Trilha dos inimigos. ');
    if (isScenery(x, y)) b.write('Terreno ocupado. ');
    final t = towerAt(x, y);
    if (t != null) b.write('${t.spec.name}, nível ${t.level}, vida ${t.hp.round()}. ');
    return b.toString();
  }

  String infoLine() {
    final t = selected ?? towerAt(cx, cy);
    if (t != null) {
      final sp = t.spec;
      var s = '${sp.name} nv ${t.level} • vida ${t.hp.round()}/${t.maxHp.round()}';
      if (sp.dmg > 0) {
        s += ' • dano ${dmgOf(t).toStringAsFixed(0)} • alcance ${rangeOf(t).toStringAsFixed(1)}';
      }
      s += t.level < 3 ? ' • U melhora por ${upgradeCost(t)} de ouro' : ' • nível máximo';
      return s;
    }
    if (isPath(cx, cy)) return 'Trilha: só Golems e Ents podem ser colocados aqui';
    if (isScenery(cx, cy)) return 'Terreno ocupado por árvore ou rocha';
    return 'Terreno livre: Enter ou clique para construir';
  }

  // ------------------------------------------------------------------ partida
  void startRun() {
    towers = [];
    enemies = [];
    shots = [];
    impacts = [];
    queue = [];
    res = {
      Res.gold: 150 + (lv('estart') > 0 ? 50 : 0),
      Res.wood: 60,
      Res.arms: 20,
      Res.crystal: 10,
    };
    _frac.clear();
    lives = 20;
    wave = 0;
    mana = maxMana;
    armed = null;
    selected = null;
    menuOpen = false;
    cx = 7;
    cy = 4;
    dwarves = 2;
    sites = [
      MineSite('Mina de Ouro', Res.gold, 1.0)..workers = 1,
      MineSite('Floresta Antiga', Res.wood, .7)..workers = 1,
      MineSite('Forja Anã', Res.arms, .4),
      MineSite('Caverna de Cristais', Res.crystal, .18),
    ];
    ms = 0;
    runState = RunState.build;
    countdown = 45;
    runActive = true;
    pauseMenu = false;
    screen = Screen.battle;
    say('Fase de preparação: construa torres e envie anões à mina (M).');
  }

  void startBattle() {
    if (runState != RunState.build) return;
    wave++;
    queue = _composeWave(wave);
    spawnGap = min(1.0, max(.06, 28.0 / queue.length));
    spawnTimer = 0;
    runState = RunState.battle;
    say(bossWaves.contains(wave)
        ? 'Onda $wave: um CHEFE lidera a horda!'
        : 'Onda $wave: a horda está chegando!');
  }

  void _endRun(bool won) {
    lastGain = wave + (won ? 10 : 0);
    essence += lastGain;
    bestWave = max(bestWave, won ? totalWaves : wave);
    runState = won ? RunState.won : RunState.lost;
    say(won ? 'Vitória! +$lastGain de essência arcana' : 'Derrota... +$lastGain de essência arcana');
  }

  void _abandon() {
    if (runActive && (runState == RunState.build || runState == RunState.battle)) {
      _endRun(false);
    }
    runActive = false;
    pauseMenu = false;
    screen = Screen.main;
    mi = 0;
  }

  List<EKind> _composeWave(int n) {
    int cap(int v, int m) => min(max(v, 0), m);
    final q = <EKind>[
      for (var i = 0; i < 18 + 10 * n; i++) EKind.orc,
      if (n >= 2) for (var i = 0; i < cap(6 + 3 * n, 50); i++) EKind.goblin,
      if (n >= 3) for (var i = 0; i < cap(2 * n, 24); i++) EKind.wolf,
      if (n >= 4) for (var i = 0; i < cap(2 * n - 4, 20); i++) EKind.bat,
      if (n >= 5) for (var i = 0; i < cap(3 * n - 10, 30); i++) EKind.skeleton,
      if (n >= 6) for (var i = 0; i < cap(2 * n - 8, 18); i++) EKind.brute,
      if (n >= 8) for (var i = 0; i < cap(n - 5, 10); i++) EKind.wraith,
      if (n >= 7) for (var i = 0; i < cap(n - 5, 8); i++) EKind.troll,
    ];
    q.shuffle(_rnd);
    if (n == 5) q.insert(0, EKind.kingOrc);
    if (n == 10) q.insert(0, EKind.elderTroll);
    if (n == 15) q.insert(0, EKind.dragon);
    return q;
  }

  // -------------------------------------------------------------------- menus
  List<(String, String)> menuItems() {
    final c = 'Alto contraste: ${highContrast ? 'ligado' : 'desligado'}';
    final t = 'Tamanho do texto: ${(textScale * 100).round()}%';
    if (screen == Screen.main) {
      return [
        (runActive ? 'continue' : 'play', runActive ? 'Continuar partida' : 'Jogar'),
        if (runActive) ('new', 'Nova partida'),
        ('tree', 'Árvore de Habilidades'),
        ('help', 'Como Jogar'),
        ('contrast', c),
        ('text', t),
      ];
    }
    return [
      ('resume', 'Continuar'),
      ('mine', 'Mina dos Anões'),
      ('tree', 'Árvore de Habilidades'),
      ('help', 'Como Jogar'),
      ('contrast', c),
      ('text', t),
      ('abandon', 'Abandonar partida'),
    ];
  }

  void activate(String id) {
    switch (id) {
      case 'play' || 'new':
        startRun();
      case 'continue':
        screen = Screen.battle;
        pauseMenu = false;
      case 'resume':
        pauseMenu = false;
      case 'tree':
        returnTo = screen;
        screen = Screen.tree;
        tb = 0;
        tt = 0;
      case 'help':
        returnTo = screen;
        screen = Screen.help;
      case 'mine':
        pauseMenu = false;
        screen = Screen.mine;
      case 'contrast':
        act(GameAction.contrast);
      case 'text':
        act(GameAction.textSize);
      case 'abandon':
        _abandon();
    }
    notifyListeners();
  }

  void menuHover(int i) => mi = i;
  void menuClick(int i) {
    mi = i;
    final items = menuItems();
    if (i < items.length) activate(items[i].$1);
  }

  // -------------------------------------------------------------------- árvore
  bool unlocked(int b, int t) => t == 0 || lv(branches[b].skills[t - 1].id) >= 1;
  bool canBuySkill(int b, int t) {
    final s = branches[b].skills[t];
    return unlocked(b, t) && lv(s.id) < s.max && essence >= s.cost;
  }

  void _buySkill(int b, int t) {
    final s = branches[b].skills[t];
    if (!canBuySkill(b, t)) {
      say(lv(s.id) >= s.max
          ? '${s.name} já está no nível máximo'
          : !unlocked(b, t)
              ? 'Compre antes a habilidade de cima nesta coluna'
              : 'Essência insuficiente (custa ${s.cost})');
      return;
    }
    essence -= s.cost;
    skillLv[s.id] = lv(s.id) + 1;
    for (final tw in towers) {
      final nm = maxHpFor(tw.kind, tw.level);
      tw.hp += nm - tw.maxHp;
      tw.maxHp = nm;
    }
    mana = min(mana + (s.id == 'smana' ? 25 : 0), maxMana);
    say('${s.name}: nível ${lv(s.id)}');
  }

  void treeHover(int b, int t) {
    tb = b;
    tt = t;
  }

  void treeClick(int b, int t) {
    tb = b;
    tt = t;
    _buySkill(b, t);
    notifyListeners();
  }

  // -------------------------------------------------------------------- mina
  void addWorker(int i) {
    final s = sites[i];
    if (idleDwarves <= 0) {
      say('Nenhum anão livre. Contrate mais ou remova de outra mina.');
    } else if (s.workers >= 5) {
      say('${s.name} está cheia (5 anões)');
    } else {
      s.workers++;
    }
    notifyListeners();
  }

  void removeWorker(int i) {
    if (sites[i].workers > 0) sites[i].workers--;
    notifyListeners();
  }

  void recruitDwarf() {
    if (dwarves >= dwarfCap) {
      say('Limite de anões atingido ($dwarfCap). Melhore o Alojamento na árvore.');
    } else if ((res[Res.gold] ?? 0) < recruitCost) {
      say('Ouro insuficiente (custa $recruitCost)');
    } else {
      res[Res.gold] = res[Res.gold]! - recruitCost;
      dwarves++;
      say('Um novo anão foi contratado');
    }
    notifyListeners();
  }

  void upgradeSite(int i) {
    final s = sites[i];
    if (s.level >= 3) {
      say('${s.name} já está no nível máximo');
    } else if ((res[Res.gold] ?? 0) < siteUpgradeCost(s)) {
      say('Ouro insuficiente (custa ${siteUpgradeCost(s)})');
    } else {
      res[Res.gold] = res[Res.gold]! - siteUpgradeCost(s);
      s.level++;
      say('${s.name} melhorada para o nível ${s.level}');
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------- entrada
  void act(GameAction a) {
    if (a == GameAction.contrast) {
      highContrast = !highContrast;
      say(highContrast ? 'Alto contraste ligado' : 'Alto contraste desligado');
      notifyListeners();
      return;
    }
    if (a == GameAction.textSize) {
      textScale = _scales[(_scales.indexOf(textScale) + 1) % _scales.length];
      say('Tamanho do texto ${(textScale * 100).round()}%');
      notifyListeners();
      return;
    }
    switch (screen) {
      case Screen.main:
        _menuInput(a);
      case Screen.help:
        if (a == GameAction.cancel || a == GameAction.confirm) screen = returnTo;
      case Screen.tree:
        _treeInput(a);
      case Screen.mine:
        _mineInput(a);
      case Screen.battle:
        _battleInput(a);
    }
    notifyListeners();
  }

  void _menuInput(GameAction a) {
    final items = menuItems();
    switch (a) {
      case GameAction.up:
        mi = (mi + items.length - 1) % items.length;
      case GameAction.down:
        mi = (mi + 1) % items.length;
      case GameAction.confirm:
        activate(items[min(mi, items.length - 1)].$1);
      case GameAction.cancel || GameAction.pause:
        if (pauseMenu) pauseMenu = false;
      default:
    }
  }

  void _treeInput(GameAction a) {
    switch (a) {
      case GameAction.left:
        tb = (tb + branches.length - 1) % branches.length;
      case GameAction.right:
        tb = (tb + 1) % branches.length;
      case GameAction.up:
        tt = max(0, tt - 1);
      case GameAction.down:
        tt = min(3, tt + 1);
      case GameAction.confirm:
        _buySkill(tb, tt);
      case GameAction.cancel || GameAction.skills || GameAction.pause:
        screen = returnTo;
      default:
    }
  }

  void _mineInput(GameAction a) {
    switch (a) {
      case GameAction.up:
        ms = (ms + sites.length - 1) % sites.length;
      case GameAction.down:
        ms = (ms + 1) % sites.length;
      case GameAction.left:
        removeWorker(ms);
      case GameAction.right:
        addWorker(ms);
      case GameAction.confirm:
        recruitDwarf();
      case GameAction.upgrade:
        upgradeSite(ms);
      case GameAction.skipWave:
        startBattle();
      case GameAction.skills:
        returnTo = Screen.mine;
        screen = Screen.tree;
      case GameAction.cancel || GameAction.mine:
        screen = Screen.battle;
      case GameAction.pause:
        screen = Screen.battle;
        pauseMenu = true;
        mi = 0;
      default:
    }
  }

  void _battleInput(GameAction a) {
    if (runState == RunState.won || runState == RunState.lost) {
      if (a == GameAction.confirm) startRun();
      if (a == GameAction.cancel) {
        runActive = false;
        screen = Screen.main;
        mi = 0;
      }
      return;
    }
    if (pauseMenu) {
      _menuInput(a);
      return;
    }
    if (menuOpen) {
      _buildMenuInput(a);
      return;
    }
    switch (a) {
      case GameAction.up:
        _moveCursor(0, -1);
      case GameAction.down:
        _moveCursor(0, 1);
      case GameAction.left:
        _moveCursor(-1, 0);
      case GameAction.right:
        _moveCursor(1, 0);
      case GameAction.confirm:
        _confirm();
      case GameAction.cancel:
        if (armed != null) {
          armed = null;
          say('Feitiço cancelado');
        } else if (selected != null) {
          selected = null;
          say('Seleção cancelada');
        } else {
          pauseMenu = true;
          mi = 0;
        }
      case GameAction.pause:
        pauseMenu = true;
        mi = 0;
      case GameAction.sell:
        _sell();
      case GameAction.upgrade:
        _upgradeTower();
      case GameAction.skipWave:
        if (runState == RunState.build) {
          startBattle();
        } else {
          say('A batalha já começou');
        }
      case GameAction.prevUnit:
        _cycle(-1);
      case GameAction.nextUnit:
        _cycle(1);
      case GameAction.skills:
        returnTo = Screen.battle;
        screen = Screen.tree;
        tb = 0;
        tt = 0;
      case GameAction.mine:
        screen = Screen.mine;
      case GameAction.spell1:
        _arm(Spell.meteor);
      case GameAction.spell2:
        _arm(Spell.frost);
      case GameAction.spell3:
        _arm(Spell.storm);
      default:
    }
  }

  void armSpell(Spell s) {
    if (screen == Screen.battle && !pauseMenu) _arm(s);
    notifyListeners();
  }

  void _arm(Spell s) {
    if (armed == s) {
      armed = null;
      return;
    }
    if (mana < spellCost[s]!) {
      say('Mana insuficiente para ${spellName[s]}');
      return;
    }
    armed = s;
    menuOpen = false;
    selected = null;
    say('${spellName[s]}: mova o cursor e confirme para lançar');
  }

  void _moveCursor(int dx, int dy) {
    cx = (cx + dx).clamp(0, cols - 1);
    cy = (cy + dy).clamp(0, rows - 1);
    _announce(describeTile(cx, cy));
  }

  void _confirm() {
    if (armed != null) {
      _cast(armed!);
      return;
    }
    final sel = selected;
    if (sel != null) {
      if (cx == sel.tx && cy == sel.ty) {
        selected = null;
        return;
      }
      if (!canPlace(sel.kind, cx, cy, ignore: sel)) {
        say('Local inválido para ${sel.spec.name}');
        return;
      }
      sel.tx = cx;
      sel.ty = cy;
      selected = null;
      say('${sel.spec.name} se teletransportando');
      return;
    }
    final t = towerAt(cx, cy);
    if (t != null) {
      selected = t;
      say('${t.spec.name} selecionada. Escolha o destino e confirme.');
      return;
    }
    if (isCastle(cx, cy) || isPortal(cx, cy) || isScenery(cx, cy)) {
      say('Não dá para construir aqui');
      return;
    }
    menuOpen = true;
  }

  void _buildMenuInput(GameAction a) {
    final n = TKind.values.length;
    switch (a) {
      case GameAction.up:
        buildIdx = (buildIdx + n - 1) % n;
      case GameAction.down:
        buildIdx = (buildIdx + 1) % n;
      case GameAction.cancel || GameAction.pause:
        menuOpen = false;
      case GameAction.confirm:
        _build(TKind.values[buildIdx]);
      default:
    }
  }

  void buildHover(int i) => buildIdx = i;
  void buildClick(int i) {
    if (!menuOpen) return;
    buildIdx = i;
    _build(TKind.values[i]);
    notifyListeners();
  }

  void _build(TKind k) {
    final sp = specs[k]!;
    if (!canPlace(k, cx, cy)) {
      say('${sp.name} não pode ser colocada aqui');
      return;
    }
    if (!afford(sp.cost)) {
      say('Recursos insuficientes para ${sp.name}');
      return;
    }
    sp.cost.forEach((r, v) => res[r] = res[r]! - v);
    towers.add(Tower(k, cx.toDouble(), cy.toDouble(), cx, cy, maxHpFor(k, 1)));
    shots.add(Shot(Offset(cx.toDouble(), cy.toDouble()), Offset(cx.toDouble(), cy.toDouble()),
        const Color(0xFFB388FF), 1.0, .4));
    menuOpen = false;
    say('${sp.name} construída');
  }

  void _sell() {
    final t = selected ?? towerAt(cx, cy);
    if (t == null) return;
    t.spec.cost.forEach((r, v) => res[r] = res[r]! + (v * .6).floor());
    towers.remove(t);
    selected = null;
    say('${t.spec.name} vendida (60% de reembolso)');
  }

  void _upgradeTower() {
    final t = selected ?? towerAt(cx, cy);
    if (t == null) return;
    if (t.level >= 3) {
      say('${t.spec.name} já está no nível máximo');
      return;
    }
    final c = upgradeCost(t);
    if ((res[Res.gold] ?? 0) < c) {
      say('Ouro insuficiente (custa $c)');
      return;
    }
    res[Res.gold] = res[Res.gold]! - c;
    t.level++;
    final nm = maxHpFor(t.kind, t.level);
    t.hp += nm - t.maxHp;
    t.maxHp = nm;
    say('${t.spec.name} melhorada para o nível ${t.level}');
  }

  void _cycle(int dir) {
    if (towers.isEmpty) return;
    final cur = towerAt(cx, cy);
    final i = cur == null ? -1 : towers.indexOf(cur);
    final next = towers[(i + dir + towers.length) % towers.length];
    cx = next.tx;
    cy = next.ty;
    _announce(describeTile(cx, cy));
  }

  // -------------------------------------------------------------------- mouse
  void hoverTile(int x, int y) {
    if (screen != Screen.battle || menuOpen || pauseMenu) return;
    cx = x.clamp(0, cols - 1);
    cy = y.clamp(0, rows - 1);
  }

  void clickTile(int x, int y) {
    if (screen != Screen.battle) return;
    if (runState == RunState.won || runState == RunState.lost || pauseMenu) return;
    if (menuOpen) {
      menuOpen = false;
      notifyListeners();
      return;
    }
    cx = x.clamp(0, cols - 1);
    cy = y.clamp(0, rows - 1);
    act(GameAction.confirm);
  }

  // ------------------------------------------------------------- feitiços
  void _cast(Spell s) {
    final cost = spellCost[s]!;
    if (mana < cost) {
      say('Mana insuficiente');
      armed = null;
      return;
    }
    mana -= cost;
    armed = null;
    final c = Offset(cx.toDouble(), cy.toDouble());
    final p = 1 + .15 * lv('spower');
    final area = 1 + .25 * lv('msplash');
    switch (s) {
      case Spell.meteor:
        impacts.add(Impact(c, .8));
        if (lv('sdouble') > 0) {
          for (var i = 0; i < 2; i++) {
            final a = _rnd.nextDouble() * 2 * pi, d = 1.0 + _rnd.nextDouble() * .8;
            impacts.add(Impact(c + Offset(cos(a) * d, sin(a) * d), 1.1 + i * .3));
          }
        }
      case Spell.frost:
        for (final e in enemies) {
          if ((e.pos - c).distance <= spellRadius[s]! * area) {
            _hit(e, 15 * p, magic: true);
            e.slowT = 4;
            e.slowAmt = max(e.slowAmt, .7);
          }
        }
        shots.add(Shot(c, c, const Color(0xFF80DEEA), spellRadius[s]! * area, .6));
      case Spell.storm:
        final near = enemies
            .where((e) => (e.pos - c).distance <= spellRadius[s]! * area)
            .toList()
          ..shuffle(_rnd);
        for (final e in near.take(8)) {
          _hit(e, 55 * p, magic: true);
          shots.add(Shot(e.pos + const Offset(.3, -4), e.pos, const Color(0xFFFFEB3B), 0, .3));
        }
        shots.add(Shot(c, c, const Color(0x66FFEB3B), spellRadius[s]! * area, .3));
    }
  }

  // ---------------------------------------------------------------- simulação
  bool get _simOn =>
      runActive &&
      (runState == RunState.build || runState == RunState.battle) &&
      !pauseMenu &&
      (screen == Screen.battle || screen == Screen.mine);

  void update(double dt) {
    time += dt;
    if (messageTime > 0) messageTime -= dt;
    if (_simOn) {
      _mine(dt);
      mana = min(maxMana, mana + manaRegen * dt);
      _waves(dt);
      _towers(dt);
      _combat(dt);
      _impacts(dt);
      _enemies(dt);
      for (final s in shots) {
        s.life -= dt;
      }
      shots.removeWhere((s) => s.life <= 0);
    }
    notifyListeners();
  }

  void _mine(double dt) {
    for (final s in sites) {
      if (s.workers == 0) continue;
      final f = (_frac[s.res] ?? 0) + s.workers * s.perWorker * gatherMult * dt;
      final whole = f.floor();
      _frac[s.res] = f - whole;
      if (whole > 0) res[s.res] = res[s.res]! + whole;
    }
  }

  void _waves(double dt) {
    if (runState == RunState.build) {
      countdown -= dt;
      if (countdown <= 0) startBattle();
      return;
    }
    if (runState != RunState.battle) return;
    if (queue.isNotEmpty) {
      spawnTimer -= dt;
      var guard = 0;
      while (spawnTimer <= 0 && queue.isNotEmpty && guard++ < 8) {
        _spawn(queue.removeLast());
        spawnTimer += spawnGap;
      }
    } else if (enemies.isEmpty) {
      final bonus = 30 + wave * 5 + (lv('estart') > 0 ? 50 : 0);
      res[Res.gold] = res[Res.gold]! + bonus;
      essence += 1;
      if (wave >= totalWaves) {
        _endRun(true);
      } else {
        runState = RunState.build;
        countdown = 35;
        say('Onda $wave vencida! +$bonus de ouro e +1 de essência');
      }
    }
  }

  void _spawn(EKind k) {
    final sp = especs[k]!;
    final scale = sp.boss ? 1 + .03 * wave : 1 + .07 * wave;
    final off = sp.boss ? 0.0 : (_rnd.nextDouble() - .5) * .7;
    final e = Enemy(k, scale, off)..s = -_rnd.nextDouble() * .3;
    e.pos = pathPos(e.s, off);
    enemies.add(e);
    if (sp.boss) say('${sp.name} chegou! Cuidado!');
  }

  void _towers(double dt) {
    for (final t in towers) {
      final tx = t.tx.toDouble(), ty = t.ty.toDouble();
      final dx = tx - t.x, dy = ty - t.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d < .03) {
        t.x = tx;
        t.y = ty;
      } else {
        final m = min(d, 7 * dt);
        t.x += dx / d * m;
        t.y += dy / d * m;
      }
    }
  }

  void _hit(Enemy e, double dmg, {bool magic = false, bool pierce = false}) {
    var d = dmg;
    if (!magic) {
      final armor = pierce ? e.spec.armor * .5 : e.spec.armor;
      d = max(1.0, d - armor) * e.spec.phys;
    }
    e.hp -= d;
    e.flash = .1;
  }

  void _combat(double dt) {
    for (final t in towers) {
      if (t.moving) continue;
      final rg = regenOf(t);
      if (rg > 0) t.hp = min(t.maxHp, t.hp + rg * dt);
      t.cd -= dt;
      if (t.cd > 0) continue;
      final sp = t.spec;

      if (sp.role == Role.support) {
        t.cd = sp.cd;
        var any = false;
        for (final v in towers) {
          if (v.hp < v.maxHp && (v.pos - t.pos).distance <= rangeOf(t)) {
            v.hp = min(v.maxHp, v.hp + healOf(t));
            any = true;
          }
        }
        if (any) shots.add(Shot(t.pos, t.pos, const Color(0xFF69F0AE), rangeOf(t), .4));
        continue;
      }

      final range = rangeOf(t);
      Enemy? best;
      for (final e in enemies) {
        if ((e.pos - t.pos).distance > range) continue;
        if (best == null ||
            (t.kind == TKind.arcane ? e.hp > best.hp : e.s > best.s)) {
          best = e;
        }
      }
      if (best == null) {
        t.cd = 0;
        continue;
      }
      t.cd = cdOf(t);
      var dmg = dmgOf(t);
      if (sp.role == Role.ranged && lv('pcrt') > 0 && _rnd.nextDouble() < .2) dmg *= 2;
      final magic = sp.role == Role.magic;
      final pierce = t.kind == TKind.cannon;
      final splash = splashOf(t);
      final color = switch (t.kind) {
        TKind.arrow => const Color(0xFF9CFF6B),
        TKind.fire => const Color(0xFFFF9800),
        TKind.frost => const Color(0xFF80DEEA),
        TKind.bolt => const Color(0xFFFFEB3B),
        TKind.arcane => const Color(0xFFE040FB),
        TKind.cannon => const Color(0xFFFFE082),
        TKind.poison => const Color(0xFF76FF03),
        _ => const Color(0xFFFF6B6B),
      };

      final targets = <Enemy>[best];
      if (splash > 0) {
        for (final e in enemies) {
          if (e != best && (e.pos - best.pos).distance <= splash) targets.add(e);
        }
      }
      if (chainOf(t) > 0) {
        var last = best;
        for (var i = 0; i < chainOf(t); i++) {
          Enemy? nx;
          var bd = 1.7;
          for (final e in enemies) {
            if (targets.contains(e)) continue;
            final d = (e.pos - last.pos).distance;
            if (d < bd) {
              bd = d;
              nx = e;
            }
          }
          if (nx == null) break;
          shots.add(Shot(last.pos, nx.pos, color, 0, .15));
          targets.add(nx);
          last = nx;
        }
      }
      final pm = (1 + .12 * lv('mdmg')) * (1 + .35 * (t.level - 1));
      for (final e in targets) {
        _hit(e, dmg, magic: magic, pierce: pierce);
        if (sp.slow > 0) {
          e.slowT = 2.2;
          e.slowAmt = max(e.slowAmt, slowOf(t));
        }
        if (sp.poison > 0) {
          e.poisonT = 4;
          e.poisonDps = max(e.poisonDps, sp.poison * pm);
        }
      }
      shots.add(Shot(t.pos, best.pos, color, splash));
    }
  }

  void _impacts(double dt) {
    final p = 1 + .15 * lv('spower');
    final area = 1 + .25 * lv('msplash');
    for (final im in impacts) {
      im.delay -= dt;
      if (im.delay <= 0) {
        final r = spellRadius[Spell.meteor]! * area;
        for (final e in enemies) {
          if ((e.pos - im.pos).distance <= r) _hit(e, 140 * p, magic: true);
        }
        shots.add(Shot(im.pos, im.pos, const Color(0xFFFF6D00), r, .5));
      }
    }
    impacts.removeWhere((i) => i.delay <= 0);
  }

  void _bossSpecial(Enemy e, double dt, List<Enemy> spawned) {
    e.special -= dt;
    if (e.special > 0) return;
    switch (e.kind) {
      case EKind.kingOrc:
        e.special = 7;
        for (var i = 1; i <= 6; i++) {
          final g = Enemy(EKind.orc, 1 + .07 * wave, (_rnd.nextDouble() - .5) * .7);
          g.s = max(0.0, e.s - .3 * i);
          g.pos = pathPos(g.s, g.off);
          spawned.add(g);
        }
        say('O Rei Orc convocou reforços!');
      case EKind.dragon:
        e.special = 4;
        for (final t in towers) {
          if ((t.pos - e.pos).distance <= 2.8) t.hp -= 45;
        }
        shots.add(Shot(e.pos, e.pos, const Color(0xFFFF6D00), 2.8, .45));
      default:
        e.special = 99;
    }
  }

  void _enemies(double dt) {
    final spawned = <Enemy>[];
    for (final e in enemies) {
      e.flash -= dt;
      e.slowT -= dt;
      if (e.slowT <= 0) e.slowAmt = 0;
      if (e.poisonT > 0) {
        e.poisonT -= dt;
        e.hp -= e.poisonDps * dt;
      }
      if (e.spec.regen > 0) e.hp = min(e.maxHp, e.hp + e.spec.regen * dt);
      e.pos = pathPos(e.s, e.off);
      if (e.spec.boss) _bossSpecial(e, dt, spawned);

      Tower? blocker;
      if (!e.spec.flying) {
        for (final t in towers) {
          if (t.moving) continue;
          if ((t.pos - e.pos).distance < .7) {
            blocker = t;
            break;
          }
        }
      }
      if (blocker != null) {
        e.atk -= dt;
        if (e.atk <= 0) {
          blocker.hp -= e.spec.dmg;
          e.atk = 1.0;
          if (blocker.spec.role == Role.melee && lv('gthorn') > 0) e.hp -= 8;
        }
      } else {
        e.s += e.spec.speed * (1 - e.slowAmt) * dt;
        if (e.s >= pathLength) {
          e.escaped = true;
          lives -= e.spec.boss ? 5 : 1;
        }
      }
    }
    enemies.addAll(spawned);

    for (final e in enemies) {
      if (e.hp <= 0 && !e.escaped) {
        res[Res.gold] = res[Res.gold]! + max(1, (e.spec.reward * goldMult).round());
        if (e.spec.boss) {
          essence += 3;
          say('${e.spec.name} derrotado! +3 de essência arcana');
        }
      }
    }
    enemies.removeWhere((e) => e.hp <= 0 || e.escaped);

    for (final t in towers.where((t) => t.hp <= 0)) {
      say('${t.spec.name} foi destruída!');
      if (selected == t) selected = null;
    }
    towers.removeWhere((t) => t.hp <= 0);

    if (lives <= 0) {
      lives = 0;
      _endRun(false);
    }
  }
}
