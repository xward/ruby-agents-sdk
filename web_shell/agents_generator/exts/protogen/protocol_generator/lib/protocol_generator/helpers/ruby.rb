module ProtocolGenerator

  module Helpers

    module Ruby

      # @return a valid Ruby module name from a given protocol.
      # If protocol.package is set to "com.test.example" and protocol.name is set to "MyProtocol" then the resulting
      # module name is Com_test_example_MyProtocol
      def self.protocol_module_name(protocol)
        package = protocol.package.gsub('.', '_').capitalize!
        "#{package}_#{protocol.name}"
      end

    end

  end

end