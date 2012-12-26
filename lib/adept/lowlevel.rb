require 'ffi'


module Adept
  module LowLevel

    VersionMaxLength = 256

    ErrorNameMaxLength = 16
    ErrorMessageMaxLength = 128

    #
    # Creates a string buffer suitable for storing runtime version information.
    #
    def self.create_version_buffer
      FFI::MemoryPointer.new(VersionMaxLength)
    end

    #
    # Creates a string buffer suitable for storing error names.
    #
    def self.create_error_name_buffer
      FFI::MemoryPointer.new(ErrorNameMaxLength)
    end

    #
    # Creates a FFI string buffer suitable for storing error messages.
    #
    def self.create_error_message_buffer
      FFI::MemoryPointer.new(ErrorMessageMaxLength)
    end

  end
end
