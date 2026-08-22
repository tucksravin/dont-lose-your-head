# Scratch

## Day Ideas

### Don't panic
Day One? Don't panic -> when you move, the panic meter goes up

### Velma

I can't see without my glasses! The head can't see and the screen's all blurry, big glasses. Head has glasses, they fall off in the intro scene, this is the first challenge, getting the glasses back to the head. 

### One Mental One Physical

The body needs a workout, and so does the brain. Cardio and a crossword

### Lockdown

WarioWare split attention (§3.13): two things at once. **Setup (smahr, Sat 10:56):** head alone in the middle → interact to pick it up → bar blocks the right exit and a pedestal opens → interact to seat the head, then the puzzle starts. (Earlier note to skip this beat is superseded.)

**Preferred (smahr, Sat 10:12): option B — dodge and answer.** Body need: sidestep things falling from the sky (kiki/bouba intrusive thoughts) — rain is fast, two at a time (smahr, Sat 11:02). Mind need: a **short chain of 3–5 puzzles** (smahr, Sat 10:17) — **built as 4**. Answers are **3 floor pads** with the possible values shown above them — stand on the pad and press **interact** (E) to submit (smahr, Sat 10:49). Last correct answer **tips the pedestal toward the exit** so the head rolls off. **Hit or wrong pad = DayManager.fail() → game-over card**. File: `scenes/days/day_lockdown.tscn`.

Earlier version (dropped): hold a button on the left while the head "solves" a tablet on the right. Button is idle; dodge is a verb. Keys (1/2/3) dropped in favour of pads.

### Mirror world

head get's stuck staring at itself in the mirror, flips left and right until you can remove it.

**Built (smahr, Sat 13:49) as `day_mirror.tscn` (C3d, option B).** Head sits on a right-hand platform. A placeholder ColorRect mirror runs from the floor up to it. Head alternates look-at-glass (`look_right`, left/right *and* up/down flipped — ↓ hops) and look-at-player (`look_left`, normal) every `look_hold` (2.2 s). Lil kikis fly out of the glass toward the body (jump them; hit = fail). Walk to the glass, `interact` throws it off the right; the head rolls after it. Fail: sunset or kiki. In `Game.DAY_SCENES` after workout, before platforming.

### Upside down - the final scene - reunion

walk in with the screen flipped upside down, do the animation that we have, then bounce to standing and the screen rights itself, then we walk off into the sunset

**Built (smahr, Sat 14:08) on `reunion.tscn`.** Camera starts at `zoom.y = -1` (floor reads as the ceiling; left/right stay put). Existing dive on E, then a bounce that rights the camera + body + head together, `Head.attach`, scripted walk off the right toward a parked `sun.png` (not the day-timer `sun.tscn`), fade to `main.tscn`. End card is still N1.

### Watching TV / Doomscrolling

The head is watching television / doomscrolling the body needs to break the tv to free it before we go on

### Negative thoughts (kikis) affecting the body's controls

### Working out (button masher)

need to mash and working out literally pushes the kikis away from the head. (barbell)

**Built (smahr, Sat 12:01) as `day_workout.tscn` (C3c).** Walk in, interact with a placeholder barbell (two weights + a bar; pumps on mash), mash Space (`jump`) to shove kikis (`kiki_frames.tres`) off the **loose** head. The swarm's circle **blocks the body from walking to the head**. **Kikis creep back.** Fail: sunset or kikis touching the head. Both needs fire when the swarm is gone. In `Game.DAY_SCENES` after lockdown, before platforming.




body shouldn't touch the head unless its rolling (broadly) or about to tstart to roll. Edge of each playscape has a slope, so when you give it something (the glasses for instance) we push it to the next scene

## Day Plan

Intro -> Velma -> Don't Panic -> Working Out -> Reunion