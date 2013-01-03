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
        GetPortCount(device.handle, count_pointer)


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
        GetPortProperties(device.handle, port_number, properties_pointer)

        #Extract the property bit-vector from the 
        properties = properties_pointer.get_ulong(0)

        #Return a hash which indicates which calls are supported.
        {
          :set_speed => properties[0].nonzero?,
          :set_pins  => properties[1].nonzero?
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
      # JTAG 
      #
      
      attach_adept_function :PutTdiBits, [:ulong, :bool, :pointer, :pointer, :ulong, :bool]
      attach_adept_function :PutTmsBits, [:ulong, :bool, :pointer, :pointer, :ulong, :bool]
      attach_adept_function :PutTmsTdiBits, [:ulong, :pointer, :pointer, :ulong, :bool]
      attach_adept_function :GetTdoBits, [:ulong, :bool, :bool, :pointer, :ulong, :bool]
      attach_adept_function :ClockTck, [:ulong, :bool, :bool, :ulong, :bool]


      #
      # Sends (and recieves) raw data via the JTAG lines.
      #
      def self.transmit(device, tms, tdi, bit_count)

        #If TMS and TDI were both provided as byte arrays, send them both.
        if tms.respond_to?(:size) and tdi.respond_to?(:size)

          #Convert the raw TMS/TDI values into an interleave bytes.
          interleave = interleave_tms_tdi_bytes(tms, tdi)

          #And perform an interleave transmission
          transmit_interleave(device, interleave, bit_count)

        #If only TMS was provided as a byte array, use the specialized version of that function.
        elsif tms.respond_to?(:size)
          transmit_mode_select(device, tms, tdi, bit_count)

        #If only TDI was provided as a byte array, use the specified version of that function.
        elsif tdi.respond_to?(:size)
          transmit_data(device, tms, tdi, bit_count)

        #Otherwise, passively recieve data.
        else
          receive(device, tms, tdi, bit_count) 
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
      def tick(device, tms, tdi, tick_count)
        ClockTck(device.handle, tms, tdi, bit_count, false)
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
      def self.transmit_mode_select(device, tms, tdi_value, bit_count)

        #Transmit the given tms values...
        received = transmit_with(tms) do |send_buffer, receive_buffer| 
          PutTmsBits(device.handle, tdi_value, send_buffer, receive_buffer, bit_count, false)
        end

        #... and return the values recieved on TDO.
        return received

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
      def self.transmit_data(device, tms_value, tdi, bit_count)

        #Transmit the given tms values...
        received = transmit_with(tdi) do |send_buffer, receive_buffer| 
          PutTdiBits(device.handle, tms_value, send_buffer, receive_buffer, bit_count, false)
        end

        #... and return the values recieved on TDO.
        return received

      end

      #
      # Transmits a constant pair of TMS/TDI values, and recieves the TDO values that appear.
      #
      # device: The device with which to transmit.
      # tms_value: The static, /boolean/ value (true or false) to be held on TMS while the TD0 values are receieved.
      # tdi_value: The static, /boolean/ value (true or false) to be held on TDI while the TD0 values are receieved.
      # bit_count: The total number of bits to be received.
      #
      def self.receive(device, tms_value, tdi_value, bit_count)
      
        #Determine the number of bytes to be transmitted...
        receive_bytes = (bit_count / 8.0).ceil

        #Transmit the given tms values...
        received = transmit_with(nil, receive_bytes) do |send_buffer, receive_buffer| 
          GetTdoBits(device.handle, tms_value, tdi_value, receive_buffer, bit_count, false)
        end

        #... and return the values recieved on TDO.
        return received

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
      def self.transmit_interleave(device, interleave, bit_count)

        #Transmit the given interleave using out transmisison helper function.
        #
        #Note that we're expecting to recieve about half as many bits as are contained in the
        #interleave, as half of them are transmitted on TMS, and the other half on TDI.
        #
        receive_data = transmit_with(interleave, interleave.size / 2) do |send_buffer, receive_buffer| 
          PutTmsTdiBits(device.handle, send_buffer, receive_buffer, bit_count, false)
        end

        #Return the recieved data.
        return receive_data

      end

      private


      #
      # Helper function which automatically handles the creation of the send/receive buffers
      # necessary for JTAG transactions.
      #
      # Accepts two arguments:
      #   transmit_data: The data to be transmitted; will be converted to a C byte array; or nil, if the send_buffer won't be used.
      #   receive_size: The amount of data to be received. If not provided, the size of transmit_data will be used.
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
      # Helper function, which returns its argument as a byte-string.
      # Used for converting arrays into byte-strings.
      #
      def self.pack_if_necessary(bytes)
        bytes.respond_to?(:pack) ? bytes.pack('C*').force_encoding('UTF-8') : bytes
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
        interleave = byte_pairs.map { |tms, tdi| interleave_tms_tdi_byte_pair(tms, tdi) }

        #And flatten the pairs into a long array of interleave bytes.
        interleave.flatten.pack('C*').force_encoding('UTF-8')

      end

      #
      # Interleaves a single byte of TDI and TMS, creating 
      #
      def self.interleave_tms_tdi_byte_pair(tms, tdi)

        #Ensure that the two values we have are represented as numbers.
        tms = tms.ord
        tdi = tdi.ord

        #
        #Perform the interleaves manually; this seems like the most clearly
        #readable way to do this. This might be a good candidate for optimization
        #later.
        #

        lower = \
          tms[3] << 7 | tdi[3] << 6 | tms[2] << 5 | tdi[2] << 4 | 
          tms[1] << 3 | tdi[1] << 2 | tms[0] << 1 | tdi[0] << 0

        upper = \
          tms[7] << 7 | tdi[7] << 6 | tms[6] << 5 | tdi[6] << 4 | 
          tms[5] << 3 | tdi[5] << 2 | tms[4] << 1 | tdi[4] << 0

      
        #Return the interleave bytes in little endian order.
        return lower, upper

      end
    end
  end
end

