require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The controllable tag makes no output on the generated documentation entry
  class Controllable < BooleanTag
    def initialize
      @pattern = "controllable"
      super
    end
  end
end