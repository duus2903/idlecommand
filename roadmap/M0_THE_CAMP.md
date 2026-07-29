# Milestone 0.0.1 — The Camp

## Objective

Prove that the smallest possible IdleCommand world can feel alive, comforting, and worth revisiting during an ordinary workday.

## Included world

- Nora
- Otto
- one dog
- one small Nordic Neolithic hide-and-reed shelter
- one campfire
- a narrow natural landscape
- day and night
- clear weather and rain

## Required behaviours

### Characters

- walk between meaningful locations
- idle with variation
- sit
- sleep
- eat
- gather branches and dry tinder
- kindle fire with flint and pyrite
- warm themselves by the fire
- seek cover from rain
- spend time together
- occasionally choose solitude
- look toward notable events or the night sky

### Dog

- follow a person sometimes
- choose a resting place
- seek warmth
- react to rain
- sleep
- display attachment through proximity

### Environment

- day/night transition
- campfire animation and light
- wind movement in vegetation
- subtle sky motion
- rain that changes behaviour
- ambient wildlife or birds

## Explicitly excluded

- resource HUD
- inventory
- XP or levels
- quests
- building placement
- direct character commands
- skill trees
- economy
- multiple settlements
- later ages
- GitHub task visualisation
- productivity metrics

## Prototype modes

### Desktop mode

- low and wide
- visually quiet
- suitable for always-on-top use
- no permanent interface
- important actions readable at a glance

### Expanded view

- closer camera
- same simulation
- optional inspection only
- no management dashboard

## Technical principles

The simulation should be data-driven enough to expand later, but architecture must remain proportional to this milestone.

Minimum conceptual systems:

- world clock
- weather state
- character state
- simple needs
- behaviour selection
- locations and interactable objects
- relationship/proximity context
- event/history logging
- persistence

## Development order

1. Static whitebox scene
2. World clock and day/night
3. Character movement between locations
4. Behaviour selection
5. Shelter, tinder, flint-and-pyrite fire, food, branch and sleep interactions
6. Dog behaviour
7. Rain and shelter response
8. Persistence
9. Desktop window behaviour
10. Pixel-art replacement and ambient animation
11. Long-running observation test

## Acceptance criteria

The milestone passes only when:

- the simulation can run unattended without breaking
- characters do not visibly repeat one short loop
- rain produces understandable behavioural change
- the dog feels connected to the people
- the camp has different rhythms across the day
- the player can understand most activity without text
- leaving the app alone causes no penalty
- at least one observer voluntarily glances back several times during a normal day
- the experience remains calm in desktop mode

## The decisive question

> If nothing could ever be unlocked beyond this camp, would watching it still feel worthwhile?

If the answer is no, later ages and more content are not the solution. The camp must become more alive first.
