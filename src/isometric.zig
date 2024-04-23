const std = @import("std");
const util = @import("utility.zig");

const Vec2f = struct { x: f32, y: f32 };
const Vec2i = struct { x: i32, y: i32 };

fn orthToIsoWrapIncrementX(tile_pix_width: f32) f32 {
    return tile_pix_width / 2;
}

fn orthToIsoWrapIncrementY(diamond_pix_height: f32) f32 {
    return diamond_pix_height / 2;
}

fn orthToIsoX(orth_x: f32, orth_y: f32, wrap_increment_x: f32) f32 {
    return (orth_x - orth_y) * wrap_increment_x;
}

fn orthToIsoY(orth_x: f32, orth_y: f32, wrap_increment_y: f32) f32 {
    return (orth_y + orth_x) * wrap_increment_y;
}

fn isoToOrthX(iso_x: f32, iso_y: f32, wrap_increment_x: f32, wrap_increment_y: f32) f32 {
    return (iso_x / wrap_increment_x + iso_y / wrap_increment_y) / 2;
}

fn isoToOrthY(iso_x: f32, iso_y: f32, wrap_increment_x: f32, wrap_increment_y: f32) f32 {
    return (iso_x / wrap_increment_x - iso_y / wrap_increment_y) / -2;
}

fn isoToOrthYLean(iso_y: f32, wrap_increment_y: f32, orth_x: f32) f32 {
    return (iso_y / wrap_increment_y) - orth_x;
}

fn rectangleWidth(tile_pix_width: f32) f32 {
    return tile_pix_width / 2;
}

fn rectangleHeight(diamond_pix_height: f32) f32 {
    return diamond_pix_height / 2;
}

fn rectangleGridPositionX(iso_x: f32, rectangle_pix_width: f32) i32 {
    return @intFromFloat(@floor(iso_x / rectangle_pix_width));
}

fn rectangleGridPositionY(iso_y: f32, rectangle_pix_height: f32) i32 {
    return @intFromFloat(@floor(iso_y / rectangle_pix_height));
}

fn rectanglePositionX(rectangle_grid_position_x: i32, rectangle_pix_width: f32) f32 {
    const f_rectangle_grid_position_x: f32 = @floatFromInt(rectangle_grid_position_x);
    return f_rectangle_grid_position_x * rectangle_pix_width;
}

fn rectanglePositionY(rectangle_grid_position_y: i32, rectangle_pix_height: f32) f32 {
    const f_rectangle_grid_position_y: f32 = @floatFromInt(rectangle_grid_position_y);
    return f_rectangle_grid_position_y * rectangle_pix_height;
}

const DiagonalDirection = enum { raising, falling };
fn diagonalDirection(rectangle_position_x: i32, rectangle_position_y: i32) ?DiagonalDirection {
    const rectangle_direction_denominator = rectangle_position_x + rectangle_position_y;
    const cell_direction = @mod(rectangle_direction_denominator, 2);

    return switch (cell_direction) {
        0 => .raising,
        1 => .falling,
        else => null,
    };
}

const RectangleSide = enum { upper, lower };
fn rectangleSideRaising(iso_x: f32, iso_y: f32, rectangle_position_x: f32, rectangle_position_y: f32, rectangle_pix_width: f32, rectangle_pix_height: f32) ?RectangleSide {
    const x = iso_x - (rectangle_position_x + rectangle_pix_width);
    const y = iso_y - rectangle_position_y;

    if (x == 0) return .upper; // in the unlikely event, that a points x position lies on the opposite of the rectangles origin

    const iso_slope = y / x;
    const diagonal_slope = rectangle_pix_height / -rectangle_pix_width;

    if (iso_slope >= diagonal_slope) {
        return .upper;
    } else if (iso_slope < diagonal_slope) {
        return .lower;
    }

    return null;
}

fn rectangleSideFalling(iso_x: f32, iso_y: f32, rectangle_position_x: f32, rectangle_position_y: f32, rectangle_pix_width: f32, rectangle_pix_height: f32) ?RectangleSide {
    const x = iso_x - rectangle_position_x;
    const y = iso_y - rectangle_position_y;

    if (x == 0) return .upper; //the unlikely event, that a point lies on the rectangles origin

    const iso_slope = y / x;
    const diagonal_slope = rectangle_pix_height / rectangle_pix_width;

    if (iso_slope <= diagonal_slope) {
        return .upper;
    } else if (iso_slope > diagonal_slope) {
        return .lower;
    }

    return null;
}

fn tilePosition(
    iso_x: f32,
    iso_y: f32,
    tile_pix_width: f32,
    diamond_pix_height: f32,
) ?struct { tile_x: f32, tile_y: f32 } {
    const rectangle_pix_width = rectangleWidth(tile_pix_width);
    const rectangle_pix_height = rectangleHeight(diamond_pix_height);
    const rectangle_grid_position_x = rectangleGridPositionX(iso_x, rectangle_pix_width);
    const rectangle_grid_position_y = rectangleGridPositionY(iso_y, rectangle_pix_height);
    const diagonal_direction = diagonalDirection(rectangle_grid_position_x, rectangle_grid_position_y).?;

    const rectangle_position_x = rectanglePositionX(rectangle_grid_position_x, rectangle_pix_width);
    const rectangle_position_y = rectanglePositionX(rectangle_grid_position_y, rectangle_pix_height);

    const rectangle_side = switch (diagonal_direction) {
        .raising => rectangleSideRaising(iso_x, iso_y, rectangle_position_x, rectangle_position_y, rectangle_pix_width, rectangle_pix_height).?,
        .falling => rectangleSideFalling(iso_x, iso_y, rectangle_position_x, rectangle_position_y, rectangle_pix_width, rectangle_pix_height).?,
    };

    if (diagonal_direction == .raising and rectangle_side == .upper) {
        return .{ .tile_x = rectangle_position_x - rectangle_pix_width, .tile_y = rectangle_position_y - rectangle_pix_height };
    }
    if (diagonal_direction == .raising and rectangle_side == .lower) {
        return .{ .tile_x = rectangle_position_x, .tile_y = rectangle_position_y };
    }
    if (diagonal_direction == .falling and rectangle_side == .upper) {
        return .{ .tile_x = rectangle_position_x, .tile_y = rectangle_position_y - rectangle_pix_height };
    }
    if (diagonal_direction == .falling and rectangle_side == .lower) {
        return .{ .tile_x = rectangle_position_x - rectangle_pix_width, .tile_y = rectangle_position_y };
    }
    return null;
}

const MapDimensions = struct { top: Vec2f, right: Vec2f, bottom: Vec2f, left: Vec2f };
fn mapDimensions(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: f32, map_tiles_height: f32, wrap_increment_x: f32, wrap_increment_y: f32) MapDimensions {
    const orth_x = map_tiles_width - 1;
    const orth_y = map_tiles_height - 1;

    const top_x = orthToIsoX(0, 0, wrap_increment_x) + tile_pix_width / 2;
    const top_y = orthToIsoY(0, 0, wrap_increment_y);

    const right_x = orthToIsoX(orth_x, 0, wrap_increment_x) + tile_pix_width;
    const right_y = orthToIsoY(orth_x, 0, wrap_increment_y) + diamond_pix_height / 2;

    const bottom_x = orthToIsoX(orth_x, orth_y, wrap_increment_x) + tile_pix_width / 2;
    const bottom_y = orthToIsoY(orth_x, orth_y, wrap_increment_y) + diamond_pix_height;

    const left_x = orthToIsoX(0, orth_y, wrap_increment_x);
    const left_y = orthToIsoY(0, orth_y, wrap_increment_y) + diamond_pix_height / 2;

    return MapDimensions{
        .top = Vec2f{ .x = top_x, .y = top_y },
        .right = Vec2f{ .x = right_x, .y = right_y },
        .bottom = Vec2f{ .x = bottom_x, .y = bottom_y },
        .left = Vec2f{ .x = left_x, .y = left_y },
    };
}

const LinearEquation = struct { m: f32, b: f32 };
const SideEquations = struct {
    upper_right: LinearEquation,
    bottom_right: LinearEquation,
    bottom_left: LinearEquation,
    upper_left: LinearEquation,
};
fn slope(x1: f32, y1: f32, x2: f32, y2: f32) f32 {
    return (y2 - y1) / (x2 - x1);
}

fn yIntercept(m: f32, x: f32, y: f32) f32 {
    return -m * x + y;
}

fn mapSideEquations(map_dimensions: *const MapDimensions) SideEquations {
    var side_equations: SideEquations = undefined;

    side_equations.upper_right.m = slope(map_dimensions.top.x, map_dimensions.top.y, map_dimensions.right.x, map_dimensions.right.y);
    side_equations.upper_right.b = yIntercept(side_equations.upper_right.m, map_dimensions.top.x, map_dimensions.top.y);

    side_equations.bottom_right.m = slope(map_dimensions.right.x, map_dimensions.right.y, map_dimensions.bottom.x, map_dimensions.bottom.y);
    side_equations.bottom_right.b = yIntercept(side_equations.bottom_right.m, map_dimensions.right.x, map_dimensions.right.y);

    side_equations.bottom_left.m = slope(map_dimensions.left.x, map_dimensions.left.y, map_dimensions.bottom.x, map_dimensions.bottom.y);
    side_equations.bottom_left.b = yIntercept(side_equations.bottom_left.m, map_dimensions.left.x, map_dimensions.left.y);

    side_equations.upper_left.m = slope(map_dimensions.top.x, map_dimensions.top.y, map_dimensions.left.x, map_dimensions.left.y);
    side_equations.upper_left.b = yIntercept(side_equations.upper_left.m, map_dimensions.top.x, map_dimensions.top.y);

    return side_equations;
}

const MapBoundries = struct {
    upper_right_x: f32,
    upper_right_y: f32,

    bottom_right_x: f32,
    bottom_right_y: f32,

    bottom_left_x: f32,
    bottom_left_y: f32,

    upper_left_x: f32,
    upper_left_y: f32,
};

fn findLinearX(m: f32, y: f32, b: f32) f32 {
    return (y - b) / m;
}
fn findLinearY(m: f32, x: f32, b: f32) f32 {
    return m * x + b;
}
fn mapBoundries(x: f32, y: f32, map_side_equations: *const SideEquations) MapBoundries {
    var map_boundries: MapBoundries = undefined;
    const mse = map_side_equations;

    map_boundries.upper_right_x = findLinearX(mse.upper_right.m, y, mse.upper_right.b);
    map_boundries.upper_right_y = findLinearY(mse.upper_right.m, x, mse.upper_right.b);

    map_boundries.bottom_right_x = findLinearX(mse.bottom_right.m, y, mse.bottom_right.b);
    map_boundries.bottom_right_y = findLinearY(mse.bottom_right.m, x, mse.bottom_right.b);

    map_boundries.bottom_left_x = findLinearX(mse.bottom_left.m, y, mse.bottom_left.b);
    map_boundries.bottom_left_y = findLinearY(mse.bottom_left.m, x, mse.bottom_left.b);

    map_boundries.upper_left_x = findLinearX(mse.upper_left.m, y, mse.upper_left.b);
    map_boundries.upper_left_y = findLinearY(mse.upper_left.m, x, mse.upper_left.b);

    return map_boundries;
}

const Boundry = enum { upper_right, bottom_right, bottom_left, upper_left };
const BoundryPosition = struct { position: Vec2f, boundry_violation: Boundry };
const IsOnMap = union(enum) { yes: void, no: BoundryPosition };
fn isPointOnMap(x: f32, y: f32, map_side_equations: *const SideEquations) IsOnMap {
    const map_boundries = mapBoundries(x, y, map_side_equations);

    if (x > map_boundries.upper_right_x and y < map_boundries.upper_right_y) {
        return IsOnMap{ .no = .{ .position = .{ .x = map_boundries.upper_right_x, .y = map_boundries.upper_right_y }, .boundry_violation = .upper_right } };
    }
    if (x > map_boundries.bottom_right_x and y > map_boundries.bottom_right_y) {
        return IsOnMap{ .no = .{ .position = .{ .x = map_boundries.bottom_right_x, .y = map_boundries.bottom_right_y }, .boundry_violation = .bottom_right } };
    }
    if (x < map_boundries.bottom_left_x and y > map_boundries.bottom_left_y) {
        return IsOnMap{ .no = .{ .position = .{ .x = map_boundries.bottom_left_x, .y = map_boundries.bottom_left_y }, .boundry_violation = .bottom_left } };
    }
    if (x < map_boundries.upper_left_x and y < map_boundries.upper_left_y) {
        return IsOnMap{ .no = .{ .position = .{ .x = map_boundries.upper_left_x, .y = map_boundries.upper_left_y }, .boundry_violation = .upper_left } };
    }

    return IsOnMap.yes;
}

const Rectangle = struct { upper_left: Vec2f, upper_right: Vec2f, bottom_right: Vec2f, bottom_left: Vec2f };
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

const PROBING_DIVISOR:f32 = 4; //divisor to determine probing length
fn gridSelFromRec(
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
    grid_buf: []bool,
    tile_pix_width: f32,
    diamond_pix_height: f32,
    map_side_equations: *const SideEquations,
    wrap_increment_x: f32,
    wrap_increment_y: f32,
    map_tiles_width: usize,
) void {
    const rectangle = rectangleEdges(x1, y1, x2, y2).?;

    var cursor_y = rectangle.upper_left.y;

    while (cursor_y <= rectangle.bottom_right.y) : (cursor_y += diamond_pix_height / PROBING_DIVISOR) {
        var cursor_x = rectangle.upper_left.x;

        var is_point_on_map = isPointOnMap(cursor_x, cursor_y, map_side_equations);

        switch (is_point_on_map) {
            .yes => {},
            .no => |p| {
                switch (p.boundry_violation) {
                    .upper_right, .bottom_right => {
                        continue;
                    }, //we are passt the right side boundries
                    .upper_left, .bottom_left => {
                        // cursor_x = p.position.x;
                    }, //move the cursor to to the left boundry and continue from there
                }
            },
        }

        while (cursor_x <= rectangle.upper_right.x) : (cursor_x += tile_pix_width / PROBING_DIVISOR) {
            is_point_on_map = isPointOnMap(cursor_x, cursor_y, map_side_equations);

            switch (is_point_on_map) {
                .no => {
                    continue;
                    // break;
                },
                .yes => {
                    const tile_position = tilePosition(cursor_x, cursor_y, tile_pix_width, diamond_pix_height).?;

                    const orth_x = isoToOrthX(tile_position.tile_x, tile_position.tile_y, wrap_increment_x, wrap_increment_y);
                    const orth_y = isoToOrthYLean(tile_position.tile_y, wrap_increment_y, orth_x);

                    if (orth_x < 0 or orth_y < 0) continue;

                    const idx = util.indexTwoDimArray(@intFromFloat(orth_x), @intFromFloat(orth_y), map_tiles_width);
                    grid_buf[idx] = true;
                },
            }
        }
    }
}

pub const Iso = struct {
    tile_pix_width: f32,
    diamond_pix_height: f32,

    wrap_increment_x: f32,
    wrap_increment_y: f32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    map_side_equations: SideEquations,

    pub fn new(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: usize, map_tiles_height: usize) @This() {
        var this: @This() = undefined;
        this.tile_pix_width = tile_pix_width;
        this.diamond_pix_height = diamond_pix_height;
        this.wrap_increment_x = orthToIsoWrapIncrementX(tile_pix_width);
        this.wrap_increment_y = orthToIsoWrapIncrementY(diamond_pix_height);
        this.map_tiles_height = map_tiles_height;
        this.map_tiles_width = map_tiles_width;

        const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, @floatFromInt(map_tiles_width), @floatFromInt(map_tiles_height), this.wrap_increment_x, this.wrap_increment_y);
        this.map_side_equations = mapSideEquations(&map_dimensions);

        return this;
    }

    pub fn orthToIso(this: *const @This(), orth_x: usize, orth_y: usize, map_pos_x: i32, map_pos_y: i32) struct { iso_x: f32, iso_y: f32 } {
        const f_orth_x: f32 = @floatFromInt(orth_x);
        const f_orth_y: f32 = @floatFromInt(orth_y);
        const iso_x = orthToIsoX(f_orth_x, f_orth_y, this.wrap_increment_x);
        const iso_y = orthToIsoY(f_orth_x, f_orth_y, this.wrap_increment_y);
        return .{ .iso_x = iso_x + @as(f32, @floatFromInt(map_pos_x)), .iso_y = iso_y + @as(f32, @floatFromInt(map_pos_y)) };
    }

    pub fn isoToOrth(this: *const @This(), iso_x: i32, iso_y: i32, map_pos_x: i32, map_pos_y: i32) ?struct { orth_x: usize, orth_y: usize } {
        const iso_x_map: f32 = @as(f32, @floatFromInt(iso_x)) - @as(f32, @floatFromInt(map_pos_x));
        const iso_y_map: f32 = @as(f32, @floatFromInt(iso_y)) - @as(f32, @floatFromInt(map_pos_y));

        const tile_position = tilePosition(iso_x_map, iso_y_map, this.tile_pix_width, this.diamond_pix_height).?;
        const orth_x = isoToOrthX(tile_position.tile_x, tile_position.tile_y, this.wrap_increment_x, this.wrap_increment_y);
        const orth_y = isoToOrthYLean(tile_position.tile_y, this.wrap_increment_y, orth_x);
        if (orth_x < 0 or orth_y < 0) return null;
        return .{ .orth_x = @intFromFloat(orth_x), .orth_y = @intFromFloat(orth_y) };
    }

    pub fn isoSquareToGrid(x1: i32, y1: i32, x2: i32, y2: i32, grid_buf: []bool) void {
        const flot_vec_1 = Vec2f{ .x = @floatFromInt(x1), .y = @floatFromInt(y1) };
        const flot_vec_2 = Vec2f{ .x = @floatFromInt(x2), .y = @floatFromInt(y2) };
        _ = flot_vec_1;
        _ = flot_vec_2;
        _ = grid_buf;
    }
};

const expect = @import("std").testing.expect;
test "diagonal_direction" {
    try expect(diagonalDirection(0, 0).? == DiagonalDirection.raising);
    try expect(diagonalDirection(2, 1).? == DiagonalDirection.falling);
    try expect(diagonalDirection(2, 3).? == DiagonalDirection.falling);
    try expect(diagonalDirection(1, 3).? == DiagonalDirection.raising);
}

test "orth to iso and back ext" {
    const wrap_increment_x = orthToIsoWrapIncrementX(120);
    const wrap_increment_y = orthToIsoWrapIncrementY(60);

    const orth_x: f32 = 3;
    const orth_y: f32 = 2;

    const iso_x = orthToIsoX(orth_x, orth_y, wrap_increment_x);
    const iso_y = orthToIsoY(orth_x, orth_y, wrap_increment_y);

    const ort_x_recalc = isoToOrthX(iso_x, iso_y, wrap_increment_x, wrap_increment_y);
    const ort_y_recalc = isoToOrthY(iso_x, iso_y, wrap_increment_x, wrap_increment_y);

    try expect(orth_x == ort_x_recalc);
    try expect(orth_y == ort_y_recalc);
}

test "orth to iso and back lean" {
    const wrap_increment_x = orthToIsoWrapIncrementX(120);
    const wrap_increment_y = orthToIsoWrapIncrementY(60);

    const orth_x: f32 = 3;
    const orth_y: f32 = 2;

    const iso_x = orthToIsoX(orth_x, orth_y, wrap_increment_x);
    const iso_y = orthToIsoY(orth_x, orth_y, wrap_increment_y);

    const ort_x_recalc = isoToOrthX(iso_x, iso_y, wrap_increment_x, wrap_increment_y);
    const ort_y_recalc = isoToOrthYLean(iso_y, wrap_increment_y, ort_x_recalc);

    try expect(orth_x == ort_x_recalc);
    try expect(orth_y == ort_y_recalc);
}

test "tile position" {
    const tile_width: f32 = 129;
    const tile_height: f32 = 65;

    const Coord = struct { x: f32, y: f32 };
    const upper_left = Coord{ .x = 43, .y = 80 };
    const upper_right = Coord{ .x = 107, .y = 91 };
    const bottom_right = Coord{ .x = 110, .y = 103 };
    const bottom_left = Coord{ .x = 74, .y = 103 };

    const tile_position_upper_left = tilePosition(upper_left.x, upper_left.y, tile_width, tile_height).?;
    const tile_position_upper_right = tilePosition(upper_right.x, upper_right.y, tile_width, tile_height).?;
    const tile_position_bottom_right = tilePosition(bottom_right.x, bottom_right.y, tile_width, tile_height).?;
    const tile_position_bottom_left = tilePosition(bottom_left.x, bottom_left.y, tile_width, tile_height).?;

    const wrap_increment_x = orthToIsoWrapIncrementX(tile_width);
    const wrap_increment_y = orthToIsoWrapIncrementY(tile_height);

    const iso_x = orthToIsoX(1, 1, wrap_increment_x);
    const iso_y = orthToIsoY(1, 1, wrap_increment_y);

    try expect(tile_position_upper_left.tile_x == iso_x);
    try expect(tile_position_upper_left.tile_y == iso_y);

    try expect(tile_position_upper_right.tile_x == iso_x);
    try expect(tile_position_upper_right.tile_y == iso_y);

    try expect(tile_position_bottom_left.tile_x == iso_x);
    try expect(tile_position_bottom_left.tile_y == iso_y);

    try expect(tile_position_bottom_right.tile_x == iso_x);
    try expect(tile_position_bottom_right.tile_y == iso_y);
}

test "map dimensions" {
    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    const wrap_increment_x = orthToIsoWrapIncrementX(tile_pix_width);
    const wrap_increment_y = orthToIsoWrapIncrementY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, wrap_increment_x, wrap_increment_y);

    try expect(map_dimensions.top.x == 4);
    try expect(map_dimensions.top.y == 0);

    try expect(map_dimensions.right.x == 16);
    try expect(map_dimensions.right.y == 6);

    try expect(map_dimensions.bottom.x == 8);
    try expect(map_dimensions.bottom.y == 10);

    try expect(map_dimensions.left.x == -4);
    try expect(map_dimensions.left.y == 4);
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

test "is point on map" {
    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    const wrap_increment_x = orthToIsoWrapIncrementX(tile_pix_width);
    const wrap_increment_y = orthToIsoWrapIncrementY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, wrap_increment_x, wrap_increment_y);
    const side_equations = mapSideEquations(&map_dimensions);

    const point_on_map_1 = Vec2f{ .x = 4, .y = 0 };
    const point_on_map_2 = Vec2f{ .x = 4, .y = 7 };
    const point_on_map_3 = Vec2f{ .x = 9, .y = 7 };
    const point_on_map_4 = Vec2f{ .x = -3, .y = 4 };

    const point_not_on_map_1 = Vec2f{ .x = 5, .y = 0 };
    const point_not_on_map_2 = Vec2f{ .x = 4, .y = 9 };
    const point_not_on_map_3 = Vec2f{ .x = 16, .y = 7 };
    const point_not_on_map_4 = Vec2f{ .x = -5, .y = 4 };

    const is_on_map_1 = isPointOnMap(point_on_map_1.x, point_on_map_1.y, &side_equations);
    const is_on_map_2 = isPointOnMap(point_on_map_2.x, point_on_map_2.y, &side_equations);
    const is_on_map_3 = isPointOnMap(point_on_map_3.x, point_on_map_3.y, &side_equations);
    const is_on_map_4 = isPointOnMap(point_on_map_4.x, point_on_map_4.y, &side_equations);

    const is_not_on_map_1 = isPointOnMap(point_not_on_map_1.x, point_not_on_map_1.y, &side_equations);
    const is_not_on_map_2 = isPointOnMap(point_not_on_map_2.x, point_not_on_map_2.y, &side_equations);
    const is_not_on_map_3 = isPointOnMap(point_not_on_map_3.x, point_not_on_map_3.y, &side_equations);
    const is_not_on_map_4 = isPointOnMap(point_not_on_map_4.x, point_not_on_map_4.y, &side_equations);

    try expect(is_on_map_1 == .yes);
    try expect(is_on_map_2 == .yes);
    try expect(is_on_map_3 == .yes);
    try expect(is_on_map_4 == .yes);

    try expect(is_not_on_map_1 == .no);
    try expect(is_not_on_map_2 == .no);
    try expect(is_not_on_map_3 == .no);
    try expect(is_not_on_map_4 == .no);
}

test "area rectangle" {
    const Points = struct { p1: Vec2f, p2: Vec2f };
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

test "select area"{

    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    var grid_buf = [_]bool{false}**(@as(usize,@intFromFloat(map_tiles_width))*@as(usize,@intFromFloat(map_tiles_height)));

    const wrap_increment_x = orthToIsoWrapIncrementX(tile_pix_width);
    const wrap_increment_y = orthToIsoWrapIncrementY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, wrap_increment_x, wrap_increment_y);
    const side_equations = mapSideEquations(&map_dimensions);

    var p1 = Vec2f{.x = 4,.y = 2};
    var p2 = Vec2f{.x = -3,.y = 6};

    gridSelFromRec(p1.x, p1.y, p2.x, p2.y, &grid_buf, tile_pix_width, diamond_pix_height, &side_equations, wrap_increment_x, wrap_increment_y, map_tiles_width);

    try expect(grid_buf[0]);
    try expect(grid_buf[3]);
    try expect(grid_buf[4]);

    try expect(!grid_buf[1]);
    try expect(!grid_buf[2]);
    try expect(!grid_buf[5]);

    p1 = Vec2f{.x = -3,.y = 1};
    p2 = Vec2f{.x = 4,.y = 5};

    grid_buf = [_]bool{false}**(@as(usize,@intFromFloat(map_tiles_width))*@as(usize,@intFromFloat(map_tiles_height)));
    gridSelFromRec(p1.x, p1.y, p2.x, p2.y, &grid_buf, tile_pix_width, diamond_pix_height, &side_equations, wrap_increment_x, wrap_increment_y, map_tiles_width);

    try expect(grid_buf[0]);
    try expect(grid_buf[3]);
    try expect(grid_buf[4]);

    try expect(!grid_buf[1]);
    try expect(!grid_buf[2]);
    try expect(!grid_buf[5]);

}