// Workspace: Target Program

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:470.
//
#place b;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:471.
//
#place a;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:471.
//
#place a;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:470.
//
#place b;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:470.
//
#place b;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/pixel.jai:468.
//
#place r;components: [FIELD_COUNT]FieldType = ---;

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/struct_utilities.jai:39.
//
if String.compare(member_name, "width") == 0 { s.width = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "height") == 0 { s.height = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "position_x") == 0 { s.position_x = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "position_y") == 0 { s.position_y = cast(s32) String.parse_int(*value); }
else if String.compare(member_name, "fullscreen") == 0 { s.fullscreen = cast(bool) String.parse_bool(*value); }

//
// #insert text. Generated from C:/Users/cauti/programs/jai/modules/MinamiEngine/struct_utilities.jai:107.
//
print_to_builder(*file_builder, "width = %\n", s.width);
print_to_builder(*file_builder, "height = %\n", s.height);
print_to_builder(*file_builder, "position_x = %\n", s.position_x);
print_to_builder(*file_builder, "position_y = %\n", s.position_y);
print_to_builder(*file_builder, "fullscreen = %\n", s.fullscreen);
