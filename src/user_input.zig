const Hardware = @import("raylib_layer.zig").Hardware;
const Keyboard = @import("hardware.zig").Keyboard;
const Map = @import("map.zig").Map;

pub fn deal_with_key_pressed(map: *Map) void {
    map_movement_direction(map);
}

fn map_movement_direction(map: *Map) void {
    if (Hardware.isKeyPressed(Keyboard.move_map_left)) map.move(Map.MovementDirection.right);
    if (Hardware.isKeyPressed(Keyboard.move_map_right)) map.move(Map.MovementDirection.left);
    if (Hardware.isKeyPressed(Keyboard.move_map_up)) map.move(Map.MovementDirection.down);
    if (Hardware.isKeyPressed(Keyboard.move_map_down)) map.move(Map.MovementDirection.up);
}
