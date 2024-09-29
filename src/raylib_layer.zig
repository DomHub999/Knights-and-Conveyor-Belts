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
            map.tile_iterator.initialize(map.map_position_x, map.map_position_y);

            var text: [*]const u8 = "";

            switch (map.tile_iterator.case_handler.data) {
                .all_points => text = "ALL_POINTS",
                .upperleft_upperright_bottomright => text = "UPPERLEFT_UPPERRIGHT_BOTTOMRIGHT",
                .upperright_bottomright_bottomleft => text = "UPPERRIGHT_BOTTOMRIGHT_BOTTOMLEFT",
                .bottomright_bottomleft_upperleft => text = "BOTTOMRIGHT_BOTTOMLEFT_UPPERLEFT",
                .bottomleft_upperleft_upperright => text = "BOTTOMLEFT_UPPERLEFT_UPPERRIGHT",
                .upperleft_upperright => text = "UPPERLEFT_UPPERRIGHT",
                .upperright_bottomright => text = "UPPERRIGHT_BOTTOMRIGHT",
                .bottomright_bottomleft => text = "BOTTOMRIGHT_BOTTOMLEFT",
                .bottomleft_upperleft => text = "BOTTOMLEFT_UPPERLEFT",
                .upperleft => text = "UPPERLEFT",
                .upperright => text = "UPPERRIGHT",
                .bottomright => text = "BOTTOMRIGHT",
                .bottomleft => text = "BOTTOMLEFT",
                .none => text = "NONE",
            }

            while (map.tile_iterator.next()) |tile_coord| {
                const tile = map.tile_map[indexTwoDimArray(tile_coord.map_array_coord_x, tile_coord.map_array_coord_y, map.map_tiles_width)];

                const ground_tile = @intFromEnum(tile.ground);
                const ground_tex = this.resources_ground[ground_tile].texture;

                const iso_coordinates = map.isometric_math_utility.mapCoordToIso(.{ .map_array_coord_x = tile_coord.map_array_coord_x, .map_array_coord_y = tile_coord.map_array_coord_y }, map.map_position_x, map.map_position_y);
                rl.DrawTextureEx(ground_tex, .{ .x = iso_coordinates.iso_pix_x, .y = iso_coordinates.iso_pix_y }, 0, 1, rl.WHITE);
            }

            rl.DrawText(text, 10, 70, 22, rl.WHITE);
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
