
require 'adept/jtag/tap_state'

module Adept
  module JTAG
    module TAPStates

      #
      # JTAG Test Access Port Finite State Machine
      #
      
      tap_state :Reset,     0 => :Idle,       1 => :Reset
      tap_state :Idle,      0 => :Idle,       1 => :SelectDR

      #Data Register Access States
      tap_state :SelectDR,  0 => :CaptureDR,  1 => :SelectIR
      tap_state :CaptureDR, 0 => :ShiftDR,    1 => :Exit1DR
      tap_state :ShiftDR,   0 => :PauseDR,    1 => :Exit1DR
      tap_state :Exit1DR,   0 => :PauseDR,    1 => :UpdateDR
      tap_state :PauseDR,   0 => :PauseDR,    1 => :Exit2DR
      tap_state :Exit2DR,   0 => :ShiftDR,    1 => :UpdateDR
      tap_state :UpdateDR,  0 => :Idle,       1 => :SelectDR

      #Instruction Register Access States
      tap_state :SelectIR,  0 => :CaptureIR,  1 => :Reset
      tap_state :CaptureIR, 0 => :ShiftIR,    1 => :Exit1IR
      tap_state :ShiftIR,   0 => :ShiftIR,    1 => :Exit1IR
      tap_state :Exit1IR,   0 => :PauseIR,    1 => :UpdateIR
      tap_state :PauseIR,   0 => :PauseIR,    1 => :Exit2IR
      tap_state :Exit2IR,   0 => :ShiftIR,    1 => :UpdateIR
      tap_state :UpdateIR,  0 => :Idle,       1 => :SelectDR


      #
      # Override the FSM's base behavior in the SelectDR state, as that state
      # is the "branch point" between the instruction register and the data-register columns.
      #
      module SelectDR

        #
        # Override the heuristic for path-finding within the TAP finite state machine;
        # move to the appropriate column depending on if we're looking for an Data Register
        # or Instruction Register access.
        #
        def self.next_hop_towards(state)
          #If we're looking for an instruction state, continue to the next column.
          (state.name =~ /IR$/) ? 1 : 0
        end

      end

    end
  end
end
