#
# FPGA JTAG Target
#

require 'adept/jtag'

module Adept
  module JTAG
    module Devices

      #
      # Base module for JTAG devices.
      #
      class FPGA < Device
       
        #Basic device definitions.
        InstructionWidth = 6
        supports_idcode "X1c1a093"

        #Supported boundary-scan instructions.
        Instructions = \
        {
          :extest      => 0b001111,
          :sample      => 0b000001,
          :preload     => 0b000001,  # Same as :sample
          :user1       => 0b000010,  # Not available until after configuration
          :user2       => 0b000011,  # Not available until after configuration
          :cfg_out     => 0b000100,  # Not available during configuration with another mode.
          :cfg_in      => 0b000101,  # Not available during configuration with another mode.
          :intest      => 0b000111,                                                         
          :usercode    => 0b001000,                                                         
          :idcode      => 0b001001,                                                         
          :highz       => 0b001010,                                                         
          :jprogram    => 0b001011,  # Not available during configuration with another mode.
          :jstart      => 0b001100,  # Not available during configuration with another mode.
          :jshutdown   => 0b001101,  # Not available during configuration with another mode.
          :bypass      => 0b111111,
          :isc_enable  => 0b010000,
          :isc_program => 0b010001,
          :isc_noop    => 0b010101,
          :isc_disable => 0b010110
        }

        ConfigurationStartup = 14_000

        #
        # Verifies the device's IDcode using the explicit IDCode instruction.
        #
        def verify_idcode

          #Put the device into IDCode retrival mode.
          self.instruction = :idcode

          #And attempt to retrieve the 32-bit IDcode.
          idcode = receive_data(32).reverse

          #If the two IDcodes don't match, raise an error.
          raise JTAG::Error, "IDCode verification failed! Expected: #{@idcode.unpack("H*")}, receieved #{idcode.unpack("H*")}. " unless idcode == @idcode

        end

        #
        # Returns the "user code", an ID number which identifies the configuration of the FPGA.
        #
        def usercode
          
          #Put the device into IDCode retrival mode.
          self.instruction = :usercode

          #And attempt to retrieve the 32-bit IDcode.
          receive_data(32).reverse

        end

        #
        # Configures (programs) the given FPGA.
        #
        def configure(bitstream)

          initialize_configuration

        end

        private

        def initialize_configuration

          #Pulse the Program pin via JTAG.
          self.instruction = :jprogram

          #Put the device into configuration mode, and give it 14,000 cycles to start up.
          self.instruction = :cfg_in
          run_test(ConfigurationStartup)

        end



      end
    end
  end
end
