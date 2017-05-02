require "jsduck/tag/tag"

module JsDuck::Tag
  # Causes a member or entire class documentation to be completely
  # excluded from docs. Matches:
  # @cmd
  # @cmd.optimizer.requires.async (...etc)
  class Cmd < Tag
    def initialize
      @pattern = "cmd"
      super
    end
  end
end