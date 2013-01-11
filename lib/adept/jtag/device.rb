
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

      #Assume an instruction width of 4; the minimum possible insruction width.
      #This should be re-defined in each inheriting class.
      InstructionWidth = 4

      # An internal list of device types which can be recognized
      # on a JTAG bus.
      @device_types = []

      #
      # Hook which is executed when a class inherits from the JTAG Device
      # class. Registers the class as a Device Type provider, and sets up
      # the device's basic metaprogramming abilities.
      #
      def self.inherited(klass)

        #Register the class as device-type provider...
        @device_types << klass
        
        #And set up the "supports_idcode" metaprogramming facility.
        klass.instance_variable_set(:@supported_idcodes, [])

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
      # Default implementation for detection of IDCode support.
      # Checks to see if any of the IDcode matches any of this class's masks.
      #
      def self.supports?(idcode) 
        @supported_idcodes.any? { |mask| idcode_matches_mask(mask, idcode) }
      end


      #
      # Returns the expected instruction width of the JTAG device.
      #
      # In this case, we don't know what the instruction width will be,
      # so we'll assume the minimum possible width of four bits.
      #
      def instruction_width
        return self.class::InstructionWidth 
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
      # Activate the device, and set its current operating instruction.
      # All other devices in the scan chain are placed into BYPASS.
      #
      def instruction=(instruction)

        #If we were provided an instruction name, look up the corresponding instruction.
        instruction = self.class::Instructions[instruction] if instruction.kind_of?(Symbol)
  
        #If we have a packable number, pack it into a byte-string.
        instruction = [instruction].pack("C*") if instruction.kind_of?(Numeric)

        #Transmit the instruction itself.
        @connection.transmit_instruction(instruction, instruction_width, true, @chain_offset)
      end

      #
      # TODO: Handle instruction readback, by rotating instructions through the device.?
      #

      #
      # Send data directly to (and receive data directly from) the given device.
      # Assumes the current device is active, and all other devices are in bypass.
      #
      def transmit_data(data, bit_count)
        @connection.transmit_data(data, bit_count, true, @position_in_chain)
      end

      #
      # Recieves data directly from the given device by sending the device an 
      # appropriately-sized string of zeroes.
      # Assumes the current device is active, and all other devices are in bypass.
      # 
      #
      def receive_data(bit_count)
        @connection.transmit_data(false, bit_count, true, @position_in_chain)
      end

      #
      # Allows the device to run its test operation for a certain amount of TCK cycles.
      # (Delegates the run_test operation to the JTAG connection object, which is in charge
      #  of the TAP state.)
      #
      def run_test(cycles) 
        @connection.run_test(cycles)
      end


      private

      #
      # Metaprogramming routine which indicates that the class being defined
      # supports an IDcode mask.
      #
      def self.supports_idcode(*idcodes) 
        
        #And merge them with the known supported IDcodes.
        @supported_idcodes |= idcodes

      end

      #
      # Determines if a given IDCode matches a hex mask.
      #
      def self.idcode_matches_mask(mask, idcode)

        #Convert the IDcode into a string, for comparison.
        idcode = idcode.unpack("H*").first.downcase

        #Get a set of pairs containing the characters with the same position in each string.
        character_pairs = mask.downcase.chars.zip(idcode.chars) 

        #And verify that each character is either a match, or a Don't Care.
        character_pairs.all? { |m, i| m == 'x' || m  == i }

      end

    end

  end
end
