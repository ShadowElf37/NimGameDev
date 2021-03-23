import logging
import times

const LOG_FMT_STR = "$levelname [$time] "

var
    consoleLogger = newConsoleLogger(fmtStr=LOG_FMT_STR)
    fileLogger = newFileLogger(filename="logs/" & $now().format("yyyy-MM-dd HH-mm-ss") & ".log", fmtStr=LOG_FMT_STR)

addHandler(consoleLogger)
addHandler(fileLogger)

info("test")