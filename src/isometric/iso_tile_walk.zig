const Coord = @import("iso_core.zig").Coord;

pub fn walkMapCoordNorth(map_array_coord_x: usize, map_array_coord_y: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_x, step_size) or
        isOutOfBoundsMapHead(map_array_coord_y, step_size))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x - step_size, .map_array_coord_y = map_array_coord_y - step_size };
}
pub fn walkMapCoordNorthEast(map_array_coord_x: usize, map_array_coord_y: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_y, step_size)) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y - step_size };
}
pub fn walkMapCoordEast(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsWidth(map_array_coord_x, step_size, map_tile_width) or
        isOutOfBoundsMapHead(map_array_coord_y, step_size))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x + step_size, .map_array_coord_y = map_array_coord_y - step_size };
}
pub fn walkMapCoordSouthEast(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsWidth(map_array_coord_x, step_size, map_tile_width)) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x + step_size, .map_array_coord_y = map_array_coord_y };
}
pub fn walkMapCoordSouth(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, map_tile_height: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsWidth(map_array_coord_x, step_size, map_tile_width) or
        isOutOfBoundsHeight(map_array_coord_y, step_size, map_tile_height))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x + step_size, .map_array_coord_y = map_array_coord_y + step_size };
}
pub fn walkMapCoordSouthWest(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_height: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsHeight(map_array_coord_y, step_size, map_tile_height)) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x, .map_array_coord_y = map_array_coord_y + step_size };
}
pub fn walkMapCoordWest(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_height: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_x, step_size) or
        isOutOfBoundsHeight(map_array_coord_y, step_size, map_tile_height))
    {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x - step_size, .map_array_coord_y = map_array_coord_y + step_size };
}
pub fn walkMapCoordNorthWest(map_array_coord_x: usize, map_array_coord_y: usize, step_size: usize) ?Coord {
    if (isOutOfBoundsMapHead(map_array_coord_x, step_size)) {
        return null;
    }
    return .{ .map_array_coord_x = map_array_coord_x - step_size, .map_array_coord_y = map_array_coord_y };
}


pub fn walkMapCoordFurthestNorth(map_array_coord_x: usize, map_array_coord_y: usize) Coord {

    if (map_array_coord_x >= map_array_coord_y) {
        return .{.map_array_coord_x = map_array_coord_x - map_array_coord_y, .map_array_coord_y = 0};
    } else {
        return .{.map_array_coord_x = 0, .map_array_coord_y = map_array_coord_y - map_array_coord_x};
    }
}
pub fn walkMapCoordFurthestEast(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize) Coord {

    const max_array_coord_x = map_tile_width - 1;
    
    if (map_array_coord_x + map_array_coord_y <= max_array_coord_x) {
        return .{.map_array_coord_x = map_array_coord_x + map_array_coord_y, .map_array_coord_y = 0};
    } else {
        return .{.map_array_coord_x = max_array_coord_x, .map_array_coord_y = map_array_coord_y - (max_array_coord_x - map_array_coord_x)};
    }

}
pub fn walkMapCoordFurthestSouth(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_width: usize, map_tile_height: usize) Coord {

    const max_array_coord_x = map_tile_width - 1;
    const max_array_coord_y = map_tile_height - 1;

    if (map_array_coord_x >= map_array_coord_y) {
        return .{.map_array_coord_x = max_array_coord_x, .map_array_coord_y = map_array_coord_y + (max_array_coord_x - map_array_coord_x)};
    } else {
        return .{.map_array_coord_x = map_array_coord_x + (max_array_coord_y - map_array_coord_y), .map_array_coord_y = max_array_coord_y};
    }

}
pub fn walkMapCoordFurthestWest(map_array_coord_x: usize, map_array_coord_y: usize, map_tile_height: usize) Coord {
    
    const max_array_coord_y = map_tile_height - 1;

    if (map_array_coord_x + map_array_coord_y <= max_array_coord_y) {
        return .{.map_array_coord_x = 0, .map_array_coord_y = map_array_coord_y + map_array_coord_x};
    }else{
        return .{.map_array_coord_x = map_array_coord_x - (max_array_coord_y - map_array_coord_y ), .map_array_coord_y = max_array_coord_y};
    }

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
    const result = walkMapCoordNorth(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 2, .map_array_coord_y = 1 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordNorthEast" {
    const result = walkMapCoordNorthEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 3, .map_array_coord_y = 1 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordEast" {
    const result = walkMapCoordEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 4, .map_array_coord_y = 1 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordSouthEast" {
    const result = walkMapCoordSouthEast(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 4, .map_array_coord_y = 2 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordSouth" {
    const result = walkMapCoordSouth(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_WIDTH, TEST_MAP_TILE_HEIGHT, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 4, .map_array_coord_y = 3 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordSouthWest" {
    const result = walkMapCoordSouthWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_HEIGHT, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 3, .map_array_coord_y = 3 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordWest" {
    const result = walkMapCoordWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, TEST_MAP_TILE_HEIGHT, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 2, .map_array_coord_y = 3 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordNorthWest" {
    const result = walkMapCoordNorthWest(TEST_COORD.map_array_coord_x, TEST_COORD.map_array_coord_y, 1).?;
    const expected_result = Coord{ .map_array_coord_x = 2, .map_array_coord_y = 2 };
    try expect(result.map_array_coord_x == expected_result.map_array_coord_x and result.map_array_coord_y == expected_result.map_array_coord_y);
}


const TEST_FURTHEST_MAP_TILE_WIDTH: usize = 6;
const TEST_FURTHEST_MAP_TILE_HEIGHT: usize = 5;
test "walkMapCoordFurthestNorth" {
    var test_set = Coord{.map_array_coord_x = 1, .map_array_coord_y = 3};
    var expected_result = Coord{.map_array_coord_x = 0, .map_array_coord_y = 2};
    var actual_result = walkMapCoordFurthestNorth(test_set.map_array_coord_x, test_set.map_array_coord_y);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);
    
    test_set = Coord{.map_array_coord_x = 5, .map_array_coord_y = 2};
    expected_result = Coord{.map_array_coord_x = 3, .map_array_coord_y = 0};
    actual_result = walkMapCoordFurthestNorth(test_set.map_array_coord_x, test_set.map_array_coord_y);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordFurthestEast" {
    var test_set = Coord{.map_array_coord_x = 1, .map_array_coord_y = 1};
    var expected_result = Coord{.map_array_coord_x = 2, .map_array_coord_y = 0};
    var actual_result = walkMapCoordFurthestEast(test_set.map_array_coord_x, test_set.map_array_coord_y, TEST_FURTHEST_MAP_TILE_WIDTH);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);
    
    test_set = Coord{.map_array_coord_x = 3, .map_array_coord_y = 3};
    expected_result = Coord{.map_array_coord_x = 5, .map_array_coord_y = 1};
    actual_result = walkMapCoordFurthestEast(test_set.map_array_coord_x, test_set.map_array_coord_y, TEST_FURTHEST_MAP_TILE_WIDTH);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordFurthestSouth" {
    var test_set = Coord{.map_array_coord_x = 0, .map_array_coord_y = 2};
    var expected_result = Coord{.map_array_coord_x = 2, .map_array_coord_y = 4};
    var actual_result = walkMapCoordFurthestSouth(test_set.map_array_coord_x, test_set.map_array_coord_y, TEST_FURTHEST_MAP_TILE_WIDTH, TEST_FURTHEST_MAP_TILE_HEIGHT);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);

    test_set = Coord{.map_array_coord_x = 2, .map_array_coord_y = 0};
    expected_result = Coord{.map_array_coord_x = 5, .map_array_coord_y = 3};
    actual_result = walkMapCoordFurthestSouth(test_set.map_array_coord_x, test_set.map_array_coord_y, TEST_FURTHEST_MAP_TILE_WIDTH, TEST_FURTHEST_MAP_TILE_HEIGHT);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);
}
test "walkMapCoordFurthestWest" {
    var test_set = Coord{.map_array_coord_x = 1, .map_array_coord_y = 1};
    var expected_result = Coord{.map_array_coord_x = 0, .map_array_coord_y = 2};
    var actual_result = walkMapCoordFurthestWest(test_set.map_array_coord_x, test_set.map_array_coord_y, TEST_FURTHEST_MAP_TILE_HEIGHT);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);

    test_set = Coord{.map_array_coord_x = 3, .map_array_coord_y = 2};
    expected_result = Coord{.map_array_coord_x = 1, .map_array_coord_y = 4};
    actual_result = walkMapCoordFurthestWest(test_set.map_array_coord_x, test_set.map_array_coord_y, TEST_FURTHEST_MAP_TILE_HEIGHT);
    try expect(actual_result.map_array_coord_x == expected_result.map_array_coord_x and actual_result.map_array_coord_y == expected_result.map_array_coord_y);
}
