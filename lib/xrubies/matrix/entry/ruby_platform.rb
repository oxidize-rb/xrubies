require_relative "value"

module Xrubies
  class Matrix
    class Entry
      RubyPlatform = Value.define(:slug, :rust_target, :dir, :images) do
        def docker_build_args
          {"RUBY_TARGET" => slug, "RUST_TARGET" => rust_target}
        end
      end
    end
  end
end
