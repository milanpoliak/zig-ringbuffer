# Zig Ringbuffer

Generic no allocation ringbuffer for Zig.

Not suitable for production (yet).

## How to use

### Install

1. Add Ringbuffer to `build.zig.zon` dependencies

Either run `zig fetch --save https://github.com/milanpoliak/zig-ringbuffer/archive/refs/tags/v0.0.1.tar.gz`

or add it manually

```zig
...
.dependencies = .{
    .ringbuffer = .{
        .url = "https://github.com/milanpoliak/zig-ringbuffer/archive/refs/tags/v0.0.1.tar.gz",
        .hash = "...", // TODO:
    },
},
...
```

2. Add Ringbuffer to `build.zig`

```zig
const ringbuffer = b.dependency("ringbuffer", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("ringbuffer", ringbuffer.module("ringbuffer"));
```

### Use

```zig
const RingBuffer = @import("ringbuffer").RingBuffer;

// Buffer with capacity for 1024 `u64`s
var buffer = RingBuffer(u64, 1024).init();

buffer.write(69420);

const value = buffer.read();

try expect(value == 69420);
```
