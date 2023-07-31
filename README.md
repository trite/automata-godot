# automata

# TODO

- Lots of things are still hard-coded around grid and kernel usage/sizing, need to get that fixed.
- Grid size needs to be increased
  - Due to how the compute shaders ask for the whole x/y/z local size / dispatch group stuff works, I'm not sure if we might need to get clever with setting these values (for example modifying the local size value in the glsl file and then loading that file again).
  - DO NOT FORGET: the combination of total local size and dispatch group values (lsx x lsy x lsz x dgx x dgy x dgz) needs to be greater than or equal to the total cells being passed in.
- Change out visual for the cells to a different icon
- Find a way to show multiple generations on the screen at the same time in a way that doesn't suck
  - Might try different colors for different generations, but this may prove difficult for cells that stay alive for several consecutive generations
  - Maybe try showing numbers/colors in each cell to denote which generation it is in relation to the "main" or "current" generation. Even better might be combining colors with numbers, where each number is also a different color.

# Rules to try out

- With this new access to generational data, perhaps add an aging mechanic. One problem with many of cellular automata simulations is that cells don't age. If the same cell staying alive for too long (maybe start with like 3 or 4 generations) then having it die off might help encourage more interesting patterns.
  - Alternately, for a continuous spatial automata simulation, perhaps cells that haven't been fully dead in a while cause some kind of penalty that makes them more likely to die, so the older a cell becomes the more likely it is to die.
