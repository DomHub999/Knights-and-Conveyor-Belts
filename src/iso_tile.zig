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

//Given a tile quarter's rectangle, which is divided diagonally by a diamond's edge, determines on which side of the diagonal divider (tile quarter divisor) a point lies

//before moving the point of origin of the coordinate system to the right upper corner of the quader (now the upper left corner ist the origin of the coordinate system)
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

//after moving the point of origin of the coordinate system to the right upper corner of the quader
//               minus
//                 |
//                 |
//                 |
//                 |
// minus ----------------------- plus
//               + |
//         *P  +   |
//           +     |
//         +       |
//       +        plus
//     +diagonal slope

const TileQuarterDivisorSide = enum { upper, lower };
fn tileQuarterRectDivisorRaising(
    iso_pix_x: f32,
    iso_pix_y: f32,
    tile_quart_rect_iso_position_x: f32,
    tile_quart_rect_iso_position_y: f32,
    rectangle_pix_width: f32,
    rectangle_pix_height: f32,
    point_on_origin_default: TileQuarterDivisorSide,
) TileQuarterDivisorSide {
    var x = iso_pix_x - tile_quart_rect_iso_position_x;
    const y = iso_pix_y - tile_quart_rect_iso_position_y;

    x -= rectangle_pix_width; // move point of origin of the coordinate system to the right upper corner of the quader

    if (x == 0) {
        return point_on_origin_default; //In the improbable scenario where a point's x-coordinate lies on the opposing side of the tile quarter rectangle's origin
    } 

    const iso_slope = y / x;
    const diagonal_slope = rectangle_pix_height / -rectangle_pix_width;

    if (iso_slope >= diagonal_slope) {
        return .upper;
    } else { //iso_slope < diagonal_slope
        return .lower;
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

fn tileQuarterRectDivisorFalling(
    iso_pix_x: f32,
    iso_pix_y: f32,
    tile_quart_rect_iso_position_x: f32,
    tile_quart_rect_iso_position_y: f32,
    rectangle_pix_width: f32,
    rectangle_pix_height: f32,
    point_on_origin_default: TileQuarterDivisorSide,
) TileQuarterDivisorSide {
    const x = iso_pix_x - tile_quart_rect_iso_position_x;
    const y = iso_pix_y - tile_quart_rect_iso_position_y;

    if (x == 0) {
        return point_on_origin_default; //In the improbable scenario where a point's y-coordinate lies on the tile quarter rectangle's origin
    } 

    const iso_slope = y / x;
    const diagonal_slope = rectangle_pix_height / rectangle_pix_width;

    if (iso_slope <= diagonal_slope) {
        return .upper;
    } else { //iso_slope > diagonal_slope
        return .lower;
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
    point_on_origin_default: TileQuarterDivisorSide,
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
        .raising => tileQuarterRectDivisorRaising(iso_pix_x, iso_pix_y, tile_quart_rect_iso_position_x, tile_quart_rect_iso_position_y, rectangle_pix_width, rectangle_pix_height, point_on_origin_default),
        .falling => tileQuarterRectDivisorFalling(iso_pix_x, iso_pix_y, tile_quart_rect_iso_position_x, tile_quart_rect_iso_position_y, rectangle_pix_width, rectangle_pix_height, point_on_origin_default),
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

test "tile position 1" {
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

test "tile position 2" {
    const tile_width: f32 = 8;
    const tile_height: f32 = 4;

    const iso_point = Point{ .x = 8, .y = 6 };
    const tile_origin_point = tileIsoOriginPosition(iso_point.x, iso_point.y, tile_width, tile_height, .upper);
    try expect(tile_origin_point.tile_origin_iso_x == 8 and tile_origin_point.tile_origin_iso_y == 4);
}
