pub fn iterator(comptime NewType: type, comptime ItType: type) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    return struct {
        nextIt: *ItType,

        const Self = @This();

        pub fn count(self: *Self) usize {
            return self.nextIt.count();
        }

        pub fn next(self: *Self) ?NewType {
            if (self.nextIt.next()) |nxt| {
                return switch (@typeInfo(BaseType)) {
                    .Int => switch (@typeInfo(NewType)) {
                        .Int => @intCast(nxt),
                        .Float => @floatFromInt(nxt),
                        else => @compileError("unsupported conversion"),
                    },
                    .Float => switch (@typeInfo(NewType)) {
                        .Int => @intFromFloat(nxt),
                        .Float => @floatCast(nxt),
                        else => @compileError("unsupported conversion"),
                    },
                    else => @compileError("unsupported conversion"),
                };
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }
    };
}
