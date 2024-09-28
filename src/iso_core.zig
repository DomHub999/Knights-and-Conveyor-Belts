const mapCoordToIsoPixX = @import("iso_tile.zig").mapCoordToIsoPixX;
const mapCoordToIsoPixY = @import("iso_tile.zig").mapCoordToIsoPixY;
const mapCoordToIsoPixIncX = @import("iso_tile.zig").mapCoordToIsoPixIncX;
const mapCoordToIsoPixIncY = @import("iso_tile.zig").mapCoordToIsoPixIncY;
const tileIsoOriginPosition = @import("iso_tile.zig").tileIsoOriginPosition;
const isoPixToMapCoordX = @import("iso_tile.zig").isoPixToMapCoordX;
const isoPixToMapCoordYLean = @import("iso_tile.zig").isoPixToMapCoordYLean;

const mapDimensions = @import("iso_map.zig").mapDimensions;
const MapSideEquations = @import("iso_map.zig").MapSideEquations;
const mapSideEquations = @import("iso_map.zig").mapSideEquations;
const MapDimensions = @import("iso_map.zig").MapDimensions;
const PointPosition = @import("iso_map.zig").PointPosition;
const isPointOnMap = @import("iso_map.zig").isPointOnMap;
const MapSideIntercepts = @import("iso_map.zig").MapSideIntercepts;
const doesLineInterceptMapBoundries = @import("iso_map.zig").doesLineInterceptMapBoundries;
const pointOutsideMapSide = @import("iso_map.zig").pointOutsideMapSide;
const Mapside = @import("iso_map.zig").Mapside;

const LinearEquation = @import("iso_util.zig").LinearEquation;

const walkMapCoordNorth = @import("iso_tile_walk.zig").walkMapCoordNorth;
const walkMapCoordNorthEast = @import("iso_tile_walk.zig").walkMapCoordNorthEast;
const walkMapCoordEast = @import("iso_tile_walk.zig").walkMapCoordEast;
const walkMapCoordSouthEast = @import("iso_tile_walk.zig").walkMapCoordSouthEast;
const walkMapCoordSouth = @import("iso_tile_walk.zig").walkMapCoordSouth;
const walkMapCoordSouthWest = @import("iso_tile_walk.zig").walkMapCoordSouthWest;
const walkMapCoordWest = @import("iso_tile_walk.zig").walkMapCoordWest;
const walkMapCoordNorthWest = @import("iso_tile_walk.zig").walkMapCoordNorthWest;

const walkMapCoordFurthestNorth = @import("iso_tile_walk.zig").walkMapCoordFurthestNorth;
const walkMapCoordFurthestNorthEast = @import("iso_tile_walk.zig").walkMapCoordFurthestNorthEast;
const walkMapCoordFurthestEast = @import("iso_tile_walk.zig").walkMapCoordFurthestEast;
const walkMapCoordFurthestSouthEast = @import("iso_tile_walk.zig").walkMapCoordFurthestSouthEast;
const walkMapCoordFurthestSouth = @import("iso_tile_walk.zig").walkMapCoordFurthestSouth;
const walkFurthestSouthWest = @import("iso_tile_walk.zig").walkFurthestSouthWest;
const walkMapCoordFurthestWest = @import("iso_tile_walk.zig").walkMapCoordFurthestWest;
const walkMapCoordFurthestNorthWest = @import("iso_tile_walk.zig").walkMapCoordFurthestNorthWest;

//TODO:rename Coord to MapArrayCoord and its internals to x and y
//TODO:rename Point to IsoPoint
pub const Coord = struct {
    map_array_coord_x: usize,
    map_array_coord_y: usize,

    pub fn isEqual(this: *const @This(), comp: *Coord) bool {
        return (this.map_array_coord_x == comp.map_array_coord_x and this.map_array_coord_y == comp.map_array_coord_y);
    }

    pub fn hasEqualX(this: *const @This(), comp: *Coord) bool {
        return this.map_array_coord_x == comp.map_array_coord_x;
    }

    pub fn hasEqualY(this: *const @This(), comp: *Coord) bool {
        return this.map_array_coord_y == comp.map_array_coord_y;
    }

    pub fn hasGreaterX(this: *const @This(), comp: *Coord) bool {
        return this.map_array_coord_x > comp.map_array_coord_x;
    }

    pub fn hasGreaterY(this: *const @This(), comp: *Coord) bool {
        return this.map_array_coord_y > comp.map_array_coord_y;
    }
};
pub const Point = struct { x: f32, y: f32 };

pub const IsometricMathUtility = struct {
    tile_pix_width: f32,
    //diamond because a tile may be a cuboid
    diamond_pix_height: f32,

    map_coord_to_iso_inc_x: f32,
    map_coord_to_iso_inc_y: f32,

    map_tiles_width: usize,
    map_tiles_height: usize,

    map_dimensions: MapDimensions,
    map_side_equations: MapSideEquations,

    const SINGLE_STEP: usize = 1;

    pub fn new(tile_pix_width: f32, diamond_pix_height: f32, map_tiles_width: usize, map_tiles_height: usize) @This() {
        var this: @This() = undefined;

        this.tile_pix_width = tile_pix_width;
        this.diamond_pix_height = diamond_pix_height;

        this.map_coord_to_iso_inc_x = mapCoordToIsoPixIncX(tile_pix_width);
        this.map_coord_to_iso_inc_y = mapCoordToIsoPixIncY(diamond_pix_height);

        this.map_tiles_height = map_tiles_height;
        this.map_tiles_width = map_tiles_width;

        this.map_dimensions = mapDimensions(tile_pix_width, diamond_pix_height, @floatFromInt(map_tiles_width), @floatFromInt(map_tiles_height), this.map_coord_to_iso_inc_x, this.map_coord_to_iso_inc_y);
        this.map_side_equations = mapSideEquations(&this.map_dimensions);

        return this;
    }
    //TODO:rename to mapCoordToIsoPointOrigin, new return value = Point
    pub fn mapCoordToIso(this: *const @This(), map_array_coord: Coord, map_pos_x: i32, map_pos_y: i32) struct { iso_pix_x: f32, iso_pix_y: f32 } {
        const iso_pix_x = mapCoordToIsoPixX(@as(f32, @floatFromInt(map_array_coord.map_array_coord_x)), @as(f32, @floatFromInt(map_array_coord.map_array_coord_y)), this.map_coord_to_iso_inc_x);
        const iso_pix_y = mapCoordToIsoPixY(@as(f32, @floatFromInt(map_array_coord.map_array_coord_x)), @as(f32, @floatFromInt(map_array_coord.map_array_coord_y)), this.map_coord_to_iso_inc_y);

        const iso_pix_map_pos_adj = this.adjustTileOriginPointInIsoToMapMovement(.{ .x = iso_pix_x, .y = iso_pix_y }, map_pos_x, map_pos_y);

        return .{ .iso_pix_x = iso_pix_map_pos_adj.x, .iso_pix_y = iso_pix_map_pos_adj.y };
    }

    //TODO:rename to isoPointToMapCoord, instead of returning null, return an error -> a map array coord cannot possibly be negative
    //HINT: The maps tile point of origin is to be moved into its initial position (without any "map movement") in order to be able to calculate its map coordinate
    pub fn isoToMapCoord(this: *const @This(), iso_pix: Point, map_pos_x: i32, map_pos_y: i32) ?Coord {
        const iso_pix_map_pos_adj = this.adjustWindowIsoPointToMapPosition(iso_pix, map_pos_x, map_pos_y);

        var tile_position = tileIsoOriginPosition(iso_pix_map_pos_adj.x, iso_pix_map_pos_adj.y, this.tile_pix_width, this.diamond_pix_height, .upper);
        var map_array_coord_x = isoPixToMapCoordX(tile_position.tile_origin_iso_x, tile_position.tile_origin_iso_y, this.map_coord_to_iso_inc_x, this.map_coord_to_iso_inc_y);
        var map_array_coord_y = isoPixToMapCoordYLean(tile_position.tile_origin_iso_y, this.map_coord_to_iso_inc_y, map_array_coord_x);

        if (map_array_coord_x < 0 or map_array_coord_y < 0) {
            //in case that a point lies in a position where it cannot be detormined if the point belongs to the upper of lower tile
            tile_position = tileIsoOriginPosition(iso_pix_map_pos_adj.x, iso_pix_map_pos_adj.y, this.tile_pix_width, this.diamond_pix_height, .lower);
            map_array_coord_x = isoPixToMapCoordX(tile_position.tile_origin_iso_x, tile_position.tile_origin_iso_y, this.map_coord_to_iso_inc_x, this.map_coord_to_iso_inc_y);
            map_array_coord_y = isoPixToMapCoordYLean(tile_position.tile_origin_iso_y, this.map_coord_to_iso_inc_y, map_array_coord_x);
        }

        if (map_array_coord_x < 0 or map_array_coord_y < 0) return null; //TODO:make this function return an error instead of null
        return .{ .map_array_coord_x = @intFromFloat(map_array_coord_x), .map_array_coord_y = @intFromFloat(map_array_coord_y) };
    }

    pub fn isIsoPointOnMap(this: *const @This(), iso_pix: Point, map_pos_x: i32, map_pos_y: i32) bool {
        const iso_pix_map_pos_adj = this.adjustWindowIsoPointToMapPosition(iso_pix, map_pos_x, map_pos_y);

        return isPointOnMap(iso_pix_map_pos_adj.x, iso_pix_map_pos_adj.y, &this.map_side_equations);
    }

    pub fn doesLineInterceptMap(this: *const @This(), line: *const LinearEquation, line_start: *const Point, line_end: *const Point, map_pos_x: i32, map_pos_y: i32) MapSideIntercepts {
        const line_start_map_pos_adj = this.adjustWindowIsoPointToMapPosition(line_start.*, map_pos_x, map_pos_y);
        const line_end_map_pos_adj = this.adjustWindowIsoPointToMapPosition(line_end.*, map_pos_x, map_pos_y);

        const line_pos_adj: LinearEquation = switch (line.*) {
            .has_slope => .{ .has_slope = .{ .m = line.has_slope.m, .b = this.adjustWindowIsoPointToMapPositionY(line.has_slope.b, map_pos_y) } },
            .vertical => .{ .vertical = .{.a = this.adjustWindowIsoPointToMapPositionX(line.vertical.a, map_pos_x) } },
        };

        return doesLineInterceptMapBoundries(&this.map_side_equations, &this.map_dimensions, &line_pos_adj, &line_start_map_pos_adj, &line_end_map_pos_adj);
    }

    pub fn getPointOutsideMapSide(this: *const @This(), iso_pix:Point, map_pos_x:i32, map_pos_y:i32) Mapside {
        const iso_pix_map_pos_adj = this.adjustWindowIsoPointToMapPosition(iso_pix, map_pos_x, map_pos_y);

        return pointOutsideMapSide(iso_pix_map_pos_adj.x, iso_pix_map_pos_adj.y, &this.map_side_equations);
    }

    //TODO: take a pointer for point
    pub fn adjustWindowIsoPointToMapPosition(this: *const @This(), point: Point, map_pos_x: i32, map_pos_y: i32) Point {
        // return .{ .x = point.x + @as(f32, @floatFromInt(map_pos_x)), .y = point.y + @as(f32, @floatFromInt(map_pos_y)) };
        return .{ .x = this.adjustWindowIsoPointToMapPositionX(point.x, map_pos_x), .y = this.adjustWindowIsoPointToMapPositionY(point.y, map_pos_y) };
    }

    pub fn adjustWindowIsoPointToMapPositionX(this: *const @This(), x: f32, map_pos_x: i32) f32 {
        _ = this;
        return x + @as(f32, @floatFromInt(map_pos_x));
    }

    pub fn adjustWindowIsoPointToMapPositionY(this: *const @This(), y: f32, map_pos_y: i32) f32 {
        _ = this;
        return y + @as(f32, @floatFromInt(map_pos_y));
    }

    pub fn adjustTileOriginPointInIsoToMapMovement(this: *const @This(), point: Point, map_pos_x: i32, map_pos_y: i32) Point {
        _ = this;
        return .{ .x = point.x - @as(f32, @floatFromInt(map_pos_x)), .y = point.y - @as(f32, @floatFromInt(map_pos_y)) };
    }

    pub fn walkMapCoordNorthSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        _ = this;
        return walkMapCoordNorth(coord.map_array_coord_x, coord.map_array_coord_y, SINGLE_STEP);
    }
    fn walkMapCoordNorthEastSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        _ = this;
        return walkMapCoordNorthEast(coord.map_array_coord_x, coord.map_array_coord_y, SINGLE_STEP);
    }
    pub fn walkMapCoordEastSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        return walkMapCoordEast(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_width, SINGLE_STEP);
    }
    pub fn walkMapCoordSouthEastSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        return walkMapCoordSouthEast(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_width, SINGLE_STEP);
    }
    pub fn walkMapCoordSouthSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        return walkMapCoordSouth(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_width, this.map_tiles_height, SINGLE_STEP);
    }
    pub fn walkMapCoordSouthWestSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        return walkMapCoordSouthWest(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_height, SINGLE_STEP);
    }
    pub fn walkMapCoordWestSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        return walkMapCoordWest(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_height, SINGLE_STEP);
    }
    pub fn walkMapCoordNorthWestSingleMove(this: *const @This(), coord: *const Coord) ?Coord {
        _ = this;
        return walkMapCoordNorthWest(coord.map_array_coord_x, coord.map_array_coord_y, SINGLE_STEP);
    }

    pub fn walkMapCoordFullNorth(this: *const @This(), coord: *const Coord) Coord {
        _ = this;
        return walkMapCoordFurthestNorth(coord.map_array_coord_x, coord.map_array_coord_y);
    }
    pub fn walkMapCoordFullNorthEast(this: *const @This(), coord: *const Coord) Coord {
        _ = this;
        return walkMapCoordFurthestNorthEast(coord.map_array_coord_x);
    }
    pub fn walkMapCoordFullEast(this: *const @This(), coord: *const Coord) Coord {
        return walkMapCoordFurthestEast(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_width);
    }
    pub fn walkMapCoordFullSouthEast(this: *const @This(), coord: *const Coord) Coord {
        return walkMapCoordFurthestSouthEast(coord.map_array_coord_y, this.map_tiles_width);
    }
    pub fn walkMapCoordFullSouth(this: *const @This(), coord: *const Coord) Coord {
        return walkMapCoordFurthestSouth(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_width, this.map_tiles_height);
    }
    pub fn walkFullCoordSouthWest(this: *const @This(), coord: *const Coord) Coord {
        return walkFurthestSouthWest(coord.map_array_coord_x, this.map_tiles_height);
    }
    pub fn walkMapCoordFullWest(this: *const @This(), coord: *const Coord) Coord {
        return walkMapCoordFurthestWest(coord.map_array_coord_x, coord.map_array_coord_y, this.map_tiles_height);
    }
    pub fn walkMapCoordFullNorthWest(this: *const @This(), coord: *const Coord) Coord {
        _ = this;
        return walkMapCoordFurthestNorthWest( coord.map_array_coord_y);
    }
};
