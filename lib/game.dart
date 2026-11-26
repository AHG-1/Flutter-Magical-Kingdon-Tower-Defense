import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'input.dart';

const int cols = 20, rows = 11;

enum Screen { main, tree, mine, help, battle }

enum RunState { build, battle, lost }

enum TreeTab { upgrades, towers }

// ------------------------------------------------------------------ recursos
enum Res { gold, wood, stone, crystal }

const resName = {
  Res.gold: 'Ouro',
  Res.wood: 'Madeira',
  Res.stone: 'Pedra',
  Res.crystal: 'Cristal',
};

// -------------------------------------------------------------------- torres
enum TKind {
  arrow,
  golem,
  fire,
  frost,
  poison,
  ent,
  shrine,
  bolt,
  cannon,
  arcane
}

enum Role { ranged, magic, melee, support }

class TSpec {
  const TSpec({
    required this.name,
    required this.desc,
    required this.cost,
    required this.hp,
    required this.role,
    this.unlockCost = 0,
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
  final int unlockCost;
  final double hp, range, dmg, cd, splash, slow, heal, regen, poison;
  final int chain;
  final Role role;
  final bool onPath;
}

const specs = <TKind, TSpec>{
  TKind.arrow: TSpec(
    name: 'Torre Élfica',
    desc: 'Dispara flechas rápidas contra terrestres e voadores.',
    cost: {Res.gold: 35, Res.wood: 15},
    hp: 80,
    role: Role.ranged,
    range: 3.5,
    dmg: 10,
    cd: .48,
  ),
  TKind.golem: TSpec(
    name: 'Golem de Pedra',
    desc: 'Bloqueia a trilha e segura a horda corpo a corpo.',
    cost: {Res.gold: 40, Res.stone: 15},
    hp: 520,
    role: Role.melee,
    range: .95,
    dmg: 18,
    cd: .95,
    regen: 2,
    onPath: true,
  ),
  TKind.fire: TSpec(
    name: 'Torre de Fogo',
    desc: 'Bolas de fogo mágicas com explosão em área.',
    cost: {Res.gold: 60, Res.wood: 15, Res.crystal: 3},
    hp: 70,
    role: Role.magic,
    range: 2.9,
    dmg: 22,
    cd: 1.45,
    splash: 1.15,
  ),
  TKind.frost: TSpec(
    name: 'Torre de Gelo',
    desc: 'Congela e reduz a velocidade da horda em área.',
    cost: {Res.gold: 50, Res.stone: 10, Res.crystal: 3},
    unlockCost: 2,
    hp: 70,
    role: Role.magic,
    range: 3.0,
    dmg: 8,
    cd: .95,
    splash: 1.0,
    slow: .42,
  ),
  TKind.poison: TSpec(
    name: 'Torre Venenosa',
    desc: 'Veneno contínuo que neutraliza regeneração de Trolls.',
    cost: {Res.gold: 45, Res.wood: 20, Res.crystal: 2},
    unlockCost: 2,
    hp: 70,
    role: Role.magic,
    range: 3.0,
    dmg: 6,
    cd: 1.0,
    splash: .9,
    poison: 10,
  ),
  TKind.ent: TSpec(
    name: 'Ent Guardião',
    desc: 'Bloqueador ancestral com alta regeneração na trilha.',
    cost: {Res.gold: 35, Res.wood: 35},
    unlockCost: 3,
    hp: 460,
    role: Role.melee,
    range: .95,
    dmg: 14,
    cd: 1.1,
    regen: 9,
    onPath: true,
  ),
  TKind.shrine: TSpec(
    name: 'Altar de Cura',
    desc: 'Restaura a vida das torres e bloqueadores próximos.',
    cost: {Res.gold: 50, Res.wood: 15, Res.stone: 15},
    unlockCost: 3,
    hp: 100,
    role: Role.support,
    range: 2.7,
    heal: 20,
    cd: 1.4,
  ),
  TKind.bolt: TSpec(
    name: 'Torre de Raios',
    desc: 'Relâmpago mágico que salta entre múltiplos alvos.',
    cost: {Res.gold: 75, Res.stone: 15, Res.crystal: 5},
    unlockCost: 4,
    hp: 75,
    role: Role.magic,
    range: 3.3,
    dmg: 19,
    cd: 1.05,
    chain: 3,
  ),
  TKind.cannon: TSpec(
    name: 'Canhão Rúnico',
    desc: 'Artilharia pesada em área que perfura 50% da armadura.',
    cost: {Res.gold: 85, Res.stone: 30, Res.wood: 15},
    unlockCost: 5,
    hp: 100,
    role: Role.ranged,
    range: 4.3,
    dmg: 62,
    cd: 2.1,
    splash: 1.05,
  ),
  TKind.arcane: TSpec(
    name: 'Orbe Arcano',
    desc: 'Alcance extremo. Dispara raios puros no inimigo mais forte.',
    cost: {Res.gold: 105, Res.stone: 20, Res.crystal: 9},
    unlockCost: 6,
    hp: 75,
    role: Role.magic,
    range: 5.6,
    dmg: 105,
    cd: 2.0,
  ),
};

// ----------------------------------------------------------------- inimigos
enum EKind {
  orc,
  goblin,
  wolf,
  bat,
  skeleton,
  shaman,
  brute,
  wraith,
  troll,
  kingOrc,
  elderTroll,
  dragon,
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
  EKind.orc: ESpec(
      name: 'Orc Guerreiro', hp: 42, speed: .92, dmg: 6, reward: 3, size: .27),
  EKind.goblin: ESpec(
      name: 'Goblin Saqueador',
      hp: 22,
      speed: 1.45,
      dmg: 4,
      reward: 2,
      size: .21),
  EKind.wolf: ESpec(
      name: 'Lobo Sombrio', hp: 38, speed: 1.75, dmg: 7, reward: 3, size: .27),
  EKind.bat: ESpec(
      name: 'Morcego Sombrio',
      hp: 24,
      speed: 1.95,
      dmg: 4,
      reward: 3,
      size: .22,
      flying: true),
  EKind.skeleton: ESpec(
      name: 'Esqueleto Blindado',
      hp: 72,
      speed: .85,
      dmg: 8,
      reward: 5,
      size: .27,
      armor: 3),
  EKind.shaman:
      ESpec(name: 'Xamã Orc', hp: 68, speed: .82, dmg: 7, reward: 6, size: .28),
  EKind.brute: ESpec(
      name: 'Orc Bruto',
      hp: 165,
      speed: .72,
      dmg: 14,
      reward: 9,
      size: .34,
      armor: 6),
  EKind.wraith: ESpec(
      name: 'Espectro',
      hp: 85,
      speed: 1.15,
      dmg: 9,
      reward: 7,
      size: .3,
      phys: .4,
      flying: true),
  EKind.troll: ESpec(
      name: 'Troll',
      hp: 320,
      speed: .54,
      dmg: 22,
      reward: 20,
      size: .38,
      armor: 3,
      regen: 6),
  EKind.kingOrc: ESpec(
      name: 'Rei Orc',
      hp: 2100,
      speed: .46,
      dmg: 35,
      reward: 140,
      size: .55,
      armor: 5,
      boss: true),
  EKind.elderTroll: ESpec(
      name: 'Troll Ancião',
      hp: 4800,
      speed: .42,
      dmg: 52,
      reward: 260,
      size: .6,
      armor: 8,
      regen: 16,
      boss: true),
  EKind.dragon: ESpec(
      name: 'Dragão Sombrio',
      hp: 8200,
      speed: .44,
      dmg: 0,
      reward: 500,
      size: .58,
      armor: 6,
      flying: true,
      boss: true),
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
  Spell.frost: 'Congela e fere todos os inimigos na área.',
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
    Skill('pdmg', 'Flechas Afiadas',
        '+14% de dano das torres físicas por nível.', 1, 4),
    Skill('pspd', 'Mãos Ágeis',
        '+10% de cadência das torres físicas por nível.', 1, 4),
    Skill('prng', 'Olhar de Águia',
        '+0,4 de alcance das torres físicas por nível.', 2, 3),
    Skill('pcrt', 'Golpe Crítico',
        '22% de chance de dano dobrado nas torres físicas.', 3, 1),
  ]),
  Branch('Magia & Feitiços', [
    Skill('mdmg', 'Poder Arcano', '+14% de dano das torres mágicas por nível.',
        1, 4),
    Skill('mslow', 'Gelo e Área',
        '+8% de lentidão e +15% de área mágica por nível.', 1, 3),
    Skill('smana', 'Fonte Arcana', '+25 mana máxima e +1,5 mana/s por nível.',
        2, 3),
    Skill('spower', 'Ira dos Feitiços', '+20% de dano de feitiços por nível.',
        2, 3),
  ]),
  Branch('Cidadela & Guardiões', [
    Skill('clives', 'Muralha Real', '+3 vidas máximas da Cidadela por nível.',
        1, 5),
    Skill('ghp', 'Pele de Pedra',
        '+22% de vida para Golems, Ents e Altares por nível.', 1, 4),
    Skill('gregen', 'Regeneração', '+2,5 de vida/s para guardiões por nível.',
        2, 3),
    Skill('gthorn', 'Espinhos Rúnicos',
        'Inimigos que atacam guardiões sofrem 10 de dano.', 3, 1),
  ]),
  Branch('Anões & Economia', [
    Skill('egspd', 'Picaretas de Mithril',
        '+22% de velocidade de coleta dos anões por nível.', 1, 4),
    Skill('ecap', 'Alojamento Anão',
        '+2 vagas de anões e -5 ouro no custo inicial por nível.', 1, 4),
    Skill('ekill', 'Saque de Guerra',
        '+20% de ouro por abate e onda vencida por nível.', 2, 3),
    Skill(
        'estart',
        'Cofre do Reino',
        '+35 ouro, +15 madeira, +10 pedra e +3 cristal iniciais por nível.',
        2,
        3),
  ]),
  Branch('Maestria Infinita', [
    Skill('vetdmg', 'Fúria Veterana',
        '+8% de dano global de TODAS as torres por nível.', 2, 99),
    Skill('veteco', 'Engenharia Anã',
        '+10% de produção dos anões e ouro de abate por nível.', 2, 99),
    Skill('vetcd', 'Ritmo de Batalha',
        '+5% de velocidade de ataque global por nível.', 3, 20),
    Skill('sdouble', 'Chuva de Meteoros',
        'O feitiço Meteoro invoca +2 meteoros extras.', 4, 1),
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
  Enemy(this.kind, double hpScale, this.speedScale, this.armorBonus, this.off)
      : hp = especs[kind]!.hp * hpScale,
        maxHp = especs[kind]!.hp * hpScale;
  final EKind kind;
  final double off, speedScale, armorBonus;
  double s = 0,
      hp,
      maxHp,
      atk = 0,
      slowT = 0,
      slowAmt = 0,
      flash = 0,
      special = 4.5;
  double poisonT = 0, poisonDps = 0;
  Offset pos = Offset.zero;
  bool escaped = false;
  ESpec get spec => especs[kind]!;
}

class Shot {
  Shot(this.from, this.to, this.color, this.splash, [this.life = .18])
      : total = life;
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
  final double rate;
  int workers = 0, level = 1;
  double get perWorker => rate * (1 + .4 * (level - 1));
}

// --------------------------------------------------------------------- jogo
class Game extends ChangeNotifier {
  Game({bool loadStorage = true}) {
    if (loadStorage) _loadMeta();
  }

  // ---- mapa tático organizado (20x11)
  static const waypoints = <List<int>>[
    [0, 3],
    [4, 3],
    [4, 8],
    [9, 8],
    [9, 2],
    [14, 2],
    [14, 8],
    [17, 8],
    [17, 5],
    [19, 5],
  ];
  static const portal = (x: 0, y: 3);
  static const castle = (x: 19, y: 5);

  /// Bastiões estratégicos elevados ao longo das curvas: concedem +0.35 de alcance.
  static final Set<int> bastionTiles = {
    for (final p in const [
      [2, 4],
      [3, 4],
      [6, 5],
      [7, 5],
      [6, 6],
      [7, 6],
      [11, 4],
      [12, 4],
      [11, 5],
      [12, 5],
      [15, 5],
      [15, 6],
    ])
      p[1] * cols + p[0],
  };

  /// Decoração medieval apenas nas bordas externas (sem obstruir posições táticas).
  static final Set<int> sceneryTiles = {
    for (final p in const [
      [0, 0],
      [1, 0],
      [2, 0],
      [0, 1],
      [0, 9],
      [0, 10],
      [1, 10],
      [2, 10],
      [6, 0],
      [7, 0],
      [16, 0],
      [18, 0],
      [19, 0],
      [19, 1],
      [6, 10],
      [11, 10],
      [12, 10],
      [18, 10],
      [19, 10],
      [19, 9],
    ])
      p[1] * cols + p[0],
  };

  /// Tochas ao longo das esquinas da estrada para ambientação medieval.
  static const List<Offset> torches = [
    Offset(3.5, 2.5),
    Offset(3.5, 8.5),
    Offset(9.5, 8.5),
    Offset(8.5, 1.5),
    Offset(14.5, 1.5),
    Offset(13.5, 8.5),
    Offset(17.5, 4.5),
  ];

  late final List<double> _cum = _buildCum();
  late final double pathLength = _cum.last;
  late final Set<int> pathTiles = _buildPathTiles();

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

  static int hash(int x, int y) =>
      (((x * 73856093) ^ (y * 19349663)) & 0x7fffffff);

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
  bool isBastion(int x, int y) => bastionTiles.contains(y * cols + x);
  bool isPortal(int x, int y) => x == portal.x && y == portal.y;
  bool isCastle(int x, int y) => x == castle.x && y == castle.y;

  // ---- progresso permanente (Roguelite)
  int essence = 0;
  int bestWave = 0;
  int totalRuns = 0;
  int lastWaveGain = 0,
      lastKillGain = 0,
      lastSalvageGain = 0,
      lastTotalGain = 0;
  final Map<String, int> skillLv = {};
  final Set<TKind> unlockedTowers = {TKind.arrow, TKind.golem, TKind.fire};

  bool isTowerUnlocked(TKind k) =>
      specs[k]!.unlockCost == 0 || unlockedTowers.contains(k);

  Future<void> _loadMeta() async {
    final raw = await loadMetaSave();
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      essence = (data['essence'] as num?)?.toInt() ?? 0;
      bestWave = (data['bestWave'] as num?)?.toInt() ?? 0;
      totalRuns = (data['totalRuns'] as num?)?.toInt() ?? 0;
      final sk = data['skillLv'] as Map<String, dynamic>?;
      if (sk != null) {
        for (final e in sk.entries) {
          skillLv[e.key] = (e.value as num).toInt();
        }
      }
      final tw = data['unlockedTowers'] as List<dynamic>?;
      if (tw != null) {
        for (final name in tw) {
          for (final k in TKind.values) {
            if (k.name == name) unlockedTowers.add(k);
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void _saveMeta() {
    final data = {
      'essence': essence,
      'bestWave': bestWave,
      'totalRuns': totalRuns,
      'skillLv': skillLv,
      'unlockedTowers': unlockedTowers.map((k) => k.name).toList(),
    };
    writeMetaSave(jsonEncode(data));
  }

  // ---- partida atual
  final _rnd = Random();
  bool runActive = false;
  RunState runState = RunState.build;
  List<Tower> towers = [];
  List<Enemy> enemies = [];
  List<Shot> shots = [];
  List<Impact> impacts = [];
  Map<Res, int> res = {};
  final Map<Res, double> _frac = {};
  int lives = 10, maxLives = 10, wave = 0, kills = 0, runEssence = 0;
  int cx = 6, cy = 5, dwarves = 2;
  double countdown = 30, spawnTimer = 0, spawnGap = .3, mana = 100, time = 0;
  List<EKind> queue = [];
  List<MineSite> sites = [];
  Spell? armed;
  Tower? selected;
  bool menuOpen = false;
  int buildIdx = 0;

  // ---- interface
  Screen screen = Screen.main, returnTo = Screen.main;
  TreeTab treeTab = TreeTab.upgrades;
  bool pauseMenu = false;
  int mi = 0, ms = 0, tb = 0, tt = 0, ut = 0;
  String message = '';
  double messageTime = 0;
  bool highContrast = false;
  double textScale = 1.0;
  static const _scales = [1.0, 1.25, 1.5, 1.8];

  // ------------------------------------------------------------------ util
  void _announce(String m) {
    try {
      final view = PlatformDispatcher.instance.implicitView;
      if (view != null)
        SemanticsService.sendAnnouncement(view, m, TextDirection.ltr);
    } catch (_) {}
  }

  void say(String m) {
    message = m;
    messageTime = 5;
    _announce(m);
  }

  int lv(String id) => skillLv[id] ?? 0;

  // ------------------------------------------------- atributos com habilidades
  double dmgOf(Tower t) {
    var m = 1.0 + .08 * lv('vetdmg');
    switch (t.spec.role) {
      case Role.ranged:
        m += .14 * lv('pdmg');
      case Role.magic:
        m += .14 * lv('mdmg');
      case Role.melee:
        m += .15 * lv('ghp') * .5;
      case Role.support:
    }
    return t.spec.dmg * m * (1 + .35 * (t.level - 1));
  }

  double cdOf(Tower t) {
    var rate = 1.0 + .12 * (t.level - 1) + .05 * lv('vetcd');
    if (t.spec.role == Role.ranged) rate += .10 * lv('pspd');
    return t.spec.cd / rate;
  }

  double rangeOf(Tower t) {
    if (t.spec.role == Role.melee) return t.spec.range;
    final bastion = isBastion(t.tx, t.ty) ? 0.35 : 0.0;
    return t.spec.range +
        bastion +
        (t.spec.role == Role.ranged ? .4 * lv('prng') : 0) +
        (t.spec.range > 1 ? .25 * (t.level - 1) : 0);
  }

  double splashOf(Tower t) =>
      t.spec.splash * (t.spec.role == Role.magic ? 1 + .15 * lv('mslow') : 1);

  double maxHpFor(TKind k, int level) {
    final role = specs[k]!.role;
    final guard = (role == Role.melee || role == Role.support)
        ? 1 + .22 * lv('ghp')
        : 1.0;
    return specs[k]!.hp * guard * (1 + .25 * (level - 1));
  }

  double regenOf(Tower t) =>
      t.spec.role == Role.melee ? t.spec.regen + 2.5 * lv('gregen') : 0;

  double slowOf(Tower t) => min(.85, t.spec.slow + .08 * lv('mslow'));
  double healOf(Tower t) => t.spec.heal * (1 + .35 * (t.level - 1));
  int chainOf(Tower t) => t.spec.chain;
  double get gatherMult => 1 + .22 * lv('egspd') + .10 * lv('veteco');
  double get goldMult => 1 + .20 * lv('ekill') + .10 * lv('veteco');
  double get maxMana => 100.0 + 25 * lv('smana');
  double get manaRegen => 4.0 + 1.5 * lv('smana');
  int get dwarfCap => 6 + 2 * lv('ecap');
  int get idleDwarves => dwarves - sites.fold(0, (a, s) => a + s.workers);
  int upgradeCost(Tower t) =>
      (specs[t.kind]!.cost[Res.gold]! * (.85 + .45 * (t.level - 1))).round();
  int get recruitCost => max(15, 25 + 15 * dwarves - 5 * lv('ecap'));
  int siteUpgradeCost(MineSite s) => 50 * s.level;

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
    return specs[k]!.onPath ? isPath(x, y) : !isPath(x, y);
  }

  bool canBuild(TKind k) =>
      isTowerUnlocked(k) && canPlace(k, cx, cy) && afford(specs[k]!.cost);

  String describeTile(int x, int y) {
    final b = StringBuffer('Coluna ${x + 1}, linha ${y + 1}. ');
    if (isCastle(x, y)) b.write('Cidadela. ');
    if (isPortal(x, y)) b.write('Portal dos orcs. ');
    if (isPath(x, y)) b.write('Trilha dos inimigos. ');
    if (isBastion(x, y)) b.write('Bastião estratégico (+0,35 alcance). ');
    if (isScenery(x, y)) b.write('Terreno de borda ocupado. ');
    final t = towerAt(x, y);
    if (t != null)
      b.write('${t.spec.name}, nível ${t.level}, vida ${t.hp.round()}. ');
    return b.toString();
  }

  String infoLine() {
    final t = selected ?? towerAt(cx, cy);
    if (t != null) {
      final sp = t.spec;
      var s =
          '${sp.name} nv ${t.level} • vida ${t.hp.round()}/${t.maxHp.round()}';
      if (sp.dmg > 0) {
        s +=
            ' • dano ${dmgOf(t).toStringAsFixed(0)} • alcance ${rangeOf(t).toStringAsFixed(1)}';
      }
      s += t.level < 3
          ? ' • [U] melhora (${upgradeCost(t)} ouro)'
          : ' • nível máximo';
      return s;
    }
    if (isPath(cx, cy))
      return 'Trilha dos inimigos: posicione Golems ou Ents para bloquear a horda';
    if (isScenery(cx, cy)) return 'Margem da floresta: terreno decorativo';
    if (isBastion(cx, cy))
      return 'Bastião estratégico (+0,35 de alcance!): clique ou Enter para construir';
    return 'Campo livre: clique ou Enter para construir uma torre';
  }

  String waveTheme(int n) {
    if (n <= 0) return 'Preparação inicial';
    if (n % 5 == 0) {
      final cycle = ((n ~/ 5) - 1) % 3;
      return switch (cycle) {
        0 => 'CHEFE: Rei Orc + Horda!',
        1 => 'CHEFE: Troll Ancião + Blindados!',
        _ => 'CHEFE: Dragão Sombrio + Voadores!',
      };
    }
    return switch (n % 4) {
      1 => 'Horda de Orcs e Saqueadores',
      2 => 'Investida Veloz (Lobos)',
      3 => 'Assalto Aéreo (Morcegos/Espectros)',
      _ => 'Cerco Pesado (Brutos e Xamãs)',
    };
  }

  // ------------------------------------------------------------------ partida
  void startRun() {
    towers = [];
    enemies = [];
    shots = [];
    impacts = [];
    queue = [];
    final st = lv('estart');
    res = {
      Res.gold: 95 + 35 * st,
      Res.wood: 30 + 15 * st,
      Res.stone: 15 + 10 * st,
      Res.crystal: 3 * st,
    };
    _frac.clear();
    maxLives = 10 + 3 * lv('clives');
    lives = maxLives;
    wave = 0;
    kills = 0;
    runEssence = 0;
    mana = maxMana;
    armed = null;
    selected = null;
    menuOpen = false;
    cx = 6;
    cy = 5;
    dwarves = 2;
    sites = [
      MineSite('Mina de Ouro', Res.gold, 1.15)..workers = 1,
      MineSite('Serraria dos Anões', Res.wood, .75)..workers = 1,
      MineSite('Pedreira Real', Res.stone, .55),
      MineSite('Caverna de Cristais', Res.crystal, .20),
    ];
    ms = 0;
    runState = RunState.build;
    countdown = 30;
    runActive = true;
    pauseMenu = false;
    screen = Screen.battle;
    say('Onda 1 se aproxima! Posicione torres e gerencie os anões na zona de coleta.');
    notifyListeners();
  }

  void startBattle() {
    if (runState != RunState.build) return;
    if (countdown > 2) {
      final earlyGold = countdown.floor() ~/ 2;
      if (earlyGold > 0) res[Res.gold] = res[Res.gold]! + earlyGold;
    }
    wave++;
    queue = _composeWave(wave);
    spawnGap = min(0.85, max(0.08, 22.0 / queue.length));
    spawnTimer = 0;
    runState = RunState.battle;
    say(wave % 5 == 0
        ? 'Onda $wave: ${waveTheme(wave)}'
        : 'Onda $wave iniciada! (${queue.length} inimigos)');
  }

  void _endRun() {
    totalRuns++;
    bestWave = max(bestWave, wave);
    lastWaveGain = max(1, wave);
    lastKillGain = kills ~/ 25;
    final totalRes = res.values.fold(0, (a, b) => a + b);
    lastSalvageGain = totalRes ~/ 150;
    final defeatBonus = lastWaveGain + lastKillGain + lastSalvageGain;
    lastTotalGain = runEssence + defeatBonus;
    essence += defeatBonus;
    runState = RunState.lost;
    _saveMeta();
    say('A Cidadela caiu na onda $wave! +$defeatBonus de bônus de essência.');
  }

  void _abandon() {
    if (runActive &&
        (runState == RunState.build || runState == RunState.battle)) {
      _endRun();
    }
    runActive = false;
    pauseMenu = false;
    screen = Screen.main;
    mi = 0;
  }

  List<EKind> _composeWave(int n) {
    final q = <EKind>[
      for (var i = 0; i < 10 + 5 * n; i++) EKind.orc,
      for (var i = 0; i < min(45, 5 + 3 * n); i++) EKind.goblin,
      if (n >= 2)
        for (var i = 0; i < min(28, 3 + 2 * n); i++) EKind.wolf,
      if (n >= 3)
        for (var i = 0; i < min(26, 2 + 2 * n); i++) EKind.bat,
      if (n >= 3)
        for (var i = 0; i < min(25, 2 * n - 2); i++) EKind.skeleton,
      if (n >= 4)
        for (var i = 0; i < min(14, n - 1); i++) EKind.shaman,
      if (n >= 4)
        for (var i = 0; i < min(20, 2 * n - 4); i++) EKind.brute,
      if (n >= 6)
        for (var i = 0; i < min(16, n - 3); i++) EKind.wraith,
      if (n >= 6)
        for (var i = 0; i < min(14, n - 4); i++) EKind.troll,
    ];
    q.shuffle(_rnd);
    if (n % 5 == 0) {
      final cycle = ((n ~/ 5) - 1) % 3;
      final bossKind = [EKind.kingOrc, EKind.elderTroll, EKind.dragon][cycle];
      final count = 1 + (n ~/ 20);
      for (var i = 0; i < count; i++) {
        q.insert(0, bossKind);
      }
    }
    return q;
  }

  // -------------------------------------------------------------------- menus
  List<(String, String)> menuItems() {
    final c = 'Alto contraste: ${highContrast ? 'ligado' : 'desligado'}';
    final t = 'Tamanho do texto: ${(textScale * 100).round()}%';
    if (screen == Screen.main) {
      return [
        (
          runActive ? 'continue' : 'play',
          runActive ? 'Continuar partida' : 'Nova expedição'
        ),
        if (runActive) ('new', 'Reiniciar expedição'),
        ('tree', 'Melhorias & Desbloqueios'),
        ('help', 'Como Jogar'),
        ('contrast', c),
        ('text', t),
      ];
    }
    return [
      ('resume', 'Continuar'),
      ('mine', 'Zona dos Anões (Tela Cheia)'),
      ('tree', 'Melhorias & Desbloqueios'),
      ('help', 'Como Jogar'),
      ('contrast', c),
      ('text', t),
      ('abandon', 'Encerrar tentativa'),
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

  // ------------------------------------------------ árvore & desbloqueios
  List<TKind> get unlockableTowers =>
      TKind.values.where((k) => specs[k]!.unlockCost > 0).toList();

  bool canUnlockTower(TKind k) =>
      !isTowerUnlocked(k) && essence >= specs[k]!.unlockCost;

  void unlockTower(TKind k) {
    final sp = specs[k]!;
    if (isTowerUnlocked(k)) {
      say('${sp.name} já foi desbloqueada');
      return;
    }
    if (essence < sp.unlockCost) {
      say('Essência insuficiente (custa ${sp.unlockCost})');
      return;
    }
    essence -= sp.unlockCost;
    unlockedTowers.add(k);
    _saveMeta();
    say('${sp.name} desbloqueada permanentemente!');
    notifyListeners();
  }

  bool unlocked(int b, int t) =>
      t == 0 || lv(branches[b].skills[t - 1].id) >= 1;

  int skillCost(Skill s) {
    if (s.max <= 5) return s.cost;
    return s.cost + lv(s.id) ~/ 3;
  }

  bool canBuySkill(int b, int t) {
    final s = branches[b].skills[t];
    return unlocked(b, t) && lv(s.id) < s.max && essence >= skillCost(s);
  }

  void _buySkill(int b, int t) {
    final s = branches[b].skills[t];
    final cost = skillCost(s);
    if (!canBuySkill(b, t)) {
      say(lv(s.id) >= s.max
          ? '${s.name} já está no nível máximo'
          : !unlocked(b, t)
              ? 'Compre antes a melhoria anterior desta coluna'
              : 'Essência insuficiente (custa $cost)');
      return;
    }
    essence -= cost;
    skillLv[s.id] = lv(s.id) + 1;
    if (s.id == 'clives' && runActive) {
      maxLives += 3;
      lives += 3;
    }
    for (final tw in towers) {
      final nm = maxHpFor(tw.kind, tw.level);
      tw.hp += nm - tw.maxHp;
      tw.maxHp = nm;
    }
    mana = min(mana + (s.id == 'smana' ? 25 : 0), maxMana);
    _saveMeta();
    say('${s.name}: nível ${lv(s.id)}');
  }

  void setTreeTab(TreeTab tab) {
    treeTab = tab;
    notifyListeners();
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
      say('Nenhum anão livre. Contrate mais anões ou realoque de outro local.');
    } else if (s.workers >= 5) {
      say('${s.name} está lotada (5/5 anões)');
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
      say('Limite de anões atingido ($dwarfCap). Melhore Alojamento Anão.');
    } else if ((res[Res.gold] ?? 0) < recruitCost) {
      say('Ouro insuficiente (custa $recruitCost)');
    } else {
      res[Res.gold] = res[Res.gold]! - recruitCost;
      dwarves++;
      say('Novo anão contratado! Envie-o para coletar recursos.');
    }
    notifyListeners();
  }

  void upgradeSite(int i) {
    final s = sites[i];
    if (s.level >= 4) {
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
        if (a == GameAction.cancel || a == GameAction.confirm)
          screen = returnTo;
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
    if (a == GameAction.prevUnit || a == GameAction.nextUnit) {
      treeTab = treeTab == TreeTab.upgrades ? TreeTab.towers : TreeTab.upgrades;
      return;
    }
    if (treeTab == TreeTab.towers) {
      final list = unlockableTowers;
      switch (a) {
        case GameAction.left || GameAction.up:
          ut = (ut + list.length - 1) % list.length;
        case GameAction.right || GameAction.down:
          ut = (ut + 1) % list.length;
        case GameAction.confirm:
          unlockTower(list[ut]);
        case GameAction.cancel || GameAction.skills || GameAction.pause:
          screen = returnTo;
        default:
      }
      return;
    }
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
    if (runState == RunState.lost) {
      if (a == GameAction.confirm) startRun();
      if (a == GameAction.skills) {
        returnTo = Screen.battle;
        screen = Screen.tree;
      }
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
          say('A batalha já está em andamento');
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
      say('${sel.spec.name} reposicionada');
      return;
    }
    final t = towerAt(cx, cy);
    if (t != null) {
      selected = t;
      say('${t.spec.name} selecionada. Clique em outro local para mover ou U para melhorar.');
      return;
    }
    if (isCastle(cx, cy) || isPortal(cx, cy) || isScenery(cx, cy)) {
      say('Não é possível construir neste local');
      return;
    }
    if (!isTowerUnlocked(TKind.values[buildIdx])) {
      buildIdx = TKind.values.firstWhere(isTowerUnlocked).index;
    }
    menuOpen = true;
  }

  void _buildMenuInput(GameAction a) {
    final unlocked = TKind.values.where(isTowerUnlocked).toList();
    if (unlocked.isEmpty) return;
    final cur = unlocked.indexOf(TKind.values[buildIdx]);
    final pos = cur < 0 ? 0 : cur;
    switch (a) {
      case GameAction.up:
        buildIdx =
            unlocked[(pos + unlocked.length - 1) % unlocked.length].index;
      case GameAction.down:
        buildIdx = unlocked[(pos + 1) % unlocked.length].index;
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
    if (!isTowerUnlocked(k)) {
      say('${sp.name} bloqueada! Desbloqueie em Melhorias & Desbloqueios (K).');
      return;
    }
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
    shots.add(Shot(
        Offset(cx.toDouble(), cy.toDouble()),
        Offset(cx.toDouble(), cy.toDouble()),
        const Color(0xFFB388FF),
        1.0,
        .4));
    menuOpen = false;
    say('${sp.name} construída');
  }

  void sellSelected() {
    _sell();
    notifyListeners();
  }

  void _sell() {
    final t = selected ?? towerAt(cx, cy);
    if (t == null) return;
    t.spec.cost.forEach((r, v) => res[r] = res[r]! + (v * .6).floor());
    towers.remove(t);
    selected = null;
    say('${t.spec.name} vendida (60% de reembolso)');
  }

  void upgradeSelected() {
    _upgradeTower();
    notifyListeners();
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
    if (runState == RunState.lost || pauseMenu) return;
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
    final p = 1 + .20 * lv('spower');
    final area = 1 + .15 * lv('mslow');
    switch (s) {
      case Spell.meteor:
        impacts.add(Impact(c, .75));
        if (lv('sdouble') > 0) {
          for (var i = 0; i < 2; i++) {
            final a = _rnd.nextDouble() * 2 * pi,
                d = 1.0 + _rnd.nextDouble() * .8;
            impacts.add(
                Impact(c + Offset(cos(a) * d, sin(a) * d), 1.05 + i * .25));
          }
        }
      case Spell.frost:
        for (final e in enemies) {
          if ((e.pos - c).distance <= spellRadius[s]! * area) {
            _hit(e, 18 * p, magic: true);
            e.slowT = 4.2;
            e.slowAmt = max(e.slowAmt, .72);
          }
        }
        shots.add(
            Shot(c, c, const Color(0xFF80DEEA), spellRadius[s]! * area, .6));
      case Spell.storm:
        final near = enemies
            .where((e) => (e.pos - c).distance <= spellRadius[s]! * area)
            .toList()
          ..shuffle(_rnd);
        for (final e in near.take(8)) {
          _hit(e, 60 * p, magic: true);
          shots.add(Shot(e.pos + const Offset(.3, -4), e.pos,
              const Color(0xFFFFEB3B), 0, .3));
        }
        shots.add(
            Shot(c, c, const Color(0x66FFEB3B), spellRadius[s]! * area, .3));
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
      final waveGold = ((25 + wave * 6) * goldMult).round();
      final gainEssence = wave % 5 == 0 ? 2 : 1;
      res[Res.gold] = res[Res.gold]! + waveGold;
      essence += gainEssence;
      runEssence += gainEssence;
      bestWave = max(bestWave, wave);
      _saveMeta();
      runState = RunState.build;
      countdown = max(14.0, 26.0 - wave * 0.35);
      say('Onda $wave vencida! +$waveGold ouro e +$gainEssence essência');
    }
  }

  void _spawn(EKind k) {
    final sp = especs[k]!;
    final hpScale = sp.boss
        ? (1.0 + 0.18 * max(0, wave - 5)) * pow(1.05, max(0, wave - 10))
        : (1.0 + 0.24 * (wave - 1)) * pow(1.045, max(0, wave - 4));
    final speedScale = min(1.65, 1.0 + max(0, wave - 6) * 0.018);
    final armorBonus = max(0, (wave - 5) ~/ 4).toDouble();
    final off = sp.boss ? 0.0 : (_rnd.nextDouble() - .5) * .68;
    final e = Enemy(k, hpScale, speedScale, armorBonus, off)
      ..s = -_rnd.nextDouble() * .25;
    e.pos = pathPos(e.s, off);
    enemies.add(e);
    if (sp.boss) say('${sp.name} entrou no campo!');
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
      final baseArmor = e.spec.armor + e.armorBonus;
      final armor = pierce ? baseArmor * .5 : baseArmor;
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
        if (any)
          shots
              .add(Shot(t.pos, t.pos, const Color(0xFF69F0AE), rangeOf(t), .4));
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
      if (sp.role == Role.ranged && lv('pcrt') > 0 && _rnd.nextDouble() < .22)
        dmg *= 2;
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
          if (e != best && (e.pos - best.pos).distance <= splash)
            targets.add(e);
        }
      }
      if (chainOf(t) > 0) {
        var last = best;
        for (var i = 0; i < chainOf(t); i++) {
          Enemy? nx;
          var bd = 1.75;
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
      final pm = (1 + .14 * lv('mdmg') + .08 * lv('vetdmg')) *
          (1 + .35 * (t.level - 1));
      for (final e in targets) {
        _hit(e, dmg, magic: magic, pierce: pierce);
        if (sp.slow > 0) {
          e.slowT = 2.3;
          e.slowAmt = max(e.slowAmt, slowOf(t));
        }
        if (sp.poison > 0) {
          e.poisonT = 4.5;
          e.poisonDps = max(e.poisonDps, sp.poison * pm);
        }
      }
      shots.add(Shot(t.pos, best.pos, color, splash));
    }
  }

  void _impacts(double dt) {
    final p = 1 + .20 * lv('spower');
    final area = 1 + .15 * lv('mslow');
    for (final im in impacts) {
      im.delay -= dt;
      if (im.delay <= 0) {
        final r = spellRadius[Spell.meteor]! * area;
        for (final e in enemies) {
          if ((e.pos - im.pos).distance <= r) _hit(e, 150 * p, magic: true);
        }
        shots.add(Shot(im.pos, im.pos, const Color(0xFFFF6D00), r, .5));
      }
    }
    impacts.removeWhere((i) => i.delay <= 0);
  }

  void _specialBehavior(Enemy e, double dt, List<Enemy> spawned) {
    e.special -= dt;
    if (e.special > 0) return;
    switch (e.kind) {
      case EKind.shaman:
        e.special = 3.5;
        var healed = false;
        for (final ally in enemies) {
          if (ally.hp < ally.maxHp && (ally.pos - e.pos).distance <= 2.2) {
            ally.hp = min(ally.maxHp, ally.hp + 20 * (1 + 0.1 * wave));
            healed = true;
          }
        }
        if (healed) {
          shots.add(Shot(e.pos, e.pos, const Color(0xFF76FF03), 1.8, .3));
        }
      case EKind.kingOrc:
        e.special = 6.5;
        final hpScale =
            (1.0 + 0.24 * (wave - 1)) * pow(1.045, max(0, wave - 4));
        for (var i = 1; i <= 5; i++) {
          final g =
              Enemy(EKind.orc, hpScale, 1.0, 0, (_rnd.nextDouble() - .5) * .65);
          g.s = max(0.0, e.s - .3 * i);
          g.pos = pathPos(g.s, g.off);
          spawned.add(g);
        }
        say('O Rei Orc convocou reforços!');
      case EKind.dragon:
        e.special = 3.8;
        for (final t in towers) {
          if ((t.pos - e.pos).distance <= 2.9) t.hp -= 50 + wave * 2;
        }
        shots.add(Shot(e.pos, e.pos, const Color(0xFFFF6D00), 2.9, .45));
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
      if (e.spec.regen > 0) {
        final effectiveRegen = e.poisonT > 0 ? e.spec.regen * .2 : e.spec.regen;
        e.hp = min(e.maxHp, e.hp + effectiveRegen * dt);
      }
      e.pos = pathPos(e.s, e.off);
      if (e.spec.boss || e.kind == EKind.shaman)
        _specialBehavior(e, dt, spawned);

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
          blocker.hp -= e.spec.dmg * (1 + max(0, wave - 6) * 0.05);
          e.atk = 1.0;
          if (blocker.spec.role == Role.melee && lv('gthorn') > 0) e.hp -= 10;
        }
      } else {
        e.s += e.spec.speed * e.speedScale * (1 - e.slowAmt) * dt;
        if (e.s >= pathLength) {
          e.escaped = true;
          lives -= e.spec.boss ? 5 : 1;
        }
      }
    }
    enemies.addAll(spawned);

    for (final e in enemies) {
      if (e.hp <= 0 && !e.escaped) {
        kills++;
        res[Res.gold] =
            res[Res.gold]! + max(1, (e.spec.reward * goldMult).round());
        if (e.spec.boss) {
          essence += 3;
          runEssence += 3;
          _saveMeta();
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
      _endRun();
    }
  }
}

/// Persiste o progresso permanente do jogo.
///
/// Por enquanto o projeto não fornece um backend de armazenamento; estes
/// helpers mantêm o arquivo compilável sem dados persistidos entre sessões.
Future<String?> loadMetaSave() async => null;

void writeMetaSave(String raw) {
  // Nenhum armazenamento foi configurado no projeto atual.
}
