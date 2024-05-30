const std = @import("std");

const Coord = @import("iso_core.zig").Coord;
const Point = @import("iso_core.zig").Point;

const walkMapCoordNorth = @import("iso_tile_walk.zig").walkMapCoordNorth;
const walkMapCoordEast = @import("iso_tile_walk.zig").walkMapCoordEast;
const walkMapCoordSouth = @import("iso_tile_walk.zig").walkMapCoordSouth;
const walkMapCoordWest = @import("iso_tile_walk.zig").walkMapCoordWest;
const walkMapCoordFurthestNorth = @import("iso_tile_walk.zig").walkMapCoordFurthestNorth;
const walkMapCoordFurthestEast = @import("iso_tile_walk.zig").walkMapCoordFurthestEast;
const walkMapCoordFurthestSouth = @import("iso_tile_walk.zig").walkMapCoordFurthestSouth;
const walkMapCoordFurthestWest = @import("iso_tile_walk.zig").walkMapCoordFurthestWest;

const PointPosition = @import("iso_map.zig").PointPosition;

const IsometricMathUtility = @import("iso_core.zig").IsometricMathUtility;

pub const TileIterator = struct {
    margin: usize, //additional tiles to be considered out of bounds
    map_coord_upper_left: Coord = undefined,
    map_coord_upper_right: Coord = undefined,
    map_coord_bottom_right: Coord = undefined,
    map_coord_bottom_left: Coord = undefined,

    isometric_math_utility: IsometricMathUtility,
    window_pix_width: i32,
    window_pix_height: i32,

    window_upper_left: Point,
    window_upper_right: Point,
    window_bottom_right: Point,
    window_bottom_left: Point,

    case_handler:CaseHandler = undefined,

    pub fn new(
        window_pix_width: i32,
        window_pix_height: i32,
        isometric_math_utility: IsometricMathUtility,
        margin: usize,
    ) @This() {
        const this_window_upper_left: Point = .{ .x = 0, .y = 0 };
        const this_window_upper_right: Point = .{ .x = @floatFromInt(window_pix_width), .y = 0 };
        const this_window_bottom_right: Point = .{ .x = @floatFromInt(window_pix_width), .y = @floatFromInt(window_pix_height) };
        const this_window_bottom_left: Point = .{ .x = 0, .y = @floatFromInt(window_pix_height) };

        return .{
            .margin = margin,
            .window_pix_width = window_pix_width,
            .window_pix_height = window_pix_height,
            .isometric_math_utility = isometric_math_utility,
            .window_upper_left = this_window_upper_left,
            .window_upper_right = this_window_upper_right,
            .window_bottom_right = this_window_bottom_right,
            .window_bottom_left = this_window_bottom_left,
        };
    }

    pub fn initialize(this: *@This(), map_position_x: i32, map_position_y: i32) void {
        const upper_left = this.isometric_math_utility.isIsoPointOnMap(this.window_upper_left, Point{ .x = map_position_x, .y = map_position_y });
        const upper_right = this.isometric_math_utility.isIsoPointOnMap(this.window_upper_right, Point{ .x = map_position_x, .y = map_position_y });
        const bottom_right = this.isometric_math_utility.isIsoPointOnMap(this.window_bottom_right, Point{ .x = map_position_x, .y = map_position_y });
        const bottom_left = this.isometric_math_utility.isIsoPointOnMap(this.window_bottom_left, Point{ .x = map_position_x, .y = map_position_y });

        const window_map_points = WindowMapPoints{ .upper_left = upper_left, .upper_right = upper_right, .bottom_right = bottom_right, .bottom_left = bottom_left };
        this.case_handler = CaseHandler.getCaseHandler(this.isometric_math_utility, &window_map_points, map_position_x, map_position_y);
    }

    pub fn nextTile(this:*@This())?Coord{
       return this.case_handler.get_next_tile_coord();     
    }
};

const WindowMapPoints = struct {
    upper_left: PointPosition,
    upper_right: PointPosition,
    bottom_right: PointPosition,
    bottom_left: PointPosition,
};


const CaseHandler = struct {
    const InitFn = *const fn (this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void;
    const NextTileCoordFn = *const fn (this: *@This()) ?Coord;

    const Data = union(enum) {
        all_points: struct {},
        upperleft_upperright_bottomright: struct {},
        upperright_bottomright_bottomleft: struct {},
        bottomright_bottomleft_upperleft: struct {},
        bottomleft_upperleft_upperright: struct {},
        upperleft_upperright: struct {},
        upperright_bottomright: struct {},
        bottomright_bottomleft: struct {},
        bottomleft_upperleft: struct {},
        upperleft: struct {},
        upperright: struct {},
        bottomright: struct {},
        bottomleft: struct {},
        none: struct {},
    };

    init: InitFn,
    get_next_tile_coord: NextTileCoordFn,
    data: Data,
    isometric_math_utility: IsometricMathUtility,

    const CaseHandlerList = [NUM_OF_CASES]CaseHandler;
    const NUM_OF_CASES: usize = 14;
    fn createCaseHandlerDeterminationFunctionTab() CaseHandlerList {
        var this_case_handler_list: CaseHandlerList = undefined;

        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, true, true))] = CaseHandler{ .init = initAllPoints, .get_next_tile_coord = handleAllPoints, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, true, false))] = CaseHandler{ .init = initUpperLeftUpperRightBottomRight, .get_next_tile_coord = handleUpperLeftUpperRightBottomRight, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, true, true, true))] = CaseHandler{ .init = initUpperRightBottomRightBottomLeft, .get_next_tile_coord = handleUpperRightBottomRightBottomLeft, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, false, true))] = CaseHandler{ .init = initBottomRightBottomLeftUpperLeft, .get_next_tile_coord = handleBottomRightBottomLeftUpperLeft, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, false, true))] = CaseHandler{ .init = initBottomLeftUpperLeftUpperRight, .get_next_tile_coord = handleBottomLeftUpperLeftUpperRight, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, false, false))] = CaseHandler{ .init = initUpperLeftUpperRight, .get_next_tile_coord = handleUpperLeftUpperRight, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, true, true, false))] = CaseHandler{ .init = initUpperRightBottomRight, .get_next_tile_coord = handleUpperRightBottomRight, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, true, true))] = CaseHandler{ .init = initBottomRightBottomLeft, .get_next_tile_coord = handleBottomRightBottomLeft, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, false, false, true))] = CaseHandler{ .init = initBottomLeftUpperLeft, .get_next_tile_coord = handleBottomLeftUpperLeft, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, false, false, false))] = CaseHandler{ .init = initUpperLeft, .get_next_tile_coord = handleUpperLeft, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, true, false, false))] = CaseHandler{ .init = initUpperRight, .get_next_tile_coord = handleUpperRight, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, true, false))] = CaseHandler{ .init = initBottomRight, .get_next_tile_coord = handleBottomRight, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, false, true))] = CaseHandler{ .init = initBottomLeft, .get_next_tile_coord = handleBottomLeft, .data = .{} };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, false, false))] = CaseHandler{ .init = initNone, .get_next_tile_coord = handleNone, .data = .{} };

        return this_case_handler_list;
    }

    fn windowOnMapFromBool(upper_left: bool, upper_right: bool, bottom_right: bool, bottom_left: bool) WindowOnMap {
    return .{
        .upper_left = upper_left,
        .upper_right = upper_right,
        .bottom_right = bottom_right,
        .bottom_left = bottom_left,
    };
}

    fn detectCase(window_on_map: *const WindowOnMap) u4 {
        var constructed_enum_int: u4 = 0b0000;

        var int_from_bool: u4 = @intCast(@intFromBool(window_on_map.upper_left));
        constructed_enum_int |= int_from_bool;

        int_from_bool = @intCast(@intFromBool(window_on_map.upper_right));
        int_from_bool <<= 1;
        constructed_enum_int |= int_from_bool;

        int_from_bool = @intCast(@intFromBool(window_on_map.bottom_right));
        int_from_bool <<= 2;
        constructed_enum_int |= int_from_bool;

        int_from_bool = @intCast(@intFromBool(window_on_map.bottom_left));
        int_from_bool <<= 3;
        constructed_enum_int |= int_from_bool;

        return constructed_enum_int;
    }

    const WindowOnMap = struct {
    upper_left: bool,
    upper_right: bool,
    bottom_right: bool,
    bottom_left: bool,
};

    fn windowOnMapFromWinMapPoints(window_map_point: *WindowMapPoints) WindowOnMap {
    return .{
        .upper_left = window_map_point.upper_left == .on_map,
        .upper_right = window_map_point.upper_right == .on_map,
        .bottom_right = window_map_point.bottom_right == .on_map,
        .bottom_left = window_map_point.bottom_left == .on_map,
    };
}

    const case_handler_list = createCaseHandlerDeterminationFunctionTab();

    pub fn getCaseHandler(isometric_math_utility: IsometricMathUtility, window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) CaseHandler {
        const window_on_map = windowOnMapFromWinMapPoints(window_map_points);
        const idx = detectCase(window_on_map);
        var case_handler = case_handler_list[idx];
        case_handler.isometric_math_utility = isometric_math_utility;
        case_handler.init(window_map_points, map_position_x, map_position_y);
        return case_handler;
    }

    fn initAllPoints(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.data.all_points;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initUpperLeftUpperRightBottomRight(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.upperleft_upperright_bottomright;
        _ = this_data;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initUpperRightBottomRightBottomLeft(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.upperright_bottomright_bottomleft;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initBottomRightBottomLeftUpperLeft(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.bottomright_bottomleft_upperleft;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initBottomLeftUpperLeftUpperRight(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.bottomleft_upperleft_upperright;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initUpperLeftUpperRight(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.upperleft_upperright;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initUpperRightBottomRight(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.upperright_bottomright;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initBottomRightBottomLeft(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.bottomright_bottomleft;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initBottomLeftUpperLeft(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.bottomleft_upperleft;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initUpperLeft(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.upperleft;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initUpperRight(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.upperright;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initBottomRight(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.bottomright;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initBottomLeft(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.bottomleft;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }
    fn initNone(this: *@This(), window_map_points: *const WindowMapPoints, map_position_x: i32, map_position_y: i32) void {
        const this_data = &this.none;
        _ = this_data;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_points;
        return undefined;
    }

    fn handleAllPoints(this: *@This()) ?Coord {
        const this_data = &this.all_points;
        _ = this_data;
        return undefined;
    }
    fn handleUpperLeftUpperRightBottomRight(this: *@This()) ?Coord {
        const this_data = &this.upperleft_upperright_bottomright;
        _ = this_data;
        return undefined;
    }
    fn handleUpperRightBottomRightBottomLeft(this: *@This()) ?Coord {
        const this_data = &this.upperright_bottomright_bottomleft;
        _ = this_data;
        return undefined;
    }
    fn handleBottomRightBottomLeftUpperLeft(this: *@This()) ?Coord {
        const this_data = &this.bottomright_bottomleft_upperleft;
        _ = this_data;
        return undefined;
    }
    fn handleBottomLeftUpperLeftUpperRight(this: *@This()) ?Coord {
        const this_data = &this.bottomleft_upperleft_upperright;
        _ = this_data;
        return undefined;
    }
    fn handleUpperLeftUpperRight(this: *@This()) ?Coord {
        const this_data = &this.upperleft_upperright;
        _ = this_data;
        return undefined;
    }
    fn handleUpperRightBottomRight(this: *@This()) ?Coord {
        const this_data = &this.upperright_bottomright;
        _ = this_data;
        return undefined;
    }
    fn handleBottomRightBottomLeft(this: *@This()) ?Coord {
        const this_data = &this.bottomright_bottomleft;
        _ = this_data;
        return undefined;
    }
    fn handleBottomLeftUpperLeft(this: *@This()) ?Coord {
        const this_data = &this.bottomleft_upperleft;
        _ = this_data;
        return undefined;
    }
    fn handleUpperLeft(this: *@This()) ?Coord {
        const this_data = &this.upperleft;
        _ = this_data;
        return undefined;
    }
    fn handleUpperRight(this: *@This()) ?Coord {
        const this_data = &this.upperright;
        _ = this_data;
        return undefined;
    }
    fn handleBottomRight(this: *@This()) ?Coord {
        const this_data = &this.bottomright;
        _ = this_data;
        return undefined;
    }
    fn handleBottomLeft(this: *@This()) ?Coord {
        const this_data = &this.bottomleft;
        _ = this_data;
        return undefined;
    }
    fn handleNone(this: *@This()) ?Coord {
        const this_data = &this.none;
        _ = this_data;
        return undefined;
    }
};

// all_points
// upperleft_upperright_bottomright
// upperright_bottomright_bottomleft
// bottomright_bottomleft_upperleft
// bottomleft_upperleft_upperright
// upperleft_upperright
// upperright_bottomright
// bottomright_bottomleft
// bottomleft_upperleft
// upperleft
// upperright
// bottomright
// bottomleft
// none
