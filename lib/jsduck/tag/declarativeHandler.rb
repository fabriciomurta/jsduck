require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The declarativeHandler tag makes no output on the generated documentation
  # entry
  # Apparently it allows a config option without an actual implementation on
  # code to have a documentation output.
  # For example, Ext.tree.Column.renderer is documented although not present
  # on the code.
  class DeclarativeHandler < BooleanTag
    def initialize
      @pattern = "declarativeHandler"
      super
    end
  end
end