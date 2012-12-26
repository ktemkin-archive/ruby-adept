
module Adept

  #
  # Wrapper for Digilent Device Manager errors, which allows
  # errors raised from the low-level SDK to be handled like ruby exceptions.
  #
  class DeviceError < StandardError

    def initialize(message, short_name, code=nil)
      @short_name = short_name
      @code = code
    end

    def self.const_missing(sym)
      self.send(sym)
    end

  end

end
