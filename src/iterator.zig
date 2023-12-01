const std = @import("std");
const whereIt = @import("where.zig").iterator;
const selectIt = @import("select.zig").iterator;
const castIt = @import("cast.zig").iterator;
const orderIt = @import("order.zig").iterator;
const skipIt = @import("skip.zig").iterator;
const skipWhileIt = @import("skipWhile.zig").iterator;
const takeIt = @import("take.zig").iterator;
const takeWhileIt = @import("takeWhile.zig").iterator;
const concatIt = @import("concat.zig").iterator;
const selectManyIt = @import("selectMany.zig").iterator;
const reverseIt = @import("reverse.zig").iterator;

pub fn iterator(comptime ItType: type) type {
    const BaseType = @TypeOf(ItType.next(undefined).?);
    return struct {
        nextIt: ItType,

        const Self = @This();

        pub fn next(self: *Self) ?BaseType {
            return self.nextIt.next();
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        pub fn count(self: *Self) i32 {
            return self.nextIt.count();
        }

        fn returnBasedOnThis(self: *Self, comptime IterType: type) iterator(IterType) {
            return iterator(IterType){
                .nextIt = .{ .nextIt = &self.nextIt },
            };
        }

        pub fn where(self: *Self, comptime filter: fn (BaseType) bool) iterator(whereIt(ItType, filter)) {
            return self.returnBasedOnThis(whereIt(ItType, filter));
        }

        fn add(a: BaseType, b: BaseType) BaseType {
            return a + b;
        }

        pub fn sum(self: *Self) ?BaseType {
            return self.aggregate(add);
        }

        fn compare(self: *Self, comptime comparer: fn (BaseType, BaseType) i32, comptime result: i32) ?BaseType {
            var maxValue: ?BaseType = null;
            self.reset();
            defer self.reset();

            while (self.next()) |nxt| {
                if (maxValue == null or comparer(nxt, maxValue) == result) {
                    maxValue = nxt;
                }
            }
            return maxValue;
        }

        pub fn max(self: *Self, comptime comparer: fn (BaseType, BaseType) i32) ?BaseType {
            return self.compare(comparer, 1);
        }

        pub fn min(self: *Self, comptime comparer: fn (BaseType, BaseType) i32) ?BaseType {
            return self.compare(comparer, -1);
        }

        pub fn reverse(self: *Self, buf: []BaseType) iterator(reverseIt(ItType)) {
            return iterator(reverseIt(ItType)){
                .nextIt = .{
                    .nextIt = &self.nextIt,
                    .index = 0,
                    .count = 0,
                    .buf = buf,
                },
            };
        }

        pub fn orderByDescending(self: *Self, comptime selectObj: anytype, buf: []BaseType) iterator(orderIt(ItType, false, selectObj)) {
            return iterator(orderIt(ItType, false, selectObj)){
                .nextIt = .{
                    .nextIt = &self.nextIt,
                    .index = 0,
                    .count = 0,
                    .buf = buf,
                },
            };
        }

        pub fn orderByAscending(self: *Self, comptime selectObj: anytype, buf: []BaseType) iterator(orderIt(ItType, true, selectObj)) {
            return iterator(orderIt(ItType, true, selectObj)){
                .nextIt = .{
                    .nextIt = &self.nextIt,
                    .index = 0,
                    .count = 0,
                    .buf = buf,
                },
            };
        }

        fn performTransform(self: *Self, comptime func: fn (BaseType, BaseType) BaseType, comptime avg: bool) ?BaseType {
            var agg: ?BaseType = null;
            self.reset();
            defer self.reset();
            var cnt: usize = 0;

            while (self.next()) |nxt| {
                cnt += 1;
                if (agg == null) {
                    agg = nxt;
                } else {
                    agg = func(agg, nxt);
                }
            }

            if (agg and avg) |some_agg| {
                return some_agg / cnt;
            } else {
                return agg;
            }
        }

        pub fn average(self: *Self, comptime func: fn (BaseType, BaseType) BaseType) ?BaseType {
            return self.performTransform(func, true);
        }

        pub fn aggregate(self: *Self, comptime func: fn (BaseType, BaseType) BaseType) ?BaseType {
            return self.performTransform(func, false);
        }

        // Select many currently only supports arrays
        pub fn selectMany(self: *Self, comptime filter: anytype) iterator(selectManyIt(ItType, filter)) {
            return iterator(selectManyIt(ItType, filter)){
                .nextIt = .{
                    .nextIt = &self.nextIt,
                    .currentIt = null,
                },
            };
        }

        // Currently requires you to give a new type, since can't have 'var' return type.
        pub fn select(self: *Self, comptime filter: anytype) iterator(selectIt(ItType, filter)) {
            return self.returnBasedOnThis(selectIt(ItType, filter));
        }

        pub fn cast(self: *Self, comptime NewType: type) iterator(castIt(NewType, ItType)) {
            return self.returnBasedOnThis(castIt(NewType, ItType));
        }

        pub fn all(self: *Self, comptime condition: fn (BaseType) bool) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (!condition(nxt)) {
                    return false;
                }
            }
            return true;
        }

        pub fn any(self: *Self, comptime condition: fn (BaseType) bool) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (condition(nxt)) {
                    return true;
                }
            }
            return false;
        }

        pub fn contains(self: *Self, value: BaseType) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (nxt == value) {
                    return true;
                }
            }
            return false;
        }

        pub fn take(self: *Self, comptime amount: usize) iterator(takeIt(ItType, amount)) {
            return self.returnBasedOnThis(takeIt(ItType, amount));
        }

        pub fn takeWhile(self: *Self, comptime condition: fn (BaseType) bool) iterator(takeWhileIt(ItType, condition)) {
            return self.returnBasedOnThis(takeWhileIt(ItType, condition));
        }

        pub fn skip(self: *Self, comptime amount: usize) iterator(skipIt(ItType, amount)) {
            return self.returnBasedOnThis(skipIt(ItType, amount));
        }

        pub fn skipWhile(self: *Self, comptime condition: fn (BaseType) bool) iterator(skipWhileIt(ItType, condition)) {
            return self.returnBasedOnThis(skipWhileIt(ItType, condition));
        }

        pub fn concat(self: *Self, other: anytype) iterator(concatIt(ItType, @TypeOf(other))) {
            return iterator(concatIt(ItType, @TypeOf(other))){
                .nextIt = .{
                    .nextIt = &self.nextIt,
                    .otherIt = other,
                },
            };
        }

        pub fn toArray(self: *Self, buffer: []BaseType) []BaseType {
            self.reset();
            defer self.reset();
            var c: usize = 0;
            while (self.next()) |nxt| {
                buffer[c] = nxt;
                c += 1;
            }
            return buffer[0..c];
        }

        pub fn toList(self: *Self, allocator: *std.mem.Allocator) std.ArrayList(BaseType) {
            self.reset();
            defer self.reset();
            var list = std.ArrayList(BaseType).init(allocator);
            while (self.next()) |nxt| {
                list.append(nxt);
            }
            return list;
        }

        pub fn fold(self: *Self, initial: anytype, comptime composeFn: fn (@TypeOf(initial), BaseType) @TypeOf(initial)) @TypeOf(initial) {
            var container = initial;
            while (self.next()) |nxt| {
                composeFn(container, nxt);
            }
            return container;
        }
    };
}
