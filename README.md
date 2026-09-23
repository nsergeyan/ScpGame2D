# Class-D Breakout

A 2D escape-the-facility platformer set in the SCP Foundation universe,
built in Godot 4.7 with GDScript.

You are Class-D subject D-9341. Site-19 is in containment breach, your cell
lock has failed, and the only way out is past the guards, the lasers and
SCP-173.

## Features

- **SCP-173 pursuit AI**: the statue is frozen while you face it and charges
  the moment you look away. It cannot be killed, only outrun or lured into a
  pit.
- **Guard AI state machine**: patrol, alert, stunned and dead states. Guards
  use raycast line-of-sight, so walls break their vision, and a downward
  raycast stops patrols walking off ledges. Rifle guards telegraph their shots
  with a red laser sight.
- **Platformer game feel**: coyote time, jump buffering, variable jump height,
  asymmetric gravity, squash-and-stretch, camera look-ahead and screen shake.
- **Level hazards**: timed laser barriers, crumbling platforms, moving
  platforms, channel-based button and door puzzles, checkpoints.

## Controls

| Action | Keys |
|---|---|
| Move | `A` / `D` or arrow keys |
| Jump / double jump | `SPACE` or `W` |
| Punch | `F` or `J` |
| Skip intro | `ENTER` |

## Running it

Open the project folder in Godot 4.7 and press `F5`, or from a terminal:

    godot --path .

## Architecture

Three autoloaded singletons hold global state, declared in `project.godot`:

| Autoload | Responsibility |
|---|---|
| `GameManager` | HP, score, deaths, run timer, keycard and alarm flags |
| `AudioManager` | pooled sound effects, looping music and alarm |
| `SceneTransition` | fade animation between scenes |

Objects communicate in three ways, and nothing in the project does it a fourth
way:

1. **Signals** for state changes. `GameManager` emits `hp_changed` and the HUD
   subscribes to it, so the player never references the HUD.
2. **Groups** for broadcasts. Dying calls
   `get_tree().call_group("resettable", "reset_to_start")`, which resets every
   guard, platform and trigger in one line. Doors join a group named after
   their channel, so a button opens only the matching doors without ever
   holding a reference to them.
3. **Duck typing** for interactions. The punch calls `take_hit()` on anything
   that has the method, so guards and the statue respond differently to the
   same code path.

## Credits

Built on the [2D Platformer Starter Kit](https://godotengine.org/asset-library/asset/2201)
by G2P Studios (Leon Oscar Kidando), MIT licensed
([source](https://github.com/AdilDevStuff/2D-Platformer-Starter-Kit)). The starter
kit provided the base player controller, the coin and the scene transition system.

Sprites and tilesheets by [Kenney](https://kenney.nl), released under CC0.

SCP Foundation emblem from
[Wikimedia Commons](https://commons.wikimedia.org/wiki/File:SCP_Foundation_(emblem).svg),
recoloured, used under CC BY-SA 3.0.

The starter kit's sound effects were generated with
[gdfxr](https://github.com/timothyqiu/gdfxr).

## License

MIT. See `LICENSE`.
