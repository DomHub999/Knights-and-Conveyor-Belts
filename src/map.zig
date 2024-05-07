const std = @import("std");
const Tile = @import("tile.zig").Tile;
const Ground = @import("tile.zig").Ground;
const Iso = @import("isometric/iso_core.zig").Iso;

const Error = error{
    initialize_ground_size_mismatch,
};

pub const Map = struct {

    map_position_x: i32,
    map_position_y: i32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    tile_map: []Tile,
    iso: Iso,

    map_movement_speed:i32,

    pub fn new(
        map_tiles_width: usize,
        map_tiles_height: usize,

        tile_pix_width: f32,
        diamond_pix_height: f32,

        window_pix_width: f32,
        window_pix_height: f32,

        map_movement_speed:i32,

    ) !@This() {

        const this_tile_map = try std.heap.page_allocator.alloc(Tile, map_tiles_width * map_tiles_height);
        const this_iso = Iso.new(tile_pix_width, diamond_pix_height, map_tiles_width, map_tiles_height);

        const map_start_position_x = window_pix_width / 2 - tile_pix_width / 2;
        const map_start_position_y = window_pix_height / 2 - (@as(f32, @floatFromInt(map_tiles_height)) * diamond_pix_height) / 2;
        
        const map = @This(){
            .map_position_x = @intFromFloat(map_start_position_x),
            .map_position_y = @intFromFloat(map_start_position_y),
            .map_tiles_width = map_tiles_width,
            .map_tiles_height = map_tiles_height,
            .tile_map = this_tile_map,
            .iso = this_iso,
            .map_movement_speed = map_movement_speed,
        };
        return map;
    }

    pub fn initGround(this: *@This(), ground_map: []const Ground) !void {
        if (ground_map.len != this.tile_map.len) return Error.initialize_ground_size_mismatch;

        for (this.tile_map, ground_map) |*tile, ground| {
            tile.ground = ground;
        }
    }

    pub const MovementDirection = enum{left,right,up,down};
    pub fn move(this:*@This(), direction:MovementDirection)void{

        switch (direction) {
            .left => { this.map_position_x -= this.map_movement_speed;},
            .right => { this.map_position_x += this.map_movement_speed;},
            .up => { this.map_position_y -= this.map_movement_speed;},
            .down => { this.map_position_y += this.map_movement_speed;},
        }
    }

    pub fn deinit(this: *@This()) void {
        std.heap.page_allocator.free(this.tile_map);
    }
};
