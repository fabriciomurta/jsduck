require "jsduck/tag/member_tag"
require "jsduck/doc/subproperties"

module JsDuck::Tag
  class Example < MemberTag
    def initialize
      @pattern = "example"
      @tagname = :example
      @repeatable = true
      @member_type = {
        :title => "Example code",
        :toolbar_title => "EPL",
        :position => MEMBER_POS_CFG,
        :icon => File.dirname(__FILE__) + "/icons/class.png"
      }
    end

    # @example
    # Ignores next sample lines -- bolds the "example" word instead.
    def parse_doc(p, pos)
      tag = p.standard_tag({
          :tagname => :cmd,
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
      "<strong>" + member_link(cmdad) + " : " + cmdad[:html_type] + "</strong>"
    end
  end
end
