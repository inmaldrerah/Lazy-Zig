pub fn iterator(comptime ItType1: type, comptime ItType2: type) type {
    const BaseType = @TypeOf(ItType1.next(undefined).?);
    if (@TypeOf(ItType2.next(undefined).?) != BaseType) @compileError("two iterators have different base types");
    return struct {
        nextIt: *ItType1,
        otherIt: ItType2,

        const Self = @This();

        pub fn count(self: *Self) i32 {
            return self.nextIt.count() + self.otherIt.count();
        }

        pub fn next(self: *Self) ?BaseType {
            if (self.nextIt.next()) |nxt| {
                return nxt;
            } else if (self.otherIt.next()) |nxt| {
                return nxt;
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
            self.otherIt.reset();
        }
    };
}
