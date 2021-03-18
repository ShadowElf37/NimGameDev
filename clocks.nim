import times, os

export os.sleep

let PROGRAM_START = epochTime()

type Clock*[Timers: static Natural] = array[Timers, float]

proc programTime*: float =
   epochTime() - PROGRAM_START

proc reset*(clock: ref Clock, n: int) =
    clock[n] = epochTime()
proc poll*(clock: ref Clock, n: int): float =
    return epochTime() - clock[n]


when isMainModule:
    var c = new Clock[3]
    c.reset(0)
    sleep(1000)
    let t = c.poll(0)
    echo t
    echo c.poll(1)
    echo c[]