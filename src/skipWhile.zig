pub fn iterator(comptime ItType: type, comptime condition: fn (@TypeOf(ItType.next(undefined).?)) bool) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    return struct {
        nextIt: *ItType,

        const Self = @This();
        var skipped: bool = false;

        pub fn next(self: *Self) ?BaseType {
            if (!skipped) {
                skipped = true;
                while (self.nextIt.next()) |nxt| {
                    if (!condition(nxt)) return nxt;
                }
                return null;
            }

            return self.nextIt.next();
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        pub fn count(_: *Self) usize {
            @compileError("Count not suitable on skip while");
        }
    };
}
