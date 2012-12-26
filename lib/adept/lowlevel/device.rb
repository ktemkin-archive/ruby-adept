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
              :dtp,         :ulong
    end

  end
end
