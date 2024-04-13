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

const Vec2 = struct { x: f32, y: f32 };
const MapDimensions = struct { top: Vec2, right: Vec2, bottom: Vec2, left: Vec2 };
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
        .top = Vec2{ .x = top_x, .y = top_y },
        .right = Vec2{ .x = right_x, .y = right_y },
        .bottom = Vec2{ .x = bottom_x, .y = bottom_y },
        .left = Vec2{ .x = left_x, .y = left_y },
    };
}

pub const Iso = struct {
    tile_pix_width: f32,
    tile_pix_height: f32,
    diamond_pix_height: f32,

    wrap_increment_x: f32,
    wrap_increment_y: f32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    map_dimensions: MapDimensions,

    pub fn new(
        tile_pix_width: f32,
        tile_pix_height: f32,
        diamond_pix_height: f32,
        map_tiles_width: usize,
        map_tiles_height: usize,
    ) @This() {
        var this: @This() = undefined;
        this.tile_pix_width = tile_pix_width;
        this.tile_pix_height = tile_pix_height;
        this.diamond_pix_height = diamond_pix_height;
        this.wrap_increment_x = orthToIsoWrapIncrementX(tile_pix_width);
        this.wrap_increment_y = orthToIsoWrapIncrementY(diamond_pix_height);
        this.map_tiles_height = map_tiles_height;
        this.map_tiles_width = map_tiles_width;
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

    // pub fn isoSquareToGrid(x1:i32, y1:i32, x2:i32, y2:i32, grid_buf:[]bool)void{

    // }
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

test "map dimensions"{
    const tile_pix_width:f32 = 8;
    const diamond_pix_height:f32 = 4;
    const map_tiles_width:f32 = 3;
    const map_tiles_height:f32 = 2;

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
