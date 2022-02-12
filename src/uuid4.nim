## uuid4 is a UUID module in pure Nim.
## 
## The primary use is for generating version-4 (random) UUIDs,
## which you can do with ``uuid4()``. UUIDs are hashable and
## printable for convenience. If you already have some UUIDs, you
## can call ``initUuid()`` with either a string representation of
## a UUID or 16 bytes (uint8).
## 
runnableExamples:
  let u1 = uuid4()  # a version-4 (random) UUID
  echo u1           # print the stringified version of the UUID

runnableExamples:
  let u2 = initUuid("b80b3380-a167-437b-9d64-6cb574e3aae7")
  echo u2.bytes[0]    # print the first byte of this UUID
  echo u2.bytes[15]   # print the last byte of this UUID
  echo u2.version     # this happens to be a version-4 UUID
  echo u2.variant     # it's a RFC-4122 UUID

runnableExamples:
  let u3 = uuid4()
  let u4 = initUuid(u3.bytes)   # make another, equivalent UUID
  echo u4 == u3                 # true

runnableExamples:
  var u5: Uuid
  echo u5.isNil   # true

import std / [sysrand, strformat, strutils, parseutils, hashes]

type
  Uuid* = object
    bytes: array[16, uint8]
  UuidVariant* {.pure.} = enum
    ApolloNcs, Rfc4122, ReservedMicrosoft, ReservedFuture

proc uuid4*(): Uuid =
  ## Generate a version-4 (random) UUID.
  let success = urandom(dest = result.bytes)
  if success:
    # set version to 4
    result.bytes[6] = (result.bytes[6] and 0x0F) or 0x40
    # set variant to 1 (byte 8 = 10xx xxxx)
    result.bytes[8] = (result.bytes[8] and 0x3F) or 0x80

proc isNil*(self: Uuid): bool =
  ## Determine if this UUID is "nil" (all 0s).
  for byte in self.bytes:
    if byte == 0: continue
    return false
  return true

proc hash*(self: Uuid): Hash =
  for byte in self.bytes:
    result = result !& byte.hash()
  result = !$result

proc `==`*(uuid1, uuid2: Uuid): bool {.inline.} =
  result = uuid1.bytes == uuid2.bytes

proc bytes*(self: Uuid): array[16, uint8] {.inline.} =
  ## Get the big-endian raw bytes of a UUID.
  result = self.bytes

proc normalizeUuidStr(candidateStr: string): string =
  let uuidStr = candidateStr.split('-').join()
  if len(uuidStr) != 32:
    raise newException(ValueError,
                       "expected 8-4-4-4-12 or 32 characters format")
  result = uuidStr

proc initUuid*(uuidStr: string): Uuid =
  ## Parse a UUID from a string (with or without hyphens, any casing).
  let uuidStrClean = normalizeUuidStr(uuidStr)

  # idx is the index into the result's bytes array; it must be doubled
  # to index into the string. We know that the string is 32 characters
  # because we normalized it above.
  assert uuidStrClean.len == 32
  for idx in 0 .. 15:
    let byteStr = uuidStrClean[2*idx .. 2*idx+1]
    if parseHex(byteStr, result.bytes[idx]) != 2:
      raise newException(ValueError,
                          "could not parse a hex character from " &
                          fmt"'{byteStr}' at index {2*idx}")

proc initUuid*(uuidBytes: array[16, uint8]): Uuid =
  ## Create a UUID directly from 16 bytes.
  result.bytes = uuidBytes

proc variant*(self: Uuid): UuidVariant =
  ## Determine the variant of the UUID. Most in the wild are RFC-4122.
  # borrowed tricks from CPython's uuid library
  let invByte = not self.bytes[8]
  if (invByte and 0x80) == 0x80:
    return UuidVariant.ApolloNcs
  elif (invByte and 0x40) == 0x40:
    return UuidVariant.Rfc4122
  elif (invByte and 0x20) == 0x20:
    return UuidVariant.ReservedMicrosoft
  return UuidVariant.ReservedFuture

proc version*(self: Uuid): int =
  ## Determine the version of an RFC-4122 UUID.
  if self.variant == UuidVariant.Rfc4122:
    result = int((self.bytes[6] and 0xF0) shr 4)

proc hexify(bytes: openArray[uint8]): string =
  for byte in bytes:
    result = result & fmt"{byte:02x}"

proc `$`*(self: Uuid): string =
  result =
    hexify(self.bytes[0..3]) &
    "-" &
    hexify(self.bytes[4..5]) &
    "-" &
    hexify(self.bytes[6..7]) &
    "-" &
    hexify(self.bytes[8..9]) &
    "-" &
    hexify(self.bytes[10..15])
