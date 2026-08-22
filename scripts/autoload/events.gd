extends Node
## Global signal bus (autoload: `Events`).
##
## Declare cross-scene signals here so scenes don't need hard references to each other.
## Emit with `Events.some_signal.emit(args)`, connect with `Events.some_signal.connect(handler)`.
##
## Only the day-flow signals are here so far. Add more as systems land — but keep
## it to things that genuinely cross scenes. A signal used inside one scene should
## be declared on that scene's script instead (README → conventions).

## One keyed win condition in the current day was satisfied. `key` is "body" or
## "mind" (DESIGN.md §2.2). WinConditionManager emits this; Sfx / the HUD listen.
signal condition_satisfied(key: String)

## Every win condition in the current day is now satisfied — the day is won.
## DayManager emits this as it releases the head. Game does not listen; Sfx does.
signal day_completed

## The current day was lost. DayManager emits this as it shows the game-over
## card. `reason` is free-form ("sunset", "pit", "panic", …).
signal day_failed(reason: String)

## The sun finished its arc (TASKS.md T3). NOTE: nothing emits this — the
## Sun node has its own local `sunset` signal (scenes/sun/sun.gd) and
## DayManager connects to that directly. Kept so the T0 contract still reads
## the same; emit it from the Sun if a cross-scene listener ever needs it.
signal sunset
