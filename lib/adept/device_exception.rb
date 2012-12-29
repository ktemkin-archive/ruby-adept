
module Adept

  #
  # Wrapper for Digilent Device Manager errors, which allows
  # errors raised from the low-level SDK to be handled like ruby exceptions.
  #
  class DeviceError < StandardError

    attr_accessor :short_name

    def initialize(message, short_name, code=nil)
      @short_name = short_name
      @code = code
      
      super(message)
    end

    def to_s
      "#@short_name (#@code) : #{super}"
    end

  end

end
