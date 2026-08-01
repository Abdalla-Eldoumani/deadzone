# Gameplay

Survive waves of enemies. Kill things, level up, take upgrades, get further
than last time.

## Controls

| Key | Action |
|-----|--------|
| `w` `a` `s` `d` or arrows | Move one cell |
| space | Bomb |
| `f` | Freeze (lowercase only) |
| `1` `2` `3` | Take an upgrade on level up |
| enter | Confirm, on the menu |
| `p` | Pause and resume |
| `r` / `m` | Restart / back to menu, on the game over screen |
| `q` or escape | Quit |

The gun fires on its own at whatever is nearest, so there is no aiming. All of
the difficulty is positioning.

## Reading the screen

The arena is the boxed area under the marquee. Dim grey is scenery: the walls,
the rubble on the floor, the two rules that bracket the status bar. Anything
bright is something that matters.

You are the white `@`. Take a hit and you flash red for a moment, then strobe
amber for the second of invincibility that follows.

The status bar along the bottom carries a twenty-segment health gauge -- green
while it holds, amber as it goes, red at the end -- then `WAVE`, `KILLS` and
`LEVEL`. The row under it is the two ability gauges: each fills back up as its
cooldown runs down and reads `READY` when it is charged.

A new wave announces itself with `W A V E n` across the middle of the field for
about a second.

## Enemies

| Type | Glyph | Colour | Health | Moves every | XP |
|------|-------|--------|--------|-------------|-----|
| Zombie | `z` | dull red | 3 | 8 frames | 10 |
| Runner | `r` | hot red | 1 | 4 frames | 15 |
| Tank | `Z` | amber | 10 | 12 frames | 50 |

Health is in hits at base damage. Everything walks straight at you. The colours
run up the heat scale, so the hotter it looks the harder it is to kill.

Waves 1 and 2 are zombies only, waves 3 and 4 mix in runners, wave 5 and up can
send anything. Wave 1 needs 5 kills to clear and each wave after needs 5 more.
Enemies spawn every `60 - wave * 2` frames, never faster than every 15.

Touching an enemy costs 5 health and buys you 1 second of invincibility, so the
worst case is 5 health a second. You start with 100.

## Boss

The Titan arrives at wave 10 with 500 health. Below half it enrages and both
its moves and its attacks come at double speed. Every attack drops two zombie
minions. Walking into it costs 20 health. Killing it is worth 100 XP and the
Boss Slayer achievement.

## Levelling

Reaching `(level + 1) * 50` XP levels you up: health refills, maximum health
goes up by 10, and you pick one of three random upgrades from a framed panel in
the middle of the field. Nothing moves until you press `1`, `2` or `3`.

| Upgrade | Effect per level | Cap |
|---------|------------------|-----|
| Fire Rate+ | one frame less between shots, floor of 2 | 5 |
| Damage+ | +1 damage per hit | 5 |
| Bullet Speed+ | projectiles step one frame sooner every 2 levels | 5 |
| Max Health+ | +20 maximum health and a full heal | 5 |
| Multi-Shot+ | +1 extra projectile per shot | 5 |
| Move Speed+ | offered, but movement is a fixed one cell per keypress and this does not change it yet | 5 |

## Abilities

Both are on cooldowns counted in frames at 30 fps. Each has a ten-segment gauge
on the status bar that fills as the cooldown runs down, with `READY`, the
seconds left, or `ACTIVE` beside it.

**Bomb** (space) kills every enemy on screen, drops an explosion at each one,
pays 5 XP and a kill for each, shakes the screen and rings the bell. 20 second
cooldown.

**Freeze** (`f`) stops every enemy where it stands for 3 seconds. New enemies
still spawn while it is up. 15 second cooldown.

## Achievements

Eight, and they persist across runs in the save file.

| Name | Condition |
|------|-----------|
| First Blood | first kill |
| Getting Started | reach wave 5 |
| Survivor | reach wave 10 |
| Veteran | reach wave 20 |
| Centurion | 100 kills in one run |
| Boss Slayer | kill the Titan |
| Untouchable | clear a wave without being hit |
| Endurance | play for 5 minutes |

The game keeps no wall clock, so Endurance counts played frames: 5 minutes is
`300 * 30` frames of the playing state. Pausing does not advance it.

Unlocking one rings the bell twice and puts a banner across the top of the
field for 3 seconds. The banner always names the most recent unlock.

## Scoring

Score is kills times ten. The top five scores are kept with the wave, kill
count and level they were set at, and the game over screen lists them.

## Tips

- Keep moving. Standing still gets you surrounded.
- Runners first: they close much faster than anything else.
- Freeze is for repositioning out of a corner; the bomb is for when that fails.
- Stay off the walls so you always have somewhere to go.
