# Project Beatemup

Project Beatemup is a single-player, 2D side-scrolling brawler inspired by
*Streets of Rage* and *Final Fight*. It is built with Godot 4.7 and set in Owen
Sound, Ontario, where Sean takes on the Bayshore Syndicate one street at a time.

The current playable build contains the complete Stage 1 vertical slice,
**Second Avenue at Night**: four enemy waves, breakable props and pickups, the
Knife Punk enemy, and a boss fight against "Slick" Rick Delaney. It also includes
lives, continues, Game Over, and a stage-clear score tally.

**Play in a browser:** https://ariesyous.github.io/projectbeatemup/

## Running the game

1. Open `project.godot` in Godot 4.7.
2. Press **F5** or select **Run Project**.

The game starts directly in Stage 1.

The browser build requires WebGL 2.0. Click the game once if it does not
immediately receive keyboard input.

## Keyboard controls

| Action | Keys |
|---|---|
| Move left/right | **Left/Right arrows** or **A/D** |
| Move up/down along the street | **Up/Down arrows** or **W/S** |
| Attack | **Z** or **J** |
| Jump | **X** or **K** |
| Jump kick | Press **Attack** while airborne |
| Confirm Continue/retry/play again | **Z** or **J** |

Press Attack repeatedly to chain Sean's three-hit combo. The third hit knocks
enemies down. To land an attack, line Sean up with the enemy along the street's
depth as well as horizontally.

Walk to the right to advance. Entering a combat area locks the camera until its
wave is defeated; when **GO ->** appears, continue toward the right. Break trash
cans and crates for Coffee and Cash pickups. Defeat Slick Rick at the end of the
street to clear the stage.

`Esc` is reserved for the pause action, but the pause menu is not implemented in
the current build.

## Project information

Development status, technical architecture, and the roadmap are documented in
[`AGENTS.md`](AGENTS.md). Asset licenses and attribution are recorded in
[`CREDITS.md`](CREDITS.md).
