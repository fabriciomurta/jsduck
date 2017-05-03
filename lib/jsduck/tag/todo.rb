require "jsduck/tag/tag"

module JsDuck::Tag
  # Causes a member or entire class documentation to be completely
  # excluded from docs. Matches:
  # @cmd
  # @cmd.optimizer.requires.async (...etc)
  class TodoUC < Tag
    def initialize
      @pattern = "TODO"
      super
    end
  end

  class TodoLC < Tag
    def initialize
      @pattern = "todo"
      super
    end
  end

  class TodoCC < Tag # camel case
    def initialize
      @pattern = "Todo"
      super
    end
  end
end