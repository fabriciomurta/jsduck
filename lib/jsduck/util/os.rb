require 'rbconfig'

module JsDuck
  module Util

    # Simple helper class to detect operating system
    class OS
      def self.windows?
        RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
      end
    end

  end
end
