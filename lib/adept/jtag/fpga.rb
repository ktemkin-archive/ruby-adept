#
# FPGA JTAG Target
#

require 'adept/jtag'
require 'adept/jtag/xilinx_device'

module Adept
  module JTAG

    #
    # Base module for JTAG devices.
    #
    class FPGA < Device
      
      InstructionWidth = 6
      supports_idcode "X1c1a093"
     
    end

  end
end
