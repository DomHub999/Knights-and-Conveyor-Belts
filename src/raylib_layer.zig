const std = @import("std");
const Map = @import("map.zig").Map;
const Ground = @import("tile.zig").Ground;
const rl = @import("raylib.zig");
const Resources = @import("resources.zig").Resources;
const indexTwoDimArray = @import("utility.zig").indexTwoDimArray;
const Keyboard = @import("hardware.zig").Keyboard;

const ImgTex = struct {
    image: rl.Image,
    texture: rl.Texture2D,
};

const magenta = rl.Color{ .r = 255, .g = 0, .b = 255, .a = 255 };

pub const Drawer = struct {
    resources_ground: []ImgTex = undefined,

    pub fn initGroundSprites(this: *@This(), sprite_pathes_ground: []const []const u8) !void {
        this.resources_ground = try std.heap.page_allocator.alloc(ImgTex, sprite_pathes_ground.len);
        for (this.resources_ground, sprite_pathes_ground) |*this_ground, sprite_path| {
            this_ground.image = rl.LoadImage(sprite_path.ptr);
            rl.ImageColorReplace(&this_ground.image, magenta, rl.BLANK);
            this_ground.texture = rl.LoadTextureFromImage(this_ground.image);
        }
    }

    pub fn deinit(this: *@This()) void {
        for (this.resources_ground) |*ground| {
            rl.UnloadTexture(ground.texture);
            rl.UnloadImage(ground.image);
        }
        std.heap.page_allocator.free(this.resources_ground);
    }

    //TODO: remove debug
    const draw_all = false;

    pub fn drawMap(this: *@This(), map: *Map) void {
        if (draw_all) {
            for (0..map.map_tiles_height) |y| {
                for (0..map.map_tiles_width) |x| {
                    const tile = map.tile_map[indexTwoDimArray(x, y, map.map_tiles_width)];

                    const ground_tile = @intFromEnum(tile.ground);
                    const ground_tex = this.resources_ground[ground_tile].texture;

                    const iso_coordinates = map.isometric_math_utility.mapCoordToIso(.{ .map_array_coord_x = x, .map_array_coord_y = y }, map.map_position_x, map.map_position_y);
                    rl.DrawTextureEx(ground_tex, .{ .x = iso_coordinates.iso_pix_x, .y = iso_coordinates.iso_pix_y }, 0, 1, rl.WHITE);
                }
            }
        }

        if (!draw_all) {

            //TODO: remove debug
            if (rl.IsKeyDown(rl.KEY_P)) {
                @breakpoint();
            }

            map.tile_iterator.initialize(map.map_position_x, map.map_position_y);

            var text_category: [*]const u8 = "";
            var text_wmsc: [*]const u8 = "";

            switch (map.tile_iterator.case_handler.data) {
                .all_points => {
                    text_category =
                        "ALL_POINTS";
                },
                .upperleft_upperright_bottomright => {
                    text_category =
                        "UPPERLEFT_UPPERRIGHT_BOTTOMRIGHT";
                },
                .upperright_bottomright_bottomleft => {
                    text_category =
                        "UPPERRIGHT_BOTTOMRIGHT_BOTTOMLEFT";
                },
                .bottomright_bottomleft_upperleft => {
                    text_category =
                        "BOTTOMRIGHT_BOTTOMLEFT_UPPERLEFT";
                },
                .bottomleft_upperleft_upperright => {
                    text_category =
                        "BOTTOMLEFT_UPPERLEFT_UPPERRIGHT";
                },
                .upperleft_upperright => {
                    text_category =
                        "UPPERLEFT_UPPERRIGHT";
                    switch (map.tile_iterator.case_handler.data.upperleft_upperright.window_map_side_case) {
                        .bottom_left => {
                            text_wmsc = "BOTTOM_LEFT";
                        },
                        .center => {
                            text_wmsc = "CENTER";
                        },
                        .bottom_right => {
                            text_wmsc = "BOTTOM_RIGHT";
                        },
                        .center_bottom_map_intercept => {
                            text_wmsc = "CENTER_BOTTOM_MAP_INTERCEPT";
                        },
                    }
                },
                .upperright_bottomright => {
                    text_category =
                        "UPPERRIGHT_BOTTOMRIGHT";
                    switch (map.tile_iterator.case_handler.data.upperright_bottomright.window_map_side_case) {
                        .upper_side => {
                            text_wmsc = "UPPER_SIDE";
                        },
                        .center => {
                            text_wmsc = "CENTER";
                        },
                        .bottom_side => {
                            text_wmsc = "BOTTOM_SIDE";
                        },
                        .center_leftside_map_intercept => {
                            text_wmsc = "CENTER_LEFTSIDE_MAP_INTERCEPT";
                        },
                    }
                },
                .bottomright_bottomleft => {
                    text_category =
                        "BOTTOMRIGHT_BOTTOMLEFT";
                    switch (map.tile_iterator.case_handler.data.bottomright_bottomleft.window_map_side_case) {
                        .upper_left => {
                            text_wmsc = "UPPER_LEFT";
                        },
                        .center => {
                            text_wmsc = "CENTER";
                        },
                        .upper_right => {
                            text_wmsc = "UPPER_RIGHT";
                        },
                        .center_upper_map_intercept => {
                            text_wmsc = "CENTER_UPPER_MAP_INTERCEPT";
                        },
                    }
                },
                .bottomleft_upperleft => {
                    text_category =
                        "BOTTOMLEFT_UPPERLEFT";
                    switch (map.tile_iterator.case_handler.data.bottomleft_upperleft.window_map_side_case) {
                        .upper_side => {
                            text_wmsc = "UPPER_SIDE";
                        },
                        .center => {
                            text_wmsc = "CENTER";
                        },
                        .bottom_side => {
                            text_wmsc = "BOTTOM_SIDE";
                        },
                        .center_rightside_map_intercept => {
                            text_wmsc = "CENTER_RIGHTSIDE_MAP_INTERCEPT";
                        },
                    }
                },
                .upperleft => {
                    text_category =
                        "UPPERLEFT";
                    switch (map.tile_iterator.case_handler.data.upperleft.window_map_side_case) {
                        .intercepts_upper_right => {
                            text_wmsc = "INTERCEPTS_UPPER_RIGHT";
                        },
                        .bottom_right => {
                            text_wmsc = "BOTTOM_RIGHT";
                        },
                        .intercepts_bottom_left => {
                            text_wmsc = "INTERCEPTS_BOTTOM_LEFT";
                        },
                    }
                },
                .upperright => {
                    text_category =
                        "UPPERRIGHT";
                    switch (map.tile_iterator.case_handler.data.upperright.window_map_side_case) {
                        .intercepts_upper_left => {
                            text_wmsc = "INTERCEPTS_UPPER_LEFT";
                        },
                        .bottom_left => {
                            text_wmsc = "BOTTOM_LEFT";
                        },
                        .intercepts_bottom_right => {
                            text_wmsc = "INTERCEPTS_BOTTOM_RIGHT";
                        },
                    }
                },
                .bottomright => {
                    text_category =
                        "BOTTOMRIGHT";
                    switch (map.tile_iterator.case_handler.data.bottomright.window_map_side_case) {
                        .intercepts_upper_right => {
                            text_wmsc = "INTERCEPTS_UPPER_RIGHT";
                        },
                        .upper_left => {
                            text_wmsc = "UPPER_LEFT";
                        },
                        .intercepts_bottom_left => {
                            text_wmsc = "INTERCEPTS_BOTTOM_LEFT";
                        },
                    }
                },
                .bottomleft => {
                    text_category =
                        "BOTTOMLEFT";
                    switch (map.tile_iterator.case_handler.data.bottomleft.window_map_side_case) {
                        .intercepts_upper_left => {
                            text_wmsc = "INTERCEPTS_UPPER_LEFT";
                        },
                        .upper_right => {
                            text_wmsc = "UPPER_RIGHT";
                        },
                        .intercepts_bottom_right => {
                            text_wmsc = "INTERCEPTS_BOTTOM_RIGHT";
                        },
                    }
                },
                .none => {
                    text_category =
                        "NONE";
                    switch (map.tile_iterator.case_handler.data.none.window_map_side_case) {
                        .map_inside_window => {
                            text_wmsc = "MAP_INSIDE_WINDOW";
                        },
                        .map_outside_window => {
                            text_wmsc = "MAP_OUTSIDE_WINDOW";
                        },
                        .top => {
                            text_wmsc = "TOP";
                        },
                        .right => {
                            text_wmsc = "RIGHT";
                        },
                        .bottom => {
                            text_wmsc = "BOTTOM";
                        },
                        .left => {
                            text_wmsc = "LEFT";
                        },
                    }
                },
            }

            //TODO: remove debug
            if (rl.IsKeyDown(rl.KEY_L)) {
                @breakpoint();
            }

            while (map.tile_iterator.next()) |tile_coord| {
                if (tile_coord.map_array_coord_x == 50 and tile_coord.map_array_coord_y == 49) {
                    const dbug: usize = 0;
                    _ = dbug;
                }

                const idx = indexTwoDimArray(tile_coord.map_array_coord_x, tile_coord.map_array_coord_y, map.map_tiles_width);

                const tile = map.tile_map[idx];

                const tile_map_size = map.tile_map.len;
                _ = tile_map_size;

                const ground_tile = @intFromEnum(tile.ground);
                const ground_tex = this.resources_ground[ground_tile].texture;

                const iso_coordinates = map.isometric_math_utility.mapCoordToIso(.{ .map_array_coord_x = tile_coord.map_array_coord_x, .map_array_coord_y = tile_coord.map_array_coord_y }, map.map_position_x, map.map_position_y);
                rl.DrawTextureEx(ground_tex, .{ .x = iso_coordinates.iso_pix_x, .y = iso_coordinates.iso_pix_y }, 0, 1, rl.WHITE);
            }

            rl.DrawText(text_category, 10, 70, 22, rl.WHITE);
            rl.DrawText(text_wmsc, 10, 90, 22, rl.WHITE);
        }
    }

    pub fn initializeWindow(_: *@This(), width: i32, height: i32, name: []const u8) void {
        rl.InitWindow(width, height, name.ptr);
    }

    pub fn initializeScreen(_: *@This()) void {
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
    }

    pub fn finalizeScreen(_: *@This()) void {
        rl.EndDrawing();
    }

    pub fn finalizeWindow(_: *@This()) void {
        rl.CloseWindow();
    }

    pub fn exitCommand(_: *@This()) bool {
        return rl.WindowShouldClose();
    }
};

pub const Hardware = struct {
    pub fn getMousePosition() struct { x: f32, y: f32 } {
        const mouse_position = rl.GetMousePosition();
        return .{ .x = mouse_position.x, .y = mouse_position.y };
    }

    const KeyMapping = [@typeInfo(Keyboard).@"enum".fields.len]i32;
    fn makeKeyMapping() KeyMapping {
        var key_map: KeyMapping = undefined;
        key_map[@intFromEnum(Keyboard.move_map_left)] = rl.KEY_A;
        key_map[@intFromEnum(Keyboard.move_map_right)] = rl.KEY_D;
        key_map[@intFromEnum(Keyboard.move_map_up)] = rl.KEY_W;
        key_map[@intFromEnum(Keyboard.move_map_down)] = rl.KEY_S;
        return key_map;
    }
    const key_mapping = makeKeyMapping();

    pub fn isKeyPressed(key: Keyboard) bool {
        return rl.IsKeyDown(key_mapping[@intFromEnum(key)]);
    }
};

//debugging
pub fn drawCoordinates(x: i32, y: i32) void {
    rl.DrawText(rl.TextFormat("%d", x), 10, 10, 22, rl.WHITE);
    rl.DrawText(rl.TextFormat("%d", y), 10, 40, 22, rl.WHITE);
}
