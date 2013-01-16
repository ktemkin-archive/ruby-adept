
require 'ffi'
require 'adept/low_level/library'

module Adept
  module LowLevel

    #
    # Low-Level Enhanced Parallel Port (EPP) Connection
    #
    module EnhancedParallel
      extend LowLevel::Library

      #Wrap the Digilent Enhanced Parallel Port library, DEPP
      wrap_adept_library 'depp'

      #And mix-in the low-level connection module.
      extend LowLevel::Connection

      #
      # Simple register read/write.
      #

      #Set the value of a given register.
      attach_adept_function :PutReg, [:ulong, :uint8, :uint8, :bool]

      #Get the value of a given register.
      attach_adept_function :GetReg, [:ulong, :uint8, :pointer, :bool]


      #
      # Sets the value of a given EPP register.
      # This function exists for symettry with get_register_value.
      #
      # handle: The handle to the target device.
      # address: 
      #   The address of the register to be set, may by from [0..255], though
      #   not all EPP devices will provide all 256 registers.
      # value: 
      #   The value to be placed into the register. Should be within the range 
      #   [0..255].
      #
      # overlap: True to make the operation non-blocking.
      #
      # 
      def self.set_register_value(handle, address, value, overlap=false)
        PutReg(handle, address, value, false)
      end

      #
      # Returns the value of a single EPP register.
      #
      def self.get_register_value(handle, address, overlap=false)
        receieve_out_arguments(:uint8) { |receive_buffer| GetReg(handle, address, receive_buffer, overlap) }
      end

      #
      # Multiple register ("set") read/write.
      #
      
      #Sets the value of a collection of registers.
      attach_adept_function :PutRegSet, [:ulong, :pointer, :ulong, :bool]

      #Gets the value of a collection of registers.
      attach_adept_function :GetRegSet, [:ulong, :pointer, :pointer, :ulong, :bool]


      #
      # Sets the value of multiple registers at once.
      #
      # handle: The handle of the affected adept device.
      # mapping: A hash mapping addresses to values. 
      #   For example { 3 => 4, 9 => 5} would place 4 in register 3, and 5 in register 9.
      #
      # overlap: True to make the operation non-blocking.
      #
      def self.set_register_values(handle, mapping, overlap=false)

        #Create a buffer, which contains each of the register => value pairs.
        value_buffer = to_buffer(mapping.flatten)

        #And set each of the register values.
        PutRegSet(handle, value_buffer, mapping.size, overlap)
      
      end


      #
      # Gets the value of mulitple registers at once.
      # 
      # handle: The handle of the affected adept device.
      # addresses: A list of register values to get. Must support to_a.
      # overlap: True to make the operation non-blocking.
      #
      def self.get_register_values(handle, addresses, overlap=false)

        #Create a buffer containing each of the addresses to query.
        address_buffer = to_buffer(addresses)
       
        #And perform the query itself, returning 
        out_args = receive_out_arguments(addresses.count) do 
          |data_buffer| GetRegSet(handle, address_buffer, data_buffer, addresses.count, overlap)
        end

        #Pair each of the addresses with the corresponding data value received.
        pairs = addresses.zip(out_args.unpack("C*"))

        #Convert that response to a hash, and return it.
        Hash[pairs]

      end

      #
      # Repeated ("serial") read/write operations.
      #
      
      #Write each of a colleciton of bytes to a given register, in order.
      attach_adept_function :PutRegRepeat, [:ulong, :uint8, :pointer, :ulong, :bool]

      #Read a colleciton of bytes from a given register, in order.
      attach_adept_function :GetRegRepeat, [:ulong, :uint8, :pointer, :ulong, :bool]


      #
      # Sends a "stream" of data to a single register, by repeatedly writing to
      # that register. Some hardware targets may be able to interpret these repeated 
      # writes as a data-stream.
      #
      # handle: The handle of the affected adept device.
      # address: The address of the register to target; should be within [0..255].
      # data: An array (or array-like object) containing the data to be sent. Index
      #   0 is sent first, followed by 1, and etc.
      #
      # overlap: True to make the operation non-blocking.
      #
      def send_to_register(handle, address, data, overlap=false)

        #Create a buffer containing the data to be sent.
        data_buffer = to_buffer(data)

        #And send the relevant data.
        PutRegRepeat(handle, address, data_buffer, data.size, overlap)

      end


    end

  end
end
