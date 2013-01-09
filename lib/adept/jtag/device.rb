
module Adept
  module JTAG

    #
    # Generic JTAG Device.
    #
    # This class primarily exists to serve as a base for custom JTAG devices,
    # but also can be used to represent an unknown JTAG device.
    #
    class Device

      attr_accessor :idcode

      # An internal list of device types which can be recognized
      # on a JTAG bus.
      @device_types = []

      #
      # Once a class inherits from the JTAG Device class, register it as 
      # providing a device-type.
      #
      def self.inherited(klass)
        @device_types << klass
      end

      #
      # Factory method which creates a new Device whose type is determined
      # by the provided IDCode.
      #
      # idcode: The IDCode of the new JTAG device.
      # chain_offset:
      #   The amount of bits which must be transmitted to other devices before an instruction
      #   can be transmitted to this device- equal to the amount of bits to the _right_ of the
      #   active device on the scan chain.
      #
      def self.from_idcode(idcode, connection, chain_offset)

        #Find the first device type which supports the IDCode.
        device_type = @device_types.find { |type| type.supports?(idcode) }

        #If we weren't able to find a device, use this class as a generic wrapper.
        device_type ||= self

        #Otherwise, instantiate tha new device from the device type.
        device_type.new(idcode, connection, chain_offset)

      end

   
      #
      # Initializes a new JTAG Device.   #
      # Returns the expected instruction width of the JTAG device.
      #
      # In this case, we don't know what the instruction width will be,
      # so we'll assume the minimum possible width of four bits.
      #
      def instruction_width
        return 4
      end

      #
      # idcode: The IDCode of the new JTAG device.
      # scan_offset:
      #   The amount of bits which must be transmitted to other devices before an instruction
      #   can be transmitted to this device- equal to the amount of bits to the _right_ of the
      #   active device on the scan chain.
      #
      #
      def initialize(idcode, connection, chain_offset)
        @idcode = idcode
        @connection = connection
        @chain_offset = chain_offset
      end

      #
      # Returns the expected instruction width of the JTAG device.
      #
      # In this case, we don't know what the instruction width will be,
      # so we'll assume the minimum possible width of four bits.
      #
      def instruction_width
        return 4
      end

      #
      # Activate the device, and set its current operating instruction.
      # All other devices in the scan chain are placed in BYPASS.
      #
      def set_instruction(instruction)
        @connection.transmit_instruction(instruction, instruction_width, true, @chain_offset) 
      end

    end

  end
end
