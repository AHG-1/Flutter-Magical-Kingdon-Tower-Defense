import 'package:flutter/services.dart';

/// Ações lógicas do jogo (teclado e mouse são convertidos para elas).
enum GameAction {
  up,
  down,
  left,
  right,
  confirm,
  cancel,
  sell,
  skipWave,
  prevUnit,
  nextUnit,
  pause,
  contrast,
  textSize,
  skills,
  mine,
  upgrade,
  spell1,
  spell2,
  spell3,
}

class InputManager {
  InputManager(this.onAction);

  final void Function(GameAction) onAction;
  final Set<GameAction> _down = {};
  final Map<GameAction, double> _timer = {};

  static const _dirs = {
    GameAction.up,
    GameAction.down,
    GameAction.left,
    GameAction.right,
  };

  static final Map<LogicalKeyboardKey, GameAction> keyMap = {
    LogicalKeyboardKey.arrowUp: GameAction.up,
    LogicalKeyboardKey.keyW: GameAction.up,
    LogicalKeyboardKey.arrowDown: GameAction.down,
    LogicalKeyboardKey.keyS: GameAction.down,
    LogicalKeyboardKey.arrowLeft: GameAction.left,
    LogicalKeyboardKey.keyA: GameAction.left,
    LogicalKeyboardKey.arrowRight: GameAction.right,
    LogicalKeyboardKey.keyD: GameAction.right,
    LogicalKeyboardKey.enter: GameAction.confirm,
    LogicalKeyboardKey.space: GameAction.confirm,
    LogicalKeyboardKey.keyZ: GameAction.confirm,
    LogicalKeyboardKey.escape: GameAction.cancel,
    LogicalKeyboardKey.backspace: GameAction.cancel,
    LogicalKeyboardKey.keyX: GameAction.cancel,
    LogicalKeyboardKey.delete: GameAction.sell,
    LogicalKeyboardKey.keyV: GameAction.sell,
    LogicalKeyboardKey.keyN: GameAction.skipWave,
    LogicalKeyboardKey.keyQ: GameAction.prevUnit,
    LogicalKeyboardKey.keyE: GameAction.nextUnit,
    LogicalKeyboardKey.keyP: GameAction.pause,
    LogicalKeyboardKey.keyH: GameAction.contrast,
    LogicalKeyboardKey.keyT: GameAction.textSize,
    LogicalKeyboardKey.keyK: GameAction.skills,
    LogicalKeyboardKey.keyM: GameAction.mine,
    LogicalKeyboardKey.keyU: GameAction.upgrade,
    LogicalKeyboardKey.digit1: GameAction.spell1,
    LogicalKeyboardKey.digit2: GameAction.spell2,
    LogicalKeyboardKey.digit3: GameAction.spell3,
    LogicalKeyboardKey.numpad1: GameAction.spell1,
    LogicalKeyboardKey.numpad2: GameAction.spell2,
    LogicalKeyboardKey.numpad3: GameAction.spell3,
    LogicalKeyboardKey.tab: GameAction.skills,
  };

  void setPressed(GameAction a, bool down) {
    if (down) {
      if (_down.add(a)) {
        onAction(a);
        if (_dirs.contains(a)) _timer[a] = 0.35;
      }
    } else {
      _down.remove(a);
      _timer.remove(a);
    }
  }

  /// Repete o movimento do cursor enquanto a seta estiver pressionada.
  void update(double dt) {
    for (final a in _down.where(_dirs.contains).toList()) {
      final t = (_timer[a] ?? 0) - dt;
      if (t <= 0) {
        onAction(a);
        _timer[a] = 0.12;
      } else {
        _timer[a] = t;
      }
    }
  }
}
