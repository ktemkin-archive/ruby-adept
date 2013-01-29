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
        supports_idcode "X1c1a093", "X1c10093"

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

        #Database which maps IDCodes to bit-file part numbers.
        #Used to validate 
        PartIdcodes = \
        {
          '3s100ecp132' => 'X1c10093',
          '3s250ecp132' => 'X1c1a093'
        }

        ConfigurationStartup = 14_000
        FPGAStartup = 100

        #
        # Verifies the device's IDcode using the explicit IDCode instruction.
        #
        def verify_idcode

          #Put the device into IDCode retrival mode.
          self.instruction = :idcode

          #And attempt to retrieve the 32-bit IDcode.
          id_code = receive_data(32).reverse

          #If the two IDcodes don't match, raise an error.
          raise JTAG::Error, "IDCode verification failed! Expected: #{@idcode.unpack("H*")}, receieved #{id_code.unpack("H*")}. " unless id_code == @idcode

        end

        #
        # Returns the "user code", an ID number which identifies the configuration of the FPGA.
        #
        def usercode
          
          #Put the device into IDCode retrival mode.
          self.instruction = :usercode

          #And attempt to retrieve the 32-bit IDcode.
          usercode_packed = receive_data(32).reverse

          #Return the usercode as a hex string.
          usercode_packed.unpack("H*").first.upcase

        end

        #
        # Configures (programs) the given FPGA.
        #
        def configure(bitstream)

          validate_bitstream(bitstream)

          #Send the bitstream to the FPGA.
          initialize_configuration
          transmit_data(bitstream.to_s)
          finalize_configuration

          #And verify that the programming succeeded. 
          unless bitstream.usercode == usercode || bitstrea.usercode.nil?
            raise ProgrammingError, "Programming failed; expected a usercode of #{bitstream.usercode}, recieved #{usercode}." 
          end

        end

        def part_name
          connected_part, _ = PartIdcodes.find { |part, mask| self.class.idcode_matches_mask(mask, @idcode) }
          connected_part
        end

        #
        # Returns true iff the provided bitstream is intended for this FPGA.
        #
        def supports_bitstream?(bitstream)
          self.class.idcode_matches_mask(PartIdcodes[bitstream.part], @idcode)
        end


        private

        #
        # Check to ensure that the provided bit-stream is intended for this part.
        #
        def validate_bitstream(bitstream)
          unless supports_bitstream?(bitstream)
            raise ProgrammingError, "The provided bitstream was intended for an '#{bitstream.part}', but a '#{part_name}' is connected."
          end
        end

        #
        # Performs the initial steps which ready the FPGA for configuration.
        #
        def initialize_configuration

          #Pulse the Program pin via JTAG.
          self.instruction = :jprogram

          #Put the device into configuration mode, and give it 14,000 cycles to start up.
          self.instruction = :cfg_in
          run_test(ConfigurationStartup)

        end

        #
        # Performs the final steps which start up a configured program.
        #
        def finalize_configuration

          #Put the FPGA into startup mode...
          self.instruction = :jstart

          #And then allow the FPGA to run normally.
          run_test(FPGAStartup)

        end



      end
    end
  end
end
