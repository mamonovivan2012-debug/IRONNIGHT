# IRON NIGHT — Godot 4

A compact, fully-scripted 3D first-person monster arena prototype for **PC and Android/iOS touch screens**. The project uses procedural geometry and materials, so it has no paid assets or external dependencies.

## Requirements
- Godot **4.3 or newer**
- Desktop: Windows / Linux / macOS
- Mobile: Android or iOS export templates and the matching platform SDK

## Run
1. Download and extract the ZIP.
2. Open Godot Project Manager → **Import**.
3. Select this folder's `project.godot`.
4. Press **F6/F5** or the Play button.

## Controls
| Action | PC |
|---|---|
| Move | WASD |
| Look | Mouse |
| Fire pistol | Left mouse |
| Sword | Q or right mouse |
| Grenade | G |
| Reload | R |
| Switch weapon | 1 sword / 2 pistol |
| Jump | Space |
| Release mouse | Esc |

On a touchscreen, a left virtual stick controls movement, dragging the right side aims, and on-screen buttons handle fire, sword, grenade and jump.

## Combat
- **Pistol:** 12-round magazine, fast single shots, hitscan. Head hits deal 3× damage, legs deal reduced damage.
- **Sword:** slower heavy melee sweep with area damage.
- **Grenades:** throw with ballistic motion; detonate after 3 seconds with a large area blast.
- **Waves:** enemy count and toughness rise as you survive.

## Visuals
Weapons, grenade and the Ash Titan enemy are now imported as separate GLB mesh assets in `assets/models/` (with named mesh parts and PBR materials), rather than assembled from primitive meshes at runtime: a layered metal hand cannon with barrel, rails, sights and glowing channel; a runed greatsword with a crossguard and wrapped hilt; and a horned brute assembled from armor plates, limbs, claws and glowing relic details. The arena is generated in GDScript: gothic pillars, ruins, emissive runes, red practical lights, a procedural sky, fog, filmic tonemapping, glow, metallic weapon materials, hit sparks, death bursts and explosion particles. The project uses Godot's GL Compatibility renderer for broad mobile support. For a higher-end PC build, switch the renderer in Project Settings to **Forward+** and enable advanced environment effects (SSAO/SSIL) if the target GPU supports them.

## Build for GitHub / exports
Commit the whole project folder (including `project.godot`, `main.tscn`, `scripts/`, and `shaders/`) to GitHub. No `.godot/` cache directory is required.

In Godot: **Project → Export**. Install export templates, add a Windows/Linux/macOS preset and an Android preset. For Android, configure the Android SDK/JDK in Editor Settings and set a unique package name before release.

## Notes / next upgrades
This is a playable foundation, not a finished AAA production. It intentionally avoids copyrighted assets. A production release would benefit from authored character/weapon models, animation rigs, sound design, controller remapping, save/settings menus, performance profiling on target phones, and multiplayer/netcode.


## Imported 3D models
- `assets/models/hellforged_handcannon.glb` — detailed hand cannon mesh
- `assets/models/oathbreaker_greatsword.glb` — tapered greatsword with runic inlay
- `assets/models/hellfire_grenade.glb` — fragmentation grenade mesh
- `assets/models/ash_titan.glb` — assembled horned monster character mesh

These are actual imported GLB model assets used by the gameplay scripts. They are static meshes at this stage; skeletal deformation, polished animation clips, and high-resolution sculpted textures are not included yet.

## Автоматическая сборка Windows EXE + отдельный PCK через GitHub Actions

В репозитории есть workflow `.github/workflows/build-windows.yml` и пресет `export_presets.cfg`. Экспорт настроен с `binary_format/embed_pck=false`, поэтому игровые ресурсы не встраиваются в EXE: создаются два отдельных файла — `IRON_NIGHT.exe` и `IRON_NIGHT.pck`.

1. Создай репозиторий GitHub и загрузи в него **все файлы этой папки**.
2. Открой вкладку **Actions** в репозитории и разреши GitHub Actions, если GitHub попросит.
3. При push в ветку `main` или `master` сборка запустится автоматически. Её также можно запустить вручную: **Actions → Build Windows EXE → Run workflow**.
4. Когда задача завершится зелёной галочкой, открой её и скачай артефакт `IRON_NIGHT-Windows-x86_64` в разделе **Artifacts**.
5. В артефакте будут `IRON_NIGHT.exe`, `IRON_NIGHT.pck`, `Start_IRON_NIGHT.bat` и архив `IRON_NIGHT-Windows.zip`.
6. Для запуска распакуй `IRON_NIGHT-Windows.zip` и оставь EXE и PCK в одной папке. Запусти EXE или `Start_IRON_NIGHT.bat`.

Сборка выполняется на GitHub-hosted Ubuntu runner с официальными Godot 4.3 Windows export templates. Сам EXE создаётся в Actions; он не хранится в Git-репозитории. Первый запуск workflow скачивает движок и шаблоны экспорта. Workflow проверяет наличие обоих файлов и завершает сборку ошибкой, если EXE или PCK отсутствует. Если экспорт завершится ошибкой, открой лог шага **Export Windows EXE and separate PCK**.


## Исправления запуска и экспорта
- Граната создаётся из `scenes/grenade.tscn` (PackedScene), а не из GDScript-файла.
- Исправлены явные типы `Vector3` в `scripts/player.gd` и `Vector2` в `scripts/hud.gd`.
- GitHub Actions выполняет headless-импорт ресурсов GLB до экспорта Windows.
- Windows export preset настроен на отдельный PCK: EXE и PCK должны лежать рядом.
