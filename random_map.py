import random
import math
from pathlib import Path
import sys

STATES = 51

ec = [3] * STATES
leans = [1] * STATES
issues = []

def main():
    EC_TOTAL = 538 - (3 * STATES)
    LEAN_TOTAL = 178

    while EC_TOTAL != 0:
        stateIndex = random.randint(0,STATES-1)
        if random.randint(0,10) == 0 and EC_TOTAL >= 18 and ec[stateIndex] < 40:
            ec[stateIndex] += 18
            EC_TOTAL -= 18
        if random.randint(0,4) == 0 and EC_TOTAL >= 10:
            ec[stateIndex] += 9
            EC_TOTAL -= 9
        elif random.randint(0,2) == 0 and EC_TOTAL >= 4:
            ec[stateIndex] += 4
            EC_TOTAL -= 4
        else:
            ec[stateIndex] += 1
            EC_TOTAL -= 1

    print(ec)
    print(sum(ec))

    while LEAN_TOTAL != 0:

        stateIndex = random.randint(0, STATES - 1)
        if leans[stateIndex] < 9:
            leans[stateIndex] += 1
            LEAN_TOTAL -= 1

    difference = calcSums()
    absoluteDifference = int(math.fabs(difference))

    while (absoluteDifference > 50):
        stateIndex = random.randint(0, STATES - 1)
        if difference > 0 and leans[stateIndex] > 1:
            leans[stateIndex] -= 1
        elif difference < 0 and leans[stateIndex] < 8:
            leans[stateIndex] += 1

        difference = calcSums()
        absoluteDifference = int(math.fabs(difference))

    print(leans)
    print(sum(leans) / STATES)
    print(absoluteDifference)

    for stateIndex in range(0,STATES):
        newIssues = []
        for i in range(0,5):
            newIssues.append(generateIssue(leans[stateIndex]))
        issues.append(newIssues)
    print(issues)

    mapFile = open(str(Path(sys.argv[1])), "w")
    #mapFile.write(str(sys.argv[2])+'\n')
    for stateIndex in range(0,STATES):
        writeIssues = issues[stateIndex]
        line = ""
        line += str(leans[stateIndex]) + ','
        for i in range(0,5):
            line += str(writeIssues[i]) + ','
        line += str(ec[stateIndex]) +'\n'
        mapFile.write(line)
    return

def calcSums():
    sumD = [0] * STATES
    sumR = [0] * STATES
    for i in range(0, STATES):
        sumD[i] = leans[i] * ec[i]
        sumR[i] = (10 - leans[i]) * ec[i]

    difference = sum(sumD) - sum(sumR)

    return difference

"""
lean is provided as R lean
"""
def generateIssue(lean):
    leanTable = [[1],[1,1,2],[2,3],[3,3,4],[3,4],[3,4,4],[5,6],[5,6,6],[6]]
    options = leanTable[lean-1]
    selectedValue = options[random.randint(0,len(options)-1)]
    if random.randint(0,1) == 0:
        selectedValue += random.randint(-1,1)
    if random.randint(0,2) == 0:
        selectedValue += random.randint(-1,1)
    if random.randint(0,3) == 0:
        selectedValue += 2
    if random.randint(0, 3) == 0:
        selectedValue -= 2
    if selectedValue < 0:
        selectedValue = 0
    if selectedValue > 7:
        selectedValue = 7
    if selectedValue == 0 and random.randint(0,1) == 0:
        selectedValue = 1
    if selectedValue == 7 and random.randint(0, 1) == 0:
        selectedValue = 6
    return selectedValue

if __name__ == "__main__":
    main()