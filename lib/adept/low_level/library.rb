require 'ffi'
require 'adept/low_level'
require 'adept/low_level/error_handler'

module Adept
  module LowLevel

    #Maximum possible length of a library version string.
    VersionMaxLength = 256

    #
    # "Base" module, which provides functionality for interfacing with 
    # Digilent Adept low-level libraries.
    #
    module Library
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

        #Make the base function protected, as not to clutter the (public) namespace.
        private_class_method(base_name)

        #And create our enhanced version of the function, 
        #which automatically raises an exception if an error occurs.
        define_singleton_method(name) do |*args|

          #Call the base function, and throw an exception if the call fails.
          unless base_function.call(*args)
          
            #Get the most recent error information as a raisable exception.
            error = ErrorHandler.last_error

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


      private

      
      #
      # Creates a C-style byte buffer containing the given item using FFI.
      #
      # The buffer exists in managed memory (and thus will be garbage
      # collected when appropriate), but is contiguous, and thus prime
      # for passing to a C interop.
      #
      def to_buffer(item)

        #Try to convert the item to an array, and then to a string,
        #if it supports it. This allows us to easily get a byte string
        #from most Ruby types.
        #
        #Strings _shouldn't_ support either of these methods, and thus will
        #pass unaltered.
        # 
        item = item.to_a if item.respond_to?(:to_a)
        item = item.pack("C*") if item.respond_to?(:pack)
        
        #Create a new buffer, and fill it with our byte string.
        buffer = FFI::MemoryPointer.new(item.byte_size)
        buffer.put_bytes(0, item)

        #And return the filled buffer.
        return buffer
        
      end


      #
      # Recieves a byte string via a C-style byte buffer.
      #
      # types: A list of types to be received, in the same format as accepted by
      #   FFI::MemoryPointer. :int, 8, and :long are all acceptable types.
      #
      # Must be called with a block, which should fill the byte buffer. 
      # Yields a c-style pointer to each of the created buffers, in the order
      # they were specified as arguments.
      #
      def receive_out_arguments(*types)

        #Create a pointer to each of the requested types.
        pointers = types.map { |type| FFI::MemoryPointer.new(type) }

        #Yield each of the pointers to the given block.
        yield(*pointers)

        #Read each of the byte-buffers given.  
        types.zip(pointers).map do |type, pointer|

          #If we've been passed a buffer type as a symbol, use the
          #symbol name to figure out the appropriate reading method.
          if type.kind_of?(Symbol)

            #Compute the method name by adding "get_" to the device type,
            #as the the FFI convention.
            method_name = 'read_' + type.to_s

            #And return the contents of the byte buffer.
            next byte_buffer.send(method_name)
  
          #Otherwise, return the data in raw binary.        
          else  
            next byte_buffer.get_string(0, type)
          end

        end

      end

    end
  end
end
