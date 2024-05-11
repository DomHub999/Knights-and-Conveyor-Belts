const Coord = struct { map_array_coord_x: usize, map_array_coord_y: usize };

pub const StepSize = enum(usize) {
    ONE = 1,
};

pub fn walkMapCoordNorth(map_array_coord_x: usize, map_array_coord_y: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_x, @intFromEnum(step_size)) or
        isOutOfBoundsMapHead(map_array_coord_y, @intFromEnum(step_size)))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x - @intFromEnum(step_size), .map_array_coord_y = map_array_coord_y - @intFromEnum(step_size) };
}
pub fn walkMapCoordNorthEast(map_array_coord_x: usize, map_array_coord_y: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_y, @intFromEnum(step_size))) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y - @intFromEnum(step_size) };
}
pub fn walkMapCoordEast(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsWidth(map_array_coord_x, @intFromEnum(step_size), map_tile_width) or
        isOutOfBoundsMapHead(map_array_coord_y, @intFromEnum(step_size)))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x + @intFromEnum(step_size), .map_array_coord_y = map_array_coord_y - @intFromEnum(step_size) };
}
pub fn walkMapCoordSouthEast(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsWidth(map_array_coord_x, @intFromEnum(step_size), map_tile_width)) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x + @intFromEnum(step_size), .map_array_coord_y = map_array_coord_y };
}
pub fn walkMapCoordSouth(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, map_tile_height: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsWidth(map_array_coord_x, @intFromEnum(step_size), map_tile_width) or
        isOutOfBoundsHeight(map_array_coord_y, @intFromEnum(step_size), map_tile_height))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x + @intFromEnum(step_size), .map_array_coord_y = map_array_coord_y + @intFromEnum(step_size) };
}
pub fn walkMapCoordSouthWest(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_height: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsHeight(map_array_coord_y, @intFromEnum(step_size), map_tile_height)) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y + @intFromEnum(step_size) };
}
pub fn walkMapCoordWest(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_height: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_x, @intFromEnum(step_size)) or
        isOutOfBoundsHeight(map_array_coord_y, @intFromEnum(step_size), map_tile_height))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x - @intFromEnum(step_size), .map_array_coord_y = map_array_coord_y + @intFromEnum(step_size) };
}
pub fn walkMapCoordNorthWest(map_array_coord_x: usize, map_array_coord_y: usize, step_size: StepSize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_x, @intFromEnum(step_size))) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x - @intFromEnum(step_size), .map_array_coord_y = map_array_coord_y };
}

pub fn walkMapCoordFurthestNorth(map_array_coord_x: usize, map_array_coord_y: usize) Coord {
    var coord = Coord{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y };
    while (walkMapCoordNorth(coord.map_array_coord_x, coord.map_array_coord_y, StepSize.ONE)) |new_coord| {
        coord = new_coord;
    }
    return coord;
}
pub fn walkMapCoordFurthestEast(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize) Coord {
    var coord = Coord{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y };
    while (walkMapCoordEast(coord.map_array_coord_x, coord.map_array_coord_y, map_tile_width, StepSize.ONE)) |new_coord| {
        coord = new_coord;
    }
    return coord;
}
pub fn walkMapCoordFurthestSouth(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, map_tile_height: usize) Coord {
    var coord = Coord{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y };
    while (walkMapCoordSouth(coord.map_array_coord_x, coord.map_array_coord_y, map_tile_width, map_tile_height, StepSize.ONE)) |new_coord| {
        coord = new_coord;
    }
    return coord;
}
pub fn walkMapCoordFurthestWest(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_height: usize) Coord {
    var coord = Coord{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y };
    while (walkMapCoordWest(coord.map_array_coord_x, coord.map_array_coord_y, map_tile_height, StepSize.ONE)) |new_coord| {
        coord = new_coord;
    }
    return coord;
}

fn isOutOfBoundsMapHead(map_array_coord: usize, step_size: usize) bool {
    return step_size > map_array_coord;
}
fn isOutOfBoundsWidth(map_array_coord_x: usize, step_size: usize, map_tile_width: usize) bool {
    return map_array_coord_x + step_size >= map_tile_width;
}
fn isOutOfBoundsHeight(map_array_coord_y: usize, step_size: usize, map_tile_height: usize) bool {
    return map_array_coord_y + step_size >= map_tile_height;
}

const expect = @import("std").testing.expect;
const TEST_COORD = Coord{ .map_array_coord_x = 3, .map_array_coord_y = 2 };
const TEST_MAP_TILE_WIDTH: usize = 5;
const TEST_MAP_TILE_HEIGHT: usize = 5;
test "walkMapCoordNorth" {
    const result = walkMapCoordNorth(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 2, .map_array_coord_y = 1};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);

}
test "walkMapCoordNorthEast" {
    const result = walkMapCoordNorthEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 3, .map_array_coord_y = 1};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordEast" {
    const result = walkMapCoordEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 4, .map_array_coord_y = 1};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordSouthEast" {
    const result = walkMapCoordSouthEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 4, .map_array_coord_y = 2};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordSouth" {
    const result = walkMapCoordSouth(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, TEST_MAP_TILE_HEIGHT, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 4, .map_array_coord_y = 3};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordSouthWest" {
    const result = walkMapCoordSouthWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_HEIGHT, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 3, .map_array_coord_y = 3};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordWest" {
    const result = walkMapCoordWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_HEIGHT, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 2, .map_array_coord_y = 3};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordNorthWest" {
    const result = walkMapCoordNorthWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, StepSize.ONE).?;
    const expected_result = Coord{.map_array_coord_x = 2, .map_array_coord_y = 2};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}


test "walkMapCoordFurthestNorth" {
    const result = walkMapCoordFurthestNorth(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y);
    const expected_result = Coord{.map_array_coord_x = 1, .map_array_coord_y = 0};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordFurthestEast" {
    const result = walkMapCoordFurthestEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH);
    const expected_result = Coord{.map_array_coord_x = 4, .map_array_coord_y = 1};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordFurthestSouth" {
    const result = walkMapCoordFurthestSouth(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, TEST_MAP_TILE_HEIGHT);
    const expected_result = Coord{.map_array_coord_x = 4, .map_array_coord_y = 3};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordFurthestWest" {
    const result = walkMapCoordFurthestWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_HEIGHT);
    const expected_result = Coord{.map_array_coord_x = 1, .map_array_coord_y = 4};
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
