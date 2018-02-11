#=========================================================================
# Copyright 2018 Double_oxygeN
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=========================================================================

import
  math,
  sequtils,
  strutils,
  algorithm,
  options,
  parsecsv,
  os

const
  maxNum = 9
  sqrtMaxNum = maxNum.float.sqrt.int

type
  Digit = range[1..maxNum]
  Index = range[0..(maxNum*maxNum-1)]
  
  PlaceState = enum
    filled, unfilled

  Place = ref object
    column, row: Digit
    case state: PlaceState
    of filled:
      value: Digit
    of unfilled:
      candidates: set[Digit]
  
  Board = object
    places : array[maxNum*maxNum, Place]

proc newFilledPlace(value, column, row: Digit): Place =
  result = Place(state: filled, value: value, column: column, row: row)

proc newUnfilledPlace(candidates: set[Digit], column, row: Digit): Place =
  result = Place(state: unfilled, candidates: candidates, column: column, row: row)

proc newBoard(): Board =
  var places: array[maxNum*maxNum, Place]
  for idx in 0..<(maxNum*maxNum):
    let candidates: set[Digit] = {(1.Digit)..(maxNum.Digit)}
    places[idx] = newUnfilledPlace(candidates = candidates, column = (idx mod maxNum + 1).Digit, row = (idx div maxNum + 1).Digit)
  result = Board(places: places)

proc toIndex(column, row: Digit): Index = row * maxNum + column - maxNum - 1

proc isSameColumn(idx0, idx1: Index): bool = (idx0 mod maxNum) == (idx1 mod maxNum)
proc isSameRow(idx0, idx1: Index): bool = (idx0 div maxNum) == (idx1 div maxNum)
proc isSameGroup(idx0, idx1: Index): bool =
  const f = proc (i: Index): int = sqrtMaxNum * (i div (sqrtMaxNum * maxNum)) + (i div sqrtMaxNum mod sqrtMaxNum)
  return f(idx0) == f(idx1)

proc dependents(column, row: Digit): seq[Index] =
  let idx = toIndex(column, row)
  return toSeq(0..(maxNum*maxNum-1)).mapIt(it.Index).filter do (x: Index) -> bool : (x.isSameColumn(idx) or x.isSameRow(idx) or x.isSameGroup(idx)) and x != idx

proc `-`(p: Place, val: Digit): Place =
  if p.state == filled:
    return p
  else:
    return newUnfilledPlace(candidates = p.candidates - {val}, column = p.column, row = p.row)

proc write(board: Board, value, column, row: Digit): Board =
  result = board
  for dependentIdx in dependents(column, row):
    let dependent = board.places[dependentIdx]
    if dependent.state == unfilled:
      result.places[dependentIdx] = dependent - value
  
  result.places[toIndex(column, row)] = newFilledPlace(value = value, column = column, row = row)

proc solve(board: Board): Option[Board] =
  var blanks = @(board.places).filter do (p: Place) -> bool : p.state == unfilled
  if blanks.len == 0:
    return some(board)
  
  blanks.sort do (p0, p1: Place) -> int : p0.candidates.card - p1.candidates.card
  let fewerCandidates = blanks[0]
  for candidate in fewerCandidates.candidates:
    result = solve(board.write(candidate, fewerCandidates.column, fewerCandidates.row))
    if result.isSome: return
  
  return none(Board)

proc readFromCSVFile(path: string): Board =
  var
    p: CsvParser
    idx = 0
    
  result = newBoard()
  p.open(filename = path)
  while p.readRow():
    for elem in items(p.row):
      if elem.isDigit() and elem != "0":
        let num = elem.parseInt().Digit
        result = result.write(num, (idx mod maxNum + 1), (idx div maxNum + 1))
      idx.inc()

proc `$`(place: Place): string =
  return if place.state == unfilled: "0" else: $(place.value)

proc `$`(board: Board): string =
  result = ""
  for rowNum in 1..maxNum:
    for place in board.places[((rowNum-1)*maxNum)..<(rowNum*maxNum)]:
      result &= $place & " "
    result &= "\n"

if paramCount() > 0:
  var
    b = readFromCSVFile(paramStr(1))
    solved = b.solve()

  if solved.isSome():
    echo solved.get()
  else:
    echo "solving failed..."
else:
  echo "please enter csv file name"
