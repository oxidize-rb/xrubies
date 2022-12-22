module Xrubies
  class Matrix
    class Value
      def self.define(*keys, &blk)
        struct = Struct.new(*keys, keyword_init: true, &blk)
        struct.extend(ClassMethods)
        struct
      end

      module ClassMethods
        def from_yaml(yaml)
          kwargs = yaml.transform_keys do |key|
            key.tr("-", "_").to_sym
          end

          new(**kwargs)
        end
      end
    end
  end
end
