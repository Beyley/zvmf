const std = @import("std");
const ascii = std.ascii;
const ArrayList = std.ArrayList;
const String = @import("zig-string/zig-string.zig").String;
const types = @import("types.zig");
const Map = types.Map;
const ParseError = types.ParseError;

const ZvmfErrors = (ParseError || String.Error || std.fmt.ParseIntError || std.fmt.ParseFloatError);

const ParserState = struct {
    char_index: usize,
    reading_string: bool,
    reading_class_name: bool,
    working_string: ?String,
};

const class_name_enders: *const [2]u8 = &[_]u8{
    '{',
    '}',
};

fn skipWhitespace(iterator: *String.StringIterator) void {
    var next: ?[]const u8 = iterator.next();

    //if theres no character next, then return out
    if (next == null) {
        return;
    }

    while (next != null) {
        //The current character
        var character: []const u8 = next.?;

        if (!ascii.isWhitespace(character[0])) {
            //decrement the iterator position so that the next read starts at the first char right after the class name
            iterator.index -= 1;
            //return out
            return;
        }

        next = iterator.next();
    }
}

fn readClass(allocator: std.mem.Allocator, user_allocator: std.mem.Allocator, map_string: String, map: Map, state: ParserState, iterator: *String.StringIterator) ZvmfErrors!types.Class {
    var class: types.Class = try types.Class.init(user_allocator);

    var class_name: String = String.init(allocator);

    var next: ?[]const u8 = iterator.next();

    //if theres no character next, then return an error
    if (next == null) {
        return types.ParseError.UnexpectedEndOfFile;
    }

    //Read the class name
    while (next != null) {
        //The current character
        var character: []const u8 = next.?;

        if (ascii.isWhitespace(character[0]) or std.mem.indexOf(u8, class_name_enders, character) != null) {
            //decrement the iterator position so that the next read starts at the first char right after the class name
            iterator.index -= 1;
            //break as we are done reading the class name
            break;
        }

        //Concat the character to the class name
        try class_name.concat(character);

        next = iterator.next();
    }

    //if theres no character next, then return an error
    if (next == null) {
        return types.ParseError.UnexpectedEndOfFile;
    }

    //If the class name is empty, return an error
    if (class_name.len() == 0) {
        return types.ParseError.EmptyClassName;
    }

    //Concat the found class name onto the output class name
    try class.name.concat(class_name.str());

    //Skip any extra whitespace
    skipWhitespace(iterator);

    next = iterator.next();

    //If the next character is not a '{', then return an error
    if ((next orelse return types.ParseError.UnexpectedEndOfFile)[0] != '{') {
        return types.ParseError.UnexpectedToken;
    }

    //Skip any extra whitespace
    skipWhitespace(iterator);

    var read_property_name: bool = false;
    var is_reading_string: bool = false;

    var working_string: ?String = null;
    var working_property: ?types.Property = null;

    next = iterator.next();
    while (next != null) {
        //The current character
        var character: []const u8 = next.?;

        //if we arent reading a string and we hit a whitespace, ignore it
        if (!is_reading_string and ascii.isWhitespace(character[0])) {
            next = iterator.next();
            continue;
        }

        //If we are closing the class, then break out of the loop
        if (character[0] == '}') {
            break;
        }

        //If the character is a quote
        if (character[0] == '\"') {
            //If we are not in a string, then we are starting a string
            if (!is_reading_string) {
                is_reading_string = true;

                working_string = String.init(allocator);
            }
            //If we are in a string, then we are ending a string
            else {
                is_reading_string = false;
                //if we have not read a property name yet, and we just finished reading a string
                if (!read_property_name) {
                    //initialize the working property with the name, and set the value to 0
                    working_property = types.Property{ .name = String.init(user_allocator), .value = .{ .int = 0 } };

                    //Append the working string to the working property name
                    try working_property.?.name.concat(working_string.?.str());

                    //mark that we have read the property name
                    read_property_name = true;
                }
                //if we have read a property name, then fill in the property value
                else {
                    var property_value = try parsePropertyValue(user_allocator, class_name, working_string.?, working_property.?.name);

                    working_property.?.value = property_value;

                    //mark that we have not read a property
                    read_property_name = false;

                    try class.properties.append(working_property.?);
                }
            }
        } else if (is_reading_string) {
            try working_string.?.concat(character);
        } else {
            //move the index back by 1, so the read_class can read the full name
            iterator.index -= 1;

            var nested_class = try readClass(allocator, user_allocator, map_string, map, state, iterator);

            try class.sub_classes.append(nested_class);
        }

        //read the next char
        next = iterator.next();

        if (next == null) {
            return types.ParseError.UnexpectedEndOfFile;
        }
    }

    return class;
}

const PropertyMapElement = struct {
    class: []const u8,
    property_name: []const u8,
    property_type: types.PropertyType,
};

const property_type_map = &[_]PropertyMapElement{
    .{ .class = "", .property_name = "editorversion", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "editorbuild", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "mapversion", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "formatversion", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "prefab", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "name", .property_type = types.PropertyType.string },
    .{ .class = "", .property_name = "visgroupid", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "color", .property_type = types.PropertyType.rgb },
    .{ .class = "", .property_name = "bSnapToGrid", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "bShowGrid", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "bShowLogicalGrid", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "nGridSpacing", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "bShow3DGrid", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "id", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "classname", .property_type = types.PropertyType.string },
    .{ .class = "", .property_name = "skyname", .property_type = types.PropertyType.string },
    .{ .class = "", .property_name = "material", .property_type = types.PropertyType.string },
    .{ .class = "", .property_name = "rotation", .property_type = types.PropertyType.decimal },
    .{ .class = "", .property_name = "lightmapscale", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "smoothing_groups", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "uaxis", .property_type = types.PropertyType.uvaxis },
    .{ .class = "", .property_name = "vaxis", .property_type = types.PropertyType.uvaxis },
    .{ .class = "", .property_name = "plane", .property_type = types.PropertyType.plane },
    .{ .class = "", .property_name = "power", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "startposition", .property_type = types.PropertyType.vertex },
    .{ .class = "", .property_name = "elevation", .property_type = types.PropertyType.decimal },
    .{ .class = "", .property_name = "subdiv", .property_type = types.PropertyType.boolean },
    .{ .class = "normals", .property_name = "row*", .property_type = types.PropertyType.vertex_array },
    .{ .class = "offsets", .property_name = "row*", .property_type = types.PropertyType.vertex_array },
    .{ .class = "offset_normals", .property_name = "row*", .property_type = types.PropertyType.vertex_array },
    .{ .class = "distances", .property_name = "row*", .property_type = types.PropertyType.decimal_array },
    .{ .class = "alphas", .property_name = "row*", .property_type = types.PropertyType.decimal_array },
    .{ .class = "triangle_tags", .property_name = "row*", .property_type = types.PropertyType.triangle_tag_array },
    .{ .class = "allowed_verts", .property_name = "10", .property_type = types.PropertyType.int_array },
    .{ .class = "", .property_name = "color", .property_type = types.PropertyType.rgb },
    .{ .class = "", .property_name = "visgroupid", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "groupid", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "visgroupshown", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "visgroupautoshown", .property_type = types.PropertyType.boolean },
    .{ .class = "", .property_name = "comments", .property_type = types.PropertyType.string },
    .{ .class = "", .property_name = "logicalpos", .property_type = types.PropertyType.vector_2 },
    .{ .class = "", .property_name = "spawnflags", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "origin", .property_type = types.PropertyType.vertex },
    .{ .class = "connections", .property_name = "*", .property_type = types.PropertyType.entity_output },
    .{ .class = "", .property_name = "activecamera", .property_type = types.PropertyType.int },
    .{ .class = "", .property_name = "position", .property_type = types.PropertyType.vertex },
    .{ .class = "", .property_name = "look", .property_type = types.PropertyType.vertex },
    .{ .class = "", .property_name = "mins", .property_type = types.PropertyType.vertex },
    .{ .class = "", .property_name = "maxs", .property_type = types.PropertyType.vertex },
    .{ .class = "", .property_name = "active", .property_type = types.PropertyType.boolean },
};

fn globStringCompare(haystack: []const u8, needle: []const u8) bool {
    var glob_prefix: ?[]const u8 = null;
    var globbing: bool = false;

    //if it starts with a glob, just return true, as everything matches
    if (haystack[0] == '*') {
        return true;
    }

    var index: usize = 0;
    while (index < haystack.len) {
        var haystack_char: u8 = haystack[index];

        if (haystack_char == '*') {
            glob_prefix = haystack[0 .. index - 1];

            globbing = true;
            break;
        }

        index += 1;
    }

    if (globbing) {
        return std.mem.startsWith(u8, needle, glob_prefix.?);
    } else {
        return std.mem.eql(u8, haystack, needle);
    }
}

fn parsePropertyValue(user_allocator: std.mem.Allocator, class_name: String, property_string: String, property_name: String) ZvmfErrors!types.PropertyValue {
    var property_type: ?types.PropertyType = null;

    for (property_type_map) |element| {
        //if the element only applies to a specific class, and the class name is wrong,
        if (element.class.len != 0 and !std.mem.eql(u8, element.class, class_name.str())) {
            //then continue
            continue;
        }

        //If they are equal, set the type
        if (globStringCompare(element.property_name, property_name.str())) {
            property_type = element.property_type;
        }
    }

    if (property_type == null) {
        std.debug.print("unknown property type for {s} ({s})! Assuming string\n", .{ property_name.str(), property_string.str() });
        property_type = types.PropertyType.string;
    }

    switch (property_type.?) {
        .int => {
            var int: i64 = try std.fmt.parseInt(i64, property_string.str(), 10);

            return .{ .int = int };
        },
        .decimal => {
            var dec: f64 = try std.fmt.parseFloat(f64, property_string.str());

            return .{ .decimal = dec };
        },
        .uvaxis => {
            var axis: types.UVAxis = .{ .x = 0, .y = 0, .z = 0, .translation = 0, .total_scaling = 0 };

            var iterator = property_string.iterator();

            var next: ?[]const u8 = iterator.next();

            var channel: u8 = 0;

            var num_start_index: ?usize = null;

            while (next != null) {
                var character: []const u8 = next.?;

                //skip [
                if (character[0] == '[') {
                    next = iterator.next();
                    continue;
                }

                var index = iterator.index;
                next = iterator.next();

                if ((ascii.isDigit(character[0]) or character[0] == '.') and num_start_index == null) {
                    num_start_index = index - 1;
                }

                if (num_start_index != null and (next == null or ascii.isWhitespace(character[0]) or character[0] == ']')) {
                    var offset: usize = if (next == null) 0 else 1;

                    var slice: []const u8 = property_string.buffer.?[num_start_index.? .. index - offset];

                    var num = try std.fmt.parseFloat(f64, slice);

                    if (channel == 0) {
                        axis.x = num;
                    } else if (channel == 1) {
                        axis.y = num;
                    } else if (channel == 2) {
                        axis.z = num;
                    } else if (channel == 3) {
                        axis.translation = num;
                    } else if (channel == 4) {
                        axis.total_scaling = num;
                    }

                    channel += 1;
                    if (channel > 4) {
                        break;
                    }

                    num_start_index = null;
                }
            }

            return .{ .uvaxis = axis };
        },
        .plane => {
            const VertexPos = struct { start: usize, end: usize };

            var plane: types.Plane = .{ .vtx1 = .{ .x = 0, .y = 0, .z = 0 }, .vtx2 = .{ .x = 0, .y = 0, .z = 0 }, .vtx3 = .{ .x = 0, .y = 0, .z = 0 } };

            var iterator = property_string.iterator();

            var pos: VertexPos = .{ .start = 0, .end = 0 };

            var element: u8 = 0;

            var next: ?[]const u8 = iterator.next();
            while (next != null) {
                var character: []const u8 = next.?;

                if (ascii.isWhitespace(character[0])) {
                    next = iterator.next();
                    continue;
                }

                if (character[0] == '(') {
                    pos.start = iterator.index - 1;
                }

                if (character[0] == ')') {
                    pos.end = iterator.index - 1;

                    //TODO: dont allocate here
                    var sub: String = try property_string.substr(pos.start, pos.end);
                    defer sub.deinit();

                    var vertex: types.Vertex = try parseVertex(sub);

                    if (element == 0) {
                        plane.vtx1 = vertex;
                    } else if (element == 1) {
                        plane.vtx2 = vertex;
                    } else if (element == 2) {
                        plane.vtx3 = vertex;
                    }

                    element += 1;

                    if (element > 2) {
                        //we have found all 3 elements
                        break;
                    }
                }

                next = iterator.next();
            }

            return .{ .plane = plane };
        },
        .vertex_array => {
            @panic("todo: vertex_array");
        },
        .decimal_array => {
            //if the length of the string is 0,
            if (property_string.len() == 0) {
                //return a blank decimal array
                return .{ .decimal_array = .{ .array = &[_]f64{} } };
            }

            var iterator = property_string.iterator();

            var next: ?[]const u8 = iterator.next();

            var array_length: usize = 1;

            //iterate through once to get the amount of elements
            while (next != null) {
                var character: []const u8 = next.?;
                if (ascii.isWhitespace(character[0])) {
                    array_length += 1;
                }

                next = iterator.next();
            }

            var array: []f64 = try user_allocator.alloc(f64, array_length);

            var element: usize = 0;

            //reset the iterator
            iterator.index = 0;
            next = iterator.next();

            var start_index: ?usize = null;

            while (next != null) {
                var character: []const u8 = next.?;
                next = iterator.next();

                //if we have not defined a start position, and we are at the end, then set the start position 1 char before the end
                if (start_index == null and next == null) {
                    start_index = iterator.index - 1;
                }

                //if we have reached the end, or we are at a whitespace
                if (next == null or ascii.isWhitespace(character[0])) {
                    //if its not null, that means we have hit a whitespace char, so go back 2 instead of 1
                    var offset: usize = if (next == null) 0 else 2;

                    var slice: []const u8 = property_string.buffer.?[start_index.? .. iterator.index - offset];

                    array[element] = try std.fmt.parseFloat(f64, slice);
                    element += 1;

                    start_index = null;

                    continue;
                }

                //if we arent at whitespace or the end, and the start index is null
                if (start_index == null) {
                    //mark 2 chars ago as the start of the number, as we grab next up above,
                    //and we are always 1 char ahead of the index of the current char
                    start_index = iterator.index - 2;
                }
            }

            return .{ .decimal_array = .{ .array = array } };
        },
        .triangle_tag_array => {
            var array_length: usize = (property_string.len() - 1) / 2 + 1;

            var array: []types.TriangleTag = try user_allocator.alloc(types.TriangleTag, array_length);

            var iterator = property_string.iterator();

            var next: ?[]const u8 = iterator.next();

            var i: usize = 0;
            while (i < array_length) {
                var character: []const u8 = next.?;

                if (character[0] == '0') {
                    array[i] = types.TriangleTag.LargeZAxisSlopeNonWalkable;
                } else if (character[0] == '1') {
                    array[i] = types.TriangleTag.LargeZAxisSlopeWalkable;
                } else if (character[0] == '9') {
                    array[i] = types.TriangleTag.NoSlope;
                } else {
                    return types.ParseError.UnexpectedToken;
                }

                _ = iterator.next();
                next = iterator.next();

                i += 1;
            }

            return .{ .triangle_tag_array = .{ .array = array } };
        },
        .int_array => {
            @panic("todo: int_array");
        },
        .vector_2 => {
            @panic("todo: vector_2");
        },
        .entity_output => {
            @panic("todo: entity_output");
        },
        .string => {
            //make a new string with the user allocator with the contents of the property string
            var user_string: String = try String.init_with_contents(user_allocator, property_string.str());

            return .{ .string = user_string };
        },
        .boolean => {
            var boolean: bool = property_string.charAt(0).?[0] != '0';

            return .{ .boolean = boolean };
        },
        .vertex => {
            return .{ .vertex = try parseVertex(property_string) };
        },
        .rgb => {
            var value: types.PropertyValue = .{ .rgb = .{ .r = 0, .g = 0, .b = 0 } };

            var iterator = property_string.iterator();

            var next: ?[]const u8 = iterator.next();

            if (next == null) {
                return types.ParseError.UnexpectedEndOfFile;
            }

            var channel: u8 = 0;
            var start_index: ?usize = null;
            while (true) {
                //If the character is not a digit and we *have* a start index
                if (next == null or (!ascii.isDigit(next.?[0]) and start_index != null)) {
                    var offset: usize = 1;
                    if (next == null)
                        offset = 0;

                    var slice: []const u8 = property_string.buffer.?[start_index.? .. iterator.index - offset];

                    //try to parse the rgb value
                    var parsed: u8 = try std.fmt.parseInt(u8, slice, 10);

                    //set the correct channel
                    if (channel == 0) {
                        value.rgb.r = parsed;
                    } else if (channel == 1) {
                        value.rgb.g = parsed;
                    } else if (channel == 2) {
                        value.rgb.b = parsed;
                        //if we parsed the last number, break out of the loop
                        break;
                    }

                    //setup state for the next number
                    start_index = null;
                    channel += 1;
                    next = iterator.next();

                    if (channel == 3) {
                        break;
                    }

                    continue;
                }

                if (start_index == null) {
                    //Set the start index to the current index
                    start_index = iterator.index - 1;
                }

                next = iterator.next();
            }

            return value;
        },
    }

    @panic("invalid property type?");
}

fn parseVertex(string: String) ZvmfErrors!types.Vertex {
    var value: types.Vertex = .{ .x = 0, .y = 0, .z = 0 };

    var iterator = string.iterator();

    var next: ?[]const u8 = iterator.next();

    if (next == null) {
        return types.ParseError.UnexpectedEndOfFile;
    }

    var num_start_index: ?usize = null;
    var element: u8 = 0;
    var hit_first: bool = false;
    while (next != null) {
        var character: []const u8 = next.?;

        //if we have not hit the first number yet, and we are not at a digit,
        if (!hit_first and !ascii.isDigit(character[0])) {
            //then skip, as we are at a ( or a [
            next = iterator.next();
            continue;
        }

        var index = iterator.index;
        next = iterator.next();

        //we have hit a number
        hit_first = true;
        //if we have not started a number yet, then mark that we have
        if (num_start_index == null) {
            num_start_index = index - 1;
        }

        var wrap_end = character[0] == ']' or character[0] == ')';

        //if we are at a whitespace, then end the current number, and write it to the value
        if (next == null or ascii.isWhitespace(character[0]) or wrap_end) {
            var offset: usize = if (next == null and !wrap_end) 0 else 1;

            var number_slice = string.buffer.?[num_start_index.? .. index - offset];

            var parsed = try std.fmt.parseFloat(f64, number_slice);

            if (element == 0) {
                value.x = parsed;
            } else if (element == 1) {
                value.y = parsed;
            } else if (element == 2) {
                value.z = parsed;
            }

            element += 1;
            if (element > 2) {
                break;
            }

            num_start_index = null;
        }
    }

    return value;
}

pub fn parseVmf(user_allocator: std.mem.Allocator, data: []const u8) ZvmfErrors!Map {
    //If its empty, return an error
    if (data.len == 0) {
        return ParseError.EmptyFile;
    }

    //Create the arena allocator where we will allocate all of our working data
    var arena_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    //Allocate a new string
    var map_string: String = String.init(allocator);

    //Add the data to the string
    try map_string.concat(data);

    //The state of the parser
    var state: ParserState = ParserState{ .reading_string = false, .reading_class_name = false, .working_string = null, .char_index = 0 };

    var map: Map = try Map.init(user_allocator);

    var iterator: String.StringIterator = map_string.iterator();

    var next: ?[]const u8 = null;
    next = iterator.next();

    //Iterate through all characters in the string
    while (next != null) {
        //The current character
        var character = next.?;

        //If the character is whitespace and we are not in a string or class name,
        if (!state.reading_class_name and !state.reading_string and ascii.isWhitespace(character[0])) {
            //then skip this character
            next = iterator.next();
            continue;
        }

        //if the character is not a quote, and we are not in a string, then we are reading a class name
        if (!state.reading_string and character[0] != '"') {
            //Go back one charactor, so read_class starts at the first character of the class name
            iterator.index -= 1;
            var class = try readClass(allocator, user_allocator, map_string, map, state, &iterator);
            //If reading the class succeeded, then add it to the map, otherwise return the error
            try map.classes.append(class);
        }

        next = iterator.next();
    }

    return map;
}
