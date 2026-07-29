# IdleCommand — Game Design Bible

**Status:** Foundation v1.0  
**Role:** Primary source of truth  
**Project phase:** Foundation / Week 1 complete

> **A tiny world that keeps living while you live yours.**

---

## 1. Vision Bible

### Mission

Build a tiny autonomous world that quietly lives alongside the player's real life.

IdleCommand exists along the bottom of the desktop while the player works, waits for builds, writes, browses, or steps away. It does not demand sessions. It offers companionship, continuity, and the feeling of occasionally witnessing a life already in progress.

The player does not merely run IdleCommand. The player shares their day with it.

### Product promise

When the player glances down, there is a real possibility that something small but meaningful has changed:

- someone started repairing the tent
- the dog fell asleep near the fire
- rain interrupted today's work
- two people shared a quiet moment
- the first wall of a future home appeared

The change must feel caused by life in the world, not by a visible countdown or reward timer.

### North Star

> The world should feel as though it would continue living even if nobody were watching.

### Desired emotions

IdleCommand is designed to create:

- calm
- warmth
- curiosity
- quiet surprise
- attachment
- tenderness
- continuity
- wonder at small details

### Forbidden emotions

IdleCommand must not intentionally create:

- stress
- fear of missing out
- grind
- urgency
- guilt for being absent
- pressure to optimize
- notification fatigue
- anxiety about efficiency

### The player's role

The player is not a god, commander, mayor, foreman, or production manager.

The player is closer to:

- an observer
- a neighbour
- a quiet guardian
- a witness to history

### Internal mantra

> If the world is still comforting to look at after 100 hours, we built the right thing.

---

## 2. World Bible

### Fundamental rule

The world continues.

People make choices, weather changes, relationships develop, work is delayed, and history accumulates while the player is occupied elsewhere.

### Time

The intended final experience is grounded in real time. Morning, afternoon, evening, and night should create different rhythms and behaviours.

The first prototype may use compressed time for development and testing, but the design target remains a slow-lived world rather than a fast simulation.

### Weather

Weather is behavioural, not merely decorative.

Possible weather states include:

- clear sun
- cloud
- wind
- rain
- storm
- fog
- snow in later development

Weather may affect:

- where characters stand or sit
- which activities are possible
- travel and work speed
- mood and social behaviour
- visibility and ambience
- construction progress

Example chain:

Storm → tree falls → path is blocked → wood gathering stops → construction is delayed → the family remains in the tent longer → neighbours help clear the path.

No quest is required. The story emerges from connected consequences.

### Seasons

Long-term development may include spring, summer, autumn, and winter. Seasons should influence behaviour, landscape, available activities, light, weather, and social rhythms.

They must never be a mere palette swap.

### Causality

Abstract numbers should be represented through observable activity wherever practical.

Avoid presenting:

- `+25 wood`
- `construction: 63%`

Prefer showing:

- people carrying timber
- a growing stack beside the site
- foundation stones appearing
- a scaffold changing over several days

### Spatial memory

The world must retain visible evidence of its past.

Examples:

- the original campfire location remains meaningful
- the first tree may become a landmark
- the first cabin may later become a museum or communal building
- old paths remain visible beneath newer roads

Progress must add history rather than erase it.

---

## 3. Character Bible

### Character model

Every significant character may eventually contain:

- name
- age
- identity
- personality traits
- current mood
- energy
- hunger and comfort needs
- skills or profession
- relationships
- memories
- preferences
- fears
- ambitions
- favourite places
- personal routines

The first prototype should use the smallest subset needed to produce believable behaviour.

### Founding characters

#### Nora

Initial direction:

- curious
- brave
- creative
- likely to investigate unfamiliar things
- emotionally expressive through animation rather than text

#### Otto

Initial direction:

- diligent
- reserved
- caring toward animals
- likely to maintain practical routines
- quietly dependable

These traits are starting points, not rigid scripts.

### The dog

The dog is not decoration. It should:

- choose places to sleep
- follow or wait for people
- react to weather
- seek warmth
- display attachment
- create small unscripted moments

### Relationships

Relationships should be directional and allowed to evolve.

Possible relationship states include:

- likes
- trusts
- admires
- loves
- avoids
- misses
- resents
- feels protective toward

Relationships should become visible through proximity, help, shared routines, hesitation, gifts, waiting, and body language.

### Memory

Characters should eventually remember meaningful experiences such as:

- who helped during a storm
- where an important event happened
- the loss or rescue of an animal
- a shared construction project
- a recurring favourite activity

Memories should influence later choices. They do not need to be exposed as stats.

### Emergent lives

The engine should support outcomes such as:

Otto enjoys fishing → drought makes fishing impossible → he helps in the forest → he spends more time with Nora → their relationship changes → they build a home → the settlement's history grows.

The systems create the conditions. The game does not force one canonical story.

---

## 4. Gameplay Bible

### Core interaction loop

Work or live your real life → glance at the world → notice something → feel curiosity or warmth → return to your real task.

This is the primary loop.

### What the player may do

Potential player actions include:

- observe
- move or zoom the camera
- open a larger world view
- inspect the historical chronicle
- discover names and relationships
- occasionally express a broad preference or direction
- explore parts of the world as they become known

All influence must remain light, optional, and respectful of character autonomy.

### What the player must not do

The player should not routinely:

- issue direct orders to individuals
- place every building manually
- drag characters between jobs
- click repeatedly to create resources
- optimize production chains
- maintain an inventory as the central activity
- be punished for ignoring the game

### Two viewing modes

#### Desktop mode

The default state is a low, wide strip integrated with the bottom of the desktop.

Characteristics:

- minimal visual obstruction
- no permanent management HUD
- ambient autonomous activity
- readable silhouettes and events
- designed for peripheral attention

#### World view

A deliberate action such as double-clicking opens a larger view.

Characteristics:

- the same living world, shown closer
- more environmental and character detail
- access to history and optional inspection
- still no transformation into a conventional management dashboard

### Real-time construction

Large changes should unfold as stories over real days.

Illustrative home-building sequence:

- Day 1: measuring and choosing the site
- Day 2: gathering timber
- Day 3: rain prevents work
- Day 4: foundation work
- Day 5: walls begin
- Day 6: roof structure
- Day 7: inhabitants move in

The precise schedule may vary because of weather, needs, help, and world events.

### Failure philosophy

IdleCommand should not contain conventional fail states for ordinary absence or inefficiency.

Setbacks are narrative material:

- rain delays construction
- an illness changes routines
- a broken tool redirects work
- a storm creates community cooperation

A setback should create a story, not a punishment screen.

---

## 5. Art Bible

### Visual form

- 100% 2D pixel art
- side-view presentation
- no isometric world
- no voxel art
- no fake 3D requirement
- no advanced ragdoll dependency

### Composition

The world is extremely wide and comparatively shallow so it can live along the desktop edge.

Characters should remain readable enough for storytelling. They should not be reduced merely to dots in order to make the world feel large.

Initial target range:

- approximately 24–32 pixels for primary character sprites
- broad landscapes with generous negative space
- clear foreground silhouettes
- layered background depth without 2.5D gameplay

### Visual mood

The visual language should feel:

- warm
- uplifting
- calm
- natural
- gently Nordic
- handcrafted
- intimate despite the wide landscape

Avoid making the world feel gloomy, oppressive, aggressively medieval, or visually noisy.

### Animation philosophy

Animation should prioritise small persistent life:

- breathing
- shifting weight
- sitting
- sleeping
- looking around
- smoke movement
- grass and leaves responding to wind
- water movement
- birds
- firelight
- tiny social gestures

A few believable animations are more valuable than a huge number of flashy ones.

### Environmental storytelling

The environment must communicate state without labels:

- rain makes people seek cover
- smoke communicates an active fire
- stacked timber suggests preparation
- footprints or paths show repeated travel
- unfinished walls show construction stage
- shared seating suggests relationships

### UI principle

The ideal desktop experience has no visible HUD.

Any necessary interface should be:

- contextual
- temporary
- quiet
- visually integrated
- absent until requested

---

## 6. Story Bible

### Story is observed, not delivered

IdleCommand should avoid relying on exposition, quest panels, dialogue boxes, or narrated instructions to create meaning.

The player sees:

- two people begin building
- the structure gradually changes
- they later sleep inside
- years later a child plays nearby

The story was not announced. It was witnessed.

### Emergent storytelling

The game creates stories by combining:

- needs
- traits
- memories
- relationships
- weather
- work
- location
- accidents
- opportunities
- time

Authored events may exist, but they should enter the same systemic world and create consequences rather than replace it.

### Small events

Potential events include:

- a travelling merchant
- a wild animal near camp
- a lost child in a later settlement
- a storm
- an unfamiliar object washing ashore
- a new animal joining the camp
- a rare night-sky event

Events should not automatically become quests.

### The Chronicle

The world may preserve history in an optional chronicle or storybook.

It is not an achievement log or quest journal.

Example entries:

- Day 18 — Nora and Otto moved into their first home.
- Day 53 — A merchant arrived by river.
- Day 121 — Luna became the settlement's first teacher.

Entries may include small visual snapshots. The chronicle allows the player to browse years of accumulated history without interrupting everyday life.

---

## 7. Audio Bible

### Purpose

Audio should make the world feel present without demanding attention.

### Soundscape

Primary sounds include:

- wind
- birds
- fire
- rain
- water
- footsteps
- distant animals
- wood work
- soft domestic activity

Later eras may add distant bells, machinery, transport, and electrical ambience while preserving calm.

### Music

Avoid continuous epic or emotionally coercive music.

Music, if used, should be:

- sparse
- gentle
- situational
- capable of fading away completely
- supportive of long desktop sessions

Silence and environmental sound are valid default states.

### Notification philosophy

Audio must not become a notification system that repeatedly pulls the player back.

Important moments may create subtle, natural sounds inside the world rather than UI alerts.

---

## 8. Progression Bible

### Long horizon

IdleCommand is designed to unfold over months and potentially years.

Progress must feel slow enough that places and people become familiar before they change.

### Possible ages

1. Neolithic / Farming Stone Age
2. Bronze Age
3. Iron Age
4. Viking Age
5. Medieval Age
6. Early Modern / Industrial Age
7. Electric / Modern Age
8. Future Age

These names and boundaries remain provisional beyond the Neolithic age. Each age must accumulate visible history instead of replacing the world that came before it.

### First release scope

Only the Nordic Neolithic camp is currently approved for active development.

Future ages are vision, not committed production scope.

### Progression principle

A new age should not simply replace the old visual set. It should layer new life on top of remembered history.

The first fire, shelter, home, path, tree, and gathering place should remain culturally and visually meaningful.

### No progression pressure

The player should not feel required to accelerate the world.

There should be no central demand to:

- maximise output
- unlock everything quickly
- maintain a streak
- purchase speed
- return at exact times

---

## 9. Design Principles

1. **Show rather than explain.** If the world can communicate something visually, avoid a text label.
2. **Remove UI whenever possible.** Interface is a last resort, not a default layer.
3. **The world tells the story.** Systems and behaviour carry meaning.
4. **Small details beat large feature counts.** A dog choosing the warm side of the fire may matter more than an entire upgrade tree.
5. **Everything may be ignored.** The world must remain safe to leave unattended.
6. **Absence creates no guilt.** Never punish the player for living their real life.
7. **Characters are not tools.** They have autonomy and are observed rather than owned.
8. **Setbacks become stories.** Delay and disruption should create narrative consequences, not failure popups.
9. **History remains visible.** Progress should preserve evidence of earlier life.
10. **Calm is a system requirement.** Not merely an art direction.
11. **Peripheral readability matters.** Important moments must be legible in desktop mode.
12. **The simulation comes before content scale.** A tiny living camp is better than a large lifeless city.

---

## 10. Milestone 0.0.1 — Definition of success

The first world contains only:

- Nora
- Otto
- one dog
- one campfire
- one small hide-and-reed shelter
- a small natural landscape

They can:

- walk
- rest
- sleep
- eat
- gather branches, dry grass, and birch-bark tinder
- kindle fire with flint and pyrite
- talk or sit together
- seek shelter from rain
- look at the night sky

The environment can:

- transition through day and night
- produce calm ambient movement
- create simple rain
- influence character behaviour

There is:

- no resource HUD
- no inventory
- no XP
- no quest log
- no direct control
- no building placement

### Success test

The milestone succeeds when a person can leave the prototype running during a normal day and genuinely wants to glance back several times simply to see what Nora, Otto, and the dog are doing.

---

## Golden Rule

> **IdleCommand is not trying to steal your attention. It is trying to deserve it.**

And the deeper illusion beneath the entire project:

> The player should never feel that the world exists solely for them. They should feel fortunate to witness a world that would have continued living anyway.
