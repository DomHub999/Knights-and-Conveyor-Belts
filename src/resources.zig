const Ground = @import("tile.zig").Ground;

const GroundSpriteSourceType = [@typeInfo(Ground).@"enum".fields.len][]const u8;
fn makeGroundSpriteSource() GroundSpriteSourceType {
    var this_ground_sprite_source: GroundSpriteSourceType = undefined;
    this_ground_sprite_source[@intFromEnum(Ground.grass)] = "resources/grass.png";
    this_ground_sprite_source[@intFromEnum(Ground.dirt)] = "resources/dirt.png";
    return this_ground_sprite_source;
}
pub const ground_sprite_source = makeGroundSpriteSource();
