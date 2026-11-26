# Mestre, Temos um Problema de Orcs! (Flutter)

Tower defense mágico em tempo real, no estilo de *Sir, We Have an Orc Problem*: fase de **preparação** e fase de **batalha**, hordas enormes, feitiços ativos e progressão permanente.

## Rodar
```powershell
flutter create --platforms=web .      # (ou windows, se tiver o Visual Studio)
flutter pub get
flutter run -d chrome
```
Copie `pubspec.yaml` e a pasta `lib/` deste projeto por cima da sua. Apague a pasta `test/` se o Flutter recriá-la.

## Controles
- **Mouse:** passe o cursor; clique esquerdo constrói/seleciona/move/lança feitiço; clique direito cancela.
- **Teclado:** setas/WASD, Enter, Esc, 1-3 (feitiços), U (melhorar), Del (vender), N (iniciar batalha), M (mina), K (habilidades), Q/E (alternar torre), H (contraste), T (tamanho do texto).

## Sistemas
- 10 torres: Élfica, Fogo, Gelo, Raios, Orbe Arcano, Canhão Rúnico, Venenosa, Golem, Ent e Altar de Cura (níveis 1-3).
- 3 feitiços com mana: Meteoro, Nova Gélida e Tempestade.
- 11 tipos de inimigos, com chefes nas ondas 5, 10 e 15.
- Mina dos Anões: tela separada para enviar anões a ouro, madeira, armas e cristais.
- Árvore de Habilidades (20 nós): usa essência arcana, que continua entre as partidas.
