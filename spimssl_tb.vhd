	
	----------------------------------------------------------------------------------
	-- Company:         Univ. Bremerhaven
	-- Engineer:        Kartik Ramesh
	-- Create Date:     18.06.2021
	-- Description:     SPI Master/Slave test bench
	----------------------------------------------------------------------------------

	LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;

	ENTITY spimssl_tb IS
	END spimssl_tb;

	ARCHITECTURE Behavioral OF spimssl_tb IS

	CONSTANT SPI_NBITS : INTEGER := 10;

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

	COMPONENT spisl IS
		GENERIC (
			USPI_SIZE : INTEGER := 16 );
		Port ( resetn : IN STD_LOGIC;
			   bclk : IN STD_LOGIC;
			   done : OUT STD_LOGIC;
			   slcsq : IN STD_LOGIC;
			   slsclk : IN STD_LOGIC;
			   slsdo : OUT STD_LOGIC;
			   slsdi : IN STD_LOGIC;
			   slsndData : IN STD_LOGIC_VECTOR (USPI_SIZE-1 DOWNTO 0);
			   slrcvData : OUT STD_LOGIC_VECTOR (USPI_SIZE-1 DOWNTO 0));
	END COMPONENT spisl;


	SIGNAL resetn : STD_LOGIC := '1';
	SIGNAL bclk : STD_LOGIC := '0';
	SIGNAL start : STD_LOGIC := '0';
	SIGNAL scsq : STD_LOGIC := '0';
	SIGNAL sclk : STD_LOGIC := '0';
	SIGNAL MISO : STD_LOGIC := '0';
	SIGNAL MOSI : STD_LOGIC := '0';
	SIGNAL sndData_master : STD_LOGIC_VECTOR (SPI_NBITS-1 downto 0) := "1011110111"; -- 2F7(hex)
	SIGNAL rcvData_master : STD_LOGIC_VECTOR (SPI_NBITS-1 downto 0) := "0000000000";
	SIGNAL sndData_slave : STD_LOGIC_VECTOR (SPI_NBITS-1 downto 0) := "1101101101"; --36D(hex)
	SIGNAL rcvData_slave : STD_LOGIC_VECTOR (SPI_NBITS-1 downto 0) := "0000000000";
	SIGNAL done_master : STD_LOGIC := '0';
	SIGNAL done_slave : STD_LOGIC := '0';

	CONSTANT  clock_period : time := 10 ns;

	BEGIN

		uut_m : spims
			GENERIC MAP ( USPI_SIZE => SPI_NBITS )
			PORT MAP ( resetn => resetn,
					   bclk => bclk,
					   start => start, 
					   done => done_master,
					   scsq => scsq,
					   sclk => sclk,
					   sdo => MOSI,
					   sdi => MISO,
					   sndData => sndData_master,
					   rcvData => rcvData_master );

		uut_s : spisl
			GENERIC MAP ( USPI_SIZE => SPI_NBITS )
			PORT MAP ( resetn => resetn,
					   bclk =>  bclk,
					   done =>  done_slave,
					   slcsq =>  scsq,
					   slsclk =>  sclk,
					   slsdo =>  MISO,
					   slsdi =>  MOSI,
					   slsndData =>  sndData_slave,
					   slrcvData =>  rcvData_slave );
	


		clk_p : PROCESS
		BEGIN
			bclk <= '0';
			wait for clock_period/2;
			bclk <= '1';
			wait for clock_period/2;
		END PROCESS clk_p;


		sim_p : PROCESS
		BEGIN
			wait for clock_period;
			resetn <= '0';
			wait for clock_period;
			resetn <= '1';
			wait for clock_period * 8;
			start <= '1';
			wait for clock_period * 4;
			start <= '0';
			wait;
		END PROCESS sim_p;

	END Behavioral;
