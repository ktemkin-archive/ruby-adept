module Adept
  class Error < StandardError; end
  class CommunicationError < Error; end
  class CommandFailedError < Error; end
  class UnsupportedDeviceError < Error; end
end
