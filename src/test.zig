const std = @import("std");
const testing = std.testing;
const lib = @import("lib.zig");
const types = @import("types.zig");
const ArrayList = std.ArrayList;
const String = @import("zig-string/zig-string.zig").String;

var test_allocator: std.mem.Allocator = std.testing.allocator;

test "blank file" {
    //try to parse a blank file
    _ = lib.parse_vmf(test_allocator, "") catch |err| {
        //Check that the error is a blank file error
        try testing.expect(err == types.ParseError.EmptyFile);
        return;
    };

    //we should not succeed in parsing a blank file!
    try testing.expect(false);
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

    var map: types.Map = try lib.parse_vmf(allocator,
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

    var map: types.Map = try lib.parse_vmf(allocator,
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

    var map: types.Map = try lib.parse_vmf(allocator,
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

    var map: types.Map = try lib.parse_vmf(allocator,
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
