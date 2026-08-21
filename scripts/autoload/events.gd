extends Node
## Global signal bus (autoload: `Events`).
##
## Declare cross-scene signals here so scenes don't need hard references to each other.
## Emit with `Events.some_signal.emit(args)`, connect with `Events.some_signal.connect(handler)`.
##
## TODO(team): add signals once the day loop is designed. Likely candidates, as examples only:
##   signal need_satisfied(kind)     # kind: "body" | "mind"
##   signal day_completed
##   signal day_failed(reason)
##   signal sunset
