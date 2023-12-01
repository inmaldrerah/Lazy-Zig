pub fn iterator(comptime ItType: type, comptime filter: fn (@TypeOf(ItType.next(undefined).?)) bool) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    return struct {
        nextIt: *ItType,

        const Self = @This();

        pub fn next(self: *Self) ?BaseType {
            while (self.nextIt.next()) |nxt| {
                if (filter(nxt)) {
                    return nxt;
                }
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        pub fn count(self: *Self) i32 {
            return self.nextIt.count();
        }
    };
}
