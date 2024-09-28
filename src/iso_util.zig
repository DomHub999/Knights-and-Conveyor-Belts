const std = @import("std");

const Point = @import("iso_core.zig").Point;
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

pub const LinearEquation = union(enum) {
    has_slope: struct { m: f32, b: f32 },
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


//TODO: return error instead of optional
const FLOAT_EQUALITY_THRESHOLD: f32 = 0.01;
pub fn lineIntercept(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    const case_handler = getLinearEquationCombCase(line1, line2);
    return case_handler(line1, line2);
}
fn regularLinearEquations(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    const first_line = &line1.has_slope;
    const second_line = &line2.has_slope;

    if (@abs(first_line.m - second_line.m) < FLOAT_EQUALITY_THRESHOLD) return null;

    var point = Point{ .x = 0, .y = 0 };
    point.x = (first_line.b - second_line.b) / (second_line.m - first_line.m);
    point.y = first_line.m * point.x + first_line.b;
    return point;
}
fn verticalLinearEquations(_: *const LinearEquation, _: *const LinearEquation) ?Point {
    return null;
}
fn regVertLinearEquations(line1: *const LinearEquation, line2: *const LinearEquation) ?Point {
    const first_line = &line1.has_slope;
    const second_line = &line2.vertical;

    var point = Point{ .x = 0, .y = 0 };
    point.y = first_line.m * second_line.a + first_line.b;
    point.x = second_line.a;
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

test "lines intercept1" {
    const line1 = LinearEquation{ .has_slope = .{ .m = 0.5, .b = 0 } };
    const line2 = LinearEquation{ .has_slope = .{ .m = 0.7, .b = -4 } };

    const point_intercept = lineIntercept(&line1, &line2).?;
    try expect(@round(point_intercept.x) == 20 and @round(point_intercept.y) == 10);
}

test "lines intercept2" {
    const line1 = LinearEquation{ .has_slope = .{ .m = 0.5, .b = 0 } };
    const line2 = LinearEquation{ .has_slope = .{ .m = 0.5, .b = -4 } };

    const point_intercept = lineIntercept(&line1, &line2);
    try expect(point_intercept == null);
}

test "lines intercept3" {
    const line1 = LinearEquation{ .has_slope = .{ .m = 0.7, .b = -4 } };
    const line2 = LinearEquation{ .has_slope = .{ .m = 0.5, .b = -4 } };

    const point_intercept = lineIntercept(&line1, &line2).?;
    try expect(@round(point_intercept.x) == 0 and @round(point_intercept.y) == -4);
}

test "lines intercept4" {
    const line1 = LinearEquation{ .has_slope = .{ .m = 0.5, .b = 0 } };
    const line2 = LinearEquation{ .vertical = .{ .a = 4 } };

    const point_intercept = lineIntercept(&line1, &line2).?;
    try expect(@round(point_intercept.x) == 4 and @round(point_intercept.y) == 2);
}

test "lines intercept5" {
    const line1 = LinearEquation{ .has_slope = .{ .m = 0.5, .b = 0 } };
    const line2 = LinearEquation{ .vertical = .{ .a = 4 } };

    const point_intercept = lineIntercept(&line2, &line1).?;
    try expect(@round(point_intercept.x) == 4 and @round(point_intercept.y) == 2);
}

test "lines intercept6" {
    const line1 = LinearEquation{ .vertical = .{ .a = 2 } };
    const line2 = LinearEquation{ .vertical = .{ .a = 4 } };

    const point_intercept = lineIntercept(&line2, &line1);
    try expect(point_intercept == null);
}

test "getLinearQuationCombCase" {
    const reg_eq = LinearEquation{ .has_slope = .{ .m = 0, .b = 0 } };
    const vert_eq = LinearEquation{ .vertical = .{ .a = 0 } };

    var result = getLinearEquationCombCase(&reg_eq, &reg_eq);
    try expect(result == regularLinearEquations);

    result = getLinearEquationCombCase(&vert_eq, &reg_eq);
    try expect(result == vertRegLinearEquations);

    result = getLinearEquationCombCase(&reg_eq, &vert_eq);
    try expect(result == regVertLinearEquations);

    result = getLinearEquationCombCase(&vert_eq, &vert_eq);
    try expect(result == verticalLinearEquations);
}
