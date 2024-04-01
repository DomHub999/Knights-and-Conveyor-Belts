const Drawer = @import("raylib_drawer.zig").Drawer;
const Map = @import("map.zig").Map;
const Ground = @import("tile.zig").Ground;
const resources = @import("resources.zig");


const MAP_TILE_WIDTH:usize = 10;
const MAP_TILE_HEIGHT:usize = 10;

const WINDOW_WIDTH: i32 = 800;
const WINDOW_HEIGHT: i32 = 600;

const TILE_PIX_WIDTH:f32 = 64;
const TILE_PIX_HEIGHT:f32 = 32;

pub fn runGame()!void{

    var map = try Map.new(MAP_TILE_WIDTH, MAP_TILE_HEIGHT, TILE_PIX_WIDTH, TILE_PIX_HEIGHT);
    defer map.deinit(); 
    
    try map.initGround(&ground_tiles);

    var drawer = Drawer{};
    
    drawer.initializeWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Knights and conveyor belts");
    defer drawer.finalizeWindow();

    try drawer.initGroundSprites(&resources.ground_sprite_source);
    defer drawer.deinit();

    while (!drawer.exitCommand()) {

        drawer.initializeScreen();

        drawer.drawMap(&map);

        drawer.finalizeScreen();
    }
}



const ground_tiles = [MAP_TILE_WIDTH * MAP_TILE_HEIGHT]Ground{
    .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass,
    .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt,
    .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass,
    .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt,
    .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass,
    .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt,
    .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass,
    .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt,
    .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass,
    .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt, .grass, .dirt,
};