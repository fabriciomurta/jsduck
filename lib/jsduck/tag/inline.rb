require "jsduck/tag/member_tag"
require "jsduck/doc/subproperties"

module JsDuck::Tag
  class Inline < MemberTag
    def initialize
      @pattern = "inline"
      @tagname = :inline
      @repeatable = true
      @member_type = {
        :title => "Inlinable function.",
        :toolbar_title => "INL",
        :position => MEMBER_POS_CFG,
        :icon => File.dirname(__FILE__) + "/icons/method.png"
      }
    end

    # @inline
    def parse_doc(p, pos)
      tag = p.standard_tag({
          :tagname => :cmdautodependency,
        })

      tag
    end

    def process_doc(h, tags, pos)
      p = tags[0]
      h[:tagname] = p[:tagname]
    end

    def process_code(code)
      h = super(code)
      h[:tagname] = code[:tagname]
      h
    end

    def to_html(cmdad, cls)
      member_link(cmdad) + " : " + cmdad[:html_type]
    end
  end
end
