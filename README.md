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

## Controls

Sean plays like Streets of Rage 2. The three buttons are the SoR2 pad:
**Special (A)**, **Attack (B)** and **Jump (C)**.

| Action | Keyboard | Controller |
|---|---|---|
| Move (8 directions) | Arrows or **WASD** | D-pad / left stick |
| Attack | **Z** or **J** | X / Square |
| Jump | **X** or **K** | A / Cross |
| Special | **C** or **L** | Y / Triangle |
| Pause | **Esc** | Start |

| Move | Input | Damage |
|---|---|---|
| Combo | Attack repeatedly: jab, jab, straight, low kick, high kick | 6, 6, 8, 10, 14 |
| Double kick | Hold Attack, then release | 16 + 20 |
| Blitz (Grand Upper) | Forward, Forward, Attack | 24 + 4 + 20 |
| Back attack | Hold Attack, press Jump (throws your weapon if armed) | 8 + 12 |
| Defensive special | Special | 16, hits both sides, invincible; costs 8 HP only if it hits |
| Offensive special | Toward + Special | 74 over eight hits; always costs 8 HP |
| Jump attacks | Jump, then Attack (straight up, diagonal, or Down+Attack) | 10+20 / 8 / 12 |
| Grab | Walk into an enemy | |
| Knees | While holding: Toward + Attack (x3) | 8, 8, 8+10 |
| Headbutt | While holding: Attack | 22 |
| Back throw | While holding: Away + Attack. The body hits other enemies | 24 (+16 to whoever it lands on) |
| Vault | While holding: Jump (twice lets go) | |
| Body slam | Holding from behind: Attack | 28 |
| Land on your feet | Hold Up + Jump while being thrown | |

The combo only moves on to the next hit when the current one connects; a miss
starts it over at the jab. The low kick knocks down unless you press Attack
again right as the straight punch pulls back, which chains both kicks.

Pick up food, cash and weapons by pressing **Attack** while standing over them.
Coffee restores 32 of Sean's 104 HP and poutine restores all of it. Knives
(16) and pipes (24) are dropped when you are knocked down and disappear after
being dropped three times. Knife punks drop their knives when knocked down.

Walk right to advance. Entering a combat area locks the camera until its
wave is defeated; when **GO ->** appears, continue right. The **99** timer at
the top refills after each wave; if it runs out you lose a life. Clearing a
stage awards a time bonus and a health bonus. Every 50,000 points earns an
extra life.

Press `Esc` to open or resume the pause menu.

## Project information

Development status, technical architecture, and the roadmap are documented in
[`AGENTS.md`](AGENTS.md). Asset licenses and attribution are recorded in
[`CREDITS.md`](CREDITS.md).
