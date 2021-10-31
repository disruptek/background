import pkg/balls

import background

suite "demonstration of background":
  block:
    ## test making function calls in different threads
    when not defined(danger): skip"too slow"

    var q {.global.}: int
    proc fib(n: int; o: int = 0): int =
      result =
        case n
        of 0, 1:
          1
        else:
          fib(n-1) + fib(n-2)

      if o > 0:
        q.inc o

    let
      x = 44
      y = 46
      z = 45

    let a = background fib(x)
    checkpoint "a: created background invocation"

    let b = background fib(y, o = 3)
    checkpoint "b: created background invocation"

    let c = background fib(z, 2)
    checkpoint "c: created background invocation"

    checkpoint "waiting for results..."

    checkpoint "a: return value ", a()
    check a() == 1134903170
    check q == 0
    checkpoint "b: return value ", b()
    check b() == 2971215073
    check q == 5
    checkpoint "c: return value ", c()
    check c() == 1836311903
    check q == 5
