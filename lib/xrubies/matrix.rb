require_relative "matrix/entry"

module Xrubies
  class Matrix
    include Enumerable

    def initialize(raw_matrix = nil)
      @raw_matrix = raw_matrix || begin
        require "yaml"

        YAML.load_file(File.join(__dir__, "../../matrix.yml"))
      end
    end

    def each
      return enum_for(:each) unless block_given?

      @raw_matrix.fetch("ruby-platform").each do |ruby_platform|
        ruby_platform = Entry::RubyPlatform.from_yaml(ruby_platform)

        @raw_matrix.fetch("ruby-version").each do |ruby_version|
          ruby_version = Entry::RubyVersion.from_yaml(ruby_version)

          ruby_platform.images.each do |image|
            image = Entry::Image.from_yaml(image)

            yield Entry.new(ruby_version: ruby_version, ruby_platform: ruby_platform, image: image)
          end
        end
      end
    end
  end
end
