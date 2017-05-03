require 'jsduck/tag_registry'
require 'jsduck/util/md5'
require 'jsduck/web/class_icons'
require 'jsduck/web/member_icons'

module JsDuck
  module Web

    # Writes the CSS gathered from Tag classes and --css option into given file.
    # Then Renames the file so it contains an MD5 hash inside it,
    # returning the resulting fingerprinted name.
    class Css
      def initialize(opts)
        @opts = opts
      end

      def write(filename)
        #File.open(filename, 'w') {|f| f.write(all_css) }
        File.open(filename, 'w') {|f| f.write(noicon_css) }
        Util::MD5.rename(filename)
      end

      private

      # icon CSS lines are overlapping with resources/images/icons
      # usage by extjs's docs/resources/css/app.css.
      def noicon_css
        [
          css_from_tags,
          @opts.css,
        ].join
      end

      def all_css
        [
          css_from_tags,
          Web::ClassIcons.css,
          Web::MemberIcons.css,
          @opts.css,
        ].join
      end

      # Returns all the CSS gathered from @css attributes of tags.
      def css_from_tags
        TagRegistry.tags.map(&:css).compact.join("\n")
      end
    end

  end
end
