const std = @import("std");
const Coord = @import("iso_core.zig").Coord;
const Point = @import("iso_core.zig").Point;

//** FROM A MAP ARRAY COORDINATE TO A PIXEL IN ISOMETRIC SPACE ON THE SCREEN AND VICE VERSA

//In screen space, a tile has to be moved to the right by that many pixels in order to be in isometric space
pub fn mapCoordToIsoPixIncX(tile_pix_width: f32) f32 {
    return tile_pix_width / 2;
}
//In screen space, a tile has to be moved downwards by that many pixels in order to be in isometric space
pub fn mapCoordToIsoPixIncY(diamond_pix_height: f32) f32 {
    return diamond_pix_height / 2;
}

//From a coordinate in the map array, calculate the pixel position on the x-axis on the screen in isometric space
pub fn mapCoordToIsoPixX(map_array_coord_x: f32, map_array_coord_y: f32, map_coord_to_iso_inc_x: f32) f32 {
    return (map_array_coord_x - map_array_coord_y) * map_coord_to_iso_inc_x;
}
//From a coordinate in the map array, calculate the pixel position on the y-axis on the screen in isometric space
pub fn mapCoordToIsoPixY(map_array_coord_x: f32, map_array_coord_y: f32, map_coord_to_iso_inc_y: f32) f32 {
    return (map_array_coord_y + map_array_coord_x) * map_coord_to_iso_inc_y;
}

// Convert the pixel position on the x-axis on the screen in isometric space to a coordinate in the map array.
pub fn isoPixToMapCoordX(iso_pix_x: f32, iso_pix_y: f32, map_coord_to_iso_inc_x: f32, map_coord_to_iso_inc_y: f32) f32 {
    return (iso_pix_x / map_coord_to_iso_inc_x + iso_pix_y / map_coord_to_iso_inc_y) / 2;
}

// Convert the pixel position on the y-axis on the screen in isometric space to a coordinate in the map array.
pub fn isoPixToMapCoordY(iso_pix_x: f32, iso_pix_y: f32, map_coord_to_iso_inc_x: f32, map_coord_to_iso_inc_y: f32) f32 {
    return (iso_pix_x / map_coord_to_iso_inc_x - iso_pix_y / map_coord_to_iso_inc_y) / -2;
}
// When the coordinate in the map array has already been calculated, an abbreviated formula can be used to convert the pixel position on the y-axis on the screen in isometric space to a coordinate in the map array.
pub fn isoPixToMapCoordYLean(iso_pix_y: f32, map_coord_to_iso_inc_y: f32, map_array_coord_x: f32) f32 {
    return (iso_pix_y / map_coord_to_iso_inc_y) - map_array_coord_x;
}

// THE SUBSEQUENT FUNCTIONS EMBODY A METHODICAL APPROACH TO PRECISE ISOMETRIC TILE SELECTION,
// ACKNOWLEDGING THE INHERENT DISPARITY BETWEEN A SELECTION MADE ON THE SCREEN WITHIN ISOMETRIC SPACE AND THE ORIGIN POINT OF A TILE.

// A tile is divided into four rectangles, each comprising an edge of the isometric diamond by diagonal and horizontal division of the rectangle into two sides
// The pixel position in isometric space is later determined to precisely ascertain its location relative to these sides, aiding in the accurate determination of the selected tile
//             |
//    -------------------
//    |        *        |
//    |      * | *      |
//    |    *   |   *    |
//    |  *     |     *  |
// ―――|*―――――――――――――――*|―――
//    |  *     |     *  |
//    |    *   |   *    |
//    |      * | *      |
//    |        *        |
//    -------------------
//             |
fn tileQuartRectPixWidth(tile_pix_width: f32) f32 {
    return tile_pix_width / 2;
}
fn tileQuartRectPixHeight(diamond_pix_height: f32) f32 {
    return diamond_pix_height / 2;
}

//On a coordinate grid, number of positions to the right from the origin (not in screen pixel space)
fn tileQuartRectIsoCoordPosX(iso_pix_x: f32, tile_quart_rec_pix_width: f32) i32 {
    return @intFromFloat(@floor(iso_pix_x / tile_quart_rec_pix_width));
}
//On a coordinate grid, number of positions to the bottom from the origin (not in screen pixel space)
fn tileQuartRectIsoCoordPosY(iso_pix_y: f32, tile_quart_rec_pix_height: f32) i32 {
    return @intFromFloat(@floor(iso_pix_y / tile_quart_rec_pix_height));
}

// The position on the screen, in pixels on the x-axis, is calculated using the x-coordinate on the coordinate grid
fn tileQuartRectIsoPosX(tile_quart_rect_grid_coord_x: i32, rectangle_pix_width: f32) f32 {
    return @as(f32, @floatFromInt(tile_quart_rect_grid_coord_x)) * rectangle_pix_width;
}
// The position on the screen, in pixels on the y-axis, is calculated using the y-coordinate on the coordinate grid
fn tileQuartRectIsoPosY(tile_quart_rect_grid_coord_y: i32, rectangle_pix_height: f32) f32 {
    return @as(f32, @floatFromInt(tile_quart_rect_grid_coord_y)) * rectangle_pix_height;
}

// Calculate the diagonal direction of a diamond's edge given its tile quarter rectangles' grid position
// ----------
// |        *
// |      * | = raising
// |    *   |
// |  *     |
// |*――――――――

// ----------
// *        |
// | *      |  = falling
// |   *    |
// |     *  |
// ――――――――*|
const DiagonalDirection = enum { raising, falling };
fn diagonalDirection(tile_quart_rect_grid_coord_x: i32, tile_quart_rect_grid_coord_y: i32) DiagonalDirection {
    const rectangle_direction_denominator = tile_quart_rect_grid_coord_x + tile_quart_rect_grid_coord_y;
    const diagonal_direction = @mod(rectangle_direction_denominator, 2);

    return switch (diagonal_direction) {
        0 => .raising,
        1 => .falling,
        else => unreachable,
    };
}


//               minus
//                 |
//                 |
//                 |                   +
//                 |                + 
// minus ----------------------- plus
//                 |           +
//                 |  *P    +   
//                 |     +  
//                 |  +diagonal slope      
//                plus 
//               + |     
//            +
// 1. Adjust the target point to fit within the dimensions of the "quarter rectangle"
// 2. Calculate the slope of the diagonal (rise over run)
// 3. Compute the y-coordinate on the diagonal line using the x-coordinate of the target point
// 4. Compare the calculated y-coordinate with the y-coordinate of the target point to determine if it's higher or lower                 

const TileQuarterDivisorSide = enum { upper, lower };
fn tileQuarterRectDivisorRaising(
    iso_pix_x: f32,
    iso_pix_y: f32,
    tile_quart_rect_iso_position_x: f32,
    tile_quart_rect_iso_position_y: f32,
    rectangle_pix_width: f32,
    rectangle_pix_height: f32,
    point_on_diagonal_slope: TileQuarterDivisorSide,
) TileQuarterDivisorSide {

    const iso_pix_x_in_quart_rect = iso_pix_x - tile_quart_rect_iso_position_x;
    const iso_pix_y_in_quart_rect = iso_pix_y - tile_quart_rect_iso_position_y;

    const diagonal_slope = -(rectangle_pix_height / rectangle_pix_width);
    const diag_slope_y_intercept: f32 = rectangle_pix_height;

    const diagonal_slope_y_at_iso_pix_x_in_quart_rect = diagonal_slope * iso_pix_x_in_quart_rect + diag_slope_y_intercept;

    if (iso_pix_y_in_quart_rect > diagonal_slope_y_at_iso_pix_x_in_quart_rect) {
        return .lower;
    } else if (iso_pix_y_in_quart_rect < diagonal_slope_y_at_iso_pix_x_in_quart_rect) {
        return .upper;
    } else {
        return point_on_diagonal_slope; //if the calculated point lies on the diagonal slope, return default
    }
}

//               minus
//                 |
//                 |
//                 |
//                 |
// minus ----------------------- plus
//                 | +
//                 |   +    *P
//                 |     +
//                 |       +
//                plus       +
//                             +diagonal slope
// 1. Adjust the target point to fit within the dimensions of the "quarter rectangle"
// 2. Calculate the slope of the diagonal (rise over run)
// 3. Compute the y-coordinate on the diagonal line using the x-coordinate of the target point
// 4. Compare the calculated y-coordinate with the y-coordinate of the target point to determine if it's higher or lower

fn tileQuarterRectDivisorFalling(
    iso_pix_x: f32,
    iso_pix_y: f32,
    tile_quart_rect_iso_position_x: f32,
    tile_quart_rect_iso_position_y: f32,
    rectangle_pix_width: f32,
    rectangle_pix_height: f32,
    point_on_diagonal_slope: TileQuarterDivisorSide,
) TileQuarterDivisorSide {
    const iso_pix_x_in_quart_rect = iso_pix_x - tile_quart_rect_iso_position_x;
    const iso_pix_y_in_quart_rect = iso_pix_y - tile_quart_rect_iso_position_y;

    const diagonal_slope = (rectangle_pix_height / rectangle_pix_width);
    const diag_slope_y_intercept: f32 = 0;

    const diagonal_slope_y_at_iso_pix_x_in_quart_rect = diagonal_slope * iso_pix_x_in_quart_rect + diag_slope_y_intercept;

    if (iso_pix_y_in_quart_rect > diagonal_slope_y_at_iso_pix_x_in_quart_rect) {
        return .lower;
    } else if (iso_pix_y_in_quart_rect < diagonal_slope_y_at_iso_pix_x_in_quart_rect) {
        return .upper;
    } else {
        return point_on_diagonal_slope; //if the calculated point lies on the diagonal slope, return default
    }
}

// Given a point on the map in isometric space, calculates the tile's origin of the diamond on which the given point lies
// This may later be used to to calculate the corresponding map array coordinate
const TileOriginalIso = struct { tile_origin_iso_x: f32, tile_origin_iso_y: f32 };
pub fn tileIsoOriginPosition(
    iso_pix_x: f32,
    iso_pix_y: f32,
    tile_pix_width: f32,
    diamond_pix_height: f32,
    point_on_diagonal_slope: TileQuarterDivisorSide,
) TileOriginalIso {
    const rectangle_pix_width = tileQuartRectPixWidth(tile_pix_width);
    const rectangle_pix_height = tileQuartRectPixHeight(diamond_pix_height);

    //when you subdivide the whole grid into quarters (hence the name quart_rect) calculate the coordinate within this finer grid (twice as fine)
    const tile_quart_rect_grid_coord_x = tileQuartRectIsoCoordPosX(iso_pix_x, rectangle_pix_width);
    const tile_quart_rect_grid_coord_y = tileQuartRectIsoCoordPosY(iso_pix_y, rectangle_pix_height);

    const diagonal_direction = diagonalDirection(tile_quart_rect_grid_coord_x, tile_quart_rect_grid_coord_y);

    const tile_quart_rect_iso_position_x = tileQuartRectIsoPosX(tile_quart_rect_grid_coord_x, rectangle_pix_width);
    const tile_quart_rect_iso_position_y = tileQuartRectIsoPosY(tile_quart_rect_grid_coord_y, rectangle_pix_height);

    const tile_quarter_div_side = switch (diagonal_direction) {
        .raising => tileQuarterRectDivisorRaising(iso_pix_x, iso_pix_y, tile_quart_rect_iso_position_x, tile_quart_rect_iso_position_y, rectangle_pix_width, rectangle_pix_height, point_on_diagonal_slope),
        .falling => tileQuarterRectDivisorFalling(iso_pix_x, iso_pix_y, tile_quart_rect_iso_position_x, tile_quart_rect_iso_position_y, rectangle_pix_width, rectangle_pix_height, point_on_diagonal_slope),
    };

    if (diagonal_direction == .raising and tile_quarter_div_side == .upper) {
        return .{ .tile_origin_iso_x = tile_quart_rect_iso_position_x - rectangle_pix_width, .tile_origin_iso_y = tile_quart_rect_iso_position_y - rectangle_pix_height };
    }
    if (diagonal_direction == .raising and tile_quarter_div_side == .lower) {
        return .{ .tile_origin_iso_x = tile_quart_rect_iso_position_x, .tile_origin_iso_y = tile_quart_rect_iso_position_y };
    }
    if (diagonal_direction == .falling and tile_quarter_div_side == .upper) {
        return .{ .tile_origin_iso_x = tile_quart_rect_iso_position_x, .tile_origin_iso_y = tile_quart_rect_iso_position_y - rectangle_pix_height };
    }
    if (diagonal_direction == .falling and tile_quarter_div_side == .lower) {
        return .{ .tile_origin_iso_x = tile_quart_rect_iso_position_x - rectangle_pix_width, .tile_origin_iso_y = tile_quart_rect_iso_position_y };
    }
    unreachable;
}

const expect = @import("std").testing.expect;

test "diagonal direction" {
    try expect(diagonalDirection(0, 0) == DiagonalDirection.raising);
    try expect(diagonalDirection(2, 1) == DiagonalDirection.falling);
    try expect(diagonalDirection(2, 3) == DiagonalDirection.falling);
    try expect(diagonalDirection(1, 3) == DiagonalDirection.raising);
}

test "orth to iso and back ext" {
    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(120);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(60);

    const map_array_coord_x: f32 = 3;
    const map_array_coord_y: f32 = 2;

    const iso_pix_x = mapCoordToIsoPixX(map_array_coord_x, map_array_coord_y, map_coord_to_iso_inc_x);
    const iso_pix_y = mapCoordToIsoPixY(map_array_coord_x, map_array_coord_y, map_coord_to_iso_inc_y);

    const map_array_coord_x_calculated = isoPixToMapCoordX(iso_pix_x, iso_pix_y, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);
    const map_array_coord_y_calculated = isoPixToMapCoordY(iso_pix_x, iso_pix_y, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);

    try expect(map_array_coord_x == map_array_coord_x_calculated);
    try expect(map_array_coord_y == map_array_coord_y_calculated);
}

test "orth to iso and back lean" {
    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(120);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(60);

    const map_array_coord_x: f32 = 3;
    const map_array_coord_y: f32 = 2;

    const iso_pix_x = mapCoordToIsoPixX(map_array_coord_x, map_array_coord_y, map_coord_to_iso_inc_x);
    const iso_pix_y = mapCoordToIsoPixY(map_array_coord_x, map_array_coord_y, map_coord_to_iso_inc_y);

    const map_array_coord_x_calculated = isoPixToMapCoordX(iso_pix_x, iso_pix_y, map_coord_to_iso_inc_x, map_coord_to_iso_inc_y);
    const map_array_coord_y_calculated = isoPixToMapCoordYLean(iso_pix_y, map_coord_to_iso_inc_y, map_array_coord_x_calculated);

    try expect(map_array_coord_x == map_array_coord_x_calculated);
    try expect(map_array_coord_y == map_array_coord_y_calculated);
}

test "tile position A" {
    const tile_width: f32 = 129;
    const tile_height: f32 = 65;

    //one diamond divided vertically and horizontally, the four sides of it
    const upper_left = Point{ .x = 43, .y = 80 };
    const upper_right = Point{ .x = 107, .y = 91 };
    const bottom_right = Point{ .x = 110, .y = 103 };
    const bottom_left = Point{ .x = 74, .y = 103 };

    const tile_position_upper_left = tileIsoOriginPosition(upper_left.x, upper_left.y, tile_width, tile_height, .upper);
    const tile_position_upper_right = tileIsoOriginPosition(upper_right.x, upper_right.y, tile_width, tile_height, .upper);
    const tile_position_bottom_right = tileIsoOriginPosition(bottom_right.x, bottom_right.y, tile_width, tile_height, .upper);
    const tile_position_bottom_left = tileIsoOriginPosition(bottom_left.x, bottom_left.y, tile_width, tile_height, .upper);

    const map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_width);
    const map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(tile_height);

    //calculate the iso tile position of the map coordinate x=1 and y=1 (which is the result of the tests above)
    const iso_pix_x = mapCoordToIsoPixX(1, 1, map_coord_to_iso_inc_x);
    const iso_pix_y = mapCoordToIsoPixY(1, 1, map_coord_to_iso_inc_y);

    try expect(tile_position_upper_left.tile_origin_iso_x == iso_pix_x);
    try expect(tile_position_upper_left.tile_origin_iso_y == iso_pix_y);

    try expect(tile_position_upper_right.tile_origin_iso_x == iso_pix_x);
    try expect(tile_position_upper_right.tile_origin_iso_y == iso_pix_y);

    try expect(tile_position_bottom_left.tile_origin_iso_x == iso_pix_x);
    try expect(tile_position_bottom_left.tile_origin_iso_y == iso_pix_y);

    try expect(tile_position_bottom_right.tile_origin_iso_x == iso_pix_x);
    try expect(tile_position_bottom_right.tile_origin_iso_y == iso_pix_y);
}

test "tile position B" {
    const tile_width: f32 = 8;
    const tile_height: f32 = 4;

    const iso_point = Point{ .x = 8, .y = 6 };
    const tile_origin_point = tileIsoOriginPosition(iso_point.x, iso_point.y, tile_width, tile_height, .upper);
    try expect(tile_origin_point.tile_origin_iso_x == 8 and tile_origin_point.tile_origin_iso_y == 4);
}

test "tile position C" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = 45;
    const iso_point_y: f32 = 21;

    const exp_result_x: f32 = 32;
    const exp_result_y: f32 = 16;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 1" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = 22;
    const iso_point_y: f32 = 41;

    const exp_result_x: f32 = 0;
    const exp_result_y: f32 = 32;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 2" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = 33;
    const iso_point_y: f32 = 36;

    const exp_result_x: f32 = 16;
    const exp_result_y: f32 = 24;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 3" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = 47;
    const iso_point_y: f32 = 43;

    const exp_result_x: f32 = 32;
    const exp_result_y: f32 = 32;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 4" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = 33;
    const iso_point_y: f32 = 42;

    const exp_result_x: f32 = 16;
    const exp_result_y: f32 = 40;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 5" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = 46;
    const iso_point_y: f32 = 52;

    const exp_result_x: f32 = 32;
    const exp_result_y: f32 = 48;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 6" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = -15;
    const iso_point_y: f32 = 56;

    const exp_result_x: f32 = -32;
    const exp_result_y: f32 = 48;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 7" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = -15;
    const iso_point_y: f32 = 63;

    const exp_result_x: f32 = -32;
    const exp_result_y: f32 = 48;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 8" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = -25;
    const iso_point_y: f32 = 71;

    const exp_result_x: f32 = -32;
    const exp_result_y: f32 = 64;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 9" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = -25;
    const iso_point_y: f32 = 75;

    const exp_result_x: f32 = -32;
    const exp_result_y: f32 = 64;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}

test "tile position 10" {
    const tile_width: f32 = 32;
    const tile_height: f32 = 16;

    const iso_point_x: f32 = -25;
    const iso_point_y: f32 = 76;

    const exp_result_x: f32 = -48;
    const exp_result_y: f32 = 72;

    const tile_origin_point = tileIsoOriginPosition(iso_point_x, iso_point_y, tile_width, tile_height, .upper);

    try expect(tile_origin_point.tile_origin_iso_x == exp_result_x and tile_origin_point.tile_origin_iso_y == exp_result_y);
}
// printResult(tile_origin_point.tile_origin_iso_x, tile_origin_point.tile_origin_iso_y, exp_result_x, exp_result_y);
fn printResult(x: f32, y: f32, ex: f32, ey: f32) void {
    _ = ex;
    _ = ey;
    std.debug.print("x: {d} / y: {d}\n", .{ x, y });
}
