require 'ffi'

module Adept
  module LowLevel

    #
    # Diglient JTAG (DJTG)
    # Wrapper for the low-level JTAG manipulation functions.
    #
    module JTAG
      extend FFI::Library

      #Wrap the JTAG interface library, libDJTG
      ffi_lib 'libdjtg'


    end

  end
end

