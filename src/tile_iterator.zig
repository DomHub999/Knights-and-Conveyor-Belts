const std = @import("std");

const Coord = @import("iso_core.zig").Coord;
const Point = @import("iso_core.zig").Point;

const PointPosition = @import("iso_map.zig").PointPosition;
const Boundry = @import("iso_map.zig").Boundry;

const IsometricMathUtility = @import("iso_core.zig").IsometricMathUtility;

const LinearEquation = @import("iso_util.zig").LinearEquation;

const WindowMapPositions = struct {
    upper_left: PointPosition,
    upper_right: PointPosition,
    bottom_right: PointPosition,
    bottom_left: PointPosition,
};

const WindowCornerPoints = struct {
    upper_left: Point,
    upper_right: Point,
    bottom_right: Point,
    bottom_left: Point,
};

pub const TileIterator = struct {
    margin: usize, //additional tiles to be considered out of bounds

    //TODO:can probably be deleted, are not used
    map_coord_upper_left: Coord = undefined,
    map_coord_upper_right: Coord = undefined,
    map_coord_bottom_right: Coord = undefined,
    map_coord_bottom_left: Coord = undefined,

    isometric_math_utility: IsometricMathUtility,
    window_pix_width: i32,
    window_pix_height: i32,

    window_corner_points: WindowCornerPoints,

    case_handler: CaseHandler = undefined,

    pub fn new(
        window_pix_width: i32,
        window_pix_height: i32,
        isometric_math_utility: IsometricMathUtility,
        margin: usize,
    ) @This() {
        const this_window_corner_points = WindowCornerPoints{
            .upper_left = .{ .x = 0, .y = 0 },
            .upper_right = .{ .x = @floatFromInt(window_pix_width), .y = 0 },
            .bottom_right = .{ .x = @floatFromInt(window_pix_width), .y = @floatFromInt(window_pix_height) },
            .bottom_left = .{ .x = 0, .y = @floatFromInt(window_pix_height) },
        };

        return .{
            .margin = margin,
            .window_pix_width = window_pix_width,
            .window_pix_height = window_pix_height,
            .isometric_math_utility = isometric_math_utility,
            .window_corner_points = this_window_corner_points,
        };
    }

    //TODO:make a struct from map_position_x and y
    pub fn initialize(this: *@This(), map_position_x: i32, map_position_y: i32) void {
        const window_map_positions = WindowMapPositions{
            .upper_left = this.isometric_math_utility.isIsoPointOnMap(this.window_upper_left, Point{ .x = map_position_x, .y = map_position_y }),
            .upper_right = this.isometric_math_utility.isIsoPointOnMap(this.window_upper_right, Point{ .x = map_position_x, .y = map_position_y }),
            .bottom_right = this.isometric_math_utility.isIsoPointOnMap(this.window_bottom_right, Point{ .x = map_position_x, .y = map_position_y }),
            .bottom_left = this.isometric_math_utility.isIsoPointOnMap(this.window_bottom_left, Point{ .x = map_position_x, .y = map_position_y }),
        };

        this.case_handler = CaseHandler.new(&this.isometric_math_utility, &window_map_positions, map_position_x, map_position_y);
    }

    pub fn nextTile(this: *@This()) ?Coord {
        return this.case_handler.get_next_tile_coord();
    }
};

const CaseHandler = struct {
    const InitFn = *const fn (this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void;
    const NextTileCoordFn = *const fn (this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord;

    const Data = union(enum) {
        all_points: struct {
            upper_left: Coord = undefined,
            upper_right: Coord = undefined,
            bottom_right: Coord = undefined,
            bottom_left: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_upper_left_corner: bool = false,
            has_row_end_reached_bottom_right_corner: bool = false,
        },
        upperleft_upperright_bottomright: struct {
            upper_left: Coord = undefined,
            upper_right: Coord = undefined,
            bottom_right: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_upper_left_corner: bool = false,
            has_row_end_reached_bottom_right_corner: bool = false,
        },
        upperright_bottomright_bottomleft: struct {
            upper_right: Coord = undefined,
            bottom_right: Coord = undefined,
            bottom_left: Coord = undefined,

            upper_window_map_boundry: Coord = undefined,
            left_window_map_boundry: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_map_boundry_upper: bool = false,
            has_row_begin_reached_map_boundry_left: bool = false,

            has_row_end_reached_bottom_right_corner: bool = false,
        },
        bottomright_bottomleft_upperleft: struct {
            upper_left: Coord = undefined,
            bottom_right: Coord = undefined,
            bottom_left: Coord = undefined,

            upper_window_map_boundry: Coord = undefined,
            right_window_map_boundry: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_upper_left_corner: bool = false,

            has_row_end_reached_bottom_right_corner: bool = false,
        },
        bottomleft_upperleft_upperright: struct {
            upper_left: Coord = undefined,
            upper_right: Coord = undefined,
            bottom_left: Coord = undefined,

            right_window_map_boundry: Coord = undefined,
            bottom_window_map_boundry: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_upper_left_cornder: bool = false,

            has_row_end_reached_map_boundry_right: bool = false,
            has_row_end_reached_map_boundry_bottom: bool = false,
        },
        upperleft_upperright: struct {
            upper_left: Coord = undefined,
            upper_right: Coord = undefined,

            right_window_map_boundry: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_upper_left_cornder: bool = false,

            has_row_end_reached_map_boundry_right: bool = false,
        },
        upperright_bottomright: struct {
            upper_right: Coord = undefined,
            bottom_right: Coord = undefined,

            upper_window_map_boundry: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            has_row_begin_reached_map_boundry_upper: bool = false,

            has_row_end_reached_bottom_right_corner: bool = false,
        },
        bottomright_bottomleft: struct {
            const WindowMapSideCase = union(enum) {
                upper_left: struct {
                    right_window_map_boundry: Coord,
                    left_window_map_boundry: Coord,

                    has_row_begin_reached_map_boundry_left: bool = false,

                    has_row_end_reached_bottom_right_corner: bool = false,
                },
                center: struct {
                    right_window_map_boundry: Coord,
                    top_map: Coord,
                    left_window_map_boundry: Coord,

                    has_row_begin_risteached_map_boundry_left: bool = false,

                    has_row_end_reached_bottom_right_corner: bool = false,
                },
                upper_right: struct {
                    right_window_map_boundry: Coord,
                    left_window_map_boundry: Coord,

                    has_row_end_reached_bottom_right_corner: bool = false,
                },
                center_upper_map_intercept: struct{
                    right_window_map_boundry: Coord,
                    left_window_map_boundry: Coord,

                    upper_window_left_map_intercept:Coord,
                    upper_window_right_map_intercept:Coord,

                    has_row_begin_reached_map_boundry_upper_left:bool = false,
                    has_row_begin_reached_map_boundry_left:bool = false,

                    has_row_end_reached_bottom_right:bool = false,
                },
            };

            bottom_right: Coord = undefined,
            bottom_left: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            window_map_side_case: WindowMapSideCase = undefined,
        },
        bottomleft_upperleft: struct {},
        upperleft: struct {},
        upperright: struct {},
        bottomright: struct {},
        bottomleft: struct {},
        //TODO: case where the map is smaller than the entire screen
        none: struct {},
    };

    init: InitFn,
    get_next_tile_coord: NextTileCoordFn,
    data: Data,
    current_coord: ?Coord = null,

    const CaseHandlerList = [NUM_OF_CASES]CaseHandler;
    const NUM_OF_CASES: usize = 14;
    fn createCaseHandlerDeterminationFunctionTab() CaseHandlerList {
        var this_case_handler_list: CaseHandlerList = undefined;

        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, true, true))] = CaseHandler{ .init = initAllPoints, .get_next_tile_coord = handleAllPoints, .data = .{ .all_points = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, true, false))] = CaseHandler{ .init = initUpperLeftUpperRightBottomRight, .get_next_tile_coord = handleUpperLeftUpperRightBottomRight, .data = .{ .upperleft_upperright_bottomright = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, true, true, true))] = CaseHandler{ .init = initUpperRightBottomRightBottomLeft, .get_next_tile_coord = handleUpperRightBottomRightBottomLeft, .data = .{ .upperright_bottomright_bottomleft = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, false, true))] = CaseHandler{ .init = initBottomRightBottomLeftUpperLeft, .get_next_tile_coord = handleBottomRightBottomLeftUpperLeft, .data = .{ .bottomright_bottomleft_upperleft = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, false, true))] = CaseHandler{ .init = initBottomLeftUpperLeftUpperRight, .get_next_tile_coord = handleBottomLeftUpperLeftUpperRight, .data = .{ .bottomleft_upperleft_upperright = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, true, false, false))] = CaseHandler{ .init = initUpperLeftUpperRight, .get_next_tile_coord = handleUpperLeftUpperRight, .data = .{ .upperleft_upperright = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, true, true, false))] = CaseHandler{ .init = initUpperRightBottomRight, .get_next_tile_coord = handleUpperRightBottomRight, .data = .{ .upperright_bottomright = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, true, true))] = CaseHandler{ .init = initBottomRightBottomLeft, .get_next_tile_coord = handleBottomRightBottomLeft, .data = .{ .bottomright_bottomleft = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, false, false, true))] = CaseHandler{ .init = initBottomLeftUpperLeft, .get_next_tile_coord = handleBottomLeftUpperLeft, .data = .{ .bottomleft_upperleft = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(true, false, false, false))] = CaseHandler{ .init = initUpperLeft, .get_next_tile_coord = handleUpperLeft, .data = .{ .upperleft = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, true, false, false))] = CaseHandler{ .init = initUpperRight, .get_next_tile_coord = handleUpperRight, .data = .{ .upperright = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, true, false))] = CaseHandler{ .init = initBottomRight, .get_next_tile_coord = handleBottomRight, .data = .{ .bottomright = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, false, true))] = CaseHandler{ .init = initBottomLeft, .get_next_tile_coord = handleBottomLeft, .data = .{ .bottomleft = .{} } };
        this_case_handler_list[detectCase(&windowOnMapFromBool(false, false, false, false))] = CaseHandler{ .init = initNone, .get_next_tile_coord = handleNone, .data = .{ .none = .{} } };

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

    fn windowOnMapFromWinMapPoints(window_map_point: *WindowMapPositions) WindowOnMap {
        return .{
            .upper_left = window_map_point.upper_left == .on_map,
            .upper_right = window_map_point.upper_right == .on_map,
            .bottom_right = window_map_point.bottom_right == .on_map,
            .bottom_left = window_map_point.bottom_left == .on_map,
        };
    }

    const case_handler_list = createCaseHandlerDeterminationFunctionTab();

    pub fn new(isometric_math_utility: *const IsometricMathUtility, window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32) @This() {
        const window_on_map = windowOnMapFromWinMapPoints(window_map_positions);
        const idx = detectCase(window_on_map);
        var case_handler = case_handler_list[idx];
        case_handler.init(window_corner_points, window_map_positions, map_position_x, map_position_y, isometric_math_utility);
        return case_handler;
    }

    fn initAllPoints(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.data.all_points;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y);
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y);
    }
    fn initUpperLeftUpperRightBottomRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperleft_upperright_bottomright;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y);
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);
    }
    fn initUpperRightBottomRightBottomLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperright_bottomright_bottomleft;
        _ = window_map_positions;

        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y);

        this_data.upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right);
        this_data.left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left);
    }
    fn initBottomRightBottomLeftUpperLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomright_bottomleft_upperleft;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y);
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y);

        this_data.upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left);
        this_data.right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right);
    }
    fn initBottomLeftUpperLeftUpperRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomleft_upperleft_upperright;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y);
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y);

        this_data.right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right);
        this_data.bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left);
    }
    fn initUpperLeftUpperRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperleft_upperright;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y);
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);

        this_data.right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right);
    }
    fn initUpperRightBottomRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperright_bottomright;
        _ = window_map_positions;

        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);

        this_data.upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right);
    }
    fn initBottomRightBottomLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomright_bottomleft;
           
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y);

        const linear_eq_upper_win = LinearEquation{.has_slope = .{.m = 0, .b = window_corner_points.upper_left.y}};        
        const map_side_intercepts_upper_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_upper_win, &window_corner_points.upper_left, &window_corner_points.upper_right, map_position_x, map_position_y);

        //window is in the middle and upper part of the window intercepts tip of the map    
        if (map_side_intercepts_upper_win.upper_left == .yes and map_side_intercepts_upper_win.upper_right == .yes) {
            this_data.window_map_side_case = .{.center_upper_map_intercept = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
                .upper_window_left_map_intercept = isometric_math_utility.isoToMapCoord(Point{.x = map_side_intercepts_upper_win.upper_left.yes.x, .y = map_side_intercepts_upper_win.upper_left.yes.y}, map_position_x, map_position_y).?,
                .upper_window_right_map_intercept = isometric_math_utility.isoToMapCoord(Point{.x = map_side_intercepts_upper_win.upper_right.yes.x, .y = map_side_intercepts_upper_win.upper_right.yes.y}, map_position_x, map_position_y).?,
            }};
        //window is on the left side of the upper tip of the map
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_left and window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_left) {
            this_data.window_map_side_case = .{ .upper_left = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
            } };
        //window is int the middle and upper tip of the map is within the window
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_left and window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right) {
            const right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right);

            this_data.window_map_side_case = .{ .center = .{
                .right_window_map_boundry = right_window_map_boundry,
                .top_map = isometric_math_utility.walkMapCoordFullNorthWest(&right_window_map_boundry),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
            } };
        //window is on the right side of the map
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_right and window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right) {
            this_data.window_map_side_case = .{ .upper_left = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
            } };
        }
    }

    fn initBottomLeftUpperLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomleft_upperleft;
        _ = this_data;
        _ = isometric_math_utility;
        _ = window_corner_points;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_positions;
    }
    fn initUpperLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperleft;
        _ = this_data;
        _ = isometric_math_utility;
        _ = window_corner_points;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_positions;
    }
    fn initUpperRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperright;
        _ = this_data;
        _ = isometric_math_utility;
        _ = window_corner_points;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_positions;
    }
    fn initBottomRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomright;
        _ = this_data;
        _ = isometric_math_utility;
        _ = window_corner_points;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_positions;
    }
    fn initBottomLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomleft;
        _ = this_data;
        _ = isometric_math_utility;
        _ = window_corner_points;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_positions;
    }
    fn initNone(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.none;
        _ = this_data;
        _ = isometric_math_utility;
        _ = window_corner_points;
        _ = map_position_x;
        _ = map_position_y;
        _ = window_map_positions;
    }

    fn handleAllPoints(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.all_points;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) { //reached the bottom

                //ROW BEGIN
                if (this_data.has_row_begin_reached_upper_left_corner) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;

                    //END OF SCREEN
                    if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;

                    this.current_coord = this_data.row_begin;
                }
                if (!this_data.has_row_begin_reached_upper_left_corner) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_upper_left_corner = this_data.row_begin.hasEqualYCoordinate(&this_data.upper_left);
                }

                //ROW END
                if (this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                }
                if (!this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                }
            } else { // havent reached the bottom, good to step one tile down
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) { // first iteration
            this_data.row_begin = this_data.upper_right;
            this_data.row_end = this_data.upper_right;
            this.current_coord = this_data.upper_right;
        }

        return this.current_coord;
    }
    fn handleUpperLeftUpperRightBottomRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperleft_upperright_bottomright;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {

                //ROW BEGIN
                if (this_data.has_row_begin_reached_upper_left_corner) {

                    //END OF SCREEN
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;

                    this.current_coord = this_data.row_begin;
                }

                if (!this_data.has_row_begin_reached_upper_left_corner) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_upper_left_corner = this_data.row_begin.hasEqualYCoordinate(&this_data.upper_left);
                }

                //ROW END
                if (this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                }

                if (!this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            this_data.row_begin = this_data.upper_right;
            this_data.row_end = this_data.upper_right;
            this.current_coord = this_data.upper_right;
        }

        return this.current_coord;
    }
    fn handleUpperRightBottomRightBottomLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperright_bottomright_bottomleft;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {

                //ROW BEGIN
                if (this_data.has_row_begin_reached_map_boundry_upper and this_data.has_row_begin_reached_map_boundry_left) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //END OF SCREEN
                    if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                }

                if (this_data.has_row_begin_reached_map_boundry_upper and !this_data.has_row_begin_reached_map_boundry_left) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_map_boundry_left = this_data.row_begin.hasEqualY(&this_data.left_window_map_boundry);
                }

                if (!this_data.has_row_begin_reached_map_boundry_upper and !this_data.has_row_begin_reached_map_boundry_left) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_map_boundry_upper = this_data.row_begin.hasEqualX(&this_data.upper_window_map_boundry);
                }

                //ROW END
                if (!this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                }

                if (this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            this_data.row_begin = this_data.upper_right;
            this_data.row_end = this_data.upper_right;
            this.current_coord = this_data.upper_right;
        }

        return this.current_coord;
    }
    fn handleBottomRightBottomLeftUpperLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomright_bottomleft_upperleft;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {

                //ROW BEGIN
                if (this_data.has_row_begin_reached_upper_left_corner) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin);
                    this.current_coord = this_data.row_begin;

                    //END OF SCREEN
                    if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                }

                if (!this_data.has_row_begin_reached_upper_left_corner) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_upper_left_corner = this_data.row_begin.hasEqualX(&this_data.upper_left);
                }

                //ROW END
                if (this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);
                }

                if (!this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end);

                    //CORNER REACHED
                    this_data.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            this_data.row_begin = this_data.upper_window_map_boundry;
            this_data.row_end = this_data.right_window_map_boundry;
            this.current_coord = this_data.row_begin;
        }

        return this.current_coord;
    }
    fn handleBottomLeftUpperLeftUpperRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomleft_upperleft_upperright;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                if (this_data.has_row_begin_reached_upper_left_cornder) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //END OF SCREEN
                    if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                }

                //ROW BEGIN
                if (!this_data.has_row_begin_reached_upper_left_cornder) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.row_begin.hasEqualX(&this_data.upper_left);
                }

                //ROW END
                if (this_data.has_row_end_reached_map_boundry_right and this_data.has_row_end_reached_map_boundry_bottom) {
                    this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);
                }

                if (this_data.has_row_end_reached_map_boundry_right and !this_data.has_row_end_reached_map_boundry_bottom) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_map_boundry_bottom = this_data.row_end.hasEqualY(&this_data.bottom_window_map_boundry);
                }

                if (!this_data.has_row_end_reached_map_boundry_right and !this_data.has_row_end_reached_map_boundry_bottom) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_map_boundry_right = this_data.row_end.hasEqualX(&this_data.right_window_map_boundry);
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            this_data.row_begin = this_data.upper_right;
            this_data.row_end = this_data.upper_right;
            this.current_coord = this_data.row_begin;
        }

        return this.current_coord;
    }
    fn handleUpperLeftUpperRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperleft_upperright;

        if (this.current_coord) |this_current_coord| {
            if (this_data.row_begin.hasEqualX(&this_data.row_end)) {

                //ROW BEGIN
                if (this_data.has_row_begin_reached_upper_left_cornder) {
                    //END OF SCREEN
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;
                }

                if (!this_data.has_row_begin_reached_upper_left_cornder) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_upper_left_cornder = this_data.row_begin.hasEqualX(&this_data.upper_left);
                }

                //ROW END
                if (this_data.has_row_end_reached_map_boundry_right) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;
                }

                if (!this_data.has_row_end_reached_map_boundry_right) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_map_boundry_right = this_data.row_end.hasEqualX(&this_data.right_window_map_boundry);
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            this_data.row_begin = this_data.upper_right;
            this_data.row_end = this_data.upper_right;
            this.current_coord = this_data.row_begin;
        }

        return this.current_coord;
    }
    fn handleUpperRightBottomRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperright_bottomright;

        if (this.current_coord) |this_current_coord| {
            if (this_data.row_begin.hasEqualX(&this_data.row_end)) {

                //ROW BEGIN
                if (this_data.has_row_begin_reached_map_boundry_upper) {

                    //END OF SCREEN
                    this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;
                }

                if (!this_data.has_row_begin_reached_map_boundry_upper) {
                    this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                    this.current_coord = this_data.row_begin;

                    //CORNER REACHED
                    this_data.has_row_begin_reached_map_boundry_upper = this_data.row_begin.hasEqualX(this_data.upper_window_map_boundry);
                }

                //ROW END
                if (this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                }

                if (this_data.has_row_end_reached_bottom_right_corner) {
                    this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                    //CORNER REACHED
                    this_data.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            this_data.row_begin = this_data.upper_right;
            this_data.row_end = this_data.upper_right;
            this.current_coord = this_data.row_begin;
        }

        return this.current_coord;
    }
    fn handleBottomRightBottomLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomright_bottomleft;

        if (this.current_coord) |this_current_coord| {
            if (this_data.row_begin.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .upper_left => |upper_left| {

                        //ROW BEGIN
                        if (upper_left.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }

                        if (!upper_left.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            upper_left.has_row_begin_reached_map_boundry_left = this_data.row_begin.hasEqualY(&upper_left.left_window_map_boundry);
                        }

                        //ROW END
                        if (upper_left.has_row_end_reached_bottom_right_corner) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!upper_left.has_row_end_reached_bottom_right_corner) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            upper_left.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .center => |center| {
                        //ROW BEGIN
                        if (center.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }

                        if (!center.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center.has_row_begin_reached_map_boundry_left = this_data.row_begin.hasEqualY(&center.left_window_map_boundry);
                        }

                        //ROW END
                        if (center.has_row_end_reached_bottom_right_corner) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!center.has_row_end_reached_bottom_right_corner) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .upper_right => |upper_right| {
                        //ROW BEGIN
                        this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_begin;

                        //END OF SCREEN
                        if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;

                        //ROW END
                        if (upper_right.has_row_end_reached_bottom_right_corner) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!upper_right.has_row_end_reached_bottom_right_corner) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            upper_right.has_row_end_reached_bottom_right_corner = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .center_upper_map_intercept => |center_upper_map_intercept|{
                        //ROW BEGIN
                        if (center_upper_map_intercept.has_row_begin_reached_map_boundry_upper_left and center_upper_map_intercept.has_row_begin_reached_map_boundry_left) {
                             this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                             this.current_coord = this_data.row_begin;   

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;

                        }

                        if (center_upper_map_intercept.has_row_begin_reached_map_boundry_upper_left and !center_upper_map_intercept.has_row_begin_reached_map_boundry_left) {
                             this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                             this.current_coord = this_data.row_begin;

                             //CORNER REACHED
                             center_upper_map_intercept.has_row_begin_reached_map_boundry_left = this_data.row_begin.hasEqualY(&center_upper_map_intercept.left_window_map_boundry);
                        }

                        if (!center_upper_map_intercept.has_row_begin_reached_map_boundry_upper_left and !center_upper_map_intercept.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;    

                            //CORNER REACHED
                            center_upper_map_intercept.has_row_begin_reached_map_boundry_upper_left = this_data.row_begin.hasEqualX(&center_upper_map_intercept.upper_window_left_map_intercept);
                        }

                        //ROW END
                        if (center_upper_map_intercept.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);
                        }

                        if (!center_upper_map_intercept.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end);

                            //CORNER REACHED
                            center_upper_map_intercept.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }

                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .upper_left => |upper_left| {
                    this_data.row_begin = upper_left.right_window_map_boundry;
                    this_data.row_end = upper_left.right_window_map_boundry;
                    this.current_coord = upper_left.right_window_map_boundry;
                },
                .center => |center| {
                    this_data.row_begin = center.top_map;
                    this_data.row_end = center.right_window_map_boundry;
                    this.current_coord = center.top_map;
                },
                .upper_right => |upper_right| {
                    this_data.row_begin = upper_right.left_window_map_boundry;
                    this_data.row_end = upper_right.right_window_map_boundry;
                    this.current_coord = upper_right.left_window_map_boundry;
                },
                .center_upper_map_intercept => |center_upper_map_intercept|{
                    this_data.row_begin = center_upper_map_intercept.upper_window_right_map_intercept;
                    this_data.row_end = center_upper_map_intercept.right_window_map_boundry;
                    this.current_coord = center_upper_map_intercept.upper_window_right_map_intercept;
                }
            }
        }

        return this.current_coord;
    }
    fn handleBottomLeftUpperLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomleft_upperleft;
        _ = this_data;
        _ = isometric_math_utility;
        return undefined;
    }
    fn handleUpperLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperleft;
        _ = this_data;
        _ = isometric_math_utility;
        return undefined;
    }
    fn handleUpperRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperright;
        _ = this_data;
        _ = isometric_math_utility;
        return undefined;
    }
    fn handleBottomRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomright;
        _ = this_data;
        _ = isometric_math_utility;
        return undefined;
    }
    fn handleBottomLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomleft;
        _ = this_data;
        _ = isometric_math_utility;
        return undefined;
    }
    fn handleNone(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.none;
        _ = this_data;
        _ = isometric_math_utility;
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
