import tables
import sequtils
import macros

proc add_ordered_no_duplicates[T](s: var seq[T], item: T) =
    for i in countup(0, s.len-1):
        if s[i] == item:
            return
        elif s[i] < item:
            s.insert(item, i)
            return
    s.add(item)

#================================

type
    EventCallback = proc: void

    Event = object
        priorities: seq[int]
        callbacks: Table[int, seq[EventCallback]]  # priority: @[callbacks]

    EventBus = Table[string, Event]


proc add_event(bus: var EventBus, name: string) =
    bus[name] = Event()

proc register(e: var Event, f: EventCallback, priority=0'i16) =
    e.priorities.add_ordered_no_duplicates(priority)
    discard e.callbacks.hasKeyOrPut(priority, newSeq[EventCallback]())
    e.callbacks[priority].add(f)
proc register(bus: var EventBus, name: string, f: EventCallback, priority=0'i16) =
    bus[name].register(f, priority)

proc trigger(e: var Event) =
    for level in e.priorities:
        for cb in e.callbacks[level]:
            cb()
proc trigger(bus: var EventBus, name: string) =
    bus[name].trigger()


macro RegisteredIn(bus, enumeration) =
    result = newStmtList()

    result.add enumeration[0]

    var idents = newSeq[NimNode]()
    for id in enumeration[0][0][2].children:
        if id.kind == nnkIdent:
            idents.add id
        elif id.kind == nnkEnumFieldDef:
            idents.add id[0]

    let
        enum_ident = enumeration[0][0][0]  # nnkIdent
        converter_name = ident("busStringConverter_" & enum_ident.strVal)
    result.add quote do:
        converter `converter_name`(field: `enum_ident`): string =
            $field

    for field in idents:
        result.add quote do:
            `bus`.add_event(`field`)

    echo result.repr

when isMainModule:
    var bus = EventBus()

    RegisteredIn bus:
        type Events = enum
            BigEvent
            SmallEvent
            MediumEvent

    proc hello =
        echo "hello"
    proc test =
        echo "testy test"

    bus.register(BigEvent, test)
    bus.register(BigEvent, hello)
    bus.register(BigEvent, test)
    bus.register(BigEvent, hello)

    bus.trigger(BigEvent)