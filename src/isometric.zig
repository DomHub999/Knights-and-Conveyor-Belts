fn orthToIsoWrapIncrementX(tile_width: f32) f32 {
    return tile_width / 2;
}

fn orthToIsoWrapIncrementY(tile_height: f32) f32 {
    return tile_height / 2;
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

fn rectangleSizeX(tile_width: f32) f32 {
    return tile_width / 2;
}

fn rectangleSizeY(tile_height: f32) f32 {
    return tile_height / 2;
}

fn rectangleGridPositionX(iso_x: f32, rectangle_size_x: f32) i32 {
    return @intFromFloat(@floor(iso_x / rectangle_size_x));
}

fn rectangleGridPositionY(iso_y: f32, rectangle_size_y: f32) i32 {
    return @intFromFloat(@floor(iso_y / rectangle_size_y));
}

fn rectanglePositionX(rectangle_grid_position_x:i32, rectangle_size_x:f32)f32{
    const f_rectangle_grid_position_x:f32 = @floatFromInt(rectangle_grid_position_x);
    return f_rectangle_grid_position_x * rectangle_size_x;
}

fn rectanglePositionY(rectangle_grid_position_y:i32, rectangle_size_y:f32)f32{
    const f_rectangle_grid_position_y:f32 = @floatFromInt(rectangle_grid_position_y);
    return f_rectangle_grid_position_y * rectangle_size_y;
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
fn rectangleSideRaising(iso_x: f32, iso_y: f32, rectangle_position_x: f32, rectangle_position_y: f32, rectangle_size_x: f32, rectangle_size_y: f32) ?RectangleSide {
    const x = iso_x - (rectangle_position_x + rectangle_size_x);
    const y = iso_y - rectangle_position_y;

    const iso_slope = y / x;
    const diagonal_slope = rectangle_size_y / -rectangle_size_x;

    if (iso_slope >= diagonal_slope) {
        return .upper;
    } else if (iso_slope < diagonal_slope) {
        return .lower;
    }

    return null;
}
fn rectangleSideFalling(iso_x: f32, iso_y: f32, rectangle_position_x: f32, rectangle_position_y: f32, rectangle_size_x: f32, rectangle_size_y: f32) ?RectangleSide {
    const x = iso_x - rectangle_position_x;
    const y = iso_y - rectangle_position_y;

    const iso_slope = y / x;
    const diagonal_slope = rectangle_size_y / rectangle_size_x;

    if (iso_slope <= diagonal_slope) {
        return .upper;
    } else if (iso_slope > diagonal_slope) {
        return .lower;
    }

    return null;
}

fn tilePosition(iso_x: f32, iso_y: f32, tile_width: f32, tile_height: f32) ?struct { tile_x: f32, tile_y: f32 } {
    const rectangle_size_x = rectangleSizeX(tile_width);
    const rectangle_size_y = rectangleSizeY(tile_height);
    const rectangle_grid_position_x = rectangleGridPositionX(iso_x, rectangle_size_x);
    const rectangle_grid_position_y = rectangleGridPositionY(iso_y, rectangle_size_y);
    const diagonal_direction = diagonalDirection(rectangle_grid_position_x, rectangle_grid_position_y).?;

    const rectangle_position_x = rectanglePositionX(rectangle_grid_position_x, rectangle_size_x);
    const rectangle_position_y = rectanglePositionX(rectangle_grid_position_y, rectangle_size_y);
    
    const rectangle_side = switch (diagonal_direction) {
        .raising => rectangleSideRaising(iso_x, iso_y, rectangle_position_x, rectangle_position_y, rectangle_size_x, rectangle_size_y).?,
        .falling => rectangleSideFalling(iso_x, iso_y, rectangle_position_x, rectangle_position_y, rectangle_size_x, rectangle_size_y).?,
    };

    if (diagonal_direction == .raising and rectangle_side == .upper) {return .{.tile_x = rectangle_position_x - rectangle_size_x, .tile_y = rectangle_position_y - rectangle_size_y};}
    if (diagonal_direction == .raising and rectangle_side == .lower) {return .{.tile_x = rectangle_position_x , .tile_y = rectangle_position_y };}
    if (diagonal_direction == .falling and rectangle_side == .upper) {return .{.tile_x = rectangle_position_x, .tile_y = rectangle_position_y - rectangle_size_y};}
    if (diagonal_direction == .falling and rectangle_side == .lower) {return .{.tile_x = rectangle_position_x - rectangle_size_x, .tile_y = rectangle_position_y};}
    return null;
}

pub const Iso = struct {
    tile_width:f32,
    tile_height:f32,
    wrap_increment_x: f32,
    wrap_increment_y: f32,

    pub fn new(tile_width: f32, tile_height: f32) @This() {
        var this: @This() = undefined;
        this.tile_width = tile_width;
        this.tile_height = tile_height;
        this.wrap_increment_x = orthToIsoWrapIncrementX(tile_width);
        this.wrap_increment_y = orthToIsoWrapIncrementY(tile_height);
        return this;
    }

    pub fn ortToIsoX(this: *const @This(), orth_x: usize, orth_y: usize) f32 {
        const f_orth_x: f32 = @floatFromInt(orth_x);
        const f_orth_y: f32 = @floatFromInt(orth_y);
        return orthToIsoX(f_orth_x, f_orth_y, this.wrap_increment_x);
    }

    pub fn ortToIsoY(this: *const @This(), orth_x: usize, orth_y: usize) f32 {
        const f_orth_x: f32 = @floatFromInt(orth_x);
        const f_orth_y: f32 = @floatFromInt(orth_y);
        return orthToIsoY(f_orth_x, f_orth_y, this.wrap_increment_y);
    }

    pub fn isoToOrtX(this: *const @This(), iso_x: i32, iso_y: i32) ?usize {
        const tile_position = tilePosition(@floatFromInt(iso_x), @floatFromInt(iso_y), this.tile_width, this.tile_height).?;
        const orth_x = isoToOrthX(tile_position.tile_x, tile_position.tile_y, this.wrap_increment_x, this.wrap_increment_y);
        if (orth_x < 0) return null;
        return @intFromFloat(orth_x);
    }

    pub fn isoToOrtY(this: *const @This(), iso_x: i32, iso_y: i32) ?usize {
        const tile_position = tilePosition(@floatFromInt(iso_x), @floatFromInt(iso_y), this.tile_width, this.tile_height).?;
        const orth_y = isoToOrthY(tile_position.tile_x, tile_position.tile_y, this.wrap_increment_x, this.wrap_increment_y);
        if (orth_y < 0) return null;
        return @intFromFloat(orth_y);
    }
};

const expect = @import("std").testing.expect;
test "diagonal_direction" {
    try expect(diagonalDirection(0, 0).? == DiagonalDirection.raising);
    try expect(diagonalDirection(2, 1).? == DiagonalDirection.falling);
    try expect(diagonalDirection(2, 3).? == DiagonalDirection.falling);
    try expect(diagonalDirection(1, 3).? == DiagonalDirection.raising);
}

test "iso"{
    const iso = Iso.new(16*2, 8*2);
    const ort_first_tile_upper_left_x = iso.isoToOrtX(14, 7).?;
    const ort_first_tile_upper_left_y = iso.isoToOrtY(14, 7).?;
    printEmptyLine();
    print(ort_first_tile_upper_left_x);
    print(ort_first_tile_upper_left_y);
}

fn printEmptyLine()void{
    @import("std").debug.print("{c}\n", .{' '});
}
fn print(n:usize)void{
    @import("std").debug.print("{d}\n", .{n});
}