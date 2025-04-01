library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity p4_adder is
    generic(
        NBIT: integer
    );
    port(
        A:  IN std_logic_vector(NBIT-1 downto 0);
        B:  IN std_logic_vector(NBIT-1 downto 0);
        Ci: IN std_logic;

        Cout: OUT std_logic;
        S:    OUT std_logic_vector(NBIT-1 downto 0)  
    );
end p4_adder;

architecture structural of p4_adder is

    component sum_generator is
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
    end component;

    component  CARRY_GENERATOR is
        GENERIC(
            -- We suppose the carry is generated each four bit 
            -- We suppose NBIT = 2^x,(8, 16, 32, 64)
            NBIT: INTEGER
        );
        PORT(
            A  : IN std_logic_vector(NBIT-1 downto 0);
            B  : IN std_logic_vector(NBIT-1 downto 0);
            Cin : IN std_logic;
            Co  : OUT std_logic_vector((NBIT/4)-1 downto 0)
        );
    end component;
    signal carry_generated: std_logic_vector((NBIT/4)-1 downto 0);
    signal carry_in_sum: std_logic_vector((NBIT/4)-1 downto 0);

begin

    carry_generate: CARRY_GENERATOR 
        generic map(NBIT => NBIT) 
        port map(
            A => A,
            B => B,
            Cin => Ci,
            Co => carry_generated
        );
    
    carry_in_sum <= carry_generated((NBIT/4)-2 downto 0) & Ci;
    sum_generate: sum_generator
        generic map(
            NBIT_PER_BLOCK => NBIT/8,       -- 
            NBLOCKS => NBIT/4               --
        )
        port map(
            A => A,
            B => B,
            Ci => carry_in_sum,
            S => S
        );
    
    Cout <= carry_generated((NBIT/4)-1);
end architecture;