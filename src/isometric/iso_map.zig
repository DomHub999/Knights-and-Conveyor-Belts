const Vec2f = @import("iso_core.zig").Point;
const mapCoordToIsoPixX = @import("iso_tile.zig").mapCoordToIsoPixX;
const mapCoordToIsoPixY = @import("iso_tile.zig").mapCoordToIsoPixY;
const mapCoordToIsoPixIncX = @import("iso_tile.zig").mapCoordToIsoPixIncX;
const mapCoordToIsoPixIncY = @import("iso_tile.zig").mapCoordToIsoPixIncY;

const slope = @import("iso_util.zig").slope;
const yIntercept = @import("iso_util.zig").yIntercept;
const findLinearX = @import("iso_util.zig").findLinearX;
const findLinearY = @import("iso_util.zig").findLinearY;


//Given a map array and its dimensions, computes the four points defining an isometric diamond-shaped map
const MapDimensions = struct { top: Vec2f, right: Vec2f, bottom: Vec2f, left: Vec2f };
pub fn mapDimensions(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: f32, map_tiles_height: f32, map_coord_to_iso_inc_x: f32, map_coord_to_iso_inc_y: f32) MapDimensions {
    const map_array_coord_x = map_tiles_width - 1;
    const map_array_coord_y = map_tiles_height - 1;

    const top_iso_pix_x = mapCoordToIsoPixX(0, 0, map_coord_to_iso_inc_x) + tile_pix_width / 2;
    const top_iso_pix_y = mapCoordToIsoPixY(0, 0, map_coord_to_iso_inc_y);

    const right_iso_pix_x = mapCoordToIsoPixX(map_array_coord_x, 0, map_coord_to_iso_inc_x) + tile_pix_width;
    const right_iso_pix_y = mapCoordToIsoPixY(map_array_coord_x, 0, map_coord_to_iso_inc_y) + diamond_pix_height / 2;

    const bottom_iso_pix_x = mapCoordToIsoPixX(map_array_coord_x, map_array_coord_y, map_coord_to_iso_inc_x) + tile_pix_width / 2;
    const bottom_iso_pix_y = mapCoordToIsoPixY(map_array_coord_x, map_array_coord_y, map_coord_to_iso_inc_y) + diamond_pix_height;

    const left_iso_pix_x = mapCoordToIsoPixX(0, map_array_coord_y, map_coord_to_iso_inc_x);
    const left_iso_pix_y = mapCoordToIsoPixY(0, map_array_coord_y, map_coord_to_iso_inc_y) + diamond_pix_height / 2;

    return MapDimensions{
        .top = Vec2f{ .x = top_iso_pix_x, .y = top_iso_pix_y },
        .right = Vec2f{ .x = right_iso_pix_x, .y = right_iso_pix_y },
        .bottom = Vec2f{ .x = bottom_iso_pix_x, .y = bottom_iso_pix_y },
        .left = Vec2f{ .x = left_iso_pix_x, .y = left_iso_pix_y },
    };
}

const LinearEquation = struct { m: f32, b: f32 };
pub const MapSideEquations = struct {
    upper_right: LinearEquation,
    bottom_right: LinearEquation,
    bottom_left: LinearEquation,
    upper_left: LinearEquation,
};

//Converts the four points of an isometric diamond-shaped map into four linear equations that outline its boundaries
pub fn mapSideEquations(map_dimensions: *const MapDimensions) MapSideEquations {
    var map_side_equations: MapSideEquations = undefined;

    map_side_equations.upper_right.m = slope(map_dimensions.top.x, map_dimensions.top.y, map_dimensions.right.x, map_dimensions.right.y);
    map_side_equations.upper_right.b = yIntercept(map_side_equations.upper_right.m, map_dimensions.top.x, map_dimensions.top.y);

    map_side_equations.bottom_right.m = slope(map_dimensions.right.x, map_dimensions.right.y, map_dimensions.bottom.x, map_dimensions.bottom.y);
    map_side_equations.bottom_right.b = yIntercept(map_side_equations.bottom_right.m, map_dimensions.right.x, map_dimensions.right.y);

    map_side_equations.bottom_left.m = slope(map_dimensions.left.x, map_dimensions.left.y, map_dimensions.bottom.x, map_dimensions.bottom.y);
    map_side_equations.bottom_left.b = yIntercept(map_side_equations.bottom_left.m, map_dimensions.left.x, map_dimensions.left.y);

    map_side_equations.upper_left.m = slope(map_dimensions.top.x, map_dimensions.top.y, map_dimensions.left.x, map_dimensions.left.y);
    map_side_equations.upper_left.b = yIntercept(map_side_equations.upper_left.m, map_dimensions.top.x, map_dimensions.top.y);

    return map_side_equations;
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


//Calculates a map's boundaries for all four sides along the x and y axes, given a point and the linear equations for each side of the map
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


// Determines whether a given point is on a map or out of bounds. 
// If the given point is out of bounds, additional information is returned indicating on which side of the map the point lies out of bounds, 
// as well as the coordinates on the boundary if the point was moved towards the map's inbounds.
const Boundry = enum { upper_right, bottom_right, bottom_left, upper_left };
const BoundrySpot = struct { spot: Vec2f, boundry_violation: Boundry };
const PointPosition = union(enum) { on_map: void, not_on_map: BoundrySpot };
fn isPointOnMap(x: f32, y: f32, map_side_equations: *const MapSideEquations) PointPosition {
    const map_boundries = mapBoundries(x, y, map_side_equations);

    if (x > map_boundries.upper_right_x and y < map_boundries.upper_right_y) {
        return PointPosition{ .not_on_map = .{ .position = .{ .x = map_boundries.upper_right_x, .y = map_boundries.upper_right_y }, .boundry_violation = .upper_right } };
    }
    if (x > map_boundries.bottom_right_x and y > map_boundries.bottom_right_y) {
        return PointPosition{ .not_on_map = .{ .position = .{ .x = map_boundries.bottom_right_x, .y = map_boundries.bottom_right_y }, .boundry_violation = .bottom_right } };
    }
    if (x < map_boundries.bottom_left_x and y > map_boundries.bottom_left_y) {
        return PointPosition{ .not_on_map = .{ .position = .{ .x = map_boundries.bottom_left_x, .y = map_boundries.bottom_left_y }, .boundry_violation = .bottom_left } };
    }
    if (x < map_boundries.upper_left_x and y < map_boundries.upper_left_y) {
        return PointPosition{ .not_on_map = .{ .position = .{ .x = map_boundries.upper_left_x, .y = map_boundries.upper_left_y }, .boundry_violation = .upper_left } };
    }

    return PointPosition.on_map;
}

const expect = @import("std").testing.expect;

test "map dimensions" {
    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);

    try expect(map_dimensions.top.x == 4);
    try expect(map_dimensions.top.y == 0);

    try expect(map_dimensions.right.x == 16);
    try expect(map_dimensions.right.y == 6);

    try expect(map_dimensions.bottom.x == 8);
    try expect(map_dimensions.bottom.y == 10);

    try expect(map_dimensions.left.x == -4);
    try expect(map_dimensions.left.y == 4);
}

test "is point on map" {
    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);
    const map_side_equations = mapSideEquations(&map_dimensions);

    const point_on_map_1 = Vec2f{ .x = 4, .y = 0 };
    const point_on_map_2 = Vec2f{ .x = 4, .y = 7 };
    const point_on_map_3 = Vec2f{ .x = 9, .y = 7 };
    const point_on_map_4 = Vec2f{ .x = -3, .y = 4 };

    const point_not_on_map_1 = Vec2f{ .x = 5, .y = 0 };
    const point_not_on_map_2 = Vec2f{ .x = 4, .y = 9 };
    const point_not_on_map_3 = Vec2f{ .x = 16, .y = 7 };
    const point_not_on_map_4 = Vec2f{ .x = -5, .y = 4 };

    const is_on_map_1 = isPointOnMap(point_on_map_1.x, point_on_map_1.y, &map_side_equations);
    const is_on_map_2 = isPointOnMap(point_on_map_2.x, point_on_map_2.y, &map_side_equations);
    const is_on_map_3 = isPointOnMap(point_on_map_3.x, point_on_map_3.y, &map_side_equations);
    const is_on_map_4 = isPointOnMap(point_on_map_4.x, point_on_map_4.y, &map_side_equations);

    const is_not_on_map_1 = isPointOnMap(point_not_on_map_1.x, point_not_on_map_1.y, &map_side_equations);
    const is_not_on_map_2 = isPointOnMap(point_not_on_map_2.x, point_not_on_map_2.y, &map_side_equations);
    const is_not_on_map_3 = isPointOnMap(point_not_on_map_3.x, point_not_on_map_3.y, &map_side_equations);
    const is_not_on_map_4 = isPointOnMap(point_not_on_map_4.x, point_not_on_map_4.y, &map_side_equations);

    try expect(is_on_map_1 == .on_map);
    try expect(is_on_map_2 == .on_map);
    try expect(is_on_map_3 == .on_map);
    try expect(is_on_map_4 == .on_map);

    try expect(is_not_on_map_1 == .not_on_map);
    try expect(is_not_on_map_2 == .not_on_map);
    try expect(is_not_on_map_3 == .not_on_map);
    try expect(is_not_on_map_4 == .not_on_map);
}
