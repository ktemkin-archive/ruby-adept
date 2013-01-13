
module Adept
  module LowLevel

    #
    # Wrapper for Digilent Device Manager errors, which allows
    # errors raised from the low-level SDK to be handled like ruby exceptions.
    #
    class DeviceError < StandardError

      attr_accessor :short_name
      attr_accessor :code

      def initialize(message, short_name, code=nil)
        @short_name = short_name
        @code = code
        super(message)
      end

    end
  end
end
