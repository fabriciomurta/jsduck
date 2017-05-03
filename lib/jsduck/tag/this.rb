require "jsduck/tag/tag"

module JsDuck::Tag
  # Tag stub. Ignored.
  # @this {Type}
  class This < Tag
    def initialize
      @pattern = "this"
      super
    end
  end
end