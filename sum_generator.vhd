library ieee;
use ieee.std_logic_1164.all;
use work.all;


entity sum_generator is
    GENERIC(
        NBIT_PER_BLOCK: integer;
        NBLOCKS:	integer
    );
    PORT(
        A:	in	std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
        B:	in	std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
        Ci:	in	std_logic_vector(NBLOCKS-1 downto 0);
        S:	out	std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0)
    );
end sum_generator;

architecture STRUCTURAL of sum_generator is

    component carry_select_block is
        GENERIC(
            NBIT  :   INTEGER
        );
        PORT(
            A:      IN std_logic_vector(NBIT - 1 downto 0);
            B:      IN std_logic_vector(NBIT - 1 downto 0);
            Cin:    IN std_logic;
            S:      OUT std_logic_vector(NBIT - 1 downto 0)
        );        
    end component; 
    
begin

    generateloop: for i in 0 to NBLOCKS-1 generate
        CSBi: carry_select_block 
            GENERIC MAP( NBIT => NBIT_PER_BLOCK )
            PORT MAP(
                A   => A(NBIT_PER_BLOCK * (i+1) - 1 downto NBIT_PER_BLOCK * i), 
                B   => B(NBIT_PER_BLOCK * (i+1) - 1 downto NBIT_PER_BLOCK * i),
                Cin => Ci(i),
                S   => S(NBIT_PER_BLOCK * (i+1) - 1 downto NBIT_PER_BLOCK * i)
            );
    end generate generateloop;

end STRUCTURAL;



configuration CFG_CSL_STRUCTURAL of sum_generator is
    for STRUCTURAL
        for generateloop
            for all: carry_select_block
                use configuration WORK.CFG_CSB_STRUCTURAL;
            end for;
        end for;
    end for;
  end CFG_CSL_STRUCTURAL;