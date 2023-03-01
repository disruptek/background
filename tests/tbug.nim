import pkg/balls

import background

suite "how to crash it":
  block:
    ## failing successfully

    # define the function to run remotely
    proc greetingsFromSomewhereElse(x: int): int =
      echo "hello from thread ", getThreadId()
      return x + 1

    # set the stage for the movement
    echo "spawning background call from ", getThreadId()

    # run the function in the background
    var k = background greetingsFromSomewhereElse(3)

    echo "recovering result in ", getThreadId()
    assert 4 == recover k

    echo "received result in ", getThreadId()
