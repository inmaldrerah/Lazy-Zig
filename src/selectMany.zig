const arrayIt = @import("arrayIterator.zig").iterator;

pub fn iterator(comptime ItType: type, comptime select: anytype) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    const infoNewSliceType = @typeInfo(@TypeOf(select(@as(BaseType, undefined))));
    if (infoNewSliceType.Pointer.size != .Slice or !infoNewSliceType.Pointer.is_const) @compileError("`select` should return a const slice of values of the new type");
    const NewType = infoNewSliceType.Pointer.child;
    return struct {
        nextIt: *ItType,
        currentIt: ?arrayIt(NewType),
        const Self = @This();

        pub fn next(self: *Self) ?NewType {
            if (self.currentIt) |*it| {
                if (it.next()) |nxt| {
                    return nxt;
                } else {
                    self.currentIt = null;
                }
            }

            if (self.nextIt.next()) |nxt| {
                var val = select(nxt);
                self.currentIt = arrayIt(NewType).init(val);
                return self.next();
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
            self.currentIt = null;
        }

        pub fn count(_: *Self) usize {
            @compileError("Can't use count on select many");
        }
    };
}
