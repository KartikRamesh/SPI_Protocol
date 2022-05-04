	
	----------------------------------------------------------------------------------
	-- Company:         Univ. Bremerhaven
	-- Engineer:        Kartik Ramesh
	-- Create Date:     18.06.2021
	-- Description:     SPI slave (CPOL=0, CPHA=1)
	----------------------------------------------------------------------------------

	LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;

	ENTITY spisl IS
		GENERIC (
			USPI_SIZE : INTEGER := 16 );
		PORT ( resetn : IN STD_LOGIC;
			   bclk : IN STD_LOGIC;
			   done : OUT STD_LOGIC;
			   slcsq : IN STD_LOGIC;
			   slsclk : IN STD_LOGIC;
			   slsdo : OUT STD_LOGIC;
			   slsdi : IN STD_LOGIC;
			   slsndData : IN STD_LOGIC_VECTOR (USPI_SIZE-1 DOWNTO 0);
			   slrcvData : OUT STD_LOGIC_VECTOR (USPI_SIZE-1 DOWNTO 0));
	END spisl;

	ARCHITECTURE Behavioral OF spisl IS

	TYPE  state_type IS (idle, csstart, starthi_s, starthi, startlo_s, startlo,
						 clkhi_s, clkhi, clklo_s, clklo, leadout);

	SIGNAL  state, next_state : state_type;
	SIGNAL  count : INTEGER RANGE 0 TO USPI_SIZE-1;

	SIGNAL sdo_buffer, sdi_buffer : std_logic_vector(USPI_SIZE-1 DOWNTO 0);

	BEGIN

		slrcvData <= sdi_buffer;

		slseq: PROCESS(bclk, resetn, next_state, count, slsdi, sdi_buffer)
		BEGIN
			IF rising_edge(bclk) THEN
				IF resetn='0' THEN
					state <= idle;
					count <= USPI_SIZE-1;
					slsdo <= '0';
				ELSE
					IF next_state=csstart THEN
						count <= USPI_SIZE-1;
						sdo_buffer <= slsndData;
					ELSIF next_state=startlo_s OR next_state=clklo_s  THEN
						sdi_buffer <= sdi_buffer(USPI_SIZE-2 downto 0) & slsdi;
						sdo_buffer <= sdo_buffer(USPI_SIZE-2 downto 0) & '-';
					ELSIF next_state=starthi_s THEN
						slsdo <= sdo_buffer(USPI_SIZE-1);
					ELSIF next_state=clkhi_s THEN
						count <= count - 1 ;
						slsdo <= sdo_buffer(USPI_SIZE-1);
					ELSIF next_state=idle THEN
						slsdo <= '0';
					END IF;
					state <= next_state;
				END IF;
			END IF;
		END PROCESS slseq;

		slcmb: PROCESS(state, slcsq, slsclk, count)
		BEGIN
			next_state <= state;
			done <= '0';
			CASE state IS
				WHEN idle =>
					done <= '1';
					IF slcsq='0' THEN
						next_state <= csstart;
					END IF;
				WHEN csstart =>
					IF slsclk='1' THEN
						next_state <= starthi_s;
					END IF;
				WHEN starthi_s =>
					 next_state <= starthi;
				WHEN starthi =>
					IF slsclk='0' THEN
						next_state <= startlo_s;
					END IF;
				WHEN startlo_s =>
					next_state <= startlo;
				WHEN startlo =>
					IF slsclk='1' THEN
						next_state <= clkhi_s;
					END IF;
				WHEN clkhi_s =>
					next_state <= clkhi;
				WHEN clkhi =>
					IF slsclk='0' THEN
						next_state <= clklo_s;
					END IF;
				WHEN clklo_s =>
					next_state <= clklo;
				WHEN clklo =>
					IF count=0 THEN
						 next_state <= leadout;
					ELSIF slsclk='1' THEN
						next_state <= clkhi_s;
					END IF;
				WHEN leadout =>
					IF slcsq='1' THEN
						next_state <= idle;
					END IF;
			END CASE;
		END PROCESS slcmb;

	END Behavioral;
