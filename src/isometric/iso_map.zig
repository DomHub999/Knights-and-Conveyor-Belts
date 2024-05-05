const Vec2f = @import("iso_core.zig").Point;
const orthToIsoX = @import("iso_tile.zig").mapCoordToIsoPixX;
const orthToIsoY = @import("iso_tile.zig").mapCoordToIsoPixY;
const orthToIsoWrapIncrementX = @import("iso_tile.zig").mapCoordToIsoPixIncX;
const orthToIsoWrapIncrementY = @import("iso_tile.zig").mapCoordToIsoPixIncY;



const MapDimensions = struct { top: Vec2f, right: Vec2f, bottom: Vec2f, left: Vec2f };
pub fn mapDimensions(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: f32, map_tiles_height: f32, wrap_increment_x: f32, wrap_increment_y: f32) MapDimensions {
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
pub const MapSideEquations = struct {
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


pub fn mapSideEquations(map_dimensions: *const MapDimensions) MapSideEquations {
    var side_equations: MapSideEquations = undefined;

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
fn mapBoundries(x: f32, y: f32, map_side_equations: *const MapSideEquations) MapBoundries {
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
fn isPointOnMap(x: f32, y: f32, map_side_equations: *const MapSideEquations) IsOnMap {
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

const expect = @import("std").testing.expect;

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
