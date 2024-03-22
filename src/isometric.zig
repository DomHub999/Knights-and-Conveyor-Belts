pub fn orthToIsoWrapIncrementX(tile_width: f32) f32 {
    return tile_width / 2;
}

pub fn orthToIsoWrapIncrementY(tile_height: f32) f32 {
    return tile_height / 2;
}

pub fn orthToIsoX(orth_x: f32, orth_y: f32, wrap_increment_x: f32) f32 {
    return (orth_x - orth_y) * wrap_increment_x;
}

pub fn orthToIsoY(orth_x: f32, orth_y: f32, wrap_increment_y: f32) f32 {
    return (orth_y + orth_x) * wrap_increment_y;
}

pub fn isoToOrthX(iso_x: f32, iso_y: f32, wrap_increment_x: f32, wrap_increment_y: f32) f32 {
    return (iso_x / wrap_increment_x + iso_y / wrap_increment_y) / 2;
}

pub fn isoToOrthY(iso_x: f32, iso_y: f32, wrap_increment_x: f32, wrap_increment_y: f32) f32 {
    return (iso_x / wrap_increment_x - iso_y / wrap_increment_y) / -2;
}

const main = @import("main.zig");
pub fn findIsoCurrentCellX(iso_x: f32, wrap_increment_x: f32) f32 {
        // _ = wrap_increment_x;
        // return iso_x;

        const a_wrap_increment_x = wrap_increment_x * 1;

        return @round((iso_x / a_wrap_increment_x) - 1) * a_wrap_increment_x;
        // return @round((iso_x / main.TILE_SIZE_X) - 1) * main.TILE_SIZE_X;
}

pub fn findIsoCurrentCellY(iso_y: f32, wrap_increment_y: f32) f32 {
        // _ = wrap_increment_y;
        // return iso_y;

        const a_wrap_increment_y = wrap_increment_y * 1;

        return @round((iso_y / a_wrap_increment_y) - 1) * a_wrap_increment_y;
        // return @round((iso_y / main.TILE_SIZE_Y) - 1) * main.TILE_SIZE_Y;

}

    pub var c_cell_x:f32 = 0;
    pub var c_cell_y:f32 = 0;

    pub var ort_x_f:f32 = 0;
    pub var ort_y_f:f32 = 0;


pub const Iso = struct {
    wrap_increment_x: f32,
    wrap_increment_y: f32,

    pub fn new(tile_width: f32, tile_height: f32) @This() {
        var this: @This() = undefined;
        this.wrap_increment_x = orthToIsoWrapIncrementX(tile_width);
        this.wrap_increment_y = orthToIsoWrapIncrementY(tile_height);
        return this;
    }

    pub fn ortToIsoX(this: *const @This(), orth_x: usize, orth_y: usize) f32 {
        const f_orth_x: f32 = @floatFromInt(orth_x);
        const f_orth_y: f32 = @floatFromInt(orth_y);
        return orthToIsoX(f_orth_x, f_orth_y, this.wrap_increment_x);
    }

    pub fn ortToIsoY(this: *const @This(), orth_x: usize, orth_y: usize) f32 {
        const f_orth_x: f32 = @floatFromInt(orth_x);
        const f_orth_y: f32 = @floatFromInt(orth_y);
        return orthToIsoY(f_orth_x, f_orth_y, this.wrap_increment_y);
    }



    pub fn isoToOrtX(this: *const @This(), iso_x: i32, iso_y: i32) ?usize {
        const f_iso_x: f32 = @floatFromInt(iso_x);
        const f_iso_y: f32 = @floatFromInt(iso_y);
        const current_cell_x = findIsoCurrentCellX(f_iso_x, this.wrap_increment_x);
        const current_cell_y = findIsoCurrentCellY(f_iso_y, this.wrap_increment_y);

        c_cell_x = current_cell_x;
        c_cell_y = current_cell_y;

        const orth_x = isoToOrthX(current_cell_x, current_cell_y, this.wrap_increment_x, this.wrap_increment_y);
        ort_x_f = orth_x;
        if (orth_x < 0) return null;
        return @intFromFloat(orth_x);
    }

    pub fn isoToOrtY(this: *const @This(), iso_x: i32, iso_y: i32) ?usize {
        const f_iso_x: f32 = @floatFromInt(iso_x);
        const f_iso_y: f32 = @floatFromInt(iso_y);
        const current_cell_x = findIsoCurrentCellX(f_iso_x, this.wrap_increment_x);
        const current_cell_y = findIsoCurrentCellY(f_iso_y, this.wrap_increment_y);
        const orth_y = isoToOrthY(current_cell_x, current_cell_y, this.wrap_increment_x, this.wrap_increment_y);
        ort_y_f = orth_y;
        if (orth_y < 0) return null;
        return @intFromFloat(orth_y);
    }
};

const expect = @import("std").testing.expect;
const print = @import("std").debug.print;
test "back_and_forth" {
    const m = Iso.new(127, 96);
    const iso_x = m.ortToIsoX(132, 62);
    const iso_y = m.ortToIsoY(132, 62);
    print("\n", .{});
    print("iso x: {d}\n", .{iso_x});
    print("iso y: {d}\n", .{iso_y});
    print("------------------------------\n", .{});
    const grid_x = m.isoToOrtX(@intFromFloat(iso_x), @intFromFloat(iso_y)).?;
    const grid_y = m.isoToOrtY(@intFromFloat(iso_x), @intFromFloat(iso_y)).?;
    print("grid x: {d}\n", .{grid_x});
    print("grid y: {d}\n", .{grid_y});
}

test "iso_to_grid" {
    const tile_width: f32 = 127;
    const tile_heigth: f32 = 96;
    const inc_x = orthToIsoWrapIncrementX(tile_width);
    const inc_y = orthToIsoWrapIncrementY(tile_heigth);

    const grid_x = isoToOrthX(133, 63, inc_x, inc_y) orelse return;
    const grid_y = isoToOrthY(133, 63, inc_x, inc_y) orelse return;

    print("\n", .{});
    print("grid_x: {d}\n", .{grid_x});
    print("grid_y: {d}\n", .{grid_y});
}
