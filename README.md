# Class-D Breakout

A 2D platformer set in the SCP Foundation universe, made in Godot 4.7 with
GDScript.

You play Class-D subject D-9341. Site-19 is in containment breach, your cell
lock has failed, and the way out leads past the guards, the lasers and
SCP-173.

## Features

- Every document you pick up is a real SCP Foundation file, and the ones you
  have found can be read in a pause screen. Entries you are still missing show
  as `[ REDACTED ]`, so the archive also tells you how much is left to find.
- The end screen ranks the run from S to D on a score out of 100: 50 for
  documents recovered, 30 for staying alive and 20 for speed.
- While SCP-173 is awake a blink meter runs. Your eyes close every few seconds
  and the statue moves freely while they are shut. Press `E` to blink early at
  a moment you pick, or the meter forces it. The eye in the HUD turns red as
  the statue gets closer.
- SCP-173 is frozen while you face it, and you face the way you walk, so going
  forward means turning your back on it. The button that opens its chamber
  door is behind the statue, so you have to get past it twice. It cannot be
  killed, but it can fall into the acid.
- Waking SCP-173 starts a lockdown countdown. The keycard, the way back past
  the statue and the run to the exit gate all happen on that clock. Dying does
  not reset it, and if it runs out the run ends on its own screen.
- Guards run a state machine with patrol, alert, stunned and dead states. They
  check line of sight with a raycast, so walls block their view, and a second
  raycast pointing down keeps patrols from walking off ledges. Rifle guards
  show a red laser sight before they fire and call out over the radio.
- The player controller has coyote time, jump buffering, variable jump height,
  faster falling than rising, squash and stretch, camera look-ahead and screen
  shake.
- The level has timed laser barriers, crumbling and moving platforms, ladders,
  buttons that open doors on the same channel, and checkpoints.
- The facility is dark apart from pools of light under the ceiling lamps,
  which are placed by reading the tilemap. Some flicker, and once the lockdown
  starts they all pulse red. A screen shader desaturates the image, tints it
  green-grey and adds a vignette and film grain.
- A voiced PA announcement and twelve guard radio lines.

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

Global state lives in five autoloads, registered in `project.godot`:

| Autoload | Responsibility |
|---|---|
| `GameManager` | HP, score, deaths, run timer, lockdown countdown, keycard and alarm flags, archive progress |
| `BlinkUI` | the blink meter, the eyelid overlay, and the `eyes_shut` flag SCP-173 reads |
| `AudioManager` | pooled sound effects, music, guard voice channel, alarm |
| `ArchiveUI` | the pause-screen archive, built in code so it exists on every screen |
| `SceneTransition` | fade animation between scenes |

Objects talk to each other in three ways:

1. Signals for state changes. `GameManager` emits `hp_changed` and the HUD
   listens for it, so the player script never touches the HUD.
2. Groups for broadcasts. When the player dies,
   `get_tree().call_group("resettable", "reset_to_start")` resets every guard,
   platform and trigger. Doors join a group named after their channel, so a
   button can open the matching doors without holding a reference to them.
3. Duck typing for interactions. The punch calls `take_hit()` on anything it
   hits that has the method, and guards and the statue each handle it in their
   own way.

### Design notes

#### Archive order

The level is linear, so `Level.gd` sorts the `documents` group by X position
and hands out archive entries in that order. The first document you reach is
entry 1, and no per-node setup is needed in the editor.

#### Guard voice lines

Guards share a single voice channel in `AudioManager`. A guard only speaks if
that channel is free, so lines never overlap, and the next one can start as
soon as the current clip ends. Death cries pass an `interrupt` flag and cut off
whatever is playing.

#### On-screen messages

Hints, subtitles and story messages share one message box. `show_message`
takes an `important` flag that holds the box for the message's duration, so a
hint cannot overwrite a subtitle. It returns whether the message was shown,
which lets a hint that was held back try again later.

#### Pausing

Opening the archive pauses the scene tree, but that does not stop everything.
`AudioManager` runs with `PROCESS_MODE_ALWAYS`, so its players are paused
separately, and the announcement waits are written to respect the pause
because `SceneTree.create_timer` keeps running through one by default.

#### Checkpoints

Reaching a checkpoint removes everything to its left from the `resettable`
group, so a later death cannot relock the SCP-173 wing or bring the statue
back. The checkpoint inside the wing sets `retires_previous = false`, because
the loop-back sends you back past it.

#### Lockdown timer

The countdown starts when SCP-173 wakes, which puts the whole loop-back under
time pressure. Started at the keycard, its 114 seconds would cover about 25
seconds of play.

#### Ladders

The player checks its own position against each ladder's rectangle, found
through the `ladders` group. An `Area2D` overlap list is one physics frame
behind, so a grab would register a frame late and feel unresponsive.

#### UI theme

All UI styling is in `Assets/UI/facility_theme.tres`, set as the project's
default theme. A `Display` type variation holds the heading font.

## Credits

Built on the [2D Platformer Starter Kit](https://godotengine.org/asset-library/asset/2201)
by G2P Studios (Leon Oscar Kidando), MIT licensed
([source](https://github.com/AdilDevStuff/2D-Platformer-Starter-Kit)). The base
player controller, the coin and the scene transition system come from the kit.

Sprites and tilesheets by [Kenney](https://kenney.nl), released under CC0.
The facility tiles (concrete, steel, doors, ladder, acid) are repainted from
Kenney's sheet by `Tools/make_facility_tiles.py`. The original sheet is kept
unchanged.

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

The code is MIT licensed, see `LICENSE`. Third-party assets keep their own
licenses, listed under Credits.
