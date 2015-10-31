import streams
import sequtils
import readline_rsyslog

const bufferSize = 4096
const lineFeed   = '\l'

type
  localBuffer = array[0..bufferSize-1,char]

#  outputFileStream should be of type Stream or implement the same interface -
#  if needed, you can also overwrite the closeImpl, flushImpl, and writeDataImpl
#  to have more control over how it behaves.  We do buffering here, so do not need
#  to do in writeDataImpl.  
let
  outputFileStream = newFileStream(open("output.txt",fmWrite))

template doCleanup(outputStream: Stream)=
  ## Operation necessary to cleanup stream, on close
  outputStream.close()

template unbufferedOutput(outputStream: Stream,line: string)=
  ## Exceptionally long line - cannot buffer
  outputStream.writeData(addr(line[0]),len(line))

template flushWith(outputStream: Stream,buffer: localBuffer,bytesRead: int)=
  ## How to handle writing buffer to file - can override this or override
  ## writeDataImpl, which is what this ultimately calls.
  outputStream.writeData(addr(buffer[0]),bytesRead)

# Nothing following needs to be altered
proc main() =
  var 
    bytesRead = 0
    buffer:  localBuffer
    curLine: string = newStringOfCap(100)
  let 
    inputFileStream  = newFileStream(stdin)
  # TODO - cannot use readLine, since it will stop on CR, LF, or whatever
  # Rsyslog guarantees that we will terminate on LF, so need to read CR as valid
  # part of the line
  while inputFileStream.readLine(curLine):
    # Restore expected EOL character to line
    curLine &= $lineFeed
    if bytesRead + len(curLine) >= bufferSize:
      outputFileStream.flushWith(buffer,bytesRead)
      bytesRead = 0
      # Handle exceptionally long line - cannot buffer
      if len(curLine) >= bufferSize:
        outputFileStream.unbufferedOutput(curLine)
        continue
    copyMem(addr(buffer[bytesRead]),addr(curLine[0]),len(curLine))
    bytesRead += len(curLine)

  if bytesRead != 0:
    outputFileStream.flushWith(buffer,bytesRead)
  outputFileStream.doCleanup()

main()
