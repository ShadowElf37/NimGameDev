import macros, tables


static:
    var procTable = initTable[string, proc:void]()

macro section(label: untyped, body: untyped): untyped =
    let labelStr = label.strVal



    result = quote do:
        static:
            procTableS[`labelStr`] = proc() {.asmNoStackFrame.} = `body`
        (proc() = `body`)()

    echo result.repr

macro goto(label: untyped) =
    let labelStr = label.strVal

    result = quote do:
        procTable[`labelStr`]()
    echo result.repr

proc MAIN() =
    var i = 0
    goto test
    echo "this better not print"
    section test:
        echo i
        i += 1
        if i < 5:
            goto main

MAIN()