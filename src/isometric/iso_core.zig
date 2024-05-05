const orthToIsoX = @import("iso_tile.zig").mapCoordToIsoPixX;
const orthToIsoY = @import("iso_tile.zig").mapCoordToIsoPixY;
const orthToIsoWrapIncrementX = @import("iso_tile.zig").mapCoordToIsoPixIncX;
const orthToIsoWrapIncrementY = @import("iso_tile.zig").mapCoordToIsoPixIncY;
const tilePosition = @import("iso_tile.zig").tileIsoOriginPosition;
const isoToOrthX = @import("iso_tile.zig").isoPixToMapCoordX;
const isoToOrthYLean = @import("iso_tile.zig").isoPixToMapCoordYLean;

const mapDimensions = @import("iso_map.zig").mapDimensions;
const SideEquations = @import("iso_map.zig").MapSideEquations;
const mapSideEquations = @import("iso_map.zig").mapSideEquations;

pub const Point = struct { x: f32, y: f32 };

pub const Iso = struct {
    tile_pix_width: f32,
    diamond_pix_height: f32,

    wrap_increment_x: f32,
    wrap_increment_y: f32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    map_side_equations: SideEquations,

    pub fn new(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: usize, map_tiles_height: usize) @This() {
        var this: @This() = undefined;
        this.tile_pix_width = tile_pix_width;
        this.diamond_pix_height = diamond_pix_height;
        this.wrap_increment_x = orthToIsoWrapIncrementX(tile_pix_width);
        this.wrap_increment_y = orthToIsoWrapIncrementY(diamond_pix_height);
        this.map_tiles_height = map_tiles_height;
        this.map_tiles_width = map_tiles_width;

        const map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, @floatFromInt(map_tiles_width), @floatFromInt(map_tiles_height), this.wrap_increment_x, this.wrap_increment_y);
        this.map_side_equations = mapSideEquations(&map_dimensions);

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
        const orth_x = isoToOrthX(tile_position.tile_origin_iso_x, tile_position.tile_origin_iso_y, this.wrap_increment_x, this.wrap_increment_y);
        const orth_y = isoToOrthYLean(tile_position.tile_origin_iso_y, this.wrap_increment_y, orth_x);
        if (orth_x < 0 or orth_y < 0) return null;
        return .{ .orth_x = @intFromFloat(orth_x), .orth_y = @intFromFloat(orth_y) };
    }
};
