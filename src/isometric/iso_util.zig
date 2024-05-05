const Vec2f = @import("iso_core.zig").Vec2f;

const Rectangle = struct { upper_left: Vec2f, upper_right: Vec2f, bottom_right: Vec2f, bottom_left: Vec2f };
fn rectangleEdges(x1: f32, y1: f32, x2: f32, y2: f32) ?Rectangle {
    if (x1 < x2 and y1 < y2) { //top left to bottom right
        return Rectangle{
            .upper_left = .{ .x = x1, .y = y1 },
            .upper_right = .{ .x = x2, .y = y1 },
            .bottom_right = .{ .x = x2, .y = y2 },
            .bottom_left = .{ .x = x1, .y = y2 },
        };
    } else if (x1 > x2 and y1 > y2) { //bottom right to top left
        return Rectangle{
            .upper_left = .{ .x = x2, .y = y2 },
            .upper_right = .{ .x = x1, .y = y2 },
            .bottom_right = .{ .x = x1, .y = y1 },
            .bottom_left = .{ .x = x2, .y = y1 },
        };
    } else if (x1 < x2 and y1 > y2) { //bottom left to top right
        return Rectangle{
            .upper_left = .{ .x = x1, .y = y2 },
            .upper_right = .{ .x = x2, .y = y2 },
            .bottom_right = .{ .x = x2, .y = y1 },
            .bottom_left = .{ .x = x1, .y = y1 },
        };
    } else if (x1 > x2 and y1 < y2) { // top right to bottom left
        return Rectangle{
            .upper_left = .{ .x = x2, .y = y1 },
            .upper_right = .{ .x = x1, .y = y1 },
            .bottom_right = .{ .x = x1, .y = y2 },
            .bottom_left = .{ .x = x2, .y = y2 },
        };
    }

    return null;
}

const expect = @import("std").testing.expect;

test "area rectangle" {
    const Points = struct { p1: Vec2f, p2: Vec2f };
    const test_points = [_]Points{
        Points{ .p1 = .{ .x = 0, .y = 0 }, .p2 = .{ .x = 1, .y = 1 } },
        Points{ .p1 = .{ .x = 1, .y = 1 }, .p2 = .{ .x = 0, .y = 0 } },
        Points{ .p1 = .{ .x = 0, .y = 1 }, .p2 = .{ .x = 1, .y = 0 } },
        Points{ .p1 = .{ .x = 1, .y = 0 }, .p2 = .{ .x = 0, .y = 1 } },
    };

    const p_res = Rectangle{
        .upper_left = .{ .x = 0, .y = 0 },
        .upper_right = .{ .x = 1, .y = 0 },
        .bottom_right = .{ .x = 1, .y = 1 },
        .bottom_left = .{ .x = 0, .y = 1 },
    };

    for (&test_points) |*p| {
        const rec = rectangleEdges(p.p1.x, p.p1.y, p.p2.x, p.p2.y).?;

        try expect(rec.upper_left.x == p_res.upper_left.x);
        try expect(rec.upper_left.y == p_res.upper_left.y);

        try expect(rec.upper_right.x == p_res.upper_right.x);
        try expect(rec.upper_right.y == p_res.upper_right.y);

        try expect(rec.bottom_right.x == p_res.bottom_right.x);
        try expect(rec.bottom_right.y == p_res.bottom_right.y);

        try expect(rec.bottom_left.x == p_res.bottom_left.x);
        try expect(rec.bottom_left.y == p_res.bottom_left.y);
    }
}
