	
	----------------------------------------------------------------------------------
	-- Company:         Univ. Bremerhaven
	-- Engineer:        Kartik Ramesh
	-- Create Date:     18.06.2021
	-- Description:     SPI Master test bench
	----------------------------------------------------------------------------------

	LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;

	ENTITY spims_tb IS
	END spims_tb;

	ARCHITECTURE Behavioral OF spims_tb IS

	CONSTANT SPI_NBITS : INTEGER := 8;

	COMPONENT spims IS
		GENERIC ( USPI_SIZE : INTEGER := 16);
		PORT ( resetn : IN STD_LOGIC;
			   bclk : IN STD_LOGIC;
			   start : IN STD_LOGIC;
			   done : OUT STD_LOGIC;
			   scsq : OUT STD_LOGIC;
			   sclk : OUT STD_LOGIC;
			   sdo : OUT STD_LOGIC;
			   sdi : IN STD_LOGIC;
			   sndData : IN STD_LOGIC_VECTOR (USPI_SIZE-1 DOWNTO 0);
			   rcvData : OUT STD_LOGIC_VECTOR (USPI_SIZE-1 DOWNTO 0));
	END COMPONENT spims;

	SIGNAL resetn : STD_LOGIC := '0';
	SIGNAL bclk : STD_LOGIC := '0';
	SIGNAL start : STD_LOGIC := '0';
	SIGNAL scsq : STD_LOGIC := '0';
	SIGNAL sclk : STD_LOGIC := '0';
	SIGNAL sdi : STD_LOGIC := '0';
	SIGNAL sdo : STD_LOGIC := '0';
	SIGNAL sndData : STD_LOGIC_VECTOR (SPI_NBITS-1 downto 0) := x"5A"; 
	SIGNAL rcvData : STD_LOGIC_VECTOR (SPI_NBITS-1 downto 0) := x"00";
	SIGNAL done : STD_LOGIC := '0';

	CONSTANT  clock_period : time := 10 ns;

	BEGIN

		uut : spims
			GENERIC MAP ( USPI_SIZE => SPI_NBITS )
			PORT MAP ( resetn => resetn,
					   bclk => bclk,
					   start => start, 
					   done => done,
					   scsq => scsq,
					   sclk => sclk,
					   sdo => sdo,
					   sdi => sdi,
					   sndData => sndData,
					   rcvData => rcvData );

		
		clk_p : PROCESS
		BEGIN
			bclk <= '1';
			wait for clock_period/2;
			bclk <= '0';
			wait for clock_period/2;
		END PROCESS clk_p;

		sdi <= NOT sdo;
		
		sim_p : PROCESS
		BEGIN
			wait for clock_period;
			resetn <= '0';
			wait for clock_period;
			resetn <= '1';
			wait for clock_period;
			start <= '1';
			wait for clock_period * 20;
			start <= '0';
			REPORT " Simulation finished for SPI Master. ";
			wait;
		END PROCESS sim_p;

	END Behavioral;
