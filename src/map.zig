const std = @import("std");
const Tile = @import("tile.zig").Tile;
const Ground = @import("tile.zig").Ground;
const IsometricMathUtility = @import("iso_core.zig").IsometricMathUtility;
const TileIterator = @import("tile_iterator.zig").TileIterator;

const Error = error{
    initialize_ground_size_mismatch,
};

//TODO:check if the types make sense
pub const Map = struct {
    map_position_x: i32,
    map_position_y: i32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    tile_map: []Tile,
    isometric_math_utility:IsometricMathUtility,

    map_movement_speed: i32,

    tile_iterator:TileIterator,

    pub fn new(
        map_tiles_width: usize,
        map_tiles_height: usize,
        tile_pix_width: f32,
        diamond_pix_height: f32,
        window_pix_width: i32,
        window_pix_height: i32,
        map_movement_speed: i32,
        
    ) !@This() {
        const this_tile_map = try std.heap.page_allocator.alloc(Tile, map_tiles_width * map_tiles_height);
        const this_isometric_math_utility = IsometricMathUtility.new(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height);

        // const window_pix_center_x = @divFloor(window_pix_width, 2);
        // const window_pix_center_y = @divFloor(window_pix_height, 2);

        // const map_start_position_x: i32 = window_pix_center_x - @divFloor(@as(i32, @intFromFloat(tile_pix_width)), 2);
        // const map_start_position_y: i32 = window_pix_center_y - @divFloor(@as(i32, @intCast(map_tiles_height)) * @as(i32, @intFromFloat(diamond_pix_height)), 2);

        const map_start_position_x: i32 = 0;
        const map_start_position_y: i32 = 0;

        const this_tile_iterator = TileIterator.new(window_pix_width, window_pix_height, this_isometric_math_utility, 0);

        return .{
            .map_position_x = map_start_position_x,
            .map_position_y = map_start_position_y,
            .map_tiles_width = map_tiles_width,
            .map_tiles_height = map_tiles_height,
            .tile_map = this_tile_map,
            .isometric_math_utility = this_isometric_math_utility,
            .map_movement_speed = map_movement_speed,
            .tile_iterator = this_tile_iterator,
        };
    }

    pub fn initGround(this: *@This(), ground_map: []const Ground) !void {
        if (ground_map.len != this.tile_map.len) return Error.initialize_ground_size_mismatch;

        for (this.tile_map, ground_map) |*tile, ground| {
            tile.ground = ground;
        }
    }

    //TODO:remove debug
    var movement_break:usize = 0;
    const MOVEMENT_MAX:usize = 0;

    pub const MovementDirection = enum { left, right, up, down };
    pub fn move(this: *@This(), direction: MovementDirection) void {

        if(movement_break <= MOVEMENT_MAX){
            movement_break += 1;
            return;
        }
        movement_break = 0;

        switch (direction) {
            .left => {
                this.map_position_x += this.map_movement_speed;
            },
            .right => {
                this.map_position_x -= this.map_movement_speed;
            },
            .up => {
                this.map_position_y += this.map_movement_speed;
            },
            .down => {
                this.map_position_y -= this.map_movement_speed;
            },
        }


    }

    pub fn deinit(this: *@This()) void {
        std.heap.page_allocator.free(this.tile_map);
    }
};


