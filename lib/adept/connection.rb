
require 'ffi'

module Adept
  module LowLevel

    #
    # Module mix-in which adds the basic functionality for 
    #
    module Connection

      #
      # Hook which runs whenever a module extends AdeptConnection.
      #
      def self.extended(base)

        #Attach each of the relevant functions to the extending class.
        base.module_eval do
        
          #Returns the amount of connections the given port provides.
          attach_adept_function :GetPortCount, [:ulong, :pointer]

          #Enable the JTAG port with the given number. Only one JTAG device can be active at a time!
          attach_adept_function :EnableEx, [:ulong, :int32]

          #Disable the currently active JTAG port.
          attach_adept_function :Disable, [:ulong]

        end
      end

      #
      # Returns the number of JTAG ports the given device offers.
      #
      def port_count(device)

        #Create a pointer to a new Int32 in memory...
        count_pointer = FFI::MemoryPointer.new(:int32)

        #... and fill it with the number of available JTAG ports.
        GetPortCount(device, count_pointer)

        #Return the acquired count as a ruby integer.
        count_pointer.get_int32(0)

      end

      #
      # Returns a true-like value if the given device supports JTAG,
      # or nil if it does not.
      #
      def supported?(device)
        port_count(device).nonzero?
      end
   
    end

  end
end
