require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  # The locale tag makes no output on the generated documentation entry
  # example: Ext.data.validator.AbstractDate.message (config)
  class Locale < BooleanTag
    def initialize
      @pattern = [ "locale", "Locale" ]
      super
    end
  end
end