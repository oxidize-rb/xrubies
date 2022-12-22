require_relative "value"

module Xrubies
  class Matrix
    class Entry
      RubyVersion = Value.define(:version, :slug, :minor, :sha256) do
        def docker_build_args
          to_h.transform_keys { |key| "RUBY_#{key.upcase}" }
        end
      end
    end
  end
end
