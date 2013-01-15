----------------------------------------------------------------------------------
-- Simple Synchronous FIFO
--
-- Author: Kyle J. Temkin, <ktemkin@binghamton.edu>
-- Copyright (c) Kyle J. Temkin,  2013 Binghamton University
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
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

  --
  -- Convenience function which waits until juster the rising edge.
  -- 
  procedure wait_until_after_rising_edge(signal clk : in std_logic) is
  begin
    wait until rising_edge(clk);
    wait for 1 ps;
  end procedure wait_until_after_rising_edge;

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
    dequeue <= '0';
    for i in 1 to 31 loop

      --Ensure that we're counting the values properly. 
      assert count = std_logic_vector(to_unsigned(i - 1, 5)) report "Count should be equal to the amount of elements enqueued.";

      --Set up the FIFO to add a new, numbered element.
      data_in <= std_logic_vector(to_unsigned(i, 8));

      --Wait until just after the next rising-edge of the clock.
      wait_until_after_rising_edge(clk);
    
      --Check to see that our enqueue is behaving properly.
      assert empty = '0' report "Empty should not be one while there are elements in the FIFO.";
      assert data_out = x"01" report "Data out should show the first element enqueued until a dequeue is performed.";

    end loop;

    --Check to see that the FIFO is full.
    assert full = '1' report "After adding 31 elements to the FIFO, it should be full.";

    --Verify that we can perform simultaneous read/writes, even when the FIFO is full.
    enqueue <= '1';
    dequeue <= '1';
    data_in <= x"20";
    wait_until_after_rising_edge(clk);

    --Check to ensure that the simultaneous enqueue/dequeue does not affect the count.
    assert data_out = x"02" report "After a dequeue, the next value in the FIFO should be exposed.";
    assert count = "11111" report "A simultaneous enqueue/dequeue should not affect the count.";

    --Remove each of the elements from the FIFO.
    enqueue <= '0';
    dequeue <= '1';
    for i in 2 to 32 loop 
      assert data_out = std_logic_vector(to_unsigned(i, 8)) report "Elements should be dequeued in the same ordered they were entered.";
      assert count = std_logic_vector(to_unsigned(33 - i, 5)) report "Count should decrease as elements are dequeued.";
      wait_until_after_rising_edge(clk);
    end loop;

    --Check to ensure that the FIFO is empty after all elements have been dequeued.
    assert count = "00000" report "After all elements are dequeued, the count should be zero.";
    assert empty = '1' report "After all elements are dequeued, the queue should be empty.";

  report "Test complete.";
  wait;
  end process;

end;
