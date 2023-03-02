const std = @import("std");
const testing = std.testing;
const lib = @import("lib.zig");
const types = @import("types.zig");
const ArrayList = std.ArrayList;
const String = @import("zig-string/zig-string.zig").String;

var test_allocator: std.mem.Allocator = std.testing.allocator;

test "blank file" {
    //try to parse a blank file
    _ = lib.parseVmf(test_allocator, "") catch |err| {
        //Check that the error is a blank file error
        try testing.expect(err == types.ParseError.EmptyFile);
        return;
    };

    //we should not succeed in parsing a blank file!
    try testing.expect(false);
}

test "vertex" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("test_class");
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "startposition"), .value = .{ .vertex = .{ .x = 123, .y = 456, .z = 789 } } });
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "origin"), .value = .{ .vertex = .{ .x = 987, .y = 654, .z = 321 } } });
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "mins"), .value = .{ .vertex = .{ .x = 10.5, .y = 55.3, .z = 88.2 } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\test_class
        \\{
        \\  "startposition" "[123 456 789]"
        \\  "origin" "987 654 321"
        \\  "mins" "(10.5 55.3 88.2)"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "uvaxis" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("test_class");
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "uaxis"), .value = .{ .uvaxis = .{ .x = 1, .y = 2, .z = 3, .translation = 4, .total_scaling = 7.3267 } } });
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "vaxis"), .value = .{ .uvaxis = .{ .x = 4, .y = 3, .z = 2, .translation = 1, .total_scaling = 9.25 } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\test_class
        \\{
        \\  "uaxis" "[1 2 3 4] 7.3267"
        \\  "vaxis" "[4 3 2 1] 9.25"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "decimal array" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("distances");

    var arr1: []f64 = try allocator.alloc(f64, 4);
    arr1[0] = 0.5;
    arr1[1] = 1.2;
    arr1[2] = 2.6;
    arr1[3] = 3.9;

    var arr2: []f64 = try allocator.alloc(f64, 6);
    arr2[0] = 1;
    arr2[1] = 2;
    arr2[2] = 3;
    arr2[3] = 4.2;
    arr2[4] = 5;
    arr2[5] = 6;

    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "row0"), .value = .{ .decimal_array = .{ .array = arr1 } } });
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "row1"), .value = .{ .decimal_array = .{ .array = arr2 } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\distances
        \\{
        \\  "row0" "0.5 1.2 2.6 3.9"
        \\  "row1" "1 2 3 4.2 5 6"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "int array" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("allowed_verts");

    var arr1: []i64 = try allocator.alloc(i64, 6);
    arr1[0] = 0;
    arr1[1] = -10;
    arr1[2] = 105678;
    arr1[3] = -14556788;
    arr1[4] = 8743;
    arr1[5] = 111;

    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "10"), .value = .{ .int_array = .{ .array = arr1 } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\allowed_verts
        \\{
        \\  "10" "0 -10 105678 -14556788 8743 111"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "vector 2d" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("editor");

    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "logicalpos"), .value = .{ .vector_2 = .{ .x = 157.3, .y = -679.1 } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\editor
        \\{
        \\  "logicalpos" "[157.3 -679.1]"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "plane" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("test_class");
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "plane"), .value = .{ .plane = .{ .vtx1 = .{ .x = 1.5, .y = 2, .z = 3.6 }, .vtx2 = .{ .x = 4.2, .y = 5, .z = 6.33 }, .vtx3 = .{ .x = 7, .y = 8.8, .z = 9 } } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\test_class
        \\{
        \\  "plane" "(1.5 2 3.6) (4.2 5 6.33) (7 8.8 9)"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "triangle tag array" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("triangle_tags");

    var array1: []types.TriangleTag = try allocator.alloc(types.TriangleTag, 7);
    array1[0] = types.TriangleTag.LargeZAxisSlopeNonWalkable;
    array1[1] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array1[2] = types.TriangleTag.NoSlope;
    array1[3] = types.TriangleTag.NoSlope;
    array1[4] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array1[5] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array1[6] = types.TriangleTag.LargeZAxisSlopeNonWalkable;

    var array2: []types.TriangleTag = try allocator.alloc(types.TriangleTag, 7);
    array2[0] = types.TriangleTag.NoSlope;
    array2[1] = types.TriangleTag.NoSlope;
    array2[2] = types.TriangleTag.LargeZAxisSlopeNonWalkable;
    array2[3] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array2[4] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array2[5] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array2[6] = types.TriangleTag.LargeZAxisSlopeNonWalkable;

    var array3: []types.TriangleTag = try allocator.alloc(types.TriangleTag, 8);
    array3[0] = types.TriangleTag.LargeZAxisSlopeNonWalkable;
    array3[1] = types.TriangleTag.LargeZAxisSlopeNonWalkable;
    array3[2] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array3[3] = types.TriangleTag.NoSlope;
    array3[4] = types.TriangleTag.NoSlope;
    array3[5] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array3[6] = types.TriangleTag.LargeZAxisSlopeWalkable;
    array3[7] = types.TriangleTag.LargeZAxisSlopeWalkable;

    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "row0"), .value = .{ .triangle_tag_array = .{ .array = array1 } } });
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "row1"), .value = .{ .triangle_tag_array = .{ .array = array2 } } });
    try reference_class.properties.append(types.Property{ .name = try String.init_with_contents(allocator, "row2"), .value = .{ .triangle_tag_array = .{ .array = array3 } } });

    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\triangle_tags
        \\{
        \\  "row0" "0 1 9 9 1 1 0"
        \\  "row1" "9 9 0 1 1 1 0"
        \\  "row2" "0 0 1 9 9 1 1 1"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "non-nested class versioninfo" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("versioninfo");
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "editorversion"), .value = .{ .int = 400 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "editorbuild"), .value = .{ .int = 3325 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "mapversion"), .value = .{ .int = 0 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "formatversion"), .value = .{ .int = 100 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "prefab"), .value = .{ .boolean = false } });
    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\versioninfo
        \\{
        \\  "editorversion" "400"
        \\  "editorbuild" "3325"
        \\  "mapversion" "0"
        \\  "formatversion" "100"
        \\  "prefab" "0"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "non-nested class viewsettings" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("viewsettings");
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bSnapToGrid"), .value = .{ .boolean = true } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bShowGrid"), .value = .{ .boolean = true } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bShowLogicalGrid"), .value = .{ .boolean = false } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "nGridSpacing"), .value = .{ .int = 64 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bShow3DGrid"), .value = .{ .boolean = false } });
    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\viewsettings
        \\{
        \\  "bSnapToGrid" "1"
        \\  "bShowGrid" "1"
        \\  "bShowLogicalGrid" "0"
        \\  "nGridSpacing" "64"
        \\  "bShow3DGrid" "0"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "multiple non-nested classes" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_class: types.Class = try types.Class.init(allocator);
    try reference_class.name.concat("viewsettings");
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bSnapToGrid"), .value = .{ .boolean = true } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bShowGrid"), .value = .{ .boolean = true } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bShowLogicalGrid"), .value = .{ .boolean = false } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "nGridSpacing"), .value = .{ .int = 64 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "bShow3DGrid"), .value = .{ .boolean = false } });
    try reference_map.classes.append(reference_class);

    reference_class = try types.Class.init(allocator);
    try reference_class.name.concat("versioninfo");
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "editorversion"), .value = .{ .int = 400 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "editorbuild"), .value = .{ .int = 3325 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "mapversion"), .value = .{ .int = 0 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "formatversion"), .value = .{ .int = 100 } });
    try reference_class.properties.append(.{ .name = try String.init_with_contents(allocator, "prefab"), .value = .{ .boolean = false } });
    try reference_map.classes.append(reference_class);

    var map: types.Map = try lib.parseVmf(allocator,
        \\viewsettings
        \\{
        \\  "bSnapToGrid" "1"
        \\  "bShowGrid" "1"
        \\  "bShowLogicalGrid" "0"
        \\  "nGridSpacing" "64"
        \\  "bShow3DGrid" "0"
        \\}
        \\
        \\versioninfo
        \\{
        \\  "editorversion" "400"
        \\  "editorbuild" "3325"
        \\  "mapversion" "0"
        \\  "formatversion" "100"
        \\  "prefab" "0"
        \\}
    );

    try testing.expect(map.eql(reference_map));
}

test "nested class visgroups" {
    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var reference_map: types.Map = try types.Map.init(allocator);

    var reference_root_class: types.Class = try types.Class.init(allocator);
    try reference_root_class.name.concat("visgroups");
    try reference_map.classes.append(reference_root_class);

    var reference_subclass_1: types.Class = try types.Class.init(allocator);
    try reference_subclass_1.name.concat("visgroup");
    try reference_subclass_1.properties.append(.{ .name = try String.init_with_contents(allocator, "name"), .value = .{ .string = try String.init_with_contents(allocator, "Tree_1") } });
    try reference_subclass_1.properties.append(.{ .name = try String.init_with_contents(allocator, "visgroupid"), .value = .{ .int = 5 } });
    try reference_subclass_1.properties.append(.{ .name = try String.init_with_contents(allocator, "color"), .value = .{ .rgb = .{ .r = 65, .g = 45, .b = 80 } } });
    try reference_root_class.sub_classes.append(reference_subclass_1);

    var reference_subclass_2: types.Class = try types.Class.init(allocator);
    try reference_subclass_2.name.concat("visgroup");
    try reference_subclass_2.properties.append(.{ .name = try String.init_with_contents(allocator, "name"), .value = .{ .string = try String.init_with_contents(allocator, "Tree_2") } });
    try reference_subclass_2.properties.append(.{ .name = try String.init_with_contents(allocator, "visgroupid"), .value = .{ .int = 1 } });
    try reference_subclass_2.properties.append(.{ .name = try String.init_with_contents(allocator, "color"), .value = .{ .rgb = .{ .r = 60, .g = 35, .b = 0 } } });
    try reference_root_class.sub_classes.append(reference_subclass_2);

    var reference_subclass_2_1: types.Class = try types.Class.init(allocator);
    try reference_subclass_2_1.name.concat("visgroup");
    try reference_subclass_2_1.properties.append(.{ .name = try String.init_with_contents(allocator, "name"), .value = .{ .string = try String.init_with_contents(allocator, "Branch_1") } });
    try reference_subclass_2_1.properties.append(.{ .name = try String.init_with_contents(allocator, "visgroupid"), .value = .{ .int = 2 } });
    try reference_subclass_2_1.properties.append(.{ .name = try String.init_with_contents(allocator, "color"), .value = .{ .rgb = .{ .r = 0, .g = 192, .b = 0 } } });
    var reference_subclass_2_2: types.Class = try types.Class.init(allocator);
    try reference_subclass_2_2.name.concat("visgroup");
    try reference_subclass_2_2.properties.append(.{ .name = try String.init_with_contents(allocator, "name"), .value = .{ .string = try String.init_with_contents(allocator, "Branch_2") } });
    try reference_subclass_2_2.properties.append(.{ .name = try String.init_with_contents(allocator, "visgroupid"), .value = .{ .int = 3 } });
    try reference_subclass_2_2.properties.append(.{ .name = try String.init_with_contents(allocator, "color"), .value = .{ .rgb = .{ .r = 0, .g = 255, .b = 0 } } });
    try reference_subclass_2.sub_classes.append(reference_subclass_2_1);
    try reference_subclass_2.sub_classes.append(reference_subclass_2_2);

    var map: types.Map = try lib.parseVmf(allocator,
        \\visgroups
        \\{
        \\  visgroup
        \\  {
        \\    "name" "Tree_1"
        \\    "visgroupid" "5"
        \\    "color" "65 45 80"
        \\  }
        \\  visgroup
        \\  {
        \\    "name" "Tree_2"
        \\    "visgroupid" "1"
        \\    "color" "60 35 0"
        \\    visgroup
        \\    {
        \\      "name" "Branch_1"
        \\      "visgroupid" "2"
        \\      "color" "0 192 0"
        \\    }
        \\    visgroup
        \\    {
        \\      "name" "Branch_2"
        \\      "visgroupid" "3"
        \\      "color" "0 255 0"
        \\    }
        \\  }
        \\}
    );

    try testing.expect(map.eql(reference_map));
}
