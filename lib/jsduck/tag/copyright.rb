require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The copyright tag makes no output on the generated documentation entry
  # it is just part of the legacy headers in some Ext.NET code.
  # example: Ext.net.CapsLockDetector (source file header)
  class Copyright < BooleanTag
    def initialize
      @pattern = "copyright"
      super
    end
  end
end