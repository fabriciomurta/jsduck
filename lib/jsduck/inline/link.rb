require 'jsduck/logger'
require 'jsduck/member_registry'

module JsDuck
  module Inline

    # Implementation of inline tag {@link}
    #
    # It also takes care of the auto-detection of links in text
    # through the #create_magic_links method.
    class Link
      # Sets up instance to work in context of particular class, so
      # that when {@link #blah} is encountered it knows that
      # Context#blah is meant.
      attr_accessor :class_context

      # Sets up instance to work in context of particular doc object.
      # Used for error reporting.
      attr_accessor :doc_context

      def initialize(link_renderer)
        @class_context = ""
        @doc_context = {}
        @relations = link_renderer.relations
        @renderer = link_renderer
        @re = /\{@link\s+(\S*?)(?:\s+(.+?))?\}/m
      end

      # Takes StringScanner instance.
      #
      # Looks for inline tag at the current scan pointer position, when
      # found, moves scan pointer forward and performs the apporpriate
      # replacement.
      def replace(input)
        if input.check(@re)
          input.scan(@re).sub(@re) { apply_tpl($1, $2, $&) }
        else
          false
        end
      end

      # applies the link template
      def apply_tpl(target, text, full_link)
        if target =~ /^(.*)#(static-)?#{MemberRegistry.regex}?(.*)$/
          cls = $1.empty? ? @class_context : $1
          static = $2 ? true : nil
          type = $3 ? $3.intern : nil
          member = $4
        else
          cls = target
          static = nil
          type = false
          member = false
        end

        # Construct link text
        if text
          text = text
        elsif member
          text = (cls == @class_context) ? member : (cls + "." + member)
        else
          text = cls
        end

        if !@relations[cls]
          # Check if it is a link provided in the "{@link <url> <text>}" format
          (tag, link, placeholder) = full_link[1..-2].split(" ")
          
          if (placeholder != nil)
            text="<a href=\"" + link + "\">" + placeholder + "</a>"
          else
            Logger.warn(:link, "#{full_link} links to non-existing class", @doc_context)
          end

          return text
        elsif member
          ms = @renderer.find_members(cls, {:name => member, :tagname => type, :static => static})
          if ms.length == 0
            Logger.warn(:link, "#{full_link} links to non-existing member", @doc_context)
            return text
          end

          if ms.length > 1
            # When multiple public members, see if there remains just
            # one when we ignore the static members. If there's more,
            # report ambiguity. If there's only static members, also
            # report ambiguity.
            instance_ms = ms.find_all {|m| !m[:static] }
            if instance_ms.length > 1
              alternatives = instance_ms.map {|m| "#{m[:tagname]} in #{m[:owner]}" }.join(", ")
              Logger.warn(:link_ambiguous, "#{full_link} is ambiguous: "+alternatives, @doc_context)
            elsif instance_ms.length == 0
              static_ms = ms.find_all {|m| m[:static] }
              alternatives = static_ms.map {|m| "static " + m[:tagname].to_s }.join(", ")
              Logger.warn(:link_ambiguous, "#{full_link} is ambiguous: "+alternatives, @doc_context)
            end
          end

          return @renderer.link(cls, member, text, type, static)
        else
          return @renderer.link(cls, false, text)
        end
      end

    end

  end
end
