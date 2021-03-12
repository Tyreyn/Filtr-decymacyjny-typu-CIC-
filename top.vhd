----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/02/2020 02:02:16 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

 

entity top is
    Generic(
    data_width : integer := 24
    );
    Port ( CLK100MHZ : in STD_LOGIC;
           LED : out STD_LOGIC_VECTOR (15 downto 0);
           AD_MCLK : out STD_LOGIC;
           AD_LRCK : out STD_LOGIC;
           AD_SCLK : out STD_LOGIC;
           AD_SDOUT : in STD_LOGIC;
           DA_MCLK : out STD_LOGIC;
           DA_LRCK : out STD_LOGIC;
           DA_SCLK : out STD_LOGIC;
           DA_SDIN : out STD_LOGIC;
           LED16_R : out STD_LOGIC;
           LED16_G : out STD_LOGIC;
           LED16_B : out STD_LOGIC;
           LED17_R : out STD_LOGIC;
           LED17_G : out STD_LOGIC;
           LED17_B : out STD_LOGIC
           );
end top;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PWM is
    GENERIC(
            TYP: in integer        
    );
    Port( 
         CLK100MHZ : in STD_LOGIC;
         duty : in STD_LOGIC_VECTOR(63 downto 0);
         pwm_out : out STD_LOGIC
    );
end PWM;

architecture Behavioral of top is   
    signal LED_TMP : unsigned(15 downto 0) := (0 => '1', OTHERS => '0');
    signal CIC_STRBL : std_logic := '0';
    signal CIC_OUTL : std_logic_vector(data_width-1 downto 0):= (OTHERS => '0');
    signal LTMP : std_logic_vector(data_width-1 downto 0):= (OTHERS => '0');
    signal cntstrb : integer range 0 to 2 :=1;
    signal cntzero :integer range 0 to 7 := 0;
    signal in_validl :std_logic :='0';
    signal in_validr :std_logic :='0';
    signal divider : std_logic_vector(32 downto 0) :=(OTHERS =>'0');
    signal shift_reg_in : std_logic_vector(63 downto 0):=(OTHERS =>'0');
    signal shift_reg_out : std_logic_vector(63 downto 0):=(OTHERS =>'0');
    signal left_in : std_logic_vector(data_width-1 downto 0):=(OTHERS=>'0');
    signal right_in : std_logic_vector(data_width-1 downto 0):=(OTHERS=>'0');
    signal zeros : std_logic_vector(data_width-1 downto 0):=(OTHERS=>'0');
    signal CIC_TMP : std_logic := '0';
    signal LOW_OUTL,LOW_OUTR : std_logic_vector(63 downto 0) :=(others =>'0');
    signal HIGH_OUTR, HIGH_OUTL : std_logic_vector(63 downto 0 ) := (others=>'0');
    signal PASS_OUTL, PASS_OUTR : std_logic_vector(63 downto 0 ) := (others=>'0');
    signal VALID_LOWL,VALID_LOWR,VALID_HIGHL,VALID_HIGHR, VALID_PASSL, VALID_PASSR : std_logic := '0';
    signal LOW_STRBL,LOW_STRBR,HIGH_STRBL,HIGH_STRBR,PASS_STRBL,PASS_STRBR : std_logic := '0';
    COMPONENT cic_decimator is
        Port ( 
        aclk : in STD_LOGIC;
        s_axis_data_tdata : in STD_LOGIC_VECTOR ( 23 downto 0 );
        s_axis_data_tvalid : in STD_LOGIC;
        s_axis_data_tready : out STD_LOGIC;
        m_axis_data_tdata : out STD_LOGIC_VECTOR ( 23 downto 0 );
        m_axis_data_tvalid : out STD_LOGIC
        );
    end component;
    component fir_high_pass is
      Port ( 
        aclk : in STD_LOGIC;
        s_axis_data_tvalid : in STD_LOGIC;
        s_axis_data_tready : out STD_LOGIC;
        s_axis_data_tdata : in STD_LOGIC_VECTOR ( 23 downto 0 );
        m_axis_data_tvalid : out STD_LOGIC;
        m_axis_data_tdata : out STD_LOGIC_VECTOR ( 47 downto 0 )
      );
    
    end component;
    component fir_low_pass is
      Port ( 
        aclk : in STD_LOGIC;
        s_axis_data_tvalid : in STD_LOGIC;
        s_axis_data_tready : out STD_LOGIC;
        s_axis_data_tdata : in STD_LOGIC_VECTOR ( 23 downto 0 );
        m_axis_data_tvalid : out STD_LOGIC;
        m_axis_data_tdata : out STD_LOGIC_VECTOR ( 39 downto 0 )
      );
    
    end component;
    component fir_pass_band is
      Port ( 
        aclk : in STD_LOGIC;
        s_axis_data_tvalid : in STD_LOGIC;
        s_axis_data_tready : out STD_LOGIC;
        s_axis_data_tdata : in STD_LOGIC_VECTOR ( 23 downto 0 );
        m_axis_data_tvalid : out STD_LOGIC;
        m_axis_data_tdata : out STD_LOGIC_VECTOR ( 47 downto 0 )
      );
    end component;
    component PWM is
    Generic(
        TYP: in integer
        );
    Port( 
         CLK100MHZ : in STD_LOGIC;
         duty : in STD_LOGIC_VECTOR(63 downto 0);
         pwm_out : out STD_LOGIC
    );
    end component;
begin
    CICL : cic_decimator PORT MAP (CLK100MHZ,std_logic_vector(signed(shift_reg_in(62 downto 39))),in_validl,open,CIC_OUTL,CIC_STRBL);
    
    LOWL : fir_low_pass PORT MAP(CLK100MHZ,in_validl,VALID_LOWL,std_logic_vector(signed(shift_reg_in(62 downto 39))),LOW_STRBL,LOW_OUTL(63 downto 24));
    LOWR : fir_low_pass PORT MAP(CLK100MHZ,in_validl,VALID_LOWR,std_logic_vector(signed(shift_reg_in(30 downto 7))),LOW_STRBR,LOW_OUTR(63 downto 24));
    
    HIGHL : fir_high_pass PORT MAP(CLK100MHZ,in_validl,VALID_HIGHL,std_logic_vector(signed(shift_reg_in(62 downto 39))),HIGH_STRBL,HIGH_OUTR(63 downto 16));
    HIGHR : fir_high_pass PORT MAP(CLK100MHZ,in_validl,VALID_HIGHR,std_logic_vector(signed(shift_reg_in(30 downto 7))),HIGH_STRBR,HIGH_OUTL(63 downto 16));
    
    PASSL : fir_pass_band PORT MAP(CLK100MHZ,in_validl,VALID_PASSL,std_logic_vector(signed(shift_reg_in(62 downto 39))),PASS_STRBL,PASS_OUTL(63 downto 16));
    PASSR : fir_pass_band PORT MAP(CLK100MHZ,in_validl,VALID_PASSR,std_logic_vector(signed(shift_reg_in(30 downto 7))),PASS_STRBR,PASS_OUTR(63 downto 16));
    
    R_RED : PWM GENERIC MAP(1) PORT MAP(CLK100MHZ, LOW_OUTR , LED16_R);
    R_GREEN : PWM GENERIC MAP(2) PORT MAP(CLK100MHZ, PASS_OUTR, LED16_G);
    R_BLUE : PWM GENERIC MAP(2) PORT MAP(CLK100MHZ, HIGH_OUTR, LED16_B);
    L_RED : PWM GENERIC MAP(1) PORT MAP(CLK100MHZ, LOW_OUTL, LED17_R);
    L_GREEN : PWM GENERIC MAP(2) PORT MAP(CLK100MHZ, PASS_OUTL, LED17_G);
    L_BLUE : PWM GENERIC MAP(2) PORT MAP(CLK100MHZ, HIGH_OUTL, LED17_B);
    process(CLK100MHZ)
    begin
      if rising_edge(CLK100MHZ) then
        if(CIC_STRBL = '1') then 
            CIC_TMP <= '1';
        end if;
        in_validl <= '0';
        divider <= divider + '1';
        if (divider(4 downto 0) = "01111") then
            shift_reg_in <= shift_reg_in(62 downto 0) & AD_SDOUT;
        end if;
        if (divider(4 downto 0) = "11111") then
            shift_reg_out <= shift_reg_out(62 downto 0) & '0';
        end if;
        if (divider = b"111_1111_1111") then
            divider <= (OTHERS => '0');
            LED <= std_logic_vector(abs(signed(shift_reg_in(62 downto 47))));
            in_validl <= '1';
            left_in <= std_logic_vector(signed(shift_reg_in(62 downto 39)));
            right_in <= std_logic_vector(signed(shift_reg_in(30 downto 7)));
            --shift_reg_out <= shift_reg_in; 
            if(CIC_TMP = '1') then
                shift_reg_out <= '0' & CIC_OUTL & "00000000" & CIC_OUTL & "0000000";
                CIC_TMP <= '0';
            else
                shift_reg_out <= '0' & CIC_OUTL & "00000000" & zeros & "0000000";
            end if;
        end if;
      end if;
    end process; 

    AD_MCLK <= divider(2);  -- 12.5 MHz
    DA_MCLK <= divider(2);
    AD_SCLK <= divider(4);  -- 3.125 MHz
    DA_SCLK <= divider(4);
    AD_LRCK <= divider(10); -- 48.83 kHz
    DA_LRCK <= divider(10);
    DA_SDIN <= shift_reg_out(63);
end Behavioral;

architecture Behavioral of PWM is   
  signal t : integer :=0;
  signal bad : integer :=0;
  SIGNAL  count : INTEGER  := 0;         
  signal old : std_logic_vector(63 downto 0) := std_logic_vector(abs(signed(duty)));
  signal half_duty, half_duty_new : integer range 0 to 100000/2;
  
begin
    process(CLK100MHZ) begin
    IF(CLK100MHZ'EVENT AND CLK100MHZ = '1') THEN  
    if(typ = 1) then
        half_duty_new <= conv_integer(duty(63 downto 47))*100000/(2**16)/2;   
    elsif(typ = 2)then
        half_duty_new <= conv_integer(duty(55 downto 39))*100000/(2**16)/2;
    end if;
    if(t = 100000) then
        t <= 0;
        half_duty <= half_duty_new;
    else
        t<= t +1;
    end if;
    if(t =half_duty) then
        pwm_out <= '0';
    elsif(t = 100000 - half_duty) then
        pwm_out <= '1';
    end if;
    
    end if;
    end process;
end Behavioral;