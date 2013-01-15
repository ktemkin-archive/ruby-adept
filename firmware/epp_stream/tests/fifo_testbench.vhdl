--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:05:20 01/15/2013
-- Design Name:   
-- Module Name:   /home/ktemkin/Documents/Projects/ruby-adept/firmware/epp_stream/tests/fifo_testbench.vhdl
-- Project Name:  epp_stream
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
 
-- uncomment the following library declaration if using
-- arithmetic functions with signed or unsigned values
use ieee.numeric_std.all;
 
entity fifo_testbench is
end fifo_testbench;
 
architecture behavior of fifo_testbench is 

  -- component declaration for the unit under test (uut)

  component fifo
  generic(
    count_bits : integer;
    element_width : integer
  );
  port(
       clk : in  std_logic;
       reset : in  std_logic;
       data_in : in  std_logic_vector(7 downto 0);
       data_out : out  std_logic_vector(7 downto 0);
       count : out  std_logic_vector(4 downto 0);
       enqueue : in  std_logic;
       dequeue : in  std_logic;
       empty : out  std_logic;
       full : out  std_logic
  );
  end component;

  --inputs
  signal clk : std_logic := '0';
  signal reset : std_logic := '1';
  signal data_in : std_logic_vector(7 downto 0) := (others => '0');
  signal enqueue : std_logic := '0';
  signal dequeue : std_logic := '0';

  --outputs
  signal data_out : std_logic_vector(7 downto 0);
  signal count : std_logic_vector(4 downto 0);
  signal empty : std_logic;
  signal full : std_logic;

  -- clock period definitions
  constant clk_period : time := 10 ns;

  constant delta_delay : time := 1 ps;

begin

  -- instantiate the unit under test (uut)
  uut: fifo 
  generic map(
    count_bits => 5,
    element_width => 8
  )
  port map (
    clk => clk,
    reset => reset,
    data_in => data_in,
    data_out => data_out,
    count => count,
    enqueue => enqueue,
    dequeue => dequeue,
    empty => empty,
    full => full
  );

  --Generate the system clock.
  clk <= not clk after clk_period / 2;

  -- stimulus process
  stim_proc: process
  begin		

    -- assert reset for 100ns;
    wait for 100 ns;	
    reset <= '0';

    --Assert conditions after reset.
    assert data_out = x"00" report "Data_out should be zero after clear.";
    assert count = "00000" report "Count should be zero after clear.";
    assert empty = '1' report "Empty should be one after clear.";
   
    --Add 31 elements to the FIFO.
    enqueue <= '1';
    for i in 1 to 31 loop

      --Ensure that we're counting the values properly. 
      assert count = std_logic_vector(to_unsigned(i - 1, 5)) report "Count should be equal to the amount of elements enqueued.";

      --Set up the FIFO to add a new, numbered element.
      data_in <= std_logic_vector(to_unsigned(i, 8));

      --Wait until just after the next rising-edge of the clock.
      wait until rising_edge(clk);
      wait for 1 ps;
    
      --Check to see that our enqueue is behaving properly.
      assert empty = '0' report "Empty should not be one while there are elements in the FIFO.";
      assert data_out = x"01" report "Data out should show the first element enqueued until a dequeue is performed.";

    end loop;

    --Check to see that the FIFO is full.
    assert full = '1' report "After adding 31 elements to the FIFO, it should be full.";


  report "Test complete.";
  wait;
  end process;

end;
