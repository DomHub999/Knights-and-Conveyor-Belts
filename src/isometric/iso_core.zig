const mapCoordToIsoPixX = @import("iso_tile.zig").mapCoordToIsoPixX;
const mapCoordToIsoPixY = @import("iso_tile.zig").mapCoordToIsoPixY;
const mapCoordToIsoPixIncX = @import("iso_tile.zig").mapCoordToIsoPixIncX;
const mapCoordToIsoPixIncY = @import("iso_tile.zig").mapCoordToIsoPixIncY;
const tilePosition = @import("iso_tile.zig").tileIsoOriginPosition;
const tileIsoOriginPosition = @import("iso_tile.zig").isoPixToMapCoordX;
const isoPixToMapCoordYLean = @import("iso_tile.zig").isoPixToMapCoordYLean;

const mapDimensions = @import("iso_map.zig").mapDimensions;
const MapSideEquations = @import("iso_map.zig").MapSideEquations;
const mapSideEquations = @import("iso_map.zig").mapSideEquations;


pub const Coord = struct { map_array_coord_x: usize, map_array_coord_y: usize };
pub const Point = struct { x: f32, y: f32 };

pub const Iso = struct {
    tile_pix_width: f32,
    diamond_pix_height: f32,

    map_coord_to_iso_inc_x: f32,
    map_coord_to_iso_inc_y: f32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    map_side_equations: MapSideEquations,

    pub fn new(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: usize, map_tiles_height: usize) @This() {
        var this: @This() = undefined;

        this.tile_pix_width = tile_pix_width;
        this.diamond_pix_height = diamond_pix_height;

        this.map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
        this.map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

        this.map_tiles_height = map_tiles_height;
        this.map_tiles_width = map_tiles_width;

        const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, @floatFromInt(map_tiles_width), @floatFromInt(map_tiles_height), this.map_coord_to_iso_inc_x, this.map_coord_to_iso_inc_y);
        this.map_side_equations = mapSideEquations(&map_dimensions);

        return this;
    }

    pub fn mapCoordToIso(this: *const @This(), map_array_coord_x: usize, map_array_coord_y: usize, map_pos_x: i32, map_pos_y: i32) struct { iso_pix_x: f32, iso_pix_y: f32 } {

        const iso_pix_x = mapCoordToIsoPixX(@as(f32,@floatFromInt(map_array_coord_x)), @as(f32,@floatFromInt(map_array_coord_y)), this.map_coord_to_iso_inc_x);
        const iso_pix_y = mapCoordToIsoPixY(@as(f32,@floatFromInt(map_array_coord_x)), @as(f32,@floatFromInt(map_array_coord_y)), this.map_coord_to_iso_inc_y);

        return .{ .iso_pix_x = iso_pix_x + @as(f32, @floatFromInt(map_pos_x)), .iso_pix_y = iso_pix_y + @as(f32, @floatFromInt(map_pos_y)) };
    }

    pub fn isoToMapCoord(this: *const @This(), iso_pix_x: i32, iso_pix_y: i32, map_pos_x: i32, map_pos_y: i32) ?struct { map_array_coord_x: usize, map_array_coord_y: usize } {
        const iso_pix_x_map_pos_adj: f32 = @as(f32, @floatFromInt(iso_pix_x)) - @as(f32, @floatFromInt(map_pos_x));
        const iso_pix_y_map_pos_adj: f32 = @as(f32, @floatFromInt(iso_pix_y)) - @as(f32, @floatFromInt(map_pos_y));

        const tile_position = tilePosition(iso_pix_x_map_pos_adj, iso_pix_y_map_pos_adj, this.tile_pix_width, this.diamond_pix_height).?;
        const map_array_coord_x = tileIsoOriginPosition(tile_position.tile_origin_iso_x, tile_position.tile_origin_iso_y, this.map_coord_to_iso_inc_x, this.map_coord_to_iso_inc_y);
        const map_array_coord_y = isoPixToMapCoordYLean(tile_position.tile_origin_iso_y, this.map_coord_to_iso_inc_y, map_array_coord_x);
        if (map_array_coord_x < 0 or map_array_coord_y < 0) return null;
        return .{ .map_array_coord_x = @intFromFloat(map_array_coord_x), .map_array_coord_y = @intFromFloat(map_array_coord_y) };
    }
};
