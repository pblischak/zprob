const std = @import("std");
const zprob = @import("zprob");
const Allocator = std.mem.Allocator;
const RandomEnvironment = zprob.RandomEnvironment;

const EnemyType = enum {
    Regular,
    Berserker,
};

const Enemy = struct {
    enemy_type: EnemyType,
    x: u32,
    y: u32,
    max_health: u8,
    current_health: u8,
    attack: u8,
    defense: u8,
};

// Screen size in pixels.
const MAX_WIDTH: u32 = 320;
const MAX_HEIGHT: u32 = 180;

// Weights for sampling enemy types.
var ENEMY_TYPE_WEIGHTS = [_]f64{ 0.9, 0.1 };

pub fn EnemySpawner() type {
    return struct {
        const Self = @This();
        env: RandomEnvironment,
        allocator: Allocator,

        pub fn init(allocator: Allocator) !Self {
            return Self{
                .env = try RandomEnvironment.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.env.deinit();
        }

        pub fn spawnEnemies(self: *Self, count: usize) ![]Enemy {
            var enemies = try self.allocator.alloc(Enemy, count);
            for (0..count) |i| {
                enemies[i] = self.spawnEnemy();
            }
            return enemies;
        }

        fn spawnEnemy(self: *Self) Enemy {
            return switch (self.env.rWeightedSample(
                EnemyType,
                std.enums.values(EnemyType),
                ENEMY_TYPE_WEIGHTS[0..],
            )) {
                .Regular => self.spawnRegularEnemy(),
                .Berserker => self.spawnBerserkerEnemy(),
            };
        }

        fn spawnRegularEnemy(self: *Self) Enemy {
            var uniform_uint = zprob.UniformInt(u8).init(self.env.getRand());
            const max_health = uniform_uint.sample(10, 15);
            return Enemy{
                .enemy_type = .Regular,
                .x = self.env.rUniformUInt(0, MAX_WIDTH - 1),
                .y = self.env.rUniformUInt(0, MAX_HEIGHT - 1),
                .max_health = max_health,
                .current_health = max_health,
                .attack = uniform_uint.sample(2, 6),
                .defense = uniform_uint.sample(3, 5),
            };
        }

        fn spawnBerserkerEnemy(self: *Self) Enemy {
            var uniform_uint = zprob.UniformInt(u8).init(self.env.getRand());
            const max_health = uniform_uint.sample(25, 30);
            return Enemy{
                .enemy_type = .Berserker,
                .x = self.env.rUniformUInt(0, MAX_WIDTH - 1),
                .y = self.env.rUniformUInt(0, MAX_HEIGHT - 1),
                .max_health = max_health,
                .current_health = max_health,
                .attack = uniform_uint.sample(14, 18),
                .defense = uniform_uint.sample(11, 15),
            };
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        std.testing.expect(status == .ok) catch {
            @panic("Memory leak!");
        };
    }

    var enemy_spawner = try EnemySpawner().init(allocator);
    defer enemy_spawner.deinit();

    const enemies = try enemy_spawner.spawnEnemies(50);
    defer allocator.free(enemies);

    std.debug.print("\nEnemies:\n", .{});
    for (enemies) |e| {
        std.debug.print("  {any}\n", .{e});
    }
}
