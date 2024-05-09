const std = @import("std");

pub const Ground = enum(u8){
    grass,
    dirt,
};

pub const AboveGroundType = enum(u8){

};

pub const Structure = struct{
    above_ground:AboveGroundType,
    tiles_height:usize,
    tiles_width:usize,
    seating:bool,
    unit_number:u16,
};

pub const Tile = struct{
    ground:Ground,
    above_ground:?Structure = null,
};



