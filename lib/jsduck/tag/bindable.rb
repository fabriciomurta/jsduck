require "jsduck/tag/boolean_tag"

module JsDuck::Tag
  class Bindable < BooleanTag
    def initialize
      @pattern = "bindable"
      @signature = {:long => "bindable", :short => "BIND"}
      @css = ".signature .bindable { background-color: #ffb700 }" # yellow
      super
    end
  end
end
