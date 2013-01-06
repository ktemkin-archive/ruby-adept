
module Adept
  module JTAG
    module TAPStates

      #
      # Base for all Test Access Port states.
      #
      module TAPState
      
        #
        # Returns the successor to the current state, given an input value.
        #
        def next_state(value)

          #Get the name of the module which describes the successor state...
          state = self::NextState[value]

          #... and get a reference to the module itself.
          TAPStates.const_get(state)

        end
      end


      #
      # Test-Logic Reset 
      #
      module Reset
        extend TAPState

        #Describes the next state the two values of TMS.
        NextState = { 0 => :Idle, 1 => :Reset }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 0
        end
      end


      #
      # Run-Test / Idle
      #
      module Idle
        extend TAPState

        NextState = { 0 => :Idle, 1 => :SelectDR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 1
        end
      end

      #
      # Data Register Column
      #

      module SelectDR
        extend TAPState

        NextState = { 0 => :CaptureDR, 1 => :SelectIR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          #If we're looking for an instruction state, continue to the next column.
          (state.name =~ /IR$/) ? 1 : 0
        end
      end

      module CaptureDR
        extend TAPState

        NextState = { 0 => :ShiftDR, 1 => :Exit1DR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == ShiftDR) ? 0 : 1
        end
      end

      module ShiftDR
        extend TAPState

        NextState = { 0 => :ShiftDR, 1 => :Exit1DR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 1
        end

      end

      module Exit1DR
        extend TAPState

        NextState = { 0 => :PauseDR, 1 => :UpdateDR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == PauseDR) ? 0 : 1
        end

      end

      module PauseDR
        extend TAPState

        NextState = { 0 => :PauseDR, 1 => :Exit2DR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 1
        end

      end

      module Exit2DR
        extend TAPState

        NextState = { 0 => :ShiftDR, 1 => :UpdateDR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == ShiftDR) ? 0 : 1
        end

      end

      module UpdateDR
        extend TAPState

        NextState = { 0 => :Idle, 1 => :SelectDR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == Idle) ? 0 : 1
        end

      end

      #
      # Instruction Register Column 
      #
      
      module SelectIR
        extend TAPState

        NextState = { 0 => :CaptureIR, 1 => :Reset }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 0
        end

      end

      module CaptureIR
        extend TAPState

        NextState = { 0 => :ShiftIR, 1 => :Exit1IR  }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == ShiftIR) ? 0 : 1
        end

      end

      module ShiftIR
        extend TAPState

        NextState = { 0 => :ShiftIR, 1 => :Exit1IR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 1
        end

      end

      module Exit1IR
        extend TAPState

        NextState = { 0 => :PauseIR, 1 => :UpdateIR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == PauseIR) ? 0 : 1
        end

      end

      module PauseIR
        extend TAPState

        NextState = { 0 => :PauseIR, 1 => :Exit2IR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          return 1
        end

      end

      module Exit2IR
        extend TAPState

        NextState = { 0 => :ShiftIR, 1 => :UpdateIR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == ShiftIR) ? 0 : 1
        end

      end

      module UpdateIR
        extend TAPState

        NextState = { 0 => :Idle, 1 => :SelectDR }

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def self.next_hop_towards(state)
          (state == Idle) ? 0 : 1
        end

      end

    end
  end
end
