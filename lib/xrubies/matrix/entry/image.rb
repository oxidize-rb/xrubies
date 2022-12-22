require_relative "value"

module Xrubies
  class Matrix
    class Entry
      Image = Value.define(:slug, :tag, :docker_platforms) do
        alias_method(:os, :slug)

        def docker_build_args
          {"BASE_IMAGE_TAG" => tag}
        end
      end
    end
  end
end
