# IdleCommand

> **A tiny world that keeps living while you live yours.**

IdleCommand is a calm, living desktop companion: a tiny autonomous society that exists along the bottom of the desktop while the player works, waits, creates, and lives.

It is not designed to steal attention. It is designed to deserve it.

## Product identity

IdleCommand is **not** a traditional idle game, city builder, productivity dashboard, or resource-management game.

The player does not micromanage villagers, click for resources, optimize production chains, or return because of guilt. The player observes a world that continues without them and gradually becomes attached to its people, places, memories, and history.

## Current playable whitebox

The first living Nordic Neolithic camp prototype now includes:

- Nora, Otto, and Milo the dog
- autonomous wandering, tinder gathering, flint-and-pyrite fire tending, resting, following, sheltering, and sleeping
- a continuous three-minute day/night cycle
- changing rain weather
- a separate hide-and-reed shelter, craft props, and stateful campfire
- subtle emergent story messages rather than a permanent HUD
- local save state and offline world-time progression
- a wide 1280 × 360 desktop-strip presentation

The prototype now uses handcrafted-style pixel-art landscapes, characters, actions, and separate world props. The current milestone still tests whether this one historical camp feels alive before later ages are considered.

## Run it

1. Install Godot 4.3 or newer.
2. Clone this repository.
3. Import `project.godot` in Godot.
4. Press **F6/F5**.
5. Do not control anything. Let the camp live for at least ten minutes.

The save file is stored by Godot at `user://idlecommand_save.cfg` and updates when a new in-world day begins or the window closes.

## Foundation documents

The project's source of truth lives in [`docs/foundation`](docs/foundation):

- [Game Design Bible](docs/foundation/GAME_DESIGN_BIBLE.md)
- [Design Authority](docs/foundation/DESIGN_AUTHORITY.md)
- [Causal World & Story Engine Plan](docs/foundation/CAUSAL_WORLD_STORY_ENGINE_PLAN.md)
- [Milestone 0.0.1 — The Camp](roadmap/M0_THE_CAMP.md)

Every feature, asset, system, and technical decision must be evaluated against these documents.

## Acceptance test

The whitebox succeeds when a person can leave it running, glance back later, and notice a small believable situation without having issued a command.

Examples include Otto returning with branches, Milo following Nora through the rain, or everyone gathering near the fire after dark.

## Guiding principle

> **IdleCommand is not trying to steal your attention. It is trying to deserve it.**
