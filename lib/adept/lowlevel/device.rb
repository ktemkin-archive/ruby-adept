require 'ffi'
require 'adept/lowlevel/device_manager'

module Adept
  module LowLevel

    #Maximum length for an Adept device's name, including a null terminator.
    NameMaxLength = 64

    #Maximum length for an Adept device path, including a null terminator.
    PathMaxLength = 260 + 1

    #
    # Structure used by the Adept SDK to represent an adept device.
    #
    class Device < FFI::Struct

      #Set up the structure's layout.
      layout  :name,        [:char, NameMaxLength], #char[NameMaxLength]
              :path,        [:char, PathMaxLength], #char[PathMaxLength]
              :transport,   :ulong

      #
      #Convert the given device record into a ruby hash.
      #
      def to_h
        result = Hash[members.zip(values)]

        #Convert the internal character arrays to ruby strings.
        result[:name] = result[:name].to_s
        result[:path] = result[:path].to_s

        #And convert the device's transport to a string.
        result[:transport] = DeviceManager::get_transport_name(result[:transport])

        #return the resultant hash
        result
      end

    end

  end
end
