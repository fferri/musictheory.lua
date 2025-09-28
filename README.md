# musictheory.lua

A Lua library for working with music theory concepts such as notes, intervals, chords, scales, etc.

## Installing

Install via luarocks.

For development, you can install locally with e.g.:

```sh
luarocks --lua-version 5.4 make musictheory-*.rockspec
```

## Example Usage

```lua
mt = require 'musictheory'

-- create a note:
c4 = mt.Note'C4'

-- add intervals:
c4 + mt.Interval'P5' == Note'G4'
c4 + mt.Interval'm3' == Note'E♭4'

-- work out intervals between notes:
mt.Note'B4' - c4 == mt.Interval'M7'

-- pitch class:
c4.pitch_class == mt.PitchClass'C'

-- chords:
Cm = mt.Chord('C', 'min')
Cm:notes() == {mt.Note'C4', mt.Note'E♭4', mt.Note'G4'}
```

There are more classes and methods. Have a look at the source code.

## Contributing

musictheory.lua is open-source and contributions in the form of issues, documentation, pull requests, unit tests, etc are welcome.

## License

See [LICENSE](LICENSE)
