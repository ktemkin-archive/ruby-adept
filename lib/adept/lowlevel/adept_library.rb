require 'ffi'
require 'adept/lowlevel'

module Adept
  module LowLevel

    #
    # "Base" module, which provides functionality for interfacing with 
    # Digilent Adept low-level libraries.
    #
    module AdeptLibrary
      include FFI::Library

      #
      # Attaches the appropriate dynamically-linked library to the calling module.
      #
      def wrap_adept_library(name)
      
        #Store the prefix for the library name, which
        #
        @prefix = name.capitalize
        #Make the adept_library function local, so it can only be used in class defintions.
        #private :wrap_adept_library

        #And attach the relevant dynamic library (DLL / SO).
        ffi_lib "lib#{name}"

        #Attach the function which queries the device runtime's version.
        attach_function "#{@prefix}GetVersion", [:pointer], :void

      end

      #Make the wrap_adept_library function local, so it can only be used in class defintions.
      private :wrap_adept_library

      #
      # Returns the version of the wrapped runtime, as a string.
      #
      def runtime_version
        
        #create a new buffer which will hold the runtime's version
        version_buffer = FFI::MemoryPointer.new(VersionMaxLength) 

        #get the system's version
        self.send("#{@prefix}GetVersion", version_buffer)

        #and return the retrieved version
        version_buffer.read_string

      end

    end

  end
end
