require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The disable tag makes no output on the generated documentation entry
  # it is intended to disable the specified warning type (from a range of
  # supported warning types). This JSDuck version does not have support
  # for this feature currently. TODO: implement it.
  # example: Ext.Widget
  # syntax: @disable {WarningType}
  class Disable < BooleanTag
    def initialize
      @pattern = "disable"
      super
    end
  end
end