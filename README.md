# Party Arena — Godot 4 (vertikaler Slice)

Neubau der Party Arena in **Godot 4.7** (Open Source, keine Lizenzkosten). Ersetzt das Canvas-JS-Flickwerk durch eine saubere Engine.

## Spielkonzept (verbindlich)
Siehe `../DC-Minigame/.hermes/plans/2026-08-06_party-arena-spielkonzept.md`:
- 8–10 Runden, 2–8 Spieler, 20–30 Min
- 40 Felder, Stern-Kauf (20 Münzen, wandert), Catch-up
- Items, Minispiel-Kategorien, 1 Hauptkarte (erweiterbar)

## Struktur
```
party-arena-godot/
├── project.godot          # Engine-Konfig (GL Compatibility für Mobile)
├── scenes/
│   └── main.tscn          # Hauptszene
├── scripts/
│   ├── main.gd            # Orchestrierung (Runden, UI, Minigame-Start)
│   ├── board_logic.gd     # Reine Spiellogik (headless testbar)
│   ├── player_data.gd     # Spieler-Zustand
│   └── minigame.gd        # Minigame-Basis-API
├── minigames/
│   ├── reaction_minigame.gd  # Reaktion (schnell tippen)
│   └── coin_minigame.gd      # Münzen sammeln
├── tests/                 # Headless-Logik-Tests
└── assets/                # (leer — Danny zeichnet Pixel-Art)
```

## Ausführen
```bash
# Godot 4.7 installiert unter /opt/data/godot
/opt/data/godot/Godot_v4.7.1-stable_linux.x86_64 --path /opt/data/party-arena-godot
```

## Tests (headless, kein Rendering)
```bash
G=/opt/data/godot/Godot_v4.7.1-stable_linux.x86_64
$G --headless --script tests/test_logic.gd      # 18 Tests Board-Logik
$G --headless --script tests/test_minigames.gd  # 5 Tests Minigames
$G --headless --script tests/test_scene.gd      # Szenen-Load
```

## Arbeitsteilung
- **Danny:** zeichnet Welt/Tiles/Figuren (Pixelorama/Aseprite → `assets/`)
- **Hermes:** Spielmechanik, Minispiele, Runden, Server (alles in GDScript)

## Nächste Schritte
- [ ] Echte Figuren-Sprites (Danny) statt farbiger Kreise
- [ ] Karte mit 40-Felder-Pfad aus Tiles (Danny zeichnet, Hermes bindet ein)
- [ ] Multiplayer (WebSocket in Godot) statt nur lokal
- [ ] Mehr Minispiele (alle 5 Kategorien)
- [ ] Export als Web/Desktop/App
