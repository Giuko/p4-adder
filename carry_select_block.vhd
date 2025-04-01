library ieee;
use ieee.std_logic_1164.all;
use work.all;


entity carry_select_block is
    GENERIC(
        NBIT  :   INTEGER
    );
    PORT(
        A:      IN std_logic_vector(NBIT - 1 downto 0);
        B:      IN std_logic_vector(NBIT - 1 downto 0);
        Cin:    IN std_logic;
        S:      OUT std_logic_vector(NBIT - 1 downto 0)
    );
end carry_select_block;

architecture STRUCTURAL of carry_select_block is
    
    component RCA is 
        generic (
            DRCAS : 	Time;
            DRCAC : 	Time;
            NBIT  :   INTEGER
        );
        Port (	
            A:	In	std_logic_vector(NBIT - 1 downto 0);
            B:	In	std_logic_vector(NBIT - 1 downto 0);
            Ci:	In	std_logic;
            S:	Out	std_logic_vector(NBIT - 1 downto 0);
            Co:	Out	std_logic
        );
    end component; 

    signal rca_out1: std_logic_vector(NBIT-1 downto 0);
    signal rca_out2: std_logic_vector(NBIT-1 downto 0);
begin
    
    RCA1: RCA 
        GENERIC MAP(
            DRCAS => 0 ns,
            DRCAC => 0 ns,
            NBIT => NBIT
        ) 
        PORT MAP(
            A => A,
            B => B,
            Ci => '1',
            S => rca_out1
        );

    RCA2: RCA 
        GENERIC MAP(
            DRCAS => 0 ns,
            DRCAC => 0 ns,
            NBIT => NBIT
        ) 
        PORT MAP(
            A => A,
            B => B,
            Ci => '0',
            S => rca_out2
        );

    S <= rca_out1 when Cin='1' else rca_out2;
end STRUCTURAL;



configuration CFG_CSB_STRUCTURAL of carry_select_block is
    for STRUCTURAL 
        for RCA1: RCA
            use configuration WORK.CFG_RCA_STRUCTURAL;
        end for;
        for RCA2: RCA
            use configuration WORK.CFG_RCA_STRUCTURAL;
        end for;
    end for;
  end CFG_CSB_STRUCTURAL;