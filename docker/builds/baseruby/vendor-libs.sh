#!/bin/bash

main() {
  echo "Copying all the libraries into the vendor directory" >&2;
  local ruby_install_dir="$1"
  install_patchelf

  mkdir -p "$ruby_install_dir"/vendor/lib
  ruby_main="$ruby_install_dir/bin/ruby"
  ruby_libs="$(find "$ruby_install_dir" -type f -name '*.so')"
  libs_to_patch="$ruby_main $ruby_libs"

  mkdir -p "$ruby_install_dir/vendor/lib"

  needed=()

  for lib in ${libs_to_patch}; do
    for dep in $(patchelf --print-needed "$lib" | grep -E '(libffi|libnurses|libreadline|libsqlite|libssl|libyaml|libz)'); do
      needed+=("$dep")
    done
  done

  for lib in "${needed[@]}"; do
    if [ ! -f "$ruby_install_dir/vendor/lib/$lib" ]; then
      echo "Vendoring $lib" >&2
      cp -v "$(ldconfig -p | grep "$lib" | cut -d ">" -f 2 | xargs)" "$ruby_install_dir/vendor/lib"
    fi
  done

  echo "Patch the rpath of the ruby binary and all the gem libraries" >&2
  for lib in $libs_to_patch; do
    relative_path_to_vendor_lib="$(realpath --relative-to="$(dirname "$lib")" "$ruby_install_dir"/vendor/lib)"
    patchelf --set-rpath "\$ORIGIN/$relative_path_to_vendor_lib:$(patchelf --print-rpath "$lib")" "$lib";
  done;

  rm "${0}"
}

main "$@"
