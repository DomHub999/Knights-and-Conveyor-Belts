const std = @import("std");
const rl = @import("raylib.zig");
const isometric = @import("isometric.zig");
const util = @import("utility.zig");


const magenta = rl.Color{ .r = 255, .g = 0, .b = 255, .a = 255 };

const inc_x = isometric.orthToIsoWrapIncrementX(TILE_SIZE_X);
const inc_y = isometric.orthToIsoWrapIncrementY(TILE_SIZE_Y);

// const TILE_SIZE_X: f32 = 127;
// const TILE_SIZE_Y: f32 = 96;

pub const TILE_SIZE_X: f32 = 129;
pub const TILE_SIZE_Y: f32 = 65;

const MAP_WIDTH: usize = 6;
const MAP_HEIGT: usize = 8;

const WINDOW_WIDTH: i32 = 800;
const WINDOW_HEIGHT: i32 = 600;

const Tile = enum {
    NONE,
    GRASS,
    DIRT,
    HOUSE,
};

var matrix = [MAP_WIDTH * MAP_HEIGT]Tile{
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
    .GRASS, .GRASS, .DIRT,  .HOUSE, .GRASS, .GRASS,
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
    .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS,
};

const runGame = @import("game.zig").runGame;

const imp_switch = true;

pub fn main() !void {
    if (imp_switch) {
        try runGame();
    } else {
        rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Knights and Conveyor Belts");

        
        var dirt_tile: rl.Image = undefined;
        var house_tile: rl.Image = undefined;

        var grass_tile: rl.Image = undefined;
        grass_tile = rl.LoadImage("resources/grey_tile.png");
        rl.ImageColorReplace(&grass_tile, magenta, rl.BLANK);
        const grass_sprite = rl.LoadTextureFromImage(grass_tile);

        dirt_tile = rl.LoadImage("resources/tree.png");
        rl.ImageColorReplace(&dirt_tile, magenta, rl.BLANK);
        const dirt_sprite = rl.LoadTextureFromImage(dirt_tile);

        house_tile = rl.LoadImage("resources/house.png");
        rl.ImageColorReplace(&house_tile, magenta, rl.BLANK);
        const house_sprite = rl.LoadTextureFromImage(house_tile);

        const iso_matrix = isometric.Iso.new(TILE_SIZE_X, TILE_SIZE_Y);

        var map_position_x: i32 = 0;
        var map_position_y: i32 = 0;

        const map_movement_increment: i32 = 10;

        while (!rl.WindowShouldClose()) {
            const button_up = rl.IsKeyPressedRepeat(rl.KEY_W);
            const button_down = rl.IsKeyPressedRepeat(rl.KEY_S);
            const button_left = rl.IsKeyPressedRepeat(rl.KEY_A);
            const button_right = rl.IsKeyPressedRepeat(rl.KEY_D);

            if (button_up) map_position_y -= map_movement_increment;
            if (button_down) map_position_y += map_movement_increment;
            if (button_left) map_position_x -= map_movement_increment;
            if (button_right) map_position_x += map_movement_increment;

            var buf_mouse_x = [_]u8{0} ** 16;
            var buf_mouse_y = [_]u8{0} ** 16;
            buf_mouse_x[0] = 'X';
            buf_mouse_x[1] = ':';
            buf_mouse_x[2] = ' ';
            buf_mouse_y[0] = 'Y';
            buf_mouse_y[1] = ':';
            buf_mouse_y[2] = ' ';

            var mouse_x: i32 = 0;
            var mouse_y: i32 = 0;

            var mouse_on_screen = false;
            if (rl.IsCursorOnScreen()) {
                mouse_on_screen = true;
                mouse_x = rl.GetMouseX();
                mouse_y = rl.GetMouseY();
                if (mouse_x >= 0 and mouse_y >= 0) {
                    util.usizeToString(@intCast(mouse_x), buf_mouse_x[3..]);
                    util.usizeToString(@intCast(mouse_y), buf_mouse_y[3..]);
                }
            } else {
                mouse_on_screen = false;
            }

            var buf_mouse_map_idx = [_]u8{0} ** 16;
            var buf_grid_x = [_]u8{0} ** 16;
            var buf_grid_y = [_]u8{0} ** 16;

            const orth_coords = iso_matrix.isoToOrth(mouse_x, mouse_y, map_position_x, map_position_y);

            if (orth_coords) |coords| {
                const map_index = util.indexTwoDimArray(coords.orth_x, coords.orth_y, MAP_WIDTH);
                if (map_index < MAP_WIDTH * MAP_HEIGT) {
                    util.usizeToString(map_index, &buf_mouse_map_idx);
                    util.usizeToString(coords.orth_x, &buf_grid_x);
                    util.usizeToString(coords.orth_y, &buf_grid_y);
                    if (mouse_on_screen and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                        matrix[map_index] = switch (matrix[map_index]) {
                            .GRASS => .NONE,
                            .NONE => .GRASS,
                            else => .GRASS,
                        };
                    }
                }
            }

            rl.BeginDrawing();
            rl.ClearBackground(rl.BLACK);

            var skip_x: ?usize = null;
            var skip_y: ?usize = null;

            for (0..MAP_HEIGT) |y| {
                for (0..MAP_WIDTH) |x| {
                    const tile = matrix[util.indexTwoDimArray(x, y, MAP_WIDTH)];

                    if (tile == .NONE) continue;
                    if (skip_x != null and skip_y != null) {
                        if (x <= skip_x.? and y <= skip_y.?) {
                            continue;
                        }
                    }

                    const spr = switch (tile) {
                        .GRASS => grass_sprite,
                        .DIRT => dirt_sprite,
                        .HOUSE => house_sprite,
                        else => grass_sprite,
                    };

                    var trans_coords = iso_matrix.orthToIso(x, y, map_position_x, map_position_y);

                    if (tile == .DIRT) trans_coords.iso_y -= TILE_SIZE_Y;
                    if (tile == .HOUSE) {
                        trans_coords.iso_y -= TILE_SIZE_Y;
                        skip_x = x + 1;
                        skip_y = y;
                    }

                    rl.DrawTextureEx(spr, rl.Vector2{ .x = trans_coords.iso_x, .y = trans_coords.iso_y }, 0, 1, rl.WHITE);
                }
            }

            rl.DrawText(&buf_mouse_x, 10, 10, 16, rl.WHITE);
            rl.DrawText(&buf_mouse_y, 10, 26, 16, rl.WHITE);

            rl.DrawText(&buf_grid_x, 10, 45, 22, rl.BEIGE);
            rl.DrawText(&buf_grid_y, 30, 45, 22, rl.BEIGE);

            rl.DrawText(&buf_mouse_map_idx, 10, 70, 22, rl.YELLOW);

            rl.EndDrawing();
        }

        rl.CloseWindow();
        rl.UnloadTexture(grass_sprite);
        rl.UnloadImage(grass_tile);
    }
}
