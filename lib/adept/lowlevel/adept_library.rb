require 'ffi'
require 'adept/lowlevel'
require 'adept/lowlevel/error_handler'

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
        attach_adept_function :GetVersion, [:pointer]

      end

      #
      # Attaches an adept function, handling error checking automatically.
      # 
      def attach_adept_function(name, arguments) 

        #Compute the name for the Digilent Adept library.
        base_name =  @prefix + name.to_s

        #Attach the library's version of the function...
        base_function = attach_function base_name, arguments, :bool

        #And create our enhanced version of the function, 
        #which automatically raises an exception if an error occurs.
        define_singleton_method(name) do |*args|

          #Call the base function, and throw an exception if the call fails.
          unless base_function.call(*args)
          
            #Get the most recent error information as a raisable exception.
            error =  ErrorHandler.last_error

            #Override the exception's backtrace so it doesn't include this anonymous singleton.
            error.set_backtrace(caller(2))

            #And raise the exception itself.
            raise error

          end
        end
      end

      #Make the wrap_adept_library/attach_adept_function functions local, so they can only be used in class defintions.
      private :wrap_adept_library
      private :attach_adept_function

      #
      # Returns the version of the wrapped runtime, as a string.
      #
      def runtime_version
        
        #create a new buffer which will hold the runtime's version
        version_buffer = FFI::MemoryPointer.new(VersionMaxLength) 

        #get the system's version
        GetVersion(version_buffer)

        #and return the retrieved version
        version_buffer.read_string

      end

    end

  end
end
