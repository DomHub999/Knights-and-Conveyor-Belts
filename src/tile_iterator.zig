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
            const WindowMapSideCase = union(enum) { bottom_left: struct {
                has_row_begin_reached_upper_left: bool = false,
            }, center: struct {
                right_window_map_boundry: Coord,

                has_row_begin_reached_upper_left: bool = false,

                has_row_end_reached_map_boundry_right: bool = false,
            }, bottom_right: struct {
                right_window_map_boundry: Coord,

                has_row_begin_reached_upper_left: bool = false,

                has_row_end_reached_map_boundry_right: bool = false,
            }, center_bottom_map_intercept: struct {
                right_window_map_boundry: Coord,
                left_window_map_boundry: Coord,

                bottom_window_left_map_intercept: Coord,
                bottom_window_right_map_intercept: Coord,

                has_row_begin_reached_upper_left: bool = false,
                has_row_begin_reached_map_boundry_left: bool = false,

                has_row_end_reached_map_boundry_right: bool = false,
                has_row_end_reached_map_boundry_bottom_right: bool = false,
            } };

            upper_left: Coord = undefined,
            upper_right: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            window_map_side_case: WindowMapSideCase = undefined,
        },
        upperright_bottomright: struct {
            const WindowMapSideCase = union(enum) {
                upper_side: struct {
                    upper_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_begin_reached_map_boundry_upper: bool = false,

                    has_row_end_reached_bottom_right: bool = false,
                },
                center: struct {
                    upper_window_map_boundry: Coord,

                    has_row_begin_reached_map_boundry_upper: bool = false,

                    has_row_end_reached_bottom_right: bool = false,
                },
                bottom_side: struct {
                    has_row_end_reached_bottom_right: bool = false,
                },
                center_leftside_map_intercept: struct {
                    upper_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,

                    left_window_upper_map_intercept: Coord,
                    left_window_bottom_map_intercept: Coord,

                    has_row_begin_reached_map_boundry_upper: bool = false,
                    has_row_begin_reached_map_boundry_left_upper: bool = false,

                    has_row_end_reached_bottom_right: bool = false,
                },
            };

            upper_right: Coord = undefined,
            bottom_right: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            window_map_side_case: WindowMapSideCase = undefined,
        },
        bottomright_bottomleft: struct {
            const WindowMapSideCase = union(enum) {
                upper_left: struct {
                    right_window_map_boundry: Coord,
                    left_window_map_boundry: Coord,

                    has_row_begin_reached_map_boundry_left: bool = false,

                    has_row_end_reached_bottom_right: bool = false,
                },
                center: struct {
                    right_window_map_boundry: Coord,
                    top_map: Coord,
                    left_window_map_boundry: Coord,

                    has_row_begin_risteached_map_boundry_left: bool = false,

                    has_row_end_reached_bottom_right: bool = false,
                },
                upper_right: struct {
                    right_window_map_boundry: Coord,
                    left_window_map_boundry: Coord,

                    has_row_end_reached_bottom_right_corner: bool = false,
                },
                center_upper_map_intercept: struct {
                    right_window_map_boundry: Coord,
                    left_window_map_boundry: Coord,

                    upper_window_left_map_intercept: Coord,
                    upper_window_right_map_intercept: Coord,

                    has_row_begin_reached_map_boundry_upper_left: bool = false,
                    has_row_begin_reached_map_boundry_left: bool = false,

                    has_row_end_reached_bottom_right: bool = false,
                },
            };

            bottom_right: Coord = undefined,
            bottom_left: Coord = undefined,

            row_begin: Coord = undefined,
            row_end: Coord = undefined,

            window_map_side_case: WindowMapSideCase = undefined,
        },
        bottomleft_upperleft: struct {
            const WindowMapSideCase = union(enum) {
                uper_side: struct {
                    upper_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_begin_reached_upper_left: bool = false,
                },
                center: struct {
                    upper_window_map_boundry: Coord,
                    most_right: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_begin_reached_upper_left: bool = false,

                    hase_row_end_reached_map_boundry_bottom: bool = false,
                },
                bottom_side: struct {
                    upper_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_begin_reached_upper_left: bool = false,

                    has_row_end_reached_map_boundry_bottom: bool = false,
                },
                center_rightside_map_intercept: struct {
                    upper_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,

                    right_window_upper_map_intercept: Coord,
                    right_window_bottom_map_intercept: Coord,

                    has_row_begin_reached_upper_left: bool = false,

                    has_row_end_reached_map_boundry_right_bottom: bool = false,
                    has_row_end_reached_map_boundry_bottom: bool = false,
                },
            };

            bottom_left: Coord,
            upper_left: Coord,

            row_begin: Coord,
            row_end: Coord,

            window_map_side_case: WindowMapSideCase,
        },
        upperleft: struct {
            const WindowMapSideCase = union(enum) {
                intercepts_upper_right: struct {
                    upper_window_map_boundry: Coord,
                    most_right: Coord,

                    has_row_begin_reached_upper_left: bool = false,
                },
                bottom_right: struct {
                    upper_window_map_boundry: Coord,

                    has_row_begin_reached_upper_left: bool = false,
                },

                intercepts_bottom_left: struct {
                    upper_window_map_boundry: Coord,

                    has_row_begin_reached_upper_left: bool = false,
                },
            };

            upper_left: Coord,

            row_begin: Coord,
            row_end: Coord,

            window_map_side_case: WindowMapSideCase,
        },
        upperright: struct {
            const WindowMapSideCase = union(enum) {
                intercepts_upper_left: struct {
                    upper_window_map_boundry: Coord,

                    has_row_begin_reached_map_boundry_upper: bool = false,
                },
                bottom_left: struct {},
                intercepts_bottom_right: struct {
                    right_window_map_boundry: Coord,

                    has_row_end_reached_map_boundry_right: bool = false,
                },
            };

            upper_right: Coord,

            row_begin: Coord,
            row_end: Coord,

            window_map_side_case: WindowMapSideCase,
        },
        bottomright: struct {
            const WindowMapsSideCase = union(enum) {
                intercepts_upper_right: struct {
                    right_window_map_boundry: Coord,
                    most_top: Coord,

                    has_row_end_reached_bottom_right: bool = false,
                },
                upper_left: struct {
                    right_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_end_reached_bottom_right: bool = false,
                },
                intercepts_bottom_left: struct {
                    right_window_map_boundry: Coord,

                    has_row_end_reached_map_boundry_bottom: bool = false,
                },
            };
            bottom_right: Coord,

            row_begin: Coord,
            row_end: Coord,

            window_map_side_case: WindowMapsSideCase,
        },
        bottomleft: struct {
            const WindowMapSideCase = union(enum) {
                intercepts_upper_left: struct {
                    left_window_map_boundry: Coord,
                    most_top: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_begin_reached_map_boundry_left: bool = false,
                },
                upper_right: struct {
                    //TODO: allign naming, Intercept/Boundry etc
                    left_window_map_boundry: Coord,
                    bottom_window_map_boundry: Coord,
                },
                intercepts_bottom_right: struct {
                    left_window_map_boundry: Coord,
                    most_right: Coord,
                    bottom_window_map_boundry: Coord,

                    has_row_end_reached_map_boundry_bottom: bool = false,
                },
            };

            bottom_left: Coord,

            row_begin: Coord,
            row_end: Coord,

            window_map_side_case: WindowMapSideCase,
        },
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

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y).?;
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y).?;
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y).?;
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y).?;
    }
    fn initUpperLeftUpperRightBottomRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperleft_upperright_bottomright;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y).?;
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y).?;
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y).?;
    }
    fn initUpperRightBottomRightBottomLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperright_bottomright_bottomleft;
        _ = window_map_positions;

        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y).?;
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y).?;
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y).?;

        this_data.upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right);
        this_data.left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left);
    }
    fn initBottomRightBottomLeftUpperLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomright_bottomleft_upperleft;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y).?;
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y).?;
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y).?;

        this_data.upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left);
        this_data.right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right);
    }
    fn initBottomLeftUpperLeftUpperRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomleft_upperleft_upperright;
        _ = window_map_positions;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y).?;
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y).?;
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y).?;

        this_data.right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right);
        this_data.bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left);
    }
    fn initUpperLeftUpperRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperleft_upperright;

        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y).?;
        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y).?;

        const linear_equation_bottom_win = LinearEquation{ .has_slope = .{ .m = 0, .b = window_corner_points.bottom_left.y } };
        const map_side_intercepts_bottom_win = isometric_math_utility.doesLineInterceptMap(&linear_equation_bottom_win, &window_corner_points.bottom_left, &window_corner_points.bottom_right, map_position_x, map_position_y);

        //window is in the middle and bottom part of the window intercepts bottom tip of the map
        if (map_side_intercepts_bottom_win.bottom_left == .yes and map_side_intercepts_bottom_win.bottom_right == .yes) {
            this_data.window_map_side_case = .{ .center_bottom_map_intercept = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_left),
                .bottom_window_left_map_intercept = isometric_math_utility.isoToMapCoord(Point{ .x = map_side_intercepts_bottom_win.bottom_left.yes.x, .y = map_side_intercepts_bottom_win.bottom_left.yes.y }, map_position_x, map_position_y).?,
                .bottom_window_right_map_intercept = isometric_math_utility.isoToMapCoord(Point{ .x = map_side_intercepts_bottom_win.bottom_right.yes.x, .y = map_side_intercepts_bottom_win.bottom_right.yes.y }, map_position_x, map_position_y).?,
            } };
            return;
            //window is on the left side of the bottom tip of the map
        } else if (window_map_positions.bottom_left.not_on_map.boundry_violation == Boundry.bottom_left and window_map_positions.bottom_right.not_on_map.boundry_violation == Boundry.bottom_left) {
            this_data.window_map_side_case = .{
                .bottom_left = .{
                    //--> nothing to initialize
                },
            };
            return;
            //window is in the middle and bottom tip of the map is within the window
        } else if (window_map_positions.bottom_left.not_on_map.boundry_violation == Boundry.bottom_left and window_map_positions.bottom_right.not_on_map.boundry_violation == Boundry.bottom_right) {
            this_data.window_map_side_case = .{ .center = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right),
            } };
            return;
            //window is on the right sid of the map
        } else if (window_map_positions.bottom_left.not_on_map.boundry_violation == Boundry.bottom_right and window_map_positions.bottom_right.not_on_map.boundry_violation == Boundry.bottom_right) {
            this_data.window_map_side_case = .{ .bottom_right = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right),
            } };
            return;
        }
    }
    fn initUpperRightBottomRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperright_bottomright;

        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y).?;
        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y).?;

        const linear_eq_left_win = LinearEquation{ .vertical = .{ .a = window_corner_points.upper_left.x } };
        const map_side_intercepts_left_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_left_win, &window_corner_points.upper_left, &window_corner_points.bottom_left, map_position_x, map_position_y);

        //window is in the middle and left part of the window intercepts the left tip of the map
        if (map_side_intercepts_left_win.upper_left == .yes and map_side_intercepts_left_win.bottom_left == .yes) {
            this_data.window_map_side_case = .{ .center_leftside_map_intercept = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.bottom_right),
                .left_window_upper_map_intercept = isometric_math_utility.isoToMapCoord(.{ .x = map_side_intercepts_left_win.upper_left.yes.x, .y = map_side_intercepts_left_win.upper_left.yes.y }, map_position_x, map_position_y).?,
                .left_window_bottom_map_intercept = isometric_math_utility.isoToMapCoord(.{ .x = map_side_intercepts_left_win.bottom_left.yes.x, .y = map_side_intercepts_left_win.bottom_left.yes.y }, map_position_x, map_position_y).?,
            } };
            return;
            //window is on top of the left tip of the map
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_left and window_map_positions.bottom_left.not_on_map.boundry_violation == Boundry.upper_left) {
            this_data.window_map_side_case = .{ .upper_side = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.bottom_right),
            } };
            return;
            //window is in the middle and left tip of the map is within the window
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_left and window_map_positions.bottom_left.not_on_map.boundry_violation == Boundry.bottom_left) {
            this_data.window_map_side_case = .{ .center = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right),
            } };
            return;
            //window is at the bottom of the left tip of the map
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.bottom_left and window_map_positions.bottom_left.not_on_map.boundry_violation == Boundry.bottom_left) {
            this_data.window_map_side_case = .{
                .bottom_side = .{
                    //-->nothing to initialize
                },
            };
            return;
        }
    }
    fn initBottomRightBottomLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomright_bottomleft;

        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y).?;
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_left, map_position_x, map_position_y).?;

        const linear_eq_upper_win = LinearEquation{ .has_slope = .{ .m = 0, .b = window_corner_points.upper_left.y } };
        const map_side_intercepts_upper_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_upper_win, &window_corner_points.upper_left, &window_corner_points.upper_right, map_position_x, map_position_y);

        //window is in the middle and upper part of the window intercepts tip of the map
        if (map_side_intercepts_upper_win.upper_left == .yes and map_side_intercepts_upper_win.upper_right == .yes) {
            this_data.window_map_side_case = .{ .center_upper_map_intercept = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
                .upper_window_left_map_intercept = isometric_math_utility.isoToMapCoord(Point{ .x = map_side_intercepts_upper_win.upper_left.yes.x, .y = map_side_intercepts_upper_win.upper_left.yes.y }, map_position_x, map_position_y).?,
                .upper_window_right_map_intercept = isometric_math_utility.isoToMapCoord(Point{ .x = map_side_intercepts_upper_win.upper_right.yes.x, .y = map_side_intercepts_upper_win.upper_right.yes.y }, map_position_x, map_position_y).?,
            } };
            return;
            //window is on the left side of the upper tip of the map
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_left and window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_left) {
            this_data.window_map_side_case = .{ .upper_left = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
            } };
            return;
            //window is in the middle and upper tip of the map is within the window
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_left and window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right) {
            const right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right);

            this_data.window_map_side_case = .{ .center = .{
                .right_window_map_boundry = right_window_map_boundry,
                .top_map = isometric_math_utility.walkMapCoordFullNorthWest(&right_window_map_boundry),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
            } };
            return;
            //window is on the right side of the map
        } else if (window_map_positions.upper_left.not_on_map.boundry_violation == Boundry.upper_right and window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right) {
            this_data.window_map_side_case = .{ .upper_left = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
            } };
            return;
        }
    }

    fn initBottomLeftUpperLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomleft_upperleft;

        //TODO: the isoeToMapCoord function returns an optional, unwrap all optionals
        this_data.upper_left = isometric_math_utility.isoToMapCoord(.{ .x = window_corner_points.upper_left.x, .y = window_corner_points.upper_left.y }, map_position_x, map_position_y).?;
        this_data.bottom_left = isometric_math_utility.isoToMapCoord(.{ .x = window_corner_points.bottom_left.x, .y = window_corner_points.bottom_left.y }, map_position_x, map_position_y).?;

        const linear_eq_right_win = LinearEquation{ .vertical = .{ .a = window_corner_points.upper_right.x } };
        const map_side_intercepts_right_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_right_win, &window_corner_points.upper_right, &window_corner_points.bottom_right, map_position_x, map_position_y);

        //window is in the middle and right part of the window intercepts the right tip of the map
        if (map_side_intercepts_right_win.upper_right == .yes and map_side_intercepts_right_win.bottom_right == .yes) {
            this_data.window_map_side_case = .{ .center_rightside_map_intercept = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
                .right_window_upper_map_intercept = isometric_math_utility.isoToMapCoord(.{ .x = map_side_intercepts_right_win.upper_right.yes.x, .y = map_side_intercepts_right_win.upper_right.yes.y }, map_position_x, map_position_y).?,
                .right_window_bottom_map_intercept = isometric_math_utility.isoToMapCoord(.{ .x = map_side_intercepts_right_win.bottom_right.yes.x, .y = map_side_intercepts_right_win.bottom_right.yes.y }, map_position_x, map_position_y).?,
            } };
            return;
            //window is on the upper side of the right tip of the map
        } else if (window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right and window_map_positions.bottom_right.not_on_map.boundry_violation == Boundry.upper_right) {
            this_data.window_map_side_case = .{ .uper_side = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
            } };
            return;
            //window is in the middle and right tip of the map is within the window
        } else if (window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right and window_map_positions.bottom_right.not_on_map.boundry_violation == Boundry.bottom_right) {
            const upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left);
            this_data.window_map_side_case = .{ .center = .{
                .upper_window_map_boundry = upper_window_map_boundry,
                .most_right = isometric_math_utility.walkMapCoordFullSouthEast(&upper_window_map_boundry),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
            } };
            return;
            //window is on the bottom side of the right tip of the map
        } else if (window_map_positions.upper_right.not_on_map.boundry_violation == Boundry.upper_right and window_map_positions.bottom_right.not_on_map.boundry_violation == Boundry.bottom_right) {
            this_data.window_map_side_case = .{ .bottom_side = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
            } };
            return;
        }
    }
    fn initUpperLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperleft;
        _ = window_map_positions;

        //TODO: remove the inline creations of Points and use the Point that is given in the window_corner_point struct
        this_data.upper_left = isometric_math_utility.isoToMapCoord(window_corner_points.upper_left, map_position_x, map_position_y).?;

        const linear_eq_top_win = LinearEquation{ .has_slope = .{ .m = 0, .b = window_corner_points.upper_left.y } };
        const map_side_intercept_upper_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_top_win, &window_corner_points.upper_left, &window_corner_points.upper_right, map_position_x, map_position_y);

        const linear_eq_left_win = LinearEquation{ .vertical = .{ .a = window_corner_points.upper_left.x } };
        const map_side_intercept_left_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_left_win, &window_corner_points.upper_left, &window_corner_points.bottom_left, map_position_x, map_position_y);

        //intercepts upper right
        if (map_side_intercept_upper_win.upper_right == .yes) {
            const upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left);

            this_data.window_map_side_case = .{ .intercepts_upper_right = .{
                .upper_window_map_boundry = upper_window_map_boundry,
                .most_right = isometric_math_utility.walkMapCoordFullSouthEast(&upper_window_map_boundry),
            } };
            return;
            //intercepts bottom_left
        } else if (map_side_intercept_left_win.bottom_left == .yes) {
            this_data.window_map_side_case = .{ .intercepts_bottom_left = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left),
            } };
            return;
            //bottom right
        } else {
            this_data.window_map_side_case = .{ .bottom_right = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.upper_left),
            } };
            return;
        }
    }
    fn initUpperRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.upperright;
        _ = window_map_positions;

        this_data.upper_right = isometric_math_utility.isoToMapCoord(window_corner_points.upper_right, map_position_x, map_position_y);

        const linear_eq_top_win = LinearEquation{ .has_slope = .{ .m = 0, .b = window_corner_points.upper_left.y } };
        const map_side_intercept_upper_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_top_win, &window_corner_points.upper_left, &window_corner_points.upper_right, map_position_x, map_position_y);

        const linear_eq_right_win = LinearEquation{ .vertical = .{ .a = window_corner_points.upper_right.x } };
        const map_side_intercept_right_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_right_win, &window_corner_points.upper_right, &window_corner_points.bottom_right, map_position_x, map_position_y);

        //itercepts upper left
        if (map_side_intercept_upper_win.upper_left == .yes) {
            this_data.window_map_side_case = .{ .intercepts_upper_left = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right),
            } };
            return;
            //intercepts bottom right
        } else if (map_side_intercept_right_win.bottom_right == .yes) {
            this_data.window_map_side_case = .{ .intercepts_bottom_right = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullSouth(&this_data.upper_right),
            } };
            return;
            //bottom left
        } else {
            this_data.window_map_side_case = .{ .bottom_left = .{
                .upper_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.upper_right),
            } };
            return;
        }
    }
    fn initBottomRight(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomright;
        _ = window_map_positions;

        this_data.bottom_right = isometric_math_utility.isoToMapCoord(window_corner_points.bottom_right, map_position_x, map_position_y);

        const linear_eq_right_win = LinearEquation{ .vertical = .{ .a = window_corner_points.upper_right.x } };
        const map_side_intercept_right_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_right_win, &window_corner_points.upper_right, &window_corner_points.bottom_right, map_position_x, map_position_y);

        const linear_eq_bottom_win = LinearEquation{ .has_slope = .{ .m = 0, .b = window_corner_points.bottom_left.y } };
        const map_side_intercept_bottom_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_bottom_win, &window_corner_points.bottom_left, &window_corner_points.bottom_right, map_position_x, map_position_y);

        //intercepts upper right
        if (map_side_intercept_right_win.upper_right == .yes) {
            const right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right);

            this_data.window_map_side_case = .{ .intercepts_upper_right = .{
                .right_window_map_boundry = right_window_map_boundry,
                .most_top = isometric_math_utility.walkMapCoordFullNorthWest(&right_window_map_boundry),
            } };
            return;
            //intercepts bottom left
        } else if (map_side_intercept_bottom_win.bottom_left == .yes) {
            this_data.window_map_side_case = .{ .intercepts_bottom_left = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.bottom_right),
            } };
            return;
            //upper left
        } else {
            this_data.window_map_side_case = .{ .upper_left = .{
                .right_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_right),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullWest(&this_data.bottom_right),
            } };
            return;
        }
    }
    fn initBottomLeft(this: *@This(), window_corner_points: *WindowCornerPoints, window_map_positions: *const WindowMapPositions, map_position_x: i32, map_position_y: i32, isometric_math_utility: *const IsometricMathUtility) void {
        const this_data = &this.data.bottomleft;
        _ = window_map_positions;

        this_data.bottom_left = isometric_math_utility.isIsoPointOnMap(window_corner_points.bottom_left, map_position_x, map_position_y);

        const linear_eq_left_win = LinearEquation{ .vertical = .{ .a = window_corner_points.upper_left.x } };
        const map_side_intercept_left_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_left_win, &window_corner_points.upper_left, &window_corner_points.bottom_left, map_position_x, map_position_y);

        const linear_eq_bottom_win = LinearEquation{ .has_slope = .{ .m = 0, .b = window_corner_points.bottom_left.y } };
        const map_side_intercept_bottom_win = isometric_math_utility.doesLineInterceptMap(&linear_eq_bottom_win, &window_corner_points.bottom_left, &window_corner_points.bottom_right, map_position_x, map_position_y);

        //intercepts upper left
        if (map_side_intercept_left_win.upper_left == .yes) {
            const left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left);
            this_data.window_map_side_case = .{ .intercepts_upper_left = .{
                .left_window_map_boundry = left_window_map_boundry,
                .most_top = isometric_math_utility.walkMapCoordFullNorthEast(&left_window_map_boundry),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
            } };
            return;
            //intercepts bottom right
        } else if (map_side_intercept_bottom_win.bottom_right == .yes) {
            const left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left);

            this_data.window_map_side_case = .{ .intercepts_bottom_right = .{
                .left_window_map_boundry = left_window_map_boundry,
                .most_right = isometric_math_utility.walkMapCoordFullSouthEast(&left_window_map_boundry),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
            } };
            return;
            //upper right
        } else {
            this_data.window_map_side_case = .{ .upper_right = .{
                .left_window_map_boundry = isometric_math_utility.walkMapCoordFullNorth(&this_data.bottom_left),
                .bottom_window_map_boundry = isometric_math_utility.walkMapCoordFullEast(&this_data.bottom_left),
            } };
            return;
        }
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
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .bottom_left => |bottom_left| {
                        if (bottom_left.has_row_begin_reached_upper_left) {

                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        //ROW BEGIN
                        if (!bottom_left.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            bottom_left.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }

                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;
                    },

                    .center => |center| {
                        if (center.has_row_begin_reached_upper_left) {

                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        //ROW BEGIN
                        if (!center.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }

                        //ROW END
                        if (center.has_row_end_reached_map_boundry_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!center.has_row_end_reached_map_boundry_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end);

                            //CORNER REACHED
                            center.has_row_end_reached_map_boundry_right = this_data.row_end.hasEqualX(&center.right_window_map_boundry) orelse return null;
                        }
                    },
                    .bottom_right => |bottom_right| {
                        if (bottom_right.has_row_begin_reached_upper_left) {

                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        //ROW BEGIN
                        if (!bottom_right.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            bottom_right.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }

                        //ROW END
                        if (bottom_right.has_row_end_reached_map_boundry_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!bottom_right.has_row_end_reached_map_boundry_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            bottom_right.has_row_end_reached_map_boundry_right = this_data.row_end.hasEqualX(&bottom_right.right_window_map_boundry);
                        }
                    },
                    .center_bottom_map_intercept => |center_bottom_map_intercept| {

                        //ROW BEGIN
                        if (center_bottom_map_intercept.has_row_begin_reached_upper_left and center_bottom_map_intercept.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(center_bottom_map_intercept.bottom_window_left_map_intercept)) return null;
                        }

                        if (center_bottom_map_intercept.has_row_begin_reached_upper_left and !center_bottom_map_intercept.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center_bottom_map_intercept.has_row_begin_reached_map_boundry_left = this_data.row_begin.hasEqualY(center_bottom_map_intercept.left_window_map_boundry);
                        }

                        if (!center_bottom_map_intercept.has_row_begin_reached_upper_left and !center_bottom_map_intercept.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center_bottom_map_intercept.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }
                        //ROW END
                        if (center_bottom_map_intercept.has_row_end_reached_map_boundry_right and center_bottom_map_intercept.has_row_end_reached_map_boundry_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (center_bottom_map_intercept.has_row_end_reached_map_boundry_right and !center_bottom_map_intercept.has_row_end_reached_map_boundry_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center_bottom_map_intercept.has_row_end_reached_map_boundry_bottom_right = this_data.row_end.hasEqualY(&center_bottom_map_intercept.bottom_window_right_map_intercept);
                        }

                        if (!center_bottom_map_intercept.has_row_end_reached_map_boundry_right and !center_bottom_map_intercept.has_row_end_reached_map_boundry_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center_bottom_map_intercept.has_row_end_reached_map_boundry_right = this_data.row_end.hasEqualX(&center_bottom_map_intercept.right_window_map_boundry);
                        }
                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .bottom_left => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .center => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .bottom_right => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .center_bottom_map_intercept => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
            }
        }

        return this.current_coord;
    }

    fn handleUpperRightBottomRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperright_bottomright;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .upper_side => |upper_side| {

                        //ROW BEGIN

                        if (upper_side.has_row_begin_reached_map_boundry_upper) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterY(&upper_side.bottom_window_map_boundry)) return null;
                        }

                        if (!upper_side.has_row_begin_reached_map_boundry_upper) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            upper_side.has_row_begin_reached_map_boundry_upper = this_data.row_begin.hasEqualX(&upper_side.upper_window_map_boundry);
                        }

                        //ROW END
                        if (upper_side.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!upper_side.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            upper_side.has_row_end_reached_bottom_right = this_data.row_end.hasGreaterX(&this_data.bottom_right);
                        }
                    },
                    .center => |center| {

                        //ROW BEGIN
                        if (center.has_row_begin_reached_map_boundry_upper) {

                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        if (!center.has_row_begin_reached_map_boundry_upper) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordEastSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center.has_row_begin_reached_map_boundry_upper = this_data.row_begin.hasEqualX(&center.upper_window_map_boundry);
                        }

                        //ROW END
                        if (center.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!center.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .bottom_side => |bottom_side| {

                        //ROW BEGIN
                        //END OF SCREEN
                        this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_end;

                        //ROW END
                        if (bottom_side.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);
                        }

                        if (!bottom_side.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            bottom_side.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .center_leftside_map_intercept => |center_leftside_map_intercept| {

                        //ROW BEGIN
                        if (center_leftside_map_intercept.has_row_begin_reached_map_boundry_upper and center_leftside_map_intercept.has_row_begin_reached_map_boundry_left_upper) {
                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        if (center_leftside_map_intercept.has_row_begin_reached_map_boundry_upper and !center_leftside_map_intercept.has_row_begin_reached_map_boundry_left_upper) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center_leftside_map_intercept.has_row_begin_reached_map_boundry_left_upper = this_data.row_begin.hasEqualY(&center_leftside_map_intercept.left_window_upper_map_intercept);
                        }

                        if (!center_leftside_map_intercept.has_row_begin_reached_map_boundry_upper and !center_leftside_map_intercept.has_row_begin_reached_map_boundry_left_upper) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center_leftside_map_intercept.has_row_begin_reached_map_boundry_upper = this_data.row_begin.hasEqualX(&center_leftside_map_intercept.upper_window_map_boundry);
                        }

                        //ROW END
                        if (center_leftside_map_intercept.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!center_leftside_map_intercept.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center_leftside_map_intercept.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .upper_side => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .center => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .bottom_side => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .center_leftside_map_intercept => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
            }
        }

        return this.current_coord;
    }

    fn handleBottomRightBottomLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomright_bottomleft;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
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
                        if (upper_left.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!upper_left.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            upper_left.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
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
                        if (center.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!center.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
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
                    .center_upper_map_intercept => |center_upper_map_intercept| {
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
                .center_upper_map_intercept => |center_upper_map_intercept| {
                    this_data.row_begin = center_upper_map_intercept.upper_window_right_map_intercept;
                    this_data.row_end = center_upper_map_intercept.right_window_map_boundry;
                    this.current_coord = center_upper_map_intercept.upper_window_right_map_intercept;
                },
            }
        }

        return this.current_coord;
    }
    fn handleBottomLeftUpperLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomleft_upperleft;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .upper_side => |upper_side| {

                        //ROW BEGIN
                        if (upper_side.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }

                        if (!upper_side.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            upper_side.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }
                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);
                    },
                    .center => |center| {

                        //ROW BEGIN
                        if (center.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }

                        if (!center.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }

                        //ROW END
                        if (center.hase_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!center.hase_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center.hase_row_end_reached_map_boundry_bottom = this_data.row_end.hasEqualY(&center.bottom_window_map_boundry);
                        }
                    },
                    .bottom_side => |bottom_side| {

                        //ROW BEGIN
                        if (bottom_side.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            //TODO: check if the use of hasGreaterX function is correct. There might be the nid of a hasLowerX
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }

                        if (!bottom_side.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            bottom_side.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }

                        //ROW END
                        if (bottom_side.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!bottom_side.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            bottom_side.has_row_end_reached_map_boundry_bottom = this_data.row_end.hasEqualY(&bottom_side.bottom_window_map_boundry);
                        }
                    },
                    .center_rightside_map_intercept => |center_rightside_map_intercept| {
                        //ROW BEGIN
                        if (center_rightside_map_intercept.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }

                        if (!center_rightside_map_intercept.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin);
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            center_rightside_map_intercept.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }
                        //ROW END

                        if (center_rightside_map_intercept.has_row_end_reached_map_boundry_right_bottom and center_rightside_map_intercept.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (center_rightside_map_intercept.has_row_end_reached_map_boundry_right_bottom and !center_rightside_map_intercept.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;

                            //CORNER REACHED
                            center_rightside_map_intercept.has_row_end_reached_map_boundry_bottom = this_data.row_end.hasEqualY(&center_rightside_map_intercept.bottom_window_map_boundry);
                        }

                        if (!center_rightside_map_intercept.has_row_end_reached_map_boundry_right_bottom and !center_rightside_map_intercept.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            center_rightside_map_intercept.has_row_end_reached_map_boundry_right_bottom = this_data.row_end.hasEqualX(&center_rightside_map_intercept.right_window_bottom_map_intercept);
                        }
                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .upper_side => |upper_side| {
                    this_data.row_begin = upper_side.upper_window_map_boundry;
                    this_data.row_end = upper_side.bottom_window_map_boundry;
                    this.current_coord = upper_side.upper_window_map_boundry;
                },
                .center => |center| {
                    this_data.row_begin = center.upper_window_map_boundry;
                    this_data.row_end = center.most_right;
                    this.current_coord = center.upper_window_map_boundry;
                },
                .bottom_side => |bottom_side| {
                    this_data.row_begin = bottom_side.upper_window_map_boundry;
                    this_data.row_end = bottom_side.upper_window_map_boundry;
                    this.current_coord = bottom_side.upper_window_map_boundry;
                },
                .center_rightside_map_intercept => |center_rightside_map_intercept| {
                    this_data.row_begin = center_rightside_map_intercept.upper_window_map_boundry;
                    this_data.row_end = center_rightside_map_intercept.right_window_upper_map_intercept;
                    this.current_coord = center_rightside_map_intercept.upper_window_map_boundry;
                },
            }
        }

        return this.current_coord;
    }
    fn handleUpperLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperleft;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .intercepts_upper_right => |intercepts_upper_right| {
                        if (intercepts_upper_right.has_row_begin_reached_upper_left) {
                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        //ROW BEGIN
                        if (!intercepts_upper_right.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            intercepts_upper_right.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(this_data.upper_left);
                        }
                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end);
                    },
                    .bottom_right => |bottom_right| {
                        //ROW BEGIN
                        if (bottom_right.has_row_begin_reached_upper_left) {
                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        if (!bottom_right.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            bottom_right.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }

                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;
                    },
                    .intercepts_bottom_left => |intercepts_bottom_left| {

                        //ROW BEGIN
                        if (intercepts_bottom_left.has_row_begin_reached_upper_left) {
                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        if (!intercepts_bottom_left.has_row_begin_reached_upper_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            intercepts_bottom_left.has_row_begin_reached_upper_left = this_data.row_begin.hasEqualX(&this_data.upper_left);
                        }
                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;
                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .intercepts_upper_right => |intercepts_upper_right| {
                    this_data.row_begin = intercepts_upper_right.upper_window_map_boundry;
                    this_data.row_end = intercepts_upper_right.most_right;
                    this.current_coord = intercepts_upper_right.upper_window_map_boundry;
                },
                .bottom_right => |bottom_right| {
                    this_data.row_begin = bottom_right.upper_window_map_boundry;
                    this_data.row_end = bottom_right.upper_window_map_boundry;
                    this.current_coord = bottom_right.upper_window_map_boundry;
                },
                .intercepts_bottom_left => |intercepts_bottom_left| {
                    this_data.row_begin = intercepts_bottom_left.upper_window_map_boundry;
                    this_data.row_end = intercepts_bottom_left.upper_window_map_boundry;
                    this.current_coord = intercepts_bottom_left.upper_window_map_boundry;
                },
            }
        }

        return this.current_coord;
    }
    fn handleUpperRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.upperright;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .intercepts_upper_left => |intercepts_upper_left| {
                        //ROW BEGIN
                        if (intercepts_upper_left.has_row_begin_reached_map_boundry_upper) {
                            //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        }

                        if (!intercepts_upper_left.has_row_begin_reached_map_boundry_upper) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            intercepts_upper_left.has_row_begin_reached_map_boundry_upper = this_data.row_begin.hasEqualX(&intercepts_upper_left.upper_window_map_boundry);
                        }
                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;
                    },
                    .bottom_left => |bottom_left| {
                        _ = bottom_left;
                        //ROW BEGIN
                        //END OF SCREEN
                        this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_begin;
                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;
                    },
                    .intercepts_bottom_right => |intercepts_bottom_right| {
                        //ROW BEGIN
                        //END OF SCREEN
                        this_data.row_begin = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_begin);
                        this.current_coord = this_data.row_begin;
                        //ROW END
                        if (intercepts_bottom_right.has_row_end_reached_map_boundry_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;
                        }

                        if (!intercepts_bottom_right.has_row_end_reached_map_boundry_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;

                            //CORNER REACHED
                            intercepts_bottom_right.has_row_end_reached_map_boundry_right = this_data.row_end.hasEqualX(&intercepts_bottom_right.right_window_map_boundry);
                        }
                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .intercepts_upper_left => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .bottom_left => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
                .intercepts_bottom_right => {
                    this_data.row_begin = this_data.upper_right;
                    this_data.row_end = this_data.upper_right;
                    this.current_coord = this_data.upper_right;
                },
            }
        }

        return this.current_coord;
    }
    fn handleBottomRight(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomright;

        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .intercepts_upper_right => |intercepts_upper_right| {
                        //ROW BEGIN
                        //END OF SCREEN
                        this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_begin;
                        //ROW END
                        if (intercepts_upper_right.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }
                        if (!intercepts_upper_right.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            intercepts_upper_right.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .upper_left => |upper_left| {
                        //ROW BEGIN
                        //END OF SCREEN
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;
                        //ROW END
                        if (upper_left.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }
                        if (!upper_left.has_row_end_reached_bottom_right) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            upper_left.has_row_end_reached_bottom_right = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                    .intercepts_bottom_left => |intercepts_bottom_left| {
                        //ROW BEGIN
                        //END OF SCREEN
                        this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_begin;
                        //ROW END
                        if (intercepts_bottom_left.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }
                        if (!intercepts_bottom_left.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED
                            intercepts_bottom_left.has_row_end_reached_map_boundry_bottom = this_data.row_end.hasEqualX(&this_data.bottom_right);
                        }
                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                .intercepts_upper_right => |intercepts_upper_right| {
                    this_data.row_begin = intercepts_upper_right.right_window_map_boundry;
                    this_data.row_end = intercepts_upper_right.right_window_map_boundry;
                    this.current_coord = intercepts_upper_right.right_window_map_boundry;
                },
                .upper_left => |upper_left| {
                    this_data.row_begin = upper_left.right_window_map_boundry;
                    this_data.row_end = upper_left.right_window_map_boundry;
                    this.current_coord = upper_left.right_window_map_boundry;
                },
                .intercepts_bottom_left => |intercepts_bottom_left| {
                    this_data.row_begin = intercepts_bottom_left.right_window_map_boundry;
                    this_data.row_end = intercepts_bottom_left.right_window_map_boundry;
                    this.current_coord = intercepts_bottom_left.right_window_map_boundry;
                },
            }
        }

        return this.current_coord;
    }
    fn handleBottomLeft(this: *@This(), isometric_math_utility: *const IsometricMathUtility) ?Coord {
        const this_data = &this.data.bottomleft;

        //TODO: make if pointer capture
        if (this.current_coord) |this_current_coord| {
            if (this_current_coord.hasEqualX(&this_data.row_end)) {
                switch (this_data.window_map_side_case) {
                    .intercepts_upper_left => |intercepts_upper_left| {
                        //ROW BEGIN
                        if (intercepts_upper_left.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //END OF SCREEN
                            if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;
                        }                        
                        if (!intercepts_upper_left.has_row_begin_reached_map_boundry_left) {
                            this_data.row_begin = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_begin) orelse return null;
                            this.current_coord = this_data.row_begin;

                            //CORNER REACHED
                            intercepts_upper_left.has_row_begin_reached_map_boundry_left = this_data.row_begin.hasEqualY(&intercepts_upper_left.left_window_map_boundry);
                        }
                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);

                    },
                    .upper_right => |upper_right| {
                        _ = upper_right;
                        //ROW BEGIN
                        this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_begin;

                        //END OF SCREEN
                        if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;

                        //ROW END
                        this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end);

                    },
                    .intercepts_bottom_right => |intercepts_bottom_right| {
                        //ROW BEGIN
                        this_data.row_begin = isometric_math_utility.walkMapCoordSouthSingleMove(&this_data.row_begin) orelse return null;
                        this.current_coord = this_data.row_begin;

                        //END OF SCREEN
                        if (this_data.row_begin.hasGreaterX(&this_data.bottom_left)) return null;

                        //ROW END
                        if (intercepts_bottom_right.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordWestSingleMove(&this_data.row_end) orelse return null;
                        }
                        if (!intercepts_bottom_right.has_row_end_reached_map_boundry_bottom) {
                            this_data.row_end = isometric_math_utility.walkMapCoordSouthWestSingleMove(&this_data.row_end) orelse return null;

                            //CORNER REACHED    
                            intercepts_bottom_right.has_row_end_reached_map_boundry_bottom = this_data.row_end.hasEqualY(&intercepts_bottom_right.bottom_window_map_boundry);
                        }

                    },
                }
            } else {
                this.current_coord = isometric_math_utility.walkMapCoordSouthEastSingleMove(&this_current_coord) orelse return null;
            }
        }

        if (this.current_coord == null) {
            switch (this_data.window_map_side_case) {
                //TODO: make all captures capture by reference, allign caputure name (equal names), copy just the pointer not the the whole struct
                .intercepts_upper_left => |*intercepts_upper_left| {
                    this_data.row_begin = intercepts_upper_left.most_top;
                    this_data.row_end = intercepts_upper_left.bottom_window_map_boundry;
                    this.current_coord = intercepts_upper_left.most_top;
                },
                .upper_right => |upper_right| {
                    this_data.row_begin = upper_right.left_window_map_boundry;
                    this_data.row_end = upper_right.bottom_window_map_boundry;
                    this.current_coord = upper_right.left_window_map_boundry;
                },
                .intercepts_bottom_right => |intercepts_bottom_right| {
                    this_data.row_begin = intercepts_bottom_right.left_window_map_boundry;
                    this_data.row_end = intercepts_bottom_right.most_right;
                    this.current_coord = intercepts_bottom_right.left_window_map_boundry;
                },
            }
        }

        return this.current_coord;
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
