# Own version of readLine needs to read in line, using '\l' as the delimiter
# Returns true if able to successfully read a line into the buffer

import streams

const 
  bufferSize = 4096
  lineFeed   = '\l'

type
  localBuffer = array[0..bufferSize-1,char]

type
  readLineResult* = tuple[
    readSuccessfully: bool,
    output: string
  ]

proc findNextLineFeedPosition(s: string): int =
  var found = false
  for i, c in s:
    if c == lineFeed:
      found = true
      result = i
  if found == false:
    return -1


iterator readLineRsyslog*(s: Stream): readLineResult =
  var 
    finishedReading: bool = false
    outputLine = newStringOfCap(bufferSize)
    # We need this line in case we read > 1 line in the buffer and need to return
    # this on next iteration
    tempLine   = newStringOfCap(bufferSize)
    bytesRead  = 0
    inputBuffer: localBuffer

  var loccationOfEOLChar: int

  while not finishedReading:
    try:
      bytesRead  = s.readData(addr(inputBuffer[0]),bufferSize)
    except:
      raise (ref IOError)(getCurrentException())

    case bytesRead
    of 0:
      finishedReading = true
      # Need to yield out anything remaining in tempLine
      if len(tempLine) != 0:
        yield (true, tempLine)
      break
    of 1..bufferSize-1:
      discard
      # Have read less than the buffer length.  Need to split up remaining lines
      # from tempLine and yield each one by one
    of bufferSize:
      discard
    else:
      var e = newException(IOError,"Invalid value returned for bufffer.  Got: " & $bytesRead)
      raise e

  yield (readSuccessfully: false, output: "")
