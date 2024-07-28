#import "CurryEngine";
#import "Compiler";
#import "Basic";

build :: () {
    project_directory := get_working_directory();
    if !create_assets_file() then return;
    set_working_directory(project_directory);

    w := compiler_create_workspace();
    options := get_build_options(w);
    options.output_executable_name = "main";
    set_build_options(options, w);
    add_build_file("main.jai", w); 
    set_build_options_dc(.{do_output=false});
}

#run build();
