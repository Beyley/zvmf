const std = @import("std");
const ArrayList = std.ArrayList;
const String = @import("zig-string/zig-string.zig").String;

pub const Vertex = struct {
    x: f64,
    y: f64,
    z: f64,
    pub fn eql(self: *const Vertex, other: Vertex) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    pub fn eql(self: *const Color, other: Color) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b;
    }
};

pub const Class = struct {
    name: String,
    properties: *ArrayList(Property),
    sub_classes: *ArrayList(Class),
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!Class {
        var property_list: *ArrayList(Property) = try allocator.create(ArrayList(Property));
        var sub_classes_list: *ArrayList(Class) = try allocator.create(ArrayList(Class));

        property_list.allocator = allocator;
        property_list.capacity = 0;
        property_list.items = &[_]Property{};

        sub_classes_list.allocator = allocator;
        sub_classes_list.capacity = 0;
        sub_classes_list.items = &[_]Class{};

        return .{ .name = String.init(allocator), .properties = property_list, .sub_classes = sub_classes_list, .allocator = allocator };
    }
    pub fn deinit(self: *const Class) void {
        self.allocator.destroy(self.properties);
        self.allocator.destroy(self.sub_classes);
    }
    pub fn eql(self: *const Class, other: Class) bool {
        if (!std.mem.eql(u8, self.name.str(), other.name.str())) {
            return false;
        }

        if (self.properties.items.len != other.properties.items.len) {
            return false;
        }

        for (self.properties.items) |property, i| {
            var prop1 = other.properties.items[i];
            _ = prop1;

            if (!std.mem.eql(u8, property.name.str(), other.properties.items[i].name.str())) {
                return false;
            }

            switch (property.value) {
                .string => |string| {
                    if (!std.mem.eql(u8, string.str(), other.properties.items[i].value.string.str())) {
                        return false;
                    }
                },
                .decimal => |decimal| {
                    if (decimal != other.properties.items[i].value.decimal) {
                        return false;
                    }
                },
                .int => |int| {
                    if (int != other.properties.items[i].value.int) {
                        return false;
                    }
                },
                .boolean => |boolean| {
                    if (boolean != other.properties.items[i].value.boolean) {
                        return false;
                    }
                },
                .vertex => |vertex| {
                    if (!vertex.eql(other.properties.items[i].value.vertex)) {
                        return false;
                    }
                },
                .rgb => |rgb| {
                    if (!rgb.eql(other.properties.items[i].value.rgb)) {
                        return false;
                    }
                },
                .plane => |plane| {
                    if(!plane.eql(other.properties.items[i].value.plane)) {
                        return false;
                    }
                },
                .uvaxis => |uvaxis| {
                    if(!uvaxis.eql(other.properties.items[i].value.uvaxis)) {
                        return false;
                    }
                },
                .vertex_array => |array| {
                    if(!array.eql(other.properties.items[i].value.vertex_array)) {
                        return false;
                    }
                },
                .decimal_array => |array| {
                    if(!array.eql(other.properties.items[i].value.decimal_array)) {
                        return false;
                    }
                },
                .triangle_tag_array => |array| {
                    if(!array.eql(other.properties.items[i].value.triangle_tag_array)) {
                        return false;
                    }
                },
                .int_array => |array| {
                    if(!array.eql(other.properties.items[i].value.int_array)) {
                        return false;
                    }
                },
                .vector_2 => |vector_2| {
                    if(!vector_2.eql(other.properties.items[i].value.vector_2)) {
                        return false;
                    }
                }
            }
        }

        if (self.sub_classes.items.len != other.sub_classes.items.len) {
            return false;
        }

        for (self.sub_classes.items) |class, index| {
            if (!class.eql(other.sub_classes.items[index])) {
                return false;
            }
        }

        return true;
    }
};

pub const Property = struct {
    name: String,
    value: PropertyValue,
};

pub const Map = struct {
    classes: *ArrayList(Class),
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!Map {
        var class_list: *ArrayList(Class) = try allocator.create(ArrayList(Class));

        class_list.allocator = allocator;
        class_list.capacity = 0;
        class_list.items = &[_]Class{};

        return .{ .classes = class_list, .allocator = allocator };
    }
    pub fn deinit(self: *const Map) void {
        self.allocator.destroy(self.classes);
    }
    pub fn eql(self: *const Map, other: Map) bool {
        for (self.classes.items) |class, index| {
            if (!class.eql(other.classes.items[index])) {
                return false;
            }
        }

        return true;
    }
};

pub const PropertyType = enum {
    int,
    decimal,
    string,
    boolean,
    vertex,
    rgb,
    plane,
    uvaxis,
    vertex_array,
    decimal_array,
    int_array,
    triangle_tag_array,
    vector_2,
    entity_output,
};

pub const PropertyValue = union(PropertyType) {
    int: i64,
    decimal: f64,
    string: String,
    boolean: bool,
    vertex: Vertex,
    rgb: Color,
    plane: Plane,
    uvaxis: UVAxis,
    vertex_array: VertexArray,
    decimal_array: DecimalArray,
    int_array: IntArray,
    triangle_tag_array: TriangleTagArray,
    vector_2: Vector2,
    entity_output: EntityOutput,
};

pub const EntityOutput = struct {
    target_entity: String,
    input: String,
    parameter_override: String,
    trigger_delay: f64,
    times_to_fire: i64
};

pub const Vector2 = struct {
    x: f64,
    y: f64,
    pub fn eql(self: Vector2, other: Vector2) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub const TriangleTag = enum(u4) {
    NoSlope = 9,
    LargeZAxisSlopeWalkable = 1,
    LargeZAxisSlopeNonWalkable = 0,
};

pub const TriangleTagArray = struct {
    array: []TriangleTag,
    pub fn eql(self: TriangleTagArray, other: TriangleTagArray) bool {
        if(self.array.len != other.array.len) {
            return false;
        }

        for(self.array) |triangle_tag, index| {
            if(triangle_tag != other.array[index]) {
                return false;
            }
        }

        return true;
    }
};

pub const IntArray = struct {
    array: []i64,
    pub fn eql(self: IntArray, other: IntArray) bool {
        if(self.array.len != other.array.len) {
            return false;
        }

        for(self.array) |int, index| {
            if(int != other.array[index]) {
                return false;
            }
        }

        return true;
    }
};

pub const VertexArray = struct {
    array: []Vertex, 
    pub fn eql(self: VertexArray, other: VertexArray) bool {
        if(self.array.len != other.array.len) {
            return false;
        }

        for(self.array) |vertex, index| {
            if(!vertex.eql(other.array[index])) {
                return false;
            }
        }

        return true;
    }
};

pub const DecimalArray = struct {
    array: []f64, 
    pub fn eql(self: DecimalArray, other: DecimalArray) bool {
        if(self.array.len != other.array.len) {
            return false;
        }

        for(self.array) |decimal, index| {
            if(decimal != other.array[index]) {
                return false;
            }
        }

        return true;
    }
};

pub const UVAxis = struct {
    x: f64,
    y: f64,
    z: f64,
    translation: f64,
    total_scaling: f64,
    pub fn eql(self: UVAxis, other: UVAxis) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z and self.translation == other.translation and self.total_scaling == other.total_scaling;
    }
};

pub const Plane = struct {
    vtx1: Vertex,
    vtx2: Vertex,
    vtx3: Vertex,
    pub fn eql(self: Plane, other: Plane) bool {
        return self.vtx1.eql(other.vtx1) and self.vtx2.eql(other.vtx2) and self.vtx3.eql(other.vtx3);
    }
};

pub const ParseError = error{ UnexpectedToken, EmptyFile, EmptyClassName, UnexpectedEndOfFile };
