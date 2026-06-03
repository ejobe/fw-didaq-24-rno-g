	component sdm_mailbox is
		port (
			in_clk_clk         : in  std_logic                     := 'X';             -- clk
			in_reset_reset     : in  std_logic                     := 'X';             -- reset
			avmm_address       : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- address
			avmm_write         : in  std_logic                     := 'X';             -- write
			avmm_writedata     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			avmm_read          : in  std_logic                     := 'X';             -- read
			avmm_readdata      : out std_logic_vector(31 downto 0);                    -- readdata
			avmm_readdatavalid : out std_logic;                                        -- readdatavalid
			avmm_waitrequest   : out std_logic;                                        -- waitrequest
			irq_irq            : out std_logic                                         -- irq
		);
	end component sdm_mailbox;

	u0 : component sdm_mailbox
		port map (
			in_clk_clk         => CONNECTED_TO_in_clk_clk,         --   in_clk.clk
			in_reset_reset     => CONNECTED_TO_in_reset_reset,     -- in_reset.reset
			avmm_address       => CONNECTED_TO_avmm_address,       --     avmm.address
			avmm_write         => CONNECTED_TO_avmm_write,         --         .write
			avmm_writedata     => CONNECTED_TO_avmm_writedata,     --         .writedata
			avmm_read          => CONNECTED_TO_avmm_read,          --         .read
			avmm_readdata      => CONNECTED_TO_avmm_readdata,      --         .readdata
			avmm_readdatavalid => CONNECTED_TO_avmm_readdatavalid, --         .readdatavalid
			avmm_waitrequest   => CONNECTED_TO_avmm_waitrequest,   --         .waitrequest
			irq_irq            => CONNECTED_TO_irq_irq             --      irq.irq
		);

