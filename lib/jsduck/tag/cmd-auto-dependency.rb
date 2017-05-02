require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # Causes a member or entire class documentation to be completely
  # excluded from docs.
  class CmdAutoDependency < BooleanTag
    def initialize
      @pattern = "cmd-auto-dependency"
      super
    end
  end
end