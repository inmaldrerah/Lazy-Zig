pub fn iterator(comptime ItType: type, comptime select: anytype) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    const NewType = @TypeOf(select(@as(BaseType, undefined)));
    return struct {
        nextIt: *ItType,

        const Self = @This();

        pub fn next(self: *Self) ?NewType {
            if (self.nextIt.next()) |nxt| {
                return select(nxt);
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
