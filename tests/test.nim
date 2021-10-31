import pkg/balls

import background

suite "how do it do":
  block:
    ## demo the simplest possible use-case
    proc greetingsFromSomewhereElse() =
      echo "hello from thread ", getThreadId()
    echo "initial thread is ", getThreadId()
    let k = background greetingsFromSomewhereElse()
    echo "this echo is emitted from ", getThreadId()
    k()
    echo "surprise, we're still in ", getThreadId()
