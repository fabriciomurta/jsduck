require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The version tag makes no output on the generated documentation entry
  # it is just part of the legacy headers in some Ext.NET code.
  # example: Ext.net.CapsLockDetector (source file header)
  class Version < BooleanTag
    def initialize
      @pattern = "version"
      super
    end
  end
end