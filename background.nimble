version = "0.0.2"
author = "disruptek"
description = "runs your function call in a background thread"
license = "MIT"

when not defined(release):
  requires "https://github.com/disruptek/balls >= 2.0.0 & < 4.0.0"

requires "https://github.com/nim-works/cps >= 0.6.1 & < 1.0.0"

task test, "run tests for ci":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec "balls"

task demo, "produce a demo":
  exec """demo docs/demo.svg "nim c --threads:on --gc:arc --define:danger --out=\$1 tests/tdemo.nim" 13"""
