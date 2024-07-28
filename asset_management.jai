
CurryAssetReference :: struct {
    asset_path: string;
    name_hash: u64;
}

create_assets_file :: () -> bool {
    HASH_SEED :: 1;
    // TODO: relative paths, file watching, etc.
    asset_directory := tprint("%\\%", get_working_directory(), "assets");
    sprite_files := find_all_files_with_extension(asset_directory, "cspr");
    end_assets_path_index := asset_directory.count+1;
    // log("creating sprite file asset entries for ...");

    sprite_names : [..]string;
    sprite_hashes : [..]u64;
    sprite_path_indices : [..]s64;
    defer array_free(sprite_names);
    defer array_free(sprite_hashes);
    defer array_free(sprite_path_indices);

    for *sprite_files {
        split_success, _, filename_with_ext := String.split_from_right(<<it, #char "/");
        if split_success {
            name_success, filename, _ := String.split_from_right(filename_with_ext, #char ".");
            if name_success {
                for c : 0..it.count-1 {
                    if it.data[c] == #char "\\" {
                        it.data[c] = #char "/";
                    }
                }
                // log("sprite file: %", filename);
                array_add(*sprite_names, copy_string(filename));
                array_add(*sprite_hashes, native_XXH64(filename.data, xx filename.count, seed=HASH_SEED));
                array_add(*sprite_path_indices, it_index);
            }
        }
    }
    for i : 0..sprite_hashes.count-2 {
        for j : i+1..sprite_hashes.count-1 {
            if sprite_hashes[i] == sprite_hashes[j] {
                log_hash_collision(sprite_files, sprite_names, sprite_hashes, sprite_path_indices, i, j);
                return false;
            }
        }
    }
    for i : 0..sprite_names.count-1 {
        sprite_name := sprite_names[i];
        for c : 0..sprite_name.count-1 {
            sprite_name[c] = to_upper(sprite_name[c]);
        }
    }

    file_builder : String_Builder;

    for i : 0..sprite_names.count-1 {
        full_path := sprite_files[sprite_path_indices[i]];
        path := String.slice(full_path, end_assets_path_index, full_path.count-end_assets_path_index);
        name := sprite_names[i];
        hash := sprite_hashes[i];
        print_to_builder(
            *file_builder, 
            "SPRITE_% :: CurryAssetReference.{\"%\", %};\n", 
            name, path, hash
        );
    }

    file_path := "assets.jai";
    file_string := builder_to_string(*file_builder);
    write_entire_file(file_path, file_string);
    return true;
}

log_hash_collision :: (
    asset_paths: []string, asset_names: [..]string, asset_hashes: [..]u64, path_indices: [..]s64, i: s64, j: s64
) {
        log(
#string END
hash collision between files:
name: %, full path: %, hash: %
name: %, full_path: %, hash: %
exiting 
END,
        asset_names[i], asset_paths[path_indices[i]], asset_hashes[i],
        asset_names[j], asset_paths[path_indices[j]], asset_hashes[j],
    );
}
