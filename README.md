# Class-D Breakout

A 2D escape-the-facility platformer set in the SCP Foundation universe,
built in Godot 4.7 with GDScript.

You are Class-D subject D-9341. Site-19 is in containment breach, your cell
lock has failed, and the only way out is past the guards, the lasers and
SCP-173.

## Features

- **SCP archive**: every document you recover is a real SCP Foundation file,
  readable in a pause screen. Uncollected slots read `[ REDACTED ]`, so the
  archive doubles as a collection tracker and a reason to explore.
- **Ranked escape**: the ending grades your run out of 100 on intel recovered
  (50), surviving (30) and speed (20), mapped to S through D.
- **Blink meter**: your eyes have to close every few seconds, and SCP-173
  moves freely while they are shut. Blink early with `E` at a moment you
  choose, or the meter forces one on you. The eye in the HUD glows red as
  the statue closes in.
- **SCP-173 loop-back**: the statue is frozen while you face it, and you face
  the way you walk, so moving forward means turning your back on it. The
  door out of its chamber is opened by a button behind the statue, so you
  have to cross it twice. It cannot be killed, only drowned in acid.
- **Lockdown countdown**: waking SCP-173 arms the site warhead. The keycard,
  the loop-back and the run to the gate all happen against the clock, and
  running out ends the run on its own screen. Dying does not rewind it.
- **Guard AI state machine**: patrol, alert, stunned and dead states. Guards
  use raycast line-of-sight, so walls break their vision, and a downward
  raycast stops patrols walking off ledges. Rifle guards telegraph their shots
  with a red laser sight and call out over the radio.
- **Platformer game feel**: coyote time, jump buffering, variable jump height,
  asymmetric gravity, squash-and-stretch, camera look-ahead and screen shake.
- **Level hazards**: timed laser barriers, crumbling and moving platforms,
  climbable ladders, channel-based button and door puzzles, checkpoints.
- **Voiced facility PA** and twelve lines of guard radio chatter.

## Controls

| Action | Keys |
|---|---|
| Move | `A` / `D` |
| Jump / double jump | `SPACE` or `W` |
| Climb ladder | `↑` / `↓` |
| Blink | `E` |
| Punch | `F` or `J` |
| Open archive | `TAB` |
| Skip intro | `ENTER` |

## Running it

Open the project folder in Godot 4.7 and press `F5`, or from a terminal:

    godot --path .

## Architecture

Five autoloaded singletons hold global state, declared in `project.godot`:

| Autoload | Responsibility |
|---|---|
| `GameManager` | HP, score, deaths, run timer, lockdown countdown, keycard and alarm flags, archive progress |
| `BlinkUI` | the blink meter, the eyelid overlay, and the `eyes_shut` flag SCP-173 reads |
| `AudioManager` | pooled sound effects, music, guard voice channel, alarm |
| `ArchiveUI` | the pause-screen archive, built in code so it exists on every screen |
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

### Notable decisions

**Archive entries assign themselves.** The level is linear, so `Level.gd` sorts
the `documents` group by X position and hands out entries in that order. The
first document you meet is entry 1, with no per-node setup in the editor.

**Guard chatter owns one audio channel.** Whether a guard may speak is answered
by asking whether that channel is busy, not by a timer guessing at clip length.
Death cries pass an `interrupt` flag and take the channel mid-sentence.

**Messages have priority.** Everything shares one message box, so a hint walked
into mid-announcement used to wipe the subtitle. `show_message` takes an
`important` flag that reserves the box, and returns whether it displayed, so a
suppressed hint can retry rather than being silently lost.

**Pausing means three things.** Opening the archive pauses the scene tree,
`AudioManager`'s players (which run with `PROCESS_MODE_ALWAYS` and therefore
ignore tree pause), and the announcement timers (`SceneTree.create_timer`
defaults `process_always` to `true`).

**Checkpoints retire what is behind them.** Dying resets the `resettable`
group, which once meant a death near the exit relocked the SCP-173 wing and
brought the statue back. Reaching a checkpoint now drops everything behind
it out of the group. The checkpoint inside the wing opts out with
`retires_previous = false`, because its loop-back sends you back past it.

**The breach starts the clock, not the keycard.** Starting the countdown at
the keycard left 114 seconds for about 25 seconds of work. Arming it when
SCP-173 wakes means the whole loop-back is played under pressure.

**Ladders use a rectangle test, not an Area2D.** An Area2D's overlap list
lags one physics frame, and a climb that engages late feels broken. The
player finds ladders through a group and checks its own position against
each one's rectangle.

**UI styling lives in one theme.** `Assets/UI/facility_theme.tres` is registered
as the project-wide default, with a `Display` type variation carrying the
heading font.

## Credits

Built on the [2D Platformer Starter Kit](https://godotengine.org/asset-library/asset/2201)
by G2P Studios (Leon Oscar Kidando), MIT licensed
([source](https://github.com/AdilDevStuff/2D-Platformer-Starter-Kit)). The starter
kit provided the base player controller, the coin and the scene transition system.

Sprites and tilesheets by [Kenney](https://kenney.nl), released under CC0.

SCP Foundation emblem from
[Wikimedia Commons](https://commons.wikimedia.org/wiki/File:SCP_Foundation_(emblem).svg),
recoloured, used under CC BY-SA 3.0.

Archive entries are quoted from the [SCP Wiki](https://scp-wiki.wikidot.com),
licensed CC BY-SA 3.0. Each entry credits its own author in game and in
`Scripts/ScpArchive.gd`, which also records the source URL.

The starter kit's sound effects were generated with
[gdfxr](https://github.com/timothyqiu/gdfxr).

The lockdown alarm is from the SCP: Secret Laboratory soundtrack, by
Northwood Studios.

## License

MIT. See `LICENSE`.
