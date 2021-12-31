when not (defined(gcArc) or defined(gcOrc)): {.error: "requires arc/orc".}
import std/genasts
import std/macros

import pkg/cps
export cps

type
  Backgrounded* = ref object of Continuation ## background() produces these

proc noop*(c: Backgrounded): Backgrounded {.cpsMagic.} =
  ## leaked impl detail; ignore it 😙
  c

proc worker(c: Backgrounded) {.thread, nimcall.} =
  {.gcsafe.}:
    discard trampoline c

macro background*(call: typed): untyped =
  ## Run the first argument, a call, in another thread.  Returns
  ## a continuation that resolves with the result of the call.
  runnableExamples:
    proc fib(n: int; o: bool = false): int =
      case n
      of 0, 1:
        1
      else:
        fib(n-1) + fib(n-2)

    let a = background fib(45)
    let b = background fib(44)
    assert 1836311903 == recover a
    assert 1134903170 == recover b

  if call.kind notin CallNodes:
    error "provide a call() to background"

  # get the call's parameter definitions as a seq
  var parameters = call[0].getImpl.params[0..^1]

  # compose new parameter symbols for a future proc
  var newParams: seq[NimNode]
  for index, arg in parameters.pairs:
    if index == 0:
      newParams.add arg                          # add the return value
    else:
      let param = nskParam.genSym arg[0].strVal  # proc argument symbol
      newParams.add newIdentDefs(param, arg[1])  # no default value needed

  # we're going to create a "runner" continuation that captures
  # the arguments into a continuation object
  let rName = nskProc.genSym"runner"
  let runner = newProc(rName, newParams)         # use those new params
  runner.addPragma:
    nnkExprColonExpr.newTree(bindSym"cps", ident"Backgrounded")

  # the runner's sole job is to call the original function with the
  # arguments which will have been moved into the continuation (see below)
  let ogCall = newCall call[0]
  runner.body = newStmtList ogCall

  # we need to compose a similar call for the runner itself; this is what
  # we'll use to whelp it at the original call site
  let mCall = newCall rName

  # the continuation that issues that call is the monitor
  let mName = nskProc.genSym"monitor"
  var mParams = @[copyNimTree newParams[0]] # the monitor's return value

  # copy the param symbols into the calls, omitting the return value
  for identdefs in newParams[1..^1]:     # these are parameter identdefs
    ogCall.add identdefs[0]              # the call is passed each parameter
    mParams.add copyNimTree identdefs    # a copy for the monitor's params
    mCall.add mParams[mParams.high][0]   # monitor's call uses the same sym

  let monitor = newProc(mname, mParams)  # creating the monitor
  monitor.addPragma:
    nnkExprColonExpr.newTree(bindSym"cps", ident"Backgrounded")
  let c = nskVar.genSym"continuation"  # the continuation we'll send off
  monitor.body =
    genAstOpt({}, worker = bindSym"worker", noop = bindSym"noop",
              c, mCall, Arg = ident"Backgrounded"):
      var c = whelp mCall                 # call the runner continuation
      var th: Thread[Arg]                 # prepare a Thread[Backgrounded]
      createThread(th, worker, c)         # pass the continuation to the thread
      noop()                              # return control to the user
      joinThread th                       # wait for the thread to complete
      recover c                           # recover any result

  var monCall = newCall(mName)            # this call makes the monitor
  for arg in call[1..^1]:                 # iterate over the original args
    monCall.add arg                       # add them into the call

  result = newStmtList(runner, monitor)   # we've defined runner and monitor
  result.add:                             # to this we add the instantiation
    genAstOpt({}, monCall):
      var monitor = whelp monCall         # create the monitor continuation
      discard monitor.fn(monitor)         # the first leg creates the thread
      monitor                             # let the user finish the monitor
