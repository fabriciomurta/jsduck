require 'jsduck/util/html'
require 'jsduck/logger'
require 'jsduck/type_parser'

module JsDuck
  module Format

    # Helper for recursively formatting subproperties.
    class Subproperties

      def initialize(formatter)
        @formatter = formatter
        @skip_type_parsing = false
      end

      # Set to true to skip parsing and formatting of types.
      # Used to skip parsing of SCSS typesdefs.
      attr_accessor :skip_type_parsing

      # Takes a hash of param, return value, throws value or subproperty.
      #
      # - Markdown-formats the :doc field in it.
      # - Parses the :type field and saves HTML to :html_type.
      # - Recursively does the same with all items in :properties field.
      #
      def format(item)
        item[:doc] = @formatter.format(item[:doc]) if item[:doc]

        if item[:type]
          item[:html_type] = format_type(item[:type])
        end

        if item[:properties]
          item[:properties].each {|p| format(p) }
        end
      end

      # Formats the given type definition string using TypeParser.
      #
      # - On success returns HTML-version of the type definition.
      # - On failure logs error and returns the type string with only HTML escaped.
      #
      def format_type(types)
        # Skip the formatting entirely when type-parsing is turned off.
        return Util::HTML.escape(types) if @skip_type_parsing

        tp = TypeParser.new(@formatter)

        typelist = types.split("/")

        result = ""
        for type in typelist[0]
         if tp.parse(type)
           tp.out
         else
           context = @formatter.doc_context
           if tp.error == :syntax
             if typelist.length > 1
               Logger.warn(:type_syntax, "Incorrect type syntax #{type} (in [#{types.join("/")}])", context)
             else
               Logger.warn(:type_syntax, "Incorrect type syntax #{type}", context)
            end
           else
            if typelist.length > 1
              Logger.warn(:type_name, "Unknown type #{type} (in [#{types.join("/")}])", context)
              raise("Raising exception upon type not found occurrence (#{type} in [#{types.join("/")}])." +
                Thread.current.backtrace.join("\n")
              )
            else
              Logger.warn(:type_name, "Unknown type #{type}", context)
              raise("Raising exception upon type not found occurrence (#{type})." +
                Thread.current.backtrace.join("\n")
             )
            end
           end
           result += Util::HTML.escape(type)
         end
        end
        result
      end

    end

  end
end
