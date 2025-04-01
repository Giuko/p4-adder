library ieee; 
use ieee.std_logic_1164.all; 

entity PG_COMP is
    PORT(
        Gik: IN std_logic;
        Pik: IN std_logic;
        Gkj: IN std_logic;      -- G_k-1_j
        Pkj: IN std_logic;      -- P_k-1_j
        
        Gij: OUT std_logic;
        Pij: OUT std_logic
    );
end PG_COMP;

architecture BEHAVIORAL of PG_COMP is
begin
    Gij <= Gik OR (Pik AND Gkj);
    Pij <= Pik AND Pkj;
end architecture;

-- configuration CFG_PG_BEHAVIORAL of PG_COMP is
--     for BEHAVIORAL
--     end for;
--   end CFG_PG_BEHAVIORAL;