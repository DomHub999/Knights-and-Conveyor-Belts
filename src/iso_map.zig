const Point = @import("iso_core.zig").Point;
const mapCoordToIsoPixX = @import("iso_tile.zig").mapCoordToIsoPixX;
const mapCoordToIsoPixY = @import("iso_tile.zig").mapCoordToIsoPixY;
const mapCoordToIsoPixIncX = @import("iso_tile.zig").mapCoordToIsoPixIncX;
const mapCoordToIsoPixIncY = @import("iso_tile.zig").mapCoordToIsoPixIncY;

const slope = @import("iso_util.zig").slope;
const yIntercept = @import("iso_util.zig").yIntercept;
const findLinearX = @import("iso_util.zig").findLinearX;
const findLinearY = @import("iso_util.zig").findLinearY;
const lineIntercept = @import("iso_util.zig").lineIntercept;
const LinearEquation = @import("iso_util.zig").LinearEquation;

//Given a map array and its dimensions, computes the four points defining an isometric diamond-shaped map
pub const MapDimensions = struct { top: Point, right: Point, bottom: Point, left: Point };
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
        .top = Point{ .x = top_iso_pix_x, .y = top_iso_pix_y },
        .right = Point{ .x = right_iso_pix_x, .y = right_iso_pix_y },
        .bottom = Point{ .x = bottom_iso_pix_x, .y = bottom_iso_pix_y },
        .left = Point{ .x = left_iso_pix_x, .y = left_iso_pix_y },
    };
}

pub const MapSideEquations = struct {
    upper_right: LinearEquation,
    bottom_right: LinearEquation,
    bottom_left: LinearEquation,
    upper_left: LinearEquation,
};

//Converts the four points of an isometric diamond-shaped map into four linear equations that outline its boundaries
pub fn mapSideEquations(map_dimensions: *const MapDimensions) MapSideEquations {
    var map_side_equations: MapSideEquations = .{
        .upper_right = .{ .has_slope = undefined },
        .bottom_right = .{ .has_slope = undefined },
        .bottom_left = .{ .has_slope = undefined },
        .upper_left = .{ .has_slope = undefined },
    };

    map_side_equations.upper_right.has_slope.m = slope(map_dimensions.top.x, map_dimensions.top.y, map_dimensions.right.x, map_dimensions.right.y);
    map_side_equations.upper_right.has_slope.b = yIntercept(map_side_equations.upper_right.has_slope.m, map_dimensions.top.x, map_dimensions.top.y);
    map_side_equations.bottom_right.has_slope.m = slope(map_dimensions.right.x, map_dimensions.right.y, map_dimensions.bottom.x, map_dimensions.bottom.y);
    map_side_equations.bottom_right.has_slope.b = yIntercept(map_side_equations.bottom_right.has_slope.m, map_dimensions.right.x, map_dimensions.right.y);
    map_side_equations.bottom_left.has_slope.m = slope(map_dimensions.left.x, map_dimensions.left.y, map_dimensions.bottom.x, map_dimensions.bottom.y);
    map_side_equations.bottom_left.has_slope.b = yIntercept(map_side_equations.bottom_left.has_slope.m, map_dimensions.left.x, map_dimensions.left.y);
    map_side_equations.upper_left.has_slope.m = slope(map_dimensions.top.x, map_dimensions.top.y, map_dimensions.left.x, map_dimensions.left.y);
    map_side_equations.upper_left.has_slope.b = yIntercept(map_side_equations.upper_left.has_slope.m, map_dimensions.top.x, map_dimensions.top.y);

    return map_side_equations;
}

const MapBoundaries = struct {
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
//in other words: the point where a point and the boundaries of a map would meet if the point was moved towards the map either ont he x or the y axis
//ilustration: meeting points only depicted if the Point(X) was moved on the x axis (bl = bottom left, ul = upper left, ur = upper right, br = bottom right)
//                    *
//                  *   *
// X     o(bl)    o(ul)   o(ur)  o(br)
//              *           *
//            *               *
//              *           *
//                *       *
//                  *   *
//                    *
fn mapBoundaries(x: f32, y: f32, map_side_equations: *const MapSideEquations) MapBoundaries {
    var map_boundaries: MapBoundaries = undefined;
    const mse = map_side_equations;

    map_boundaries.upper_right_x = findLinearX(mse.upper_right.has_slope.m, y, mse.upper_right.has_slope.b);
    map_boundaries.upper_right_y = findLinearY(mse.upper_right.has_slope.m, x, mse.upper_right.has_slope.b);

    map_boundaries.bottom_right_x = findLinearX(mse.bottom_right.has_slope.m, y, mse.bottom_right.has_slope.b);
    map_boundaries.bottom_right_y = findLinearY(mse.bottom_right.has_slope.m, x, mse.bottom_right.has_slope.b);

    map_boundaries.bottom_left_x = findLinearX(mse.bottom_left.has_slope.m, y, mse.bottom_left.has_slope.b);
    map_boundaries.bottom_left_y = findLinearY(mse.bottom_left.has_slope.m, x, mse.bottom_left.has_slope.b);

    map_boundaries.upper_left_x = findLinearX(mse.upper_left.has_slope.m, y, mse.upper_left.has_slope.b);
    map_boundaries.upper_left_y = findLinearY(mse.upper_left.has_slope.m, x, mse.upper_left.has_slope.b);

    return map_boundaries;
}

// Determines whether a given point is on a map or out of bounds.
pub fn isPointOnMap(x: f32, y: f32, map_side_equations: *const MapSideEquations) bool {
    const map_boundaries = mapBoundaries(x, y, map_side_equations);

    const outside_upper_right_boundry = x > map_boundaries.upper_right_x and y < map_boundaries.upper_right_y;
    const outside_bottom_right_boundry = x > map_boundaries.bottom_right_x and y > map_boundaries.bottom_right_y;
    const outside_bottom_left_boundry = x < map_boundaries.bottom_left_x and y > map_boundaries.bottom_left_y;
    const outside_upper_left_boundry = x < map_boundaries.upper_left_x and y < map_boundaries.upper_left_y;

    return !outside_upper_right_boundry and !outside_bottom_right_boundry and !outside_bottom_left_boundry and !outside_upper_left_boundry;
}

pub const Mapside = enum {
    upper_right,
    bottom_right,
    bottom_left,
    upper_left,
};

//Does not necessarily work for points outside of the map because the map may not be symmetrical, potentially introducing blind spots
pub fn pointOutsideMapSide(x:f32, y:f32, map_side_equations: *const MapSideEquations) Mapside {
    const map_right_point = lineIntercept(&map_side_equations.upper_right, &map_side_equations.bottom_right).?;
    const map_bottom_point = lineIntercept(&map_side_equations.bottom_right, &map_side_equations.bottom_left).?;
    const map_left_point = lineIntercept(&map_side_equations.bottom_left, &map_side_equations.upper_left).?;
    const map_top_point = lineIntercept(&map_side_equations.upper_left, &map_side_equations.upper_right).?;

    if (x >= map_top_point.x and y < map_right_point.y) return .upper_right;
    if (x >= map_bottom_point.x and y >= map_right_point.y) return .bottom_right;
    if (x < map_bottom_point.x and y >= map_left_point.y) return .bottom_left;
    if (x < map_top_point.x and y < map_left_point.y) return .upper_left;

    unreachable; 
}

const Intercept = union(enum) {
    no: void,
    yes: Point,
};

pub const MapSideIntercepts = struct {
    upper_right: Intercept,
    bottom_right: Intercept,
    bottom_left: Intercept,
    upper_left: Intercept,
};

// A line to be tested should be moved (line_start and line_end) according to the map movement
//TODO:make proper line object, with an equation and start and end
pub fn doesLineInterceptMapBoundries(map_side_equations: *const MapSideEquations, map_dimensions: *const MapDimensions, line: *const LinearEquation, line_start: *const Point, line_end: *const Point) MapSideIntercepts {
    var map_side_intercepts: MapSideIntercepts = .{ .upper_right = .no, .bottom_right = .no, .bottom_left = .no, .upper_left = .no };

    map_side_intercepts.upper_right = determineIntercept(line, &map_side_equations.upper_right, line_start, line_end, &map_dimensions.top, &map_dimensions.right);
    map_side_intercepts.bottom_right = determineIntercept(line, &map_side_equations.bottom_right, line_start, line_end, &map_dimensions.right, &map_dimensions.bottom);
    map_side_intercepts.bottom_left = determineIntercept(line, &map_side_equations.bottom_left, line_start, line_end, &map_dimensions.left, &map_dimensions.bottom);
    map_side_intercepts.upper_left = determineIntercept(line, &map_side_equations.upper_left, line_start, line_end, &map_dimensions.top, &map_dimensions.left);

    return map_side_intercepts;
}

fn determineIntercept(line: *const LinearEquation, map_side_equation: *const LinearEquation, line_start: *const Point, line_end: *const Point, map_boundary_start: *const Point, map_boundary_end: *const Point) Intercept {
    var intercept: Intercept = .no;
    const intercept_point = lineIntercept(line, map_side_equation);
    if (intercept_point) |point| {
        const intercept_within_tested_line = isPointWithinLine(&point, line_start, line_end);
        const intercept_within_map_side = isPointWithinLine(&point, map_boundary_start, map_boundary_end);
        if (intercept_within_tested_line and intercept_within_map_side) {
            intercept = .{ .yes = point };
        }
    }
    return intercept;
}

//TODO:error handling if the tested line is upside down
fn isPointWithinLine(point: *const Point, line_start: *const Point, line_end: *const Point) bool {
    if (point.y < line_start.y or point.y > line_end.y) return false;
    return if (line_start.x > line_end.x) (point.x <= line_start.x and point.x >= line_end.x) else (point.x >= line_start.x and point.x <= line_end.x);
}

const expect = @import("std").testing.expect;

test "test map dimensions" {
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

//TODO: make test which checks for the spot_x_boundry_intersect and spot_y_boundry_intersect
test "test is point on map" {
    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);
    const map_side_equations = mapSideEquations(&map_dimensions);

    const point_on_map_1 = Point{ .x = 4, .y = 0 };
    const point_on_map_2 = Point{ .x = 4, .y = 7 };
    const point_on_map_3 = Point{ .x = 9, .y = 7 };
    const point_on_map_4 = Point{ .x = -3, .y = 4 };

    const point_not_on_map_1 = Point{ .x = 5, .y = 0 };
    const point_not_on_map_2 = Point{ .x = 4, .y = 9 };
    const point_not_on_map_3 = Point{ .x = 16, .y = 7 };
    const point_not_on_map_4 = Point{ .x = -5, .y = 4 };

    const is_on_map_1 = isPointOnMap(point_on_map_1.x, point_on_map_1.y, &map_side_equations);
    const is_on_map_2 = isPointOnMap(point_on_map_2.x, point_on_map_2.y, &map_side_equations);
    const is_on_map_3 = isPointOnMap(point_on_map_3.x, point_on_map_3.y, &map_side_equations);
    const is_on_map_4 = isPointOnMap(point_on_map_4.x, point_on_map_4.y, &map_side_equations);

    const is_not_on_map_1 = isPointOnMap(point_not_on_map_1.x, point_not_on_map_1.y, &map_side_equations);
    const is_not_on_map_2 = isPointOnMap(point_not_on_map_2.x, point_not_on_map_2.y, &map_side_equations);
    const is_not_on_map_3 = isPointOnMap(point_not_on_map_3.x, point_not_on_map_3.y, &map_side_equations);
    const is_not_on_map_4 = isPointOnMap(point_not_on_map_4.x, point_not_on_map_4.y, &map_side_equations);

    try expect(is_on_map_1);
    try expect(is_on_map_2);
    try expect(is_on_map_3);
    try expect(is_on_map_4);

    try expect(!is_not_on_map_1);
    try expect(!is_not_on_map_2);
    try expect(!is_not_on_map_3);
    try expect(!is_not_on_map_4);
}

test "test line intercept boundary" {
    const tile_pix_width: f32 = 8;
    const diamond_pix_height: f32 = 4;
    const map_tiles_width: f32 = 3;
    const map_tiles_height: f32 = 2;

    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);
    const map_side_equations = mapSideEquations(&map_dimensions);

    var line = LinearEquation{ .has_slope = .{ .m = 0, .b = 2 } };
    var line_start = Point{ .x = -4, .y = 2 };
    var line_end = Point{ .x = 12, .y = 2 };
    var result = doesLineInterceptMapBoundries(&map_side_equations, &map_dimensions, &line, &line_start, &line_end);
    try expect(result.upper_right.yes.x == 8 and result.upper_right.yes.y == 2);
    try expect(result.bottom_right == .no);
    try expect(result.bottom_left == .no);
    try expect(result.upper_left.yes.x == 0 and result.upper_left.yes.y == 2);

    line = LinearEquation{ .has_slope = .{ .m = 0, .b = 9 } };
    line_start = Point{ .x = 1, .y = 9 };
    line_end = Point{ .x = 8, .y = 9 };
    result = doesLineInterceptMapBoundries(&map_side_equations, &map_dimensions, &line, &line_start, &line_end);
    try expect(result.upper_right == .no);
    try expect(result.bottom_right == .no);
    try expect(result.bottom_left.yes.x == 6 and result.bottom_left.yes.y == 9);
    try expect(result.upper_left == .no);

    //TODO: use this test to test iso_core: it should be possible to translate the iso Point
    //coming from an intercept to a map array Coordinate
    const isometric_math_utility = @import("iso_core.zig").IsometricMathUtility.new(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height);
    const point_to_coord = isometric_math_utility.isoToMapCoord(Point{ .x = result.bottom_left.yes.x, .y = result.bottom_left.yes.y }, 0, 0).?;
    _ = point_to_coord;

    line = LinearEquation{ .has_slope = .{ .m = 0, .b = 9 } };
    line_start = Point{ .x = 1, .y = 9 };
    line_end = Point{ .x = 16, .y = 9 };
    result = doesLineInterceptMapBoundries(&map_side_equations, &map_dimensions, &line, &line_start, &line_end);
    try expect(result.upper_right == .no);
    try expect(result.bottom_right.yes.x == 10 and result.bottom_left.yes.y == 9);
    try expect(result.bottom_left.yes.x == 6 and result.bottom_left.yes.y == 9);
    try expect(result.upper_left == .no);

    line = LinearEquation{ .has_slope = .{ .m = 0, .b = 9 } };
    line_start = Point{ .x = 1, .y = 9 };
    line_end = Point{ .x = 16, .y = 9 };
    result = doesLineInterceptMapBoundries(&map_side_equations, &map_dimensions, &line, &line_start, &line_end);
    try expect(result.upper_right == .no);
    try expect(result.bottom_right.yes.x == 10 and result.bottom_left.yes.y == 9);
    try expect(result.bottom_left.yes.x == 6 and result.bottom_left.yes.y == 9);
    try expect(result.upper_left == .no);

    line = LinearEquation{ .vertical = .{ .a = 12 } };
    line_start = Point{ .x = 12, .y = 0 };
    line_end = Point{ .x = 12, .y = 14 };
    result = doesLineInterceptMapBoundries(&map_side_equations, &map_dimensions, &line, &line_start, &line_end);
    try expect(result.upper_right.yes.x == 12 and result.upper_right.yes.y == 4);
    try expect(result.bottom_right.yes.x == 12 and result.bottom_right.yes.y == 8);
    try expect(result.bottom_left == .no);
    try expect(result.upper_left == .no);

    line = LinearEquation{ .vertical = .{ .a = 20 } };
    line_start = Point{ .x = 20, .y = 0 };
    line_end = Point{ .x = 20, .y = 14 };
    result = doesLineInterceptMapBoundries(&map_side_equations, &map_dimensions, &line, &line_start, &line_end);
    try expect(result.upper_right == .no);
    try expect(result.bottom_right == .no);
    try expect(result.bottom_left == .no);
    try expect(result.upper_left == .no);
}

test "test pointOutsideMapSide"{
    const tile_pix_width: f32 = 32;
    const diamond_pix_height: f32 = 16;
    const map_tiles_width: f32 = 7;
    const map_tiles_height: f32 = 8;

    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

    const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);
    const map_side_equations = mapSideEquations(&map_dimensions);


    const upper_right = pointOutsideMapSide(128, 50, &map_side_equations);
    const bottom_right = pointOutsideMapSide(49, 106, &map_side_equations);
    const bottom_left = pointOutsideMapSide(-38, 129, &map_side_equations);
    const upper_left = pointOutsideMapSide(-105, 2, &map_side_equations);

    try expect(upper_right == Mapside.upper_right );
    try expect(bottom_right == Mapside.bottom_right);
    try expect(bottom_left == Mapside.bottom_left);
    try expect(upper_left == Mapside.upper_left);

}
