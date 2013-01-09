
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
      # position_in_chain:
      #   The device's position in the chain.  The first device to recieve data will have
      #   the highest device number. In a two device chain, Device 1 will recieve data before
      #   Device 0.
      # chain_offset:
      #   The amount of bits which must be transmitted to other devices before an instruction
      #   can be transmitted to this device- equal to the amount of bits to the _right_ of the
      #   active device on the scan chain.
      #
      def self.from_idcode(idcode, connection, position_in_chain, chain_offset)

        #Find the first device type which supports the IDCode.
        device_type = @device_types.find { |type| type.supports?(idcode) }

        #If we weren't able to find a device, use this class as a generic wrapper.
        device_type ||= self

        #Otherwise, instantiate tha new device from the device type.
        device_type.new(idcode, connection, position_in_chain, chain_offset)

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
      def initialize(idcode, connection, position_in_chain, chain_offset)
        @idcode = idcode
        @connection = connection
        @position_in_chain = position_in_chain
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
      # All other devices in the scan chain are placed into BYPASS.
      #
      def instruction=(instruction)
        @connection.transmit_instruction(instruction, instruction_width, true, @chain_offset)
      end

      #
      # TODO: Handle instruction readback, by rotating instructions through the device.
      #

      #
      # Send data directly to the given device. Assumes the current device is
      # active, and all other devices are in bypass.
      #
      def transmit_data(data, bit_count)
        @connection.transmit_data(data, bit_count, true, @position_in_chain)
      end

    end

  end
end
