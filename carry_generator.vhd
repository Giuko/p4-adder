library ieee; 
use ieee.std_logic_1164.all; 
use ieee.math_real.all;

entity CARRY_GENERATOR is
    GENERIC(
        -- We suppose the carry is generated each four bit 
        -- We suppose NBIT = 2^x, 2 < x < 7 (8, 16, 32, 64)
        NBIT: INTEGER
    );
    PORT(
        A  : IN std_logic_vector(NBIT-1 downto 0);
        B  : IN std_logic_vector(NBIT-1 downto 0);
        Cin : IN std_logic;
        Co  : OUT std_logic_vector((NBIT/4)-1 downto 0)
    );
end CARRY_GENERATOR;

architecture STRUCTURAL of CARRY_GENERATOR is

    -------------------------------------------
    -- Function
    -------------------------------------------
    
    -- In each level there are 'block', and only in the first block we are going to 
    -- instantiate G_COMP, for each other group we are going to instantiate PG_COMP
    function get_group(level: integer; position:integer) return integer is     
        constant level_width : integer := 2**(level-1)*4;
    begin
        return (position+level_width-1)/(level_width);
    end function;

    -- In each level there are 'block' for example
    -- for level 1:
    --      {1, 2, 3, 4} {5, 6, 7, 8} {9, 10, 11, 12} {13, 14, 15, 16}
    -- for level 2:
    --      {1, 2, 3, 4, 5, 6, 7, 8} {9, 10, 11, 12, 13, 14, 15, 16}
    -- and so on, for each group we will say if the position is in the
    -- upper_half or not
    function is_upper_half(level: integer; position:integer) return integer is
        constant level_width : integer := 2**(level-1)*4;
        constant group_num : integer := get_group(level, position);
        constant relative_position: integer := position-level_width*(group_num-1);

    begin
        if (relative_position > level_width/2) then 
            return 1;                   -- if it is in the upper half
        end if;
        return 0;                       -- if it is in the lower half
    end function;
    

    -- For each block instantiated we need to find k, i and j

    function get_k(level: integer; position:integer) return integer is     
    begin
        return get_group(level, position)*2**(level-1)*16-2**(level-1)*8+1;
    end function;

    function get_i(position:integer) return integer is     
    begin
        return position*4;
    end function;

    -- j = (group = 1) ? 0 : [k-1-(2^(level-1)*8-1)]
    function get_j(level: integer; position:integer) return integer is     
    begin
        if(get_group(level, position) = 1) then
            return 0;
        else
            return (get_k(level, position)-1)-(2**(level-1)*8-1);
        end if;
    end function;
    -------------------------------------------
    -- Component
    -------------------------------------------
    component G_COMP is
        PORT(
            Gik: IN std_logic;
            Pik: IN std_logic;
            Gkj: IN std_logic;      -- G_k-1_j
            
            Gij: OUT std_logic
        );
    end component;

    component PG_COMP is
        PORT(
            Gik: IN std_logic;
            Pik: IN std_logic;
            Gkj: IN std_logic;      -- G_k-1_j
            Pkj: IN std_logic;      -- P_k-1_j
            
            Gij: OUT std_logic;
            Pij: OUT std_logic
        );
    end component;
    
    signal p: std_logic_vector(NBIT downto 1);   -- a xor b
    signal g: std_logic_vector(NBIT downto 1);   -- a and b
    
	type PG_matrix is array (NBIT downto 1) of std_logic_vector(NBIT-1 downto 0);
    signal capitalP: PG_matrix;
    signal capitalG: PG_matrix;


    constant other_levels: integer := integer(log2(real(NBIT)));

begin
    -- PG NETWORK
    PG_network: for i in 0 to NBIT-1 generate
        p(i+1) <= A(i) xor B(i);
        g(i+1) <= A(i) and B(i);
    end generate PG_network;
    
    -- First capital G generated
    capitalG(1)(0) <= g(1) OR (p(1) and Cin); --G 1:0 = G 1:1 + P 1:1 * G 0:0 = g1 + p1 * g0, the g0 is the carry in

    -- Sparse tree
    
    first_level: for i in 0 to NBIT/2-1 generate
        first_level_g_if: if i=0 generate
            first_level_g: G_COMP
                PORT MAP(
                    Gik => g(2),
                    Pik => p(2),
                    Gkj => capitalG(1)(0),

                    Gij => capitalG(2)(0)
                );
        end generate;

        first_level_pg_if: if i/=0 generate
            first_level_pg: PG_COMP
                PORT MAP(                    
                    Gik => g(2*i+2),
                    Pik => p(2*i+2),

                    Gkj => g(2*i+1),
                    Pkj => p(2*i+1),

                    Gij => capitalG(2*i+2)(2*i+1),  -- Here we generate G 4:3, 6:5, 8:7, ..
                    Pij => capitalP(2*i+2)(2*i+1)   -- Here we generate P 4:3, 6:5, 8:7, ..
                );
        end generate;
    end generate first_level;
    
    second_level: for i in 0 to NBIT/4-1 generate
        second_level_g_if: if i=0 generate
            second_level_g: G_COMP
                PORT MAP(
                    Gik => capitalG(4)(3),
                    Pik => capitalP(4)(3),
                    Gkj => capitalG(2)(0),

                    Gij => capitalG(4)(0)
                );
        end generate;

        second_level_pg_if: if i/=0 generate
            second_level_pg: PG_COMP
                PORT MAP(                               -- In this way we will have
                    Gik => capitalG(4*i+4)(4*i+3),      -- G 6:5, 10:9, 14:13, ..
                    Pik => capitalP(4*i+4)(4*i+3),      -- P 6:5, 10:9, 14:13, ..

                    Gkj => capitalG(4*i+2)(4*i+1),      -- G 8:7, 12:1, 16:15, ..
                    Pkj => capitalP(4*i+2)(4*i+1),      -- P 8:7, 12:1, 16:15, ..

                    Gij => capitalG(4*i+4)(4*i+1),      -- G 8:5, 12:9, 16:13, ..
                    Pij => capitalP(4*i+4)(4*i+1)       -- P 8:5, 12:9, 16:13, ..
                );
        end generate;
    end generate second_level;
    
    third_level: for i in 0 to NBIT/8-1 generate
        third_level_g_if: if i=0 generate
            third_level_g: G_COMP
                PORT MAP(
                    Gik => capitalG(8)(5),
                    Pik => capitalP(8)(5),
                    Gkj => capitalG(4)(0),

                    Gij => capitalG(8)(0)
                );
        end generate;

        third_level_pg_if: if i/=0 generate
            third_level_pg: PG_COMP
                PORT MAP(                               -- In this way we will have
                    Gik => capitalG(8*i+8)(8*i+5),      -- G  12:9, 20:17, 28:25
                    Pik => capitalP(8*i+8)(8*i+5),      -- P  12:9, 20:17, 28:25

                    Gkj => capitalG(8*i+4)(8*i+1),      -- G 16:13, 24:21, 32:29 
                    Pkj => capitalP(8*i+4)(8*i+1),      -- P 16:13, 24:21, 32:29 

                    Gij => capitalG(8*i+8)(8*i+1),      -- G  16:9, 24:17, 32:25
                    Pij => capitalP(8*i+8)(8*i+1)       -- P  16:9, 24:17, 32:25
                );
        end generate;
    end generate third_level;

    -- After the 3 levels, the pattern is different

    for_other_levels: for level in 1 to other_levels-2 generate
        foreach_level: for position in 1 to NBIT/4 generate
            upper_half: if(is_upper_half(level, position) = 1) generate
                -- only in the upper half we instantiate G_COMP or PG_COMP
                
                identify_g: if(get_group(level, position) = 1) generate
                    -- G_COMP
                    others_level_g: G_COMP
                    PORT MAP(
                        Gik => capitalG(get_i(position))(get_k(level, position)),
                        Pik => capitalP(get_i(position))(get_k(level, position)),
                        
                        Gkj => capitalG(get_k(level, position)-1)(get_j(level, position)),

                        Gij => capitalG(get_i(position))(get_j(level, position))
                    );
                end generate identify_g;

                identify_pg: if(get_group(level, position) /= 1) generate
                    -- PG_COMP
                    others_level_pg: PG_COMP
                    PORT MAP(
                        Gik => capitalG(get_i(position))(get_k(level, position)),
                        Pik => capitalP(get_i(position))(get_k(level, position)),    

                        Gkj => capitalG(get_k(level, position)-1)(get_j(level, position)),
                        Pkj => capitalP(get_k(level, position)-1)(get_j(level, position)),

                        Gij => capitalG(get_i(position))(get_j(level, position)),
                        Pij => capitalP(get_i(position))(get_j(level, position))
                    );
                end generate identify_pg;
                
            end generate upper_half;
        end generate foreach_level;
    end generate for_other_levels;
    
---------------------------------------------------
-- Fixed for 32 bits (start)
---------------------------------------------------
--     G_block1: G_COMP
--     PORT MAP(
--         Gik => capitalG(12)(9),
--         Pik => capitalP(12)(9),
--         Gkj => capitalG(8)(0),

--         Gij => capitalG(12)(0)
--     );
--     G_block2: G_COMP
--     PORT MAP(
--         Gik => capitalG(16)(9),
--         Pik => capitalP(16)(9),
--         Gkj => capitalG(8)(0),

--         Gij => capitalG(16)(0)
--     );

--     PG_block1: PG_COMP
--     PORT MAP(                    
--         Gik => capitalG(24)(17),
--         Pik => capitalP(24)(17),

--         Gkj => capitalG(28)(25),
--         Pkj => capitalP(28)(25),

--         Gij => capitalG(28)(17),  
--         Pij => capitalP(28)(17)  
--     );

--     PG_block2: PG_COMP
--     PORT MAP(                    
--         Gik => capitalG(24)(17),
--         Pik => capitalP(24)(17),

--         Gkj => capitalG(32)(25),
--         Pkj => capitalP(32)(25),

--         Gij => capitalG(32)(17),  
--         Pij => capitalP(32)(17)  
--     );

-- -- Last level
--     G_block3: G_COMP
--     PORT MAP(
--         Gik => capitalG(20)(17),
--         Pik => capitalP(20)(17),
--         Gkj => capitalG(16)(0),

--         Gij => capitalG(20)(0)
--     );

--     G_block4: G_COMP
--     PORT MAP(
--         Gik => capitalG(24)(17),
--         Pik => capitalP(24)(17),
--         Gkj => capitalG(16)(0),

--         Gij => capitalG(24)(0)
--     );

--     G_block5: G_COMP
--     PORT MAP(
--         Gik => capitalG(28)(17),
--         Pik => capitalP(28)(17),
--         Gkj => capitalG(16)(0),

--         Gij => capitalG(28)(0)
--     );

--     G_block6: G_COMP
--     PORT MAP(
--         Gik => capitalG(32)(17),
--         Pik => capitalP(32)(17),
--         Gkj => capitalG(16)(0),

--         Gij => capitalG(32)(0)
--     );

---------------------------------------------------
-- Fixed for 32 bits (end)
---------------------------------------------------

-- Assigning the carry
    carry_assignment: for i in 0 to NBIT/4-1 generate
        Co(i) <= capitalG((i+1)*4)(0);
    end generate;

end architecture;

configuration CFG_CLA_GENERATOR_STRUCTURAL of CLA_generator is
    for STRUCTURAL
    end for;
end CFG_CLA_GENERATOR_STRUCTURAL;
