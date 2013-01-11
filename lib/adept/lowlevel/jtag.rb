require 'ffi'
require 'adept/lowlevel/adept_library'

module Adept
  module LowLevel

    #
    # Diglient JTAG (DJTG)
    # Wrapper for the low-level JTAG manipulation functions.
    #
    module JTAG
      extend AdeptLibrary

      #Wrap the JTAG library, libDJTG
      wrap_adept_library 'djtg'

      #
      # JTAG Support Query Functions
      #

      #Determines the number of JTAG ports that the given device provides.
      attach_adept_function :GetPortCount, [:ulong, :pointer]

      #Determines which interfaces the given JTAG port provides.
      attach_adept_function :GetPortProperties, [:ulong, :int32, :pointer]

      #Bit numbers for the call support functions.
      SUPPORTS_SET_SPEED = 0
      SUPPORTS_SET_PIN_STATE = 1


      #
      # Returns the number of JTAG ports the given device offers.
      #
      def self.port_count(device)

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
      def self.supported?(device)
        port_count(device).nonzero?
      end

      #
      # Returns a hash which indicates the calls that the given port supports.
      # Keys include:
      #   -set_speed, which sets the bit-rate of the JTAG connection.
      #   -set_pins, which sets the values of the JTAG pins directly.
      #
      def self.supported_calls(device, port_number)

        #Create a pointer to a new DWORD...
        properties_pointer = FFI::MemoryPointer.new(:ulong)

        #... and fill it with a bit-vector indicates supports for various system calls.
        GetPortProperties(device, port_number, properties_pointer)

        #Extract the property bit-vector from the
        properties = properties_pointer.get_ulong(0)

        #Return a hash which indicates which calls are supported.
        {
          :set_speed => properties[SUPPORTS_SET_SPEED].nonzero?,
          :set_pins  => properties[SUPPORTS_SET_PIN_STATE].nonzero?
        }

      end

      #
      # JTAG Enable/Disable calls.
      #

      #Enable the JTAG port with the given number. Only one JTAG device can be active at a time!
      attach_adept_function :EnableEx, [:ulong, :int32]

      #Disable the currently active JTAG port.
      attach_adept_function :Disable, [:ulong]

      #
      # JTAG speed manipulation calls
      #
     
      attach_adept_function :GetSpeed, [:ulong, :pointer]
      attach_adept_function :SetSpeed, [:ulong, :ulong, :pointer]

      #
      # Attempts to set the device's speed, in Hz.
      # Returns the actual speed set.
      #
      def self.get_speed(handle)
        get_speed_out_argument { |speed_out| GetSpeed(handle, speed_out) }
      end

      #
      # Attempts to set the device's speed, in Hz.
      # Returns the actual speed set.
      #
      def self.set_speed(handle, speed)
        get_speed_out_argument { |speed_out| SetSpeed(handle, speed, speed_out) }
      end


 
      #
      # JTAG Transmit/Receive Calls
      #

      attach_adept_function :PutTdiBits, [:ulong, :bool, :pointer, :pointer, :ulong, :bool]
      attach_adept_function :PutTmsBits, [:ulong, :bool, :pointer, :pointer, :ulong, :bool]
      attach_adept_function :PutTmsTdiBits, [:ulong, :pointer, :pointer, :ulong, :bool]
      attach_adept_function :GetTdoBits, [:ulong, :bool, :bool, :pointer, :ulong, :bool]
      attach_adept_function :ClockTck, [:ulong, :bool, :bool, :ulong, :bool]


      #
      # Sends (and recieves) raw data via the JTAG lines.
      #
      def self.transmit(handle, tms, tdi, bit_count, overlap=false)

        #If TMS and TDI were both provided as byte arrays, send them both.
        if tms.respond_to?(:size) and tdi.respond_to?(:size)

          #Convert the raw TMS/TDI values into an interleave bytes.
          interleave = interleave_tms_tdi_bytes(tms, tdi)

          #And perform an interleave transmission
          transmit_interleave(handle, interleave, bit_count, overlap)

        #If only TMS was provided as a byte array, use the specialized version of that function.
        elsif tms.respond_to?(:size)
          transmit_mode_select(handle, tms, tdi, bit_count, overlap)

        #If only TDI was provided as a byte array, use the specified version of that function.
        elsif tdi.respond_to?(:size)
          transmit_data(handle, tms, tdi, bit_count, overlap)

        #Otherwise, transmit only constant#Otherwise, transmit only constants.
        else
          transmit_constants(handle, tms, tdi, bit_count, overlap)
        end

      end

      #
      # Tick the Test Clock (TCK) without recieving data.
      #
      # device: The device with which to transmit.
      # tms_value: The static, /boolean/ value (true or false) to be held on TMS while the clock is ticked.
      # tdi_value: The static, /boolean/ value (true or false) to be held on TDI while the clock is ticked.
      # tick_count: The amount of times TCK should be ticked.
      #
      #
      def self.tick(handle, tms, tdi, tick_count, overlap=false)
        ClockTck(handle, tms, tdi, tick_count, overlap)
      end

      #
      # Transmits a stream of bits on the TMS (Test Mode Set) line.
      #
      # device: The device with which to transmit.
      # tms: A string (or array) of bytes, which will be transmitted over TMS.
      # tdi_value: The static, /boolean/ value (true or false) to be held on TDI while the TMS values are transmitted.
      # bit_count: The total number of bits to be transmitted.
      #
      # Returns the values recieved on TDO during the transmission.
      #
      def self.transmit_mode_select(handle, tms, tdi_value, bit_count, overlap=false)
        specialized_transmit(:PutTmsBits, handle, tdi_value, tms, bit_count, overlap)
      end

      #
      # Transmits a stream of bits on the TDI (test data in).
      #
      # device: The device with which to transmit.
      # tms_value: The static, /boolean/ value (true or false) to be held on TMS while the TDI values are transmitted.
      # tdi: A string (or array) of bytes, which will be transmitted over TDI.
      # bit_count: The total number of bits to be transmitted.
      #
      # Returns the values recieved on TDO during the transmission.
      #
      def self.transmit_data(handle, tms_value, tdi, bit_count, overlap=false)
        specialized_transmit(:PutTdiBits, handle, tms_value, tdi, bit_count, overlap)
      end

      #
      # Transmits a constant pair of TMS/TDI values, and recieves the TDO values that appear.
      #
      # device: The device with which to transmit.
      # tms_value: The static, /boolean/ value (true or false) to be held on TMS while the TD0 values are receieved.
      # tdi_value: The static, /boolean/ value (true or false) to be held on TDI while the TD0 values are receieved.
      # bit_count: The total number of bits to be received.
      #
      def self.transmit_constants(handle, tms_value, tdi_value, bit_count, overlap=false)

        #Determine the number of bytes to be transmitted...
        receive_bytes = (bit_count / 8.0).ceil

        #Transmit the given tms values...
        received = transmit_with(nil, receive_bytes) do |send_buffer, receive_buffer|
          GetTdoBits(handle, tms_value, tdi_value, receive_buffer, bit_count, overlap)
        end

        #... and return the values recieved on TDO.
        return received

      end

      #
      # When using JTAG, receiving is the same as transmitting a
      # long string of constant values. 
      #
      class << self
        alias_method :receive, :transmit_constants
      end


      #
      # Sends (and recieves) raw data via the JTAG lines.
      # Accepts input as an array of _interleaved_ bytes, in the format specified by the DJTG
      # reference manual.
      #
      # device: A reference to a Digilent Adept device.
      #
      # interleaved:
      #   An array or binary string of single-byte values, in the format specified in the
      #   DJTG reference manual. Each byte in the interleaved array should contain a _nibble_
      #   of TMS, and a nibble of TDI, in the following order:
      #
      #   TMS[3], TDI[3], TMS[2], TDI[2], TMS[1], TDI[1], TMS[0], TMS[0]
      #
      # bit_count: The total amount of bits to send.
      #
      def self.transmit_interleave(handle, interleave, bit_count, overlap = false)

        #Transmit the given interleave using out transmisison helper function.
        #
        #Note that we're expecting to recieve about half as many bits as are contained in the
        #interleave, as half of them are transmitted on TMS, and the other half on TDI.
        #
        receive_data = transmit_with(interleave, interleave.size / 2) do |send_buffer, receive_buffer|
          PutTmsTdiBits(handle, send_buffer, receive_buffer, bit_count, overlap)
        end

        #Return the recieved data.
        return receive_data

      end

      private

      #
      # Helper function which creates a buffer for a frequency out-argument.
      # Used for calling the get/set speed low-level functions.
      #
      def self.get_speed_out_argument

        #Reserve space in memory for the actual speed returned.
        speed_pointer = FFI::MemoryPointer.new(:ulong)

        #Attempt to set the JTAG connection's speed...
        yield speed_pointer

        #... and return the actual speed set.
        speed_pointer.get_ulong(0)

      end

      #
      # Helper function which calls the specialized Adept transmit functions.
      #
      # handle: The device with which to transmit.
      # tms: The tmi value to be provided to the
      # tdi: A string (or array) of bytes, which will be transmitted over TDI.
      # bit_count: The total number of bits to be transmitted.
      #
      # Returns the values recieved on TDO during the transmission.
      #

      def self.specialized_transmit(base_function_name, handle, static_value, dynamic_value, bit_count, overlap=false)

        byte_count = (bit_count / 8.0).ceil

        #Transmit the given values.
        received = transmit_with(dynamic_value, byte_count) do |send_buffer, receive_buffer|
          send(base_function_name, handle, static_value, send_buffer, receive_buffer, bit_count, overlap)
        end

        #... and return the values recieved on TDO.
        return received

      end


      #
      # Helper function which automatically handles the creation of the send/receive buffers
      # necessary for JTAG transactions.
      #
      # Accepts two arguments:
      #   transmit_data: The data to be transmitted; will be converted to a C byte array; or nil, if the send_buffer won't be used.
      #   receive_size: The amount of data to be received, in bytes. If not provided, the size of transmit_data will be used.
      #
      # Requires a block, which should accept two pointers:
      #   transmit_buffer: A FFI pointer to a block of memory which contains the transmit data.
      #   receive_buffer: A FFI pointer to a block of memory where the recieved data should be placed.
      #
      # Returns the contents of the recieve buffer after the block is called, as a ruby string.
      #
      def self.transmit_with(transmit_data, receive_size=nil)

        #If the transmit data was provided as a byte array, convert it to a string of bytes.
        if transmit_data.respond_to?(:pack)
          transmit_data = transmit_data.pack('C*').force_encoding('UTF-8')
        end

        #Create the recieve buffer.
        #If no receive size was provided, assume the same size as the data to be transmitted.
        receive_size ||= transmit_data.bytesize
        receive_buffer = FFI::MemoryPointer.new(receive_size)

        #If transmit data was provided, place it in contiguous memory and get a pointer to it.
        unless transmit_data.nil?
          send_buffer = FFI::MemoryPointer.new(transmit_data.bytesize)
          send_buffer.put_bytes(0, transmit_data)
        end

        #Yield the newly-created send and recieve buffer to the passed-in block.
        yield send_buffer, receive_buffer

        #And return the contents of the recieve buffer.
        return receive_buffer.get_bytes(0, receive_size)

      end

      #
      # Interleaves two sequences of TMS and TDI values into the format used by the Digilent
      # API.
      #
      # tms: A string (or array of bytes) to be used as TMS values in the interleave.
      # tdi: A string (or array of bytes) to be used as TDI values in the interleave.
      #
      # Returns a byte-string in the format used by transmit_interleave.
      #
      def self.interleave_tms_tdi_bytes(tms, tdi)

        #Ensure we have two byte arrays of the same length.
        raise ArgumentError, "You must specify the same amount of bytes for TDI and TMS!" if tdi.size != tms.size

        #If we were given a string-like object, handle it byte by byte.
        tms = tms.bytes if tms.respond_to?(:bytes)
        tdi = tdi.bytes if tdi.respond_to?(:bytes)

        #Merge the two arrays into a single array of byte-pairs.
        byte_pairs = tms.zip(tdi)

        #Convert each of the byte pairs into pairs of interleave bytes.
        interleave = byte_pairs.map { |tms_byte, tdi_byte| interleave_tms_tdi_byte_pair(tms_byte, tdi_byte) }

        #And flatten the pairs into a long array of interleave bytes.
        interleave.flatten.pack('C*').force_encoding('UTF-8')

      end

      #
      # Interleaves a single byte of TDI with a single byte of TMS, creating two bytes
      # of interleave data.
      #
      def self.interleave_tms_tdi_byte_pair(tms, tdi)

        #Ensure that the two values we have are represented as numbers.
        tms = tms.ord
        tdi = tdi.ord

        #Interleave the lower and upper nibbles of each of the two values.
        lower = interleave_tms_tdi_nibble_pair(tms, tdi)
        upper = interleave_tms_tdi_nibble_pair(tms >> 4, tdi >> 4)

        #Return the interleave bytes in little endian order.
        return lower, upper

      end

      #
      # Interleaves a single nibble of TMS and TDI data, creating a new byte.
      # See transmit_interleave (or the Digilent DJTG API) for the interleave format.
      #
      def self.interleave_tms_tdi_nibble_pair(tms, tdi)
          #Interleave the TMS and TDI values into a new byte.
          new_byte = [tms[3], tdi[3], tms[2], tdi[2], tms[1], tdi[1], tms[0], tdi[0]]

          #And convert the new byte into a ruby fixnum.
          new_byte.join.to_i(2)
      end

    end
  end
end

