## Guide

As with all docs, this is a work in progress...

### 

```rs
const std = @import("std");
const zprob = @import("zprob");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        std.testing.expect(status == .ok) catch {
            @panic("Memory leak!");
        };
    }

    var env = zprob.RandomEnvironment.init(allocator);
    defer env.deinit();

    // Generate single random deviates from different distributions
    const v1 = env.rBinomial(10, 0.2);
    const v2 = env.rExponential(10.0);

    // Generate a slice of `size` random deviates from different distributions
    // **Note:** You are responsible for freeing the slice's memory after allocation
    const s1 = env.rBinomialSlice(2500, 15, 0.6);
    defer allocator.free(s1);

    const s2 = env.rExponentialSlice(10_000, 5.0);
    defer allocator.free(s2);
}
```

### Sampling from Collections

```rs
const Enemy = struct {
    max_health: u8,
    current_health: u8,
    attack: u8,
    defense: u8,
};

var enemies = try allocator.alloc(Enemy, 100);
```