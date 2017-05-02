require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The cancelable tag makes no output on the generated documentation entry
  # example: Ext.view.Table.beforerowexit (event)
  class Cancelable < BooleanTag
    def initialize
      @pattern = "cancelable"
      super
    end
  end
end