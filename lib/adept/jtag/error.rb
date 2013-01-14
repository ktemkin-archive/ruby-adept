require 'adept/error'

module Adept
  module JTAG
    class Error < Adept::Error; end
    class ProgrammingError < Error; end
  end
end
