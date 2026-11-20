const std = @import("std");

const Signedness = std.builtin.Signedness;
const ShiftInt = std.math.Log2Int;

pub fn CalkinWilfRational(comptime signedness: Signedness, comptime length: comptime_int) type {
    if (length < 0) @compileError("Length of CalkinWilfRational must be >= 0");

    return struct {
        value: BackingInt,

        /// The largest integer the cf-rational can hold
        const MAX_INT = switch (signedness) {
            .signed => length / 2,
            .unsigned => length,
        };

        /// Denominator cannot equal 0
        pub fn fromFraction(numer: BackingInt, denom: BackingInt) Self {
            std.debug.assert(denom != 0);

            switch (signedness) {
                .unsigned => return Self{ .value = inverseFusc(BackingInt, numer, denom) },
                .signed => {
                    if (numer >= 0 and denom >= 0) {
                        return inverseFusc(BackingInt, numer, denom);
                    } else if (numer < 0 and denom < 0) {
                        return inverseFusc(BackingInt, -numer, -denom);
                    } else if (numer < 0) {
                        return -inverseFusc(BackingInt, -numer, denom);
                    } else {
                        return -inverseFusc(BackingInt, numer, -denom);
                    }
                },
            }
        }
        // pub fn fromF32(val: f32) Self {}
        // pub fn fromf64(val: f32) Self {}

        pub fn numerator(self: Self) BackingInt {
            return fusc(BackingInt, self.value);
        }

        pub fn denominator(self: Self) BackingInt {
            return fusc(BackingInt, self.value + 1);
        }

        pub fn format(
            self: Self,
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try writer.print("{d}/{d}", .{ self.numerator(), self.denominator() });
        }

        const BackingInt = @Int(signedness, length);
        const Self = @This();
    };
}

/// Calculates the nth term of Stern's diatomic series (fusc) in O(log n) time.
pub fn fusc(comptime T: type, n: T) T {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned) {
        @compileError("fusc requires an unsigned integer type");
    }

    if (n == 0) return 0;

    // Strip trailing zeros since fusc(2n) == fusc(n)
    var val = n >> @intCast(@ctz(n));
    var a: T = 1;
    var b: T = 0;

    while (val > 0) : (val >>= 1) {
        if ((val & 1) == 0) {
            a += b;
        } else {
            b += a;
        }
    }

    return b;
}

pub fn inverseFusc(comptime T: type, fusc_n: T, fusc_n_plus_1: T) T {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned) {
        @compileError("fusc requires an unsigned integer type");
    }

    var a = fusc_n;
    var b = fusc_n_plus_1;

    if (a == 0 and b == 1) return 0;

    var n: T = 0;
    var shift: ShiftInt(T) = 0;

    while (a != b) {
        if (a < b) {
            const q = (b - 1) / a;
            b -= q * a;
            shift += @intCast(q);
        } else {
            const q = (a - 1) / b;
            a -= q * b;
            const mask = (@as(T, 1) << @intCast(q)) - 1;
            n |= mask << shift;
            shift += @intCast(q);
        }
    }

    // Prepend the leading 1 bit from the root (1, 1)
    return n | (@as(T, 1) << shift);
}
