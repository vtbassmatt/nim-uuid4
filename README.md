# uuid4

A UUID module in pure Nim.

## Installation

```
nimble install uuid4
```

## Usage

```nim
import uuid4

let u1 = uuid4()  # a version-4 (random) UUID
echo u1           # print the stringified version of the UUID

let u2 = initUuid("b80b3380-a167-437b-9d64-6cb574e3aae7")
echo u2.bytes[0]    # print the first byte of this UUID
echo u2.bytes[15]   # print the last byte of this UUID
echo u2.version     # this happens to be a version-4 UUID
echo u2.variant     # it's a RFC-4122 UUID

let u3 = initUuid(u1.bytes)   # make another, equivalent UUID
echo u3 == u1                 # true
var u4: Uuid
echo u4.isNil                 # true
```

## Full API

```nim
type
  Uuid*        # an opaque object
  UuidVariant* # a {.pure.} enum of
               # ApolloNcs, Rfc4122, ReservedMicrosoft, ReservedFuture

proc uuid4*(): Uuid

proc isNil*(self: Uuid): bool

proc hash*(self: Uuid): Hash
proc `==`*(uuid1, uuid2: Uuid): bool
proc `$`*(self: Uuid): string

proc bytes*(self: Uuid): array[16, uint8]

proc initUuid*(uuidStr: string): Uuid
proc initUuid*(uuidBytes: array[16, uint8]): Uuid

proc variant*(self: Uuid): UuidVariant
proc version*(self: Uuid): int
```

## Contributing

Contributions are welcome, especially adding more surface area from the Python `uuid` module.
Feel free to open a PR.
