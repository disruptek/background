version = "0.0.1"
author = "disruptek"
description = "runs your function call in a background thread"
license = "MIT"

when not defined(release):
  requires "https://github.com/disruptek/balls >= 2.0.0 & < 4.0.0"

requires "https://github.com/nim-works/cps >= 0.4.4 & < 1.0.0"

task test, "run tests for ci":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec "balls"

task demo, "produce a demo":
  exec """demo docs/demo.svg "nim c --define:release --out=\$1 tests/test.nim""""

