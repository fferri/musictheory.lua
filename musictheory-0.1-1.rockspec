package = "musictheory"
version = "0.1-1"
source = {
   url = "git+https://github.com/fferri/musictheory.lua.git",
   tag = "v0.1.0"
}
description = {
   summary = "A Lua library for music theory (notes, intervals, chords, scales)",
   detailed = [[
      musictheory provides classes for representing and manipulating
      musical concepts such as notes, intervals, chords, and scales.
   ]],
   license = "MIT",
   homepage = "https://github.com/fferri/musictheory.lua"
}
dependencies = {
   "lua >= 5.1",
   "middleclass >= 4.1.1"
}
build = {
   type = "builtin",
   modules = {
      ["musictheory"]            = "src/musictheory/init.lua",
      ["musictheory.Note"]       = "src/musictheory/Note.lua",
      ["musictheory.Interval"]   = "src/musictheory/Interval.lua",
      ["musictheory.PitchClass"] = "src/musictheory/PitchClass.lua",
      ["musictheory.NoteSequence"] = "src/musictheory/NoteSequence.lua",
      ["musictheory.Chord"]      = "src/musictheory/Chord.lua",
      ["musictheory.Scale"]      = "src/musictheory/Scale.lua",
      ["musictheory.utils"]      = "src/musictheory/utils.lua",
   }
}
