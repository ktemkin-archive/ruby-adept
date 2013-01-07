
require 'adept/lowlevel'
require 'adept/jtag/tap_states'

module Adept

  class JTAGConnection

    attr_reader :tap_state

    #
    # Sets up a new JTAG connection.
    #
    def initialize(device, port_number=0)

      #Store the information regarding the owning device...
      @device = device

      #... open a JTAG connection.
      LowLevel::JTAG::EnableEx(@device.handle, port_number)

    end

    #
    # Closes the given JTAG connection.
    #
    def close
      LowLevel::JTAG::Disable(@device.handle)
    end


    #
    # Sets the state of the target's Test Access Port.
    #
    def tap_state=(new_state) 

      #If we're trying to enter the reset state, force a reset of the test hardware.
      #(This ensure that we can reset the test hardware even if a communications (or target) error
      # causes improper behavior.)
      reset_target if new_state == JTAG::TAPStates::Reset

      #If we're already in the desired state, abort.
      return if new_state == @tap_state

      #Find the correct sequence of TMS values to reach the desired state...
      path = path_to_state(new_state)
      tms_values = [path.to_i(2)]

      #... and apply them.
      LowLevel::JTAG::transmit_mode_select(@device.handle, tms_values, false, path.length)

      #Update the internal record of the TAP state.
      @tap_state = new_state

    end

    #
    # Transmit an instruction over the JTAG test access lines, to be placed into
    # the JTAG instruction register.
    #
    # bytes:     A byte-string which contains the instruction to be transmitted.
    # bit_count: The total amount of bits to be transmitted.
    #
    # do_not_finish: If set, the transmission window will be "left open", so additional instructions can be transmitted.
    #
    def transmit_instruction(bytes, bit_count, do_not_finish=false)
      transmit_in_state(ShiftIR, bytes, bit_count, do_not_finish ? nil : Exit1IR)
    end

    #
    # Transmit an instruction over the JTAG test access lines, to be placed into
    # the JTAG data register.
    #
    # bytes:     A byte-string which contains the instruction to be transmitted.
    # bit_count: The total amount of bits to be transmitted.
    #
    def transmit_data(bytes, bit_count, do_not_finish=false)
      transmit_in_state(ShiftDR, bytes, bit_count, do_not_finish ? nil : Exit1DR)
    end

    #
    # Switches to run/test mode, and holds that state for the desired amount of clock ticks.
    #
    def run_test(clock_ticks)
      
      #Put the target into the Run-Test-Idle state.
      tap_state = JTAG::TAPStates::Idle

      #And "tick" the test clock for the desired amount of cycles.
      LowLevel::JTAG::tick(@device.handle, false, false, clock_ticks)

    end

    #
    # Force-resets the target device.
    #
    def reset_target
      
      #Reset the target device's JTAG controller by sending five bits of TMS='1'.
      LowLevel::JTAG::tick(@device.handle, true, false, 5)

      #Set the internal TAP state to reset.
      @tap_state = JTAG::TAPStates::Reset

    end


    #
    # Determines if the given device can serve as the host for a JTAG connection.
    #
    def self.supported_by?(device)
      LowLevel::JTAG::supported?(device)
    end

    private

    #
    # Transmits a sequence of data while in a given state.
    #
    # bytes:     A byte-string which contains the instruction to be transmitted.
    # bit_count: The total amount of bits to be transmitted.
    #
    #
    def transmit_in_state(state_before, bytes, bit_count, state_after=nil)

      #Put the device into the desired state.
      self.tap_state = state_before

      #Transmit the data, and recieve the accompanying response.
      response = LowLevel::JTAG::transmit_data(@device.handle, false, bytes, bit_count)

      #If a state_after was provided, place the device into that state.
      unless state_after.nil?
        self.tap_state = state_after
      end

    end

    #
    # Find the shortest "path" (sequence of most-select values) which will 
    # put the JTAG TAP FSM into the desired state.
    #
    # Note that the next-hop-towards algorithms do not consider "impossible"
    # combinations, such as a jump from EXIT1DR to EXIT2DR; these may cause
    # an infinite loop.
    #
    def path_to_state(destination, start=nil)

      #Create a "state pointer", which will be used to trace the FSM in order to
      #find a path to the destination state. If no start was provided, use the
      #current TAP state.
      state = start || @tap_state

      path = ""

      #Traverse the FSM until we reach our destination.
      until state == destination

        #Find the next hop on the path to the destination...
        next_hop = state.next_hop_towards(destination)

        #Move the "state pointer" to the next state, simulating a traversal
        #of the Finite State Machine.
        state = state.next_state(next_hop)

        #And add the hop to the path
        path << next_hop.to_s

      end

      #And return the computed path.
      path

    end
  end
end
