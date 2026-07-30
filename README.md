# Project Beatemup

Project Beatemup is a single-player, 2D side-scrolling brawler inspired by
*Streets of Rage* and *Final Fight*. It is built with Godot 4.7 and set in Owen
Sound, Ontario, where Sean takes on the Bayshore Syndicate one street at a time.

The current playable build contains a four-stage campaign: **Second Avenue at
Night**, **The Sewers of Shame**, **The Nightmarish Candy Factory**, and **The
Elevator to the Penthouse**. It includes the complete enemy roster, bosses,
breakable props, pickups, lives, continues, stage-clear tallies, Game Over, and
the ending sequence.

**Play in a browser:** https://claypricepeter-source.github.io/projectbeatemup/

## Running the game

1. Open `project.godot` in Godot 4.7.
2. Press **F5** or select **Run Project**.

The game starts at the title screen and routes through the complete campaign.

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
cans and crates for Coffee and Cash pickups.

Press `Esc` to open or resume the pause menu.

## Project information

Development status, technical architecture, and the roadmap are documented in
[`AGENTS.md`](AGENTS.md). Asset licenses and attribution are recorded in
[`CREDITS.md`](CREDITS.md).
