library ieee; 
use ieee.std_logic_1164.all; 

entity G_COMP is
    PORT(
        Gik: IN std_logic;
        Pik: IN std_logic;
        Gkj: IN std_logic;      -- G_k-1_j
        
        Gij: OUT std_logic
    );
end G_COMP;

architecture BEHAVIORAL of G_COMP is
begin
    Gij <= Gik OR (Pik AND Gkj);
end architecture;

configuration CFG_G_BEHAVIORAL of G_COMP is
    for BEHAVIORAL
    end for;
  end CFG_G_BEHAVIORAL;