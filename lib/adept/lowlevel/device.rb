require 'ffi'

module Adept
  module LowLevel

    NameMaxLength = 64
    PathMaxLength = 260 + 1

    #
    # Structure used by the Adept SDK to represent an adept device.
    #
    class Device < FFI::Struct
      layout  :name,        [:char, NameMaxLength], #char[NameMaxLength]
              :connection,  [:char, PathMaxLength], #char[PathMaxLength]
              :transport,   :ulong

      #
      #Convert the given device record into a ruby hash.
      #TODO: possibly decode the transport type?
      #
      def to_h
        result = Hash[members.zip(values)]

        #Convert the internal character arrays to ruby strings.
        result[:name] = result[:name].to_s
        result[:connection] = result[:connection].to_s

        #return the resultant hash
        result
      end

    end

  end
end
