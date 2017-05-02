require "jsduck/tag/tag"

module JsDuck::Tag
  class Define < Tag
    def initialize
      @pattern = "define"
      @ext_define_pattern = "define"
      @repeatable = false
    end

    # @define Ex.util.Operators
    def parse_doc(p, pos)
      {
        :tagname => :defines,
        :name => p
      }
    end

    def parse_ext_define(cls, ast)
      cls[:aliases] += ast
    end
  end
end
