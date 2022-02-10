import unittest

import uuid4
test "for nilness":
  var u0: Uuid
  check isNil(u0)
  check u0.version == 0

test "version 4 and variant":
  let u1 = uuid4()
  check u1.variant == UuidVariant.Rfc4122
  check u1.version == 4

test "version 1":
  let u3 = initUuid("18cda93e-89e2-11ec-a697-d294d5d7f39d")
  check u3.variant == UuidVariant.Rfc4122
  check u3.version == 1

test "bytes are correct":
  let u2 = initUuid("3aff9c81-549d-4658-bbfd-a03bb40653d0")
  check $u2 == "3aff9c81-549d-4658-bbfd-a03bb40653d0"
  check u2.bytes[0] == 0x3a
  check u2.bytes[1] == 0xff
  check u2.bytes[2] == 0x9c
  check u2.bytes[3] == 0x81
  check u2.bytes[4] == 0x54
  check u2.bytes[5] == 0x9d
  check u2.bytes[6] == 0x46
  check u2.bytes[7] == 0x58
  check u2.bytes[8] == 0xbb
  check u2.bytes[9] == 0xfd
  check u2.bytes[10] == 0xa0
  check u2.bytes[11] == 0x3b
  check u2.bytes[12] == 0xb4
  check u2.bytes[13] == 0x06
  check u2.bytes[14] == 0x53
  check u2.bytes[15] == 0xd0

test "equality and construction from bytes":
  let u2 = initUuid("3aff9c81-549d-4658-bbfd-a03bb40653d0")
  let u4 = initUuid(u2.bytes)
  check u2 == u4

test "accept uppercase; emit lowercase":
  let u5 = initUuid("3AFF9C81-549D-4658-BBFD-A03BB40653D0")
  check $u5 == "3aff9c81-549d-4658-bbfd-a03bb40653d0"

test "valid characters, invalid length":
  try:
    discard initUuid("3aff9c8-549d-4658-bbfd-a03bb40653d0")
  except ValueError:
    discard

test "invalid characters, valid length":
  try:
    discard initUuid("3aff9c8g-549d-4658-bbfd-a03bb40653d0")
  except ValueError:
    discard

test "valid characters and length but invalid structure":
  try:
    discard initUuid("3aff9c810549d046580bbfd0a03bb40653d0")
  except ValueError:
    discard
