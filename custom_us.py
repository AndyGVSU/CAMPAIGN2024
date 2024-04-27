import sys
from pathlib import Path

camp = open(str(Path(sys.argv[1])), "rb")
customMap = open(str(Path(sys.argv[2])), "r")

STATES = 51
SIZE = 199

fileBytes = bytes.hex(camp.read())
OFFSET = int(fileBytes[-2:] + fileBytes[-4:-2],16)

camp = open(str(Path(sys.argv[1])), "rb")

inData = customMap.readlines()
inStateLean = []
inIssues = []
inEC = [0] * STATES

print(inData.remove(inData[0]))
stateIndex = 0
for line in inData:
    noNewLine = line[:-1]
    processedLine = noNewLine.split(',')
    inStateLean.append((processedLine[0],processedLine[1]))
    inIssues.append((processedLine[2],processedLine[3],processedLine[4],processedLine[5],processedLine[6]))
    inEC[stateIndex] = processedLine[7]
    stateIndex += 1

fileBytes = bytes.hex(camp.read())
modOffset = len(fileBytes) - OFFSET * 2
firstString = fileBytes[:modOffset]
modEndOffset = modOffset+SIZE*2
campString = fileBytes[modOffset:modEndOffset]
lastString = fileBytes[modOffset+SIZE*2:]
newString = ""
for stateIndex in range(0,STATES):
    stateLeans = inStateLean[stateIndex]
    newString += str(stateLeans[0])+str(stateLeans[1])

compress = ""
for stateIndex in range(0,STATES):
    issues = inIssues[stateIndex]
    for i in issues:
        compress += format(int(i), '03b')
compress += "000"
newString += hex(int(compress,2))[2:]

newString += "00"
for stateIndex in range(0,STATES):
    ec = int(inEC[stateIndex])
    hexEC = format(ec,'02x')
    newString += hexEC

campString = firstString + newString + lastString

camp.close()
customMap.close()

camp = open(str(Path(sys.argv[1]+"mod")), "wb")
asBinary = bytes.fromhex(campString)
camp.write(asBinary)
camp.close()
