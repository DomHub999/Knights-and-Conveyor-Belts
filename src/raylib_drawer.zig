const std = @import("std");
const Map = @import("map.zig").Map;
const Ground = @import("tile.zig").Ground;
const rl = @import("raylib.zig");
const Resources = @import("resources.zig").Resources;
const indexTwoDimArray = @import("utility.zig").indexTwoDimArray;

const ImgTex = struct {
    image: rl.Image,
    texture: rl.Texture2D,
};

const magenta = rl.Color{ .r = 255, .g = 0, .b = 255, .a = 255 };



pub const Drawer = struct {
    resources_ground: []ImgTex = undefined,

    pub fn initGroundSprites(this: *@This(), sprite_pathes_ground: []const[]const u8) !void {
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

    pub fn drawMap(this: *@This(), map: *Map) void {
        for (0..map.map_tiles_height) |y| {
            for (0..map.map_tiles_width) |x| {
                const tile = map.tile_map[indexTwoDimArray(x, y, map.map_tiles_width)];

                const ground_tile = @intFromEnum(tile.ground);
                const ground_tex = this.resources_ground[ground_tile].texture;

                const iso_coordinates = map.iso.orthToIso(x, y, map.map_position_x, map.map_position_y);

                rl.DrawTextureEx(ground_tex, .{ .x = iso_coordinates.iso_x, .y = iso_coordinates.iso_y }, 0, 1, rl.WHITE);
            }
        }
    }

    pub fn initializeWindow(_:*@This(),width: i32, height: i32, name: []const u8) void {
        rl.InitWindow(width, height, name.ptr);
    }

    pub fn initializeScreen(_:*@This()) void {
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
    }

    pub fn finalizeScreen(_:*@This()) void {
        rl.EndDrawing();
    }

    pub fn finalizeWindow(_:*@This()) void {
        rl.CloseWindow();
    }

    pub fn exitCommand(_:*@This()) bool {
        return rl.WindowShouldClose();
    }
};
