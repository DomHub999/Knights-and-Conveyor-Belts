const std = @import("std");
const rl = @import("raylib.zig");
const isometric = @import("isometric.zig");
const util = @import("utility.zig");

var grass_tile: rl.Image = undefined;
var dirt_tile: rl.Image = undefined;
const magenta = rl.Color{ .r = 255, .g = 0, .b = 255, .a = 255 };

const inc_x = isometric.orthToIsoWrapIncrementX(TILE_SIZE_X);
const inc_y = isometric.orthToIsoWrapIncrementY(TILE_SIZE_Y);

// const TILE_SIZE_X: f32 = 127;
// const TILE_SIZE_Y: f32 = 96;

pub const TILE_SIZE_X: f32 = 129;
pub const TILE_SIZE_Y: f32 = 65;


const MAP_WIDTH: usize = 3;
const MAP_HEIGT: usize = 4;

const WINDOW_WIDTH: i32 = 800;
const WINDOW_HEIGHT: i32 = 600;

const Tile = enum {
    NONE,
    GRASS,
    DIRT,
};

var matrix = [MAP_WIDTH * MAP_HEIGT]Tile{ .GRASS, .GRASS, .GRASS, .NONE, .GRASS, .NONE, .GRASS, .GRASS, .GRASS, .GRASS, .GRASS, .NONE };


pub fn main() !void {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Knights and Conveyor Belts");

    grass_tile = rl.LoadImage("resources/grey_tile.png");
    rl.ImageColorReplace(&grass_tile, magenta, rl.BLANK);
    dirt_tile = rl.LoadImage("resources/dirt_tile.png");
    rl.ImageColorReplace(&dirt_tile, magenta, rl.BLANK);

    const grass_sprite = rl.LoadTextureFromImage(grass_tile);
    const dirt_sprite = rl.LoadTextureFromImage(dirt_tile);

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

        // var print_mouse_map_idx = false;
        var buf_mouse_map_idx = [_]u8{0} ** 16;
        var buf_grid_x = [_]u8{0} ** 16;
        var buf_grid_y = [_]u8{0} ** 16;

        

        const mouse_x_map_adj:i32 = mouse_x - map_position_x;
        const mouse_y_map_adj:i32 = mouse_y - map_position_y;

        const grid_x = iso_matrix.isoToOrtX(mouse_x_map_adj, mouse_y_map_adj);
        const grid_y = iso_matrix.isoToOrtY(mouse_x_map_adj, mouse_y_map_adj);
        

        if (grid_x != null and grid_y != null) {
            const map_index = util.indexTwoDimArray(grid_x.?, grid_y.?, MAP_WIDTH);
            if (map_index < MAP_WIDTH * MAP_HEIGT) {
                // print_mouse_map_idx = true;
                util.usizeToString(map_index, &buf_mouse_map_idx);
                util.usizeToString(grid_x.?, &buf_grid_x);
                util.usizeToString(grid_y.?, &buf_grid_y);
                if (mouse_on_screen and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                    matrix[map_index] = switch(matrix[map_index]){
                        .GRASS => .NONE,
                        .NONE => .GRASS,
                        else => .GRASS,
                    };
                    // matrix[map_index] = .GRASS;
                }
            }
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        for (0..MAP_WIDTH) |x| {
            for (0..MAP_HEIGT) |y| {
                const tile = matrix[util.indexTwoDimArray(x, y, MAP_WIDTH)];

                if (tile == .NONE) continue;

                const spr = switch (tile) {
                    .GRASS => grass_sprite,
                    .DIRT => dirt_sprite,
                    else => grass_sprite,
                };

                var trans_x = iso_matrix.ortToIsoX(x, y);
                var trans_y = iso_matrix.ortToIsoY(x, y);

                trans_x += @floatFromInt(map_position_x);
                trans_y += @floatFromInt(map_position_y);

                rl.DrawTextureEx(spr, rl.Vector2{ .x = trans_x, .y = trans_y }, 0, 1, rl.WHITE);
            }
        }

        rl.DrawText(&buf_mouse_x, 10, 10, 16, rl.WHITE);
        rl.DrawText(&buf_mouse_y, 10, 26, 16, rl.WHITE);

        rl.DrawText(&buf_grid_x, 10, 45, 22, rl.BEIGE);
        rl.DrawText(&buf_grid_y, 30, 45, 22, rl.BEIGE);

        rl.DrawText(&buf_mouse_map_idx, 10, 70, 22, rl.YELLOW);

   

        // rl.DrawText(rl.TextFormat("%f", isometric.c_cell_x), 160, 120 + 60, 22, rl.RED);
        // rl.DrawText(rl.TextFormat("%f", isometric.c_cell_y), 160, 140 + 60, 22, rl.RED);
        // rl.DrawText(rl.TextFormat("%f", isometric.ort_x_f), 160, 120 + 100, 22, rl.GREEN);
        // rl.DrawText(rl.TextFormat("%f", isometric.ort_y_f), 160, 140 + 100, 22, rl.GREEN);


        rl.EndDrawing();
    }

    rl.CloseWindow();
    rl.UnloadTexture(grass_sprite);
    rl.UnloadImage(grass_tile);
}
