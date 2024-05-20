const std = @import("std");

const Point = @import("iso_core.zig").Point;
// const indexTwoDimArray = @import("././utility.zig").indexTwoDimArray;
const indexTwoDimArray = @import("utility.zig").indexTwoDimArray;

//Given two points, return all points of a rectangle in a consistent order, regardless of the order of the given points
const Rectangle = struct { upper_left: Point, upper_right: Point, bottom_right: Point, bottom_left: Point };
//TODO:implement appropriate error handling
fn rectangleEdges(x1: f32, y1: f32, x2: f32, y2: f32) ?Rectangle {
    if (x1 < x2 and y1 < y2) { //top left to bottom right
        return Rectangle{
            .upper_left = .{ .x = x1, .y = y1 },
            .upper_right = .{ .x = x2, .y = y1 },
            .bottom_right = .{ .x = x2, .y = y2 },
            .bottom_left = .{ .x = x1, .y = y2 },
        };
    } else if (x1 > x2 and y1 > y2) { //bottom right to top left
        return Rectangle{
            .upper_left = .{ .x = x2, .y = y2 },
            .upper_right = .{ .x = x1, .y = y2 },
            .bottom_right = .{ .x = x1, .y = y1 },
            .bottom_left = .{ .x = x2, .y = y1 },
        };
    } else if (x1 < x2 and y1 > y2) { //bottom left to top right
        return Rectangle{
            .upper_left = .{ .x = x1, .y = y2 },
            .upper_right = .{ .x = x2, .y = y2 },
            .bottom_right = .{ .x = x2, .y = y1 },
            .bottom_left = .{ .x = x1, .y = y1 },
        };
    } else if (x1 > x2 and y1 < y2) { // top right to bottom left
        return Rectangle{
            .upper_left = .{ .x = x2, .y = y1 },
            .upper_right = .{ .x = x1, .y = y1 },
            .bottom_right = .{ .x = x1, .y = y2 },
            .bottom_left = .{ .x = x2, .y = y2 },
        };
    }

    return null;
}

//Math functins for linear equations
//TODO:Type can be deleted
// pub const LinearEquation = struct { m: f32, b: f32 };

pub const LinearEquation = union(enum) {
    regular: struct { m: f32, b: f32 },
    vertical: struct { a: f32 },
};

pub fn slope(x1: f32, y1: f32, x2: f32, y2: f32) f32 {
    return (y2 - y1) / (x2 - x1);
}
pub fn yIntercept(m: f32, x: f32, y: f32) f32 {
    return -m * x + y;
}
pub fn findLinearX(m: f32, y: f32, b: f32) f32 {
    return (y - b) / m;
}
pub fn findLinearY(m: f32, x: f32, b: f32) f32 {
    return m * x + b;
}

const FLOAT_EQUALITY_THRESHOLD: f32 = 0.01;
pub fn lineIntercept(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    const case_handler = createLinearEquationsCombCases(line1, line2);
    return case_handler(line1, line2);
}

// const LinearEquationCombCase = enum(u2) {
//     both_regular = 0b00,
//     both_vertical = 0b11,
//     regular_vertical = 0b10,
//     vertical_regular = 0b01,
// };

fn regularLinearEquations(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    if (@abs(line1.m - line2.m) < FLOAT_EQUALITY_THRESHOLD) return null;

    var point = Point{ .x = 0, .y = 0 };
    point.x = (line1.b - line2.b) / (line2.m - line1.m);
    point.y = line1.m * point.x + line1.b;
    return point;
}
fn verticalLinearEquations(_: *const LinearEquation, _: *const LinearEquation) ?Point {
    return null;
}
fn regVertLinearEquations(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    var point = Point{ .x = 0, .y = 0 };
    point.y = line1.regular.b * line2.vertical.a + line1.regular.b;
    point.x = line2.vertical.a;
    return point;
}
fn vertRegLinearEquations(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    return regVertLinearEquations(line2, line1);
}

const NUMBER_OF_EQ_COMB: usize = 4;
const LinearEquationCaseHandlerFunction = *const fn (line1: *const LinearEquation, line2: *const LinearEquation) ?Point;
const LinearEquationsCombCasesType = [NUMBER_OF_EQ_COMB]LinearEquationCaseHandlerFunction;

fn createLinearEquationsCombCases() LinearEquationsCombCasesType {
    return .{
        regularLinearEquations,
        vertRegLinearEquations,
        regVertLinearEquations,
        verticalLinearEquations,
    };
}

const linear_equation_case_handlers = createLinearEquationsCombCases();

fn getLinearEquationCombCase(equation1: *const LinearEquation, equation2: *const LinearEquation) LinearEquationCaseHandlerFunction {
    const int_from_enum1 = @intFromEnum(equation1.*);
    const int_from_enum2 = @intFromEnum(equation2.*);

    const i = indexTwoDimArray(int_from_enum1, int_from_enum2, 2);
    return linear_equation_case_handlers[i];

}

const expect = @import("std").testing.expect;

test "getLinearQuationCombCase" {
    const reg_eq = LinearEquation{.regular = .{.m = 0, .b = 0}};
    const vert_eq = LinearEquation{.vertical = .{.a = 0}};
    _= vert_eq;

    const result = getLinearEquationCombCase(&reg_eq, &reg_eq);
    _ = result;

}

test "area rectangle" {
    const Points = struct { p1: Point, p2: Point };
    const test_points = [_]Points{
        Points{ .p1 = .{ .x = 0, .y = 0 }, .p2 = .{ .x = 1, .y = 1 } },
        Points{ .p1 = .{ .x = 1, .y = 1 }, .p2 = .{ .x = 0, .y = 0 } },
        Points{ .p1 = .{ .x = 0, .y = 1 }, .p2 = .{ .x = 1, .y = 0 } },
        Points{ .p1 = .{ .x = 1, .y = 0 }, .p2 = .{ .x = 0, .y = 1 } },
    };

    const p_res = Rectangle{
        .upper_left = .{ .x = 0, .y = 0 },
        .upper_right = .{ .x = 1, .y = 0 },
        .bottom_right = .{ .x = 1, .y = 1 },
        .bottom_left = .{ .x = 0, .y = 1 },
    };

    for (&test_points) |*p| {
        const rec = rectangleEdges(p.p1.x, p.p1.y, p.p2.x, p.p2.y).?;

        try expect(rec.upper_left.x == p_res.upper_left.x);
        try expect(rec.upper_left.y == p_res.upper_left.y);

        try expect(rec.upper_right.x == p_res.upper_right.x);
        try expect(rec.upper_right.y == p_res.upper_right.y);

        try expect(rec.bottom_right.x == p_res.bottom_right.x);
        try expect(rec.bottom_right.y == p_res.bottom_right.y);

        try expect(rec.bottom_left.x == p_res.bottom_left.x);
        try expect(rec.bottom_left.y == p_res.bottom_left.y);
    }
}



test "slope" {
    const result = slope(-5, 13, 3, -3);
    try expect(result == -2);
}

test "y intercept" {
    const result = yIntercept(-2, 3, -3);
    try expect(result == 3);
}

test "find linear x and y" {
    const resultX = findLinearX(-2, -3, 3);
    const resultY = findLinearY(-2, 3, 3);

    try expect(resultX == 3);
    try expect(resultY == -3);
}

// test "lines intercept1" {
//     const line1 = LinearEquation{ .m = 0.5, .b = 0 };
//     const line2 = LinearEquation{ .m = 0.7, .b = -4 };

//     const point_intercept = lineIntercept(&line1, &line2).?;
//     try expect(@round(point_intercept.x) == 20 and @round(point_intercept.y) == 10);
// }

// test "lines intercept2" {
//     const line1 = LinearEquation{ .m = 0.5, .b = 0 };
//     const line2 = LinearEquation{ .m = 0.5, .b = -4 };

//     const point_intercept = lineIntercept(&line1, &line2);
//     try expect(point_intercept == null);
// }

// test "lines intercept3" {
//     const line1 = LinearEquation{ .m = 0.7, .b = -4 };
//     const line2 = LinearEquation{ .m = 0.5, .b = -4 };

//     const point_intercept = lineIntercept(&line1, &line2).?;
//     try expect(@round(point_intercept.x) == 0 and @round(point_intercept.y) == -4);
// }


