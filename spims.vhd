	
	----------------------------------------------------------------------------------
	-- Company:         Univ. Bremerhaven
	-- Engineer:        Kartik Ramesh
	-- Create Date:     18.06.2021
	-- Description:     SPI Transmitter for (CPOL=0, CPHA=1)
	----------------------------------------------------------------------------------

	LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;

	ENTITY spims IS
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
	END spims;

	ARCHITECTURE Behavioral OF spims IS

	TYPE state_type IS (sidle, sstartx, sstart_lo, sclk_lo, sclk_hi, stop_hi, stop_lo);
	SIGNAL  state, next_state: state_type;
	SIGNAL sclk_i, scsq_i, sdo_i : STD_LOGIC;
	SIGNAL wr_buf : STD_LOGIC_VECTOR(USPI_SIZE-1 DOWNTO 0);
	SIGNAL rd_buf : STD_LOGIC_VECTOR(USPI_SIZE-1 DOWNTO 0);
	SIGNAL count : INTEGER RANGE 0 TO USPI_SIZE-1;

	CONSTANT CLK_DIV : INTEGER := 3;
	SUBTYPE  ClkDiv_type IS INTEGER RANGE 0 to CLK_DIV-1;
	SIGNAL  spi_clkp : STD_LOGIC;

	BEGIN

		rcvData <= rd_buf;
		
		-- Clock Division Logic
		clk_d : PROCESS(bclk, resetn)
		VARIABLE clkd_cnt : ClkDiv_type;
		BEGIN
			IF rising_edge(bclk) THEN
				spi_clkp <= '0';
				IF resetn= '0' THEN
					clkd_cnt := CLK_DIV - 1;
				ELSIF clkd_cnt=0 THEN
					spi_clkp <= '1';
					clkd_cnt := CLK_DIV - 1;
				ELSE
					clkd_cnt := clkd_cnt - 1;
				END IF;
			END IF;
		END PROCESS clk_d;


		-- spi sequential logic
		sseq_proc: PROCESS(bclk)
		BEGIN
			IF rising_edge(bclk) THEN
				IF resetn='0' THEN
					state <= sidle;
					count <= USPI_SIZE-1;
				ELSIF spi_clkp='1' THEN
					IF next_state=sstartx THEN
						wr_buf <= sndData;
						count <= USPI_SIZE - 1;
					ELSIF next_state=sclk_lo THEN
						wr_buf <= wr_buf(USPI_SIZE-2 downto 0) & '-';
						rd_buf <= rd_buf(USPI_SIZE-2 downto 0) & sdi;
					ELSIF next_state=sclk_hi THEN
						count <= count - 1;
					ELSIF next_state=stop_lo THEN
						rd_buf <= rd_buf(USPI_SIZE-2 downto 0) & sdi;
					END IF;
					state <= next_state;
					sclk <= sclk_i;
					scsq <= scsq_i;
					sdo <= sdo_i;
				END IF;
			END IF;
		END PROCESS sseq_proc;
		
		--spi Combinational Logic
		scmb_proc: PROCESS(state, start, count, wr_buf)
		BEGIN
			next_state <= state;
			sclk_i <= '0';
			scsq_i <= '0';
			sdo_i <= '0';
			done <= '0';
			CASE state IS
				WHEN sidle =>
					done <= '1';
					scsq_i <= '1';
					IF start='1' THEN
						next_state <= sstartx;
					END IF;
				WHEN sstartx =>
					next_state <= sstart_lo;
				WHEN sstart_lo =>
					sclk_i <= '1';
					sdo_i <= wr_buf(USPI_SIZE-1);
					next_state <= sclk_hi;
				WHEN sclk_hi =>
					sdo_i <= wr_buf(USPI_SIZE-1);
					next_state <= sclk_lo;
				WHEN sclk_lo =>
					sclk_i <= '1';
					sdo_i <= wr_buf(USPI_SIZE-1);
					IF count=0 THEN
						next_state <= stop_hi;
					ELSE
						next_state <= sclk_hi;
					END IF;
				WHEN stop_hi =>
					sdo_i <= wr_buf(USPI_SIZE-1);
					next_state <= stop_lo;
				WHEN stop_lo =>
					scsq_i <= '1';
					next_state <= sidle;
			END CASE;
		END PROCESS scmb_proc;

	END Behavioral;
