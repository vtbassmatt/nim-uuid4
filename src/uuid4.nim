import std / [sysrand, strformat, strutils, parseutils, hashes]

type
  Uuid* = object
    bytes: array[16, uint8]
  UuidVariant* {.pure.} = enum
    ApolloNcs, Rfc4122, ReservedMicrosoft, ReservedFuture

proc uuid4*(): Uuid =
  let success = urandom(dest = result.bytes)
  if success:
    # set version to 4
    result.bytes[6] = (result.bytes[6] and 0x0F) or 0x40
    # set variant to 1 (byte 8 = 10xx xxxx)
    result.bytes[8] = (result.bytes[8] and 0x3F) or 0x80

proc isNil*(self: Uuid): bool =
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
  result = self.bytes

proc normalizeUuidStr(candidateStr: string): string =
  let uuidStr = candidateStr.split('-').join()
  if len(uuidStr) != 32:
    raise newException(ValueError,
                       "expected 8-4-4-4-12 or 32 characters format")
  result = uuidStr

proc initUuid*(uuidStr: string): Uuid =
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
  result.bytes = uuidBytes

proc variant*(self: Uuid): UuidVariant =
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

when isMainModule:
  var u0: Uuid
  assert isNil(u0)
  assert u0.version == 0

  let u1 = uuid4()
  assert u1.variant == UuidVariant.Rfc4122
  assert u1.version == 4

  let u2 = initUuid("3aff9c81-549d-4658-bbfd-a03bb40653d0")
  assert $u2 == "3aff9c81-549d-4658-bbfd-a03bb40653d0"
  assert u2.bytes[0] == 0x3a
  assert u2.bytes[1] == 0xff
  assert u2.bytes[2] == 0x9c
  assert u2.bytes[3] == 0x81
  assert u2.bytes[4] == 0x54
  assert u2.bytes[5] == 0x9d
  assert u2.bytes[6] == 0x46
  assert u2.bytes[7] == 0x58
  assert u2.bytes[8] == 0xbb
  assert u2.bytes[9] == 0xfd
  assert u2.bytes[10] == 0xa0
  assert u2.bytes[11] == 0x3b
  assert u2.bytes[12] == 0xb4
  assert u2.bytes[13] == 0x06
  assert u2.bytes[14] == 0x53
  assert u2.bytes[15] == 0xd0

  # version 1 UUID
  let u3 = initUuid("18cda93e-89e2-11ec-a697-d294d5d7f39d")
  assert u3.variant == UuidVariant.Rfc4122
  assert u3.version == 1

  # test from bytes
  let u4 = initUuid(u2.bytes)
  assert u2 == u4

  # must accept uppercase and return lowercase
  let u5 = initUuid("3AFF9C81-549D-4658-BBFD-A03BB40653D0")
  assert $u5 == "3aff9c81-549d-4658-bbfd-a03bb40653d0"

  # valid characters, invalid length
  try:
    discard initUuid("3aff9c8-549d-4658-bbfd-a03bb40653d0")
  except ValueError:
    discard

  # invalid characters, valid length
  try:
    discard initUuid("3aff9c8g-549d-4658-bbfd-a03bb40653d0")
  except ValueError:
    discard

  # valid characters and length but invalid structure
  try:
    discard initUuid("3aff9c810549d046580bbfd0a03bb40653d0")
  except ValueError:
    discard
