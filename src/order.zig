const std = @import("std");

pub fn iterator(comptime ItType: type, comptime ascending: bool, comptime select: anytype) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    const NewType = @TypeOf(select(@as(BaseType, undefined)));
    return struct {
        const Self = @This();
        nextIt: *ItType,
        index: usize,
        count: usize,
        buf: []BaseType,

        pub fn next(self: *Self) ?NewType {
            if (self.count == 0) {
                // Sort
                var i: usize = 0;
                while (self.nextIt.next()) |nxt| {
                    self.buf[i] = nxt;
                    i += 1;
                }

                self.count = i;
                std.mem.sort(BaseType, self.buf[0..self.count], {}, compare);
            }

            if (self.index >= self.count) return null;

            defer self.index += 1;
            return self.buf[self.index];
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        fn compare(_: void, a: BaseType, b: BaseType) bool {
            if (ascending) {
                return select(a) < select(b);
            } else {
                return select(a) > select(b);
            }
        }
    };
}
