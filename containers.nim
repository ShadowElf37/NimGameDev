import macros, tables

type ObjectContainer[S: static int, T] = object
    # ARRAY STRUCTURE
    # [active object 1 ... active object n ... 00000000 ... reserved object n ... reserved object 1]
    arr*: ref array[S, T]
    count*: int
    reserved_count*: int
    table*: ref Table[uint, ptr T]
    table_id_counter: uint


iterator items*[S: static int, T](x: ObjectContainer[S, T]): T =
    # gets all objects that are allocated and ready for use
    var i = 0
    while i < x.count:
        yield x.arr[i]
        i += 1
iterator item_ptrs*[S: static int, T](x: var ObjectContainer[S, T]): ptr T =
    # gets all object ptrs that are allocated and ready for use
    var i = 0
    while i < x.count:
        yield addr x.arr[i]
        i += 1

iterator reserved*[S: static int, T](x: ObjectContainer[S, T]): T =
    # gets all objects that are allocated but not marked as ready for use
    var i = 1
    while i < x.reserved_count + 1:
        yield x.arr[][^i]
        i += 1
iterator reserved_ptrs*[S: static int, T](x: ObjectContainer[S, T]): ptr T =
    # gets all objects that are allocated but not marked as ready for use
    var i = 1
    while i < x.reserved_count + 1:
        yield addr x.arr[][^i]
        i += 1


func getLast*[S: static int, T](x: ObjectContainer[S, T]): ptr T =
    addr x.arr[x.count-1]

func `$`*[S: static int, T](x: ObjectContainer[S, T]): string =
    "Container[" & $T & "]:  " & $x.arr[]
func `[]`*[S: static int, T](x: ObjectContainer[S, T], key: uint): ptr T =
    x.table[key]


proc new*[S: static int, T](container: var ObjectContainer[S, T]): ptr T =
    # creates an object after all the other objects in the container array

    # die if we're at the edge
    if container.count + container.reserved_count > S:
        raise newException(OutOfMemDefect, "[new] out of space in " & $T & " container!")

    # make a pointer to the first unallocated object space, which is tracked for free by container.count
    let p = cast[ptr T](cast[int](container.arr) + sizeof(T) * container.count)
    container.table_id_counter += 1
    container.count += 1
    # ensure the table knows where it is
    p.table_id = container.table_id_counter
    container.table[container.table_id_counter] = p
    return p  # return pointer

proc destroy*[S: static int, T](container: var ObjectContainer[S, T], id: uint) =
    # detroys an INITIALIZED object in the contiguous map when you're done with it
    let
        p: ptr T = container[id]  # pointer to the object you're destroying
        last: ptr T = container.getLast()  # pointer to the last object

    # overwrite the destroyed object with the last object's data
    # object creation works at the end of the array, and if the array is cluttered with gaps then you hit the edge fast
    copyMem(p, last, sizeof T)
    container.count -= 1
    container.table[last.table_id] = p  # the last object's id should point to its new address
    last.table_id = 0  # just making sure the old last-object's address isn't mistaken for a real one
    container.table.del(id)  # remove the destroyed object's id from the map
proc destroy*[S: static int, T](container: var ObjectContainer[S, T], obj: ptr T) =
    # destroy by object ptr instead of by id
    destroy(container, obj.table_id)


proc reserve*[S: static int, T](container: var ObjectContainer[S, T]): ptr T =
    # creates an object at the VERY end of the array
    # these should be used for async object creation, in case it takes a while
    # CANNOT BE DESTROYED UNTIL FINALIZED

    # die if we're at the edge
    if container.count + container.reserved_count > S:
        raise newException(OutOfMemDefect, "[reserve] out of space in " & $T & " container!")

    # make a pointer to the first unallocated object space, which is tracked for free by container.count
    let p = cast[ptr T](cast[int](container.arr) + (S - container.reserved_count - 1) * sizeof(T))
    container.reserved_count += 1
    # add it to the table so we can reference it by the same id forever
    container.table_id_counter += 1
    p.table_id = container.table_id_counter
    container.table[container.table_id_counter] = p
    return p  # return pointer

proc finalize*[S: static int, T](container: var ObjectContainer[S, T], obj: ptr T): ptr T =
    # mark reserved object as finalized, and give it a table id

    # pointer to end of real finalized objects
    let p = cast[ptr T](cast[int](container.arr) + sizeof(T) * container.count)
    # copy reserved object to the active slot
    copyMem(p, obj, sizeof T)
    # overwrite old reserved object with the last of the reserved objects to avoid gaps
    copyMem(obj, addr container.arr[][^container.reserved_count], sizeof T)
    # stuff
    container.count += 1
    container.reserved_count -= 1
    # note that it should already be in the table
    return p  # return pointer


macro container*(name, typesec: untyped) =
    echo treeRepr name
    echo treeRepr typesec
    result = newStmtList()

    var
        obj_ident: NimNode
        container_ident: NimNode
        max_size: NimNode

    if name.kind != nnkBracketExpr:
        raise newException(ValueError, "bad syntax, or maximum container size not specified")

    container_ident = name[0]
    max_size = name[1]

    obj_ident = typesec[0][0][0]

    typesec[0][0][2][2].add(newIdentDefs(ident "table_id", ident "uint", newEmptyNode()))

    echo treeRepr typesec

    result.add(typesec)
    result.add quote do:
        var `container_ident`* = ObjectContainer[`max_size`, `obj_ident`]()
        `container_ident`.arr = new array[`max_size`, `obj_ident`]
        `container_ident`.table = newTable[uint, ptr `obj_ident`](`max_size`)


when isMainModule:
    const MAX_ENTITY = 20

    expandMacros:
        container Entities[MAX_ENTITY]:
            type Entity = object
                a: int
                b, c: int



when isMainModule:
    echo "GENERAL TEST"
    echo Entities
    echo Entities.new()[]
    echo Entities.new()[]
    echo Entities.new()[]
    echo Entities.new()[]
    Entities[1].a = 5
    echo Entities
    Entities.destroy(Entities[1])
    echo Entities

    echo "RESERVATION TEST"

    var e = Entities.reserve()
    echo Entities
    e.b = 3
    echo e[]
    echo Entities.finalize(e)[]
    echo Entities

    Entities.destroy(2)

    discard Entities.reserve()

    echo "ITER TEST"
    for e in Entities:
        echo e
    for e in Entities.reserved_ptrs():
        echo e[]


    #echo Entities.create()[]
    #echo $Entities
    #echo Entities[0][]

    #echo newObjectIn(Entities)[]