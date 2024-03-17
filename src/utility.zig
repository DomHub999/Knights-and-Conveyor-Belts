const std = @import("std");

pub fn indexTwoDimArray(x:usize, y:usize, width: usize)usize{
    return y * width + x;
}

pub fn usizeToString(num:usize, buf:[]u8)void{
    const limb = [1]std.math.big.Limb{num};
    const cons = std.math.big.int.Const{ .limbs = &limb, .positive = true };
    var limb_buf: [10]std.math.big.Limb = undefined;
    _ = std.math.big.int.Const.toString(cons, buf, 10, std.fmt.Case.lower, &limb_buf);
}
