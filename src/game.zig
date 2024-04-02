const Drawer = @import("raylib_drawer.zig").Drawer;
const Map = @import("map.zig").Map;
const Ground = @import("tile.zig").Ground;
const resources = @import("resources.zig");
const util = @import("utility.zig");

const MAP_TILE_WIDTH: usize = 10 * 5;
const MAP_TILE_HEIGHT: usize = 10 * 5;

const WINDOW_PIX_WIDTH: i32 = 800;
const WINDOW_PIX_HEIGHT: i32 = 600;

const TILE_PIX_WIDTH: f32 = 64;
const TILE_PIX_HEIGHT: f32 = 32;

pub fn runGame() !void {
    var map = try Map.new(
        MAP_TILE_WIDTH,
        MAP_TILE_HEIGHT,
        TILE_PIX_WIDTH,
        TILE_PIX_HEIGHT,
        WINDOW_PIX_WIDTH,
        WINDOW_PIX_HEIGHT,
    );
    defer map.deinit();

    try map.initGround(&ground_tiles);

    var drawer = Drawer{};

    drawer.initializeWindow(WINDOW_PIX_WIDTH, WINDOW_PIX_HEIGHT, "Knights and conveyor belts");
    defer drawer.finalizeWindow();

    try drawer.initGroundSprites(&resources.ground_sprite_source);
    defer drawer.deinit();

    while (!drawer.exitCommand()) {
        drawer.initializeScreen();

        drawer.drawMap(&map);

        drawer.finalizeScreen();
    }
}

const ground_tiles = makeGroundTiles();

fn makeGroundTiles()[MAP_TILE_WIDTH * MAP_TILE_HEIGHT]Ground{

    @setEvalBranchQuota(100000);

    var ground_tile:[MAP_TILE_WIDTH * MAP_TILE_HEIGHT]Ground = undefined;

    for (0..MAP_TILE_HEIGHT) |y| {
        for (0..MAP_TILE_WIDTH) |x| {

            var tile_result:usize = @mod(x, 2);
            if (@mod(y, 2) == 0){
                tile_result = if (tile_result == 0) 1 else 0;
            }

            const tile = if (tile_result == 0) Ground.grass else Ground.dirt;

            ground_tile[util.indexTwoDimArray(x, y, MAP_TILE_WIDTH)] = tile;
        }
    }

    return ground_tile;
}
