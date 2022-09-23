`timescale 1ns/1ps

module system
(
  
	input wire CLK200M_1p, // Genesys2 has a differential LVDS 200MHz oscillator
	input wire CLK200M_1n,

	
	input wire mcu_rst,   // MCU_RESET-E18 button. ATTENTION: when pressing, value = 1. See: 13 Basic I/O Fig. 15

	// Dedicated QSPI interface
	output wire qspi0_cs,
	// output wire qspi0_sck, //  Genesys2 dosen't have it. See: 6.2 Quad-SPI Flash
	inout wire [3:0] qspi0_dq,

  //gpioA
  // inout wire [7:0] gpioA, // GPIOA-0~28, use 29 gpios of port A

  /*
  * Leds on board
  * GPIOA0 LED0
  * GPIOA1 LED1
  * GPIOA2 LED2
  * GPIOA3 LED3
  */
	inout wire [ 3:0]gpioA_LED,

  /*
  * Buttons on board
  * GPIOA4  btnd
  * GPIOA5  btnl
  * GPIOA6 	btnr
  */
	inout wire [ 2:0]gpioA_btn,
  
  /*
  * OLED SPI CS is always active. See: 15 OLED
  * GPIOA8  SCLK. OLED SPI sclk of Genesys2
  * GPIOA9  RES. OLED Reset. Active-low
  * GPIOA10 DC. OLED SPI dc
  * GPIOA11 SDIN. OLED SPI sdin
  * GPIOA12 VBAT
  * GPIOA13 VDD
  */
	
	/*
	*	GPIO IOF IIC
	*	GPIOA14
	*	GPIOA15
	*/
	inout wire gpioA_14,
	inout wire gpioA_15,

	/*
	*	GPIO IOF UART
	*	
	*
	*/
	inout wire uart_rx,
	inout wire uart_tx,
  
	//led_mcu_signal
    output wire led_mcu_signal,

	// JD (used for JTAG connection)
	inout wire mcu_TDO,   // MCU_TDO
	inout wire mcu_TCK,   // MCU_TCK
	inout wire mcu_TDI,   // MCU_TDI
	inout wire mcu_TMS  // MCU_TMS

  //pmu_wakeup


);
	//for trial to make the led on
  assign  led_mcu_signal = 1'b1;
  wire mmcm_locked;
  wire reset_periph;
  wire ck_rst;

  // All wires connected to the chip top
  wire dut_clock;
  wire dut_reset;

  wire dut_io_pads_jtag_TCK_i_ival;
  wire dut_io_pads_jtag_TMS_i_ival;
  wire dut_io_pads_jtag_TMS_o_oval;
  wire dut_io_pads_jtag_TMS_o_oe;
  wire dut_io_pads_jtag_TMS_o_ie;
  wire dut_io_pads_jtag_TMS_o_pue;
  wire dut_io_pads_jtag_TMS_o_ds;
  wire dut_io_pads_jtag_TDI_i_ival;
  wire dut_io_pads_jtag_TDO_o_oval;
  wire dut_io_pads_jtag_TDO_o_oe;

  wire [32-1:0] dut_io_pads_gpioA_i_ival;
  wire [32-1:0] dut_io_pads_gpioA_o_oval;
  wire [32-1:0] dut_io_pads_gpioA_o_oe;

  wire [32-1:0] dut_io_pads_gpioB_i_ival;
  wire [32-1:0] dut_io_pads_gpioB_o_oval;
  wire [32-1:0] dut_io_pads_gpioB_o_oe;

  wire dut_io_pads_qspi0_sck_o_oval;
  wire dut_io_pads_qspi0_cs_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_i_ival;
  wire dut_io_pads_qspi0_dq_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_o_oe;
  wire dut_io_pads_qspi0_dq_1_i_ival;
  wire dut_io_pads_qspi0_dq_1_o_oval;
  wire dut_io_pads_qspi0_dq_1_o_oe;
  wire dut_io_pads_qspi0_dq_2_i_ival;
  wire dut_io_pads_qspi0_dq_2_o_oval;
  wire dut_io_pads_qspi0_dq_2_o_oe;
  wire dut_io_pads_qspi0_dq_3_i_ival;
  wire dut_io_pads_qspi0_dq_3_o_oval;
  wire dut_io_pads_qspi0_dq_3_o_oe;


  wire dut_io_pads_aon_erst_n_i_ival;
  wire dut_io_pads_aon_pmu_dwakeup_n_i_ival;
  wire dut_io_pads_aon_pmu_vddpaden_o_oval;
  wire dut_io_pads_aon_pmu_padrst_o_oval ;
  wire dut_io_pads_bootrom_n_i_ival;
  wire dut_io_pads_dbgmode0_n_i_ival;
  wire dut_io_pads_dbgmode1_n_i_ival;
  wire dut_io_pads_dbgmode2_n_i_ival;

  //=================================================
  // Clock & Reset
  wire clk_8388;    // 8.388MHz clock
  wire clk_16M;     // 16MHz clock
  wire CLK32768KHZ;   // 32768KHz clock
  wire pll_locked;
  wire clk200M;

  assign ck_rst =  ~mcu_rst;
  
  	IBUFGDS #(
		.DIFF_TERM    ("FALSE"),
		.IBUF_LOW_PWR ("TRUE"),
		.IOSTANDARD   ("LVDS")
	) get_clk (
		.O  (clk200M),
		.I  (CLK200M_1p),
		.IB (CLK200M_1n)
	);

  clk_wiz_0 PLL
  (
    .CLK_O_16M(clk_16M),
    .CLK_O_8M388(clk_8388),
  // Status and control signals
    .resetn(ck_rst),
    .locked(pll_locked),
    .clk_in1(clk200M)
  );
  
    clkdivider rtc_clk_gen(
    .clk         (clk_8388   ),//generate 32.768KHz
    .reset       (~pll_locked),
    .clk_out     (CLK32768KHZ)
  );


  //=================================================
  // SPI0 Interface

  wire [3:0] qspi0_ui_dq_o;
  wire [3:0] qspi0_ui_dq_oe;
  wire [3:0] qspi0_ui_dq_i;

  PULLUP qspi0_pullup[3:0]
  (
    .O(qspi0_dq)
  );

  IOBUF qspi0_iobuf[3:0]
  (
    .IO(qspi0_dq),
    .O(qspi0_ui_dq_i),
    .I(qspi0_ui_dq_o),
    .T(~qspi0_ui_dq_oe)
  );


   //=================================================
  // IOBUF instantiation for GPIOs
  //***led**//
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_LED_USED
  (
    .O(dut_io_pads_gpioA_i_ival[0]),
    .IO(gpioA_LED[0]),
    .I(dut_io_pads_gpioA_o_oval[0]),
    .T(~dut_io_pads_gpioA_o_oe[0])
  ); 
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA1_LED_USED
  (
    .O(dut_io_pads_gpioA_i_ival[1]),
    .IO(gpioA_LED[1]),
    .I(dut_io_pads_gpioA_o_oval[1]),
    .T(~dut_io_pads_gpioA_o_oe[1])
  ); 
    IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA2_LED_USED
  (
    .O(dut_io_pads_gpioA_i_ival[2]),
    .IO(gpioA_LED[2]),
    .I(dut_io_pads_gpioA_o_oval[2]),
    .T(~dut_io_pads_gpioA_o_oe[2])
  ); 
    IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA3_LED_USED
  (
    .O(dut_io_pads_gpioA_i_ival[3]),
    .IO(gpioA_LED[3]),
    .I(dut_io_pads_gpioA_o_oval[3]),
    .T(~dut_io_pads_gpioA_o_oe[3])
  ); 


    //***button**//
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_key_USED
  (
    .O(dut_io_pads_gpioA_i_ival[6:4]),
    .IO(gpioA_btn),
    .I(dut_io_pads_gpioA_o_oval[6:4]),
    .T(~dut_io_pads_gpioA_o_oe[6:4])
  ); 
  //** I2C***//
    IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_SCL
  (
    .O(dut_io_pads_gpioA_i_ival[14]),
    .IO(gpioA_14),
    .I(dut_io_pads_gpioA_o_oval[14]),
    .T(~dut_io_pads_gpioA_o_oe[14])
  ); 
  
    IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_SDA
  (
    .O(dut_io_pads_gpioA_i_ival[15]),
    .IO(gpioA_15),
    .I(dut_io_pads_gpioA_o_oval[15]),
    .T(~dut_io_pads_gpioA_o_oe[15])
  ); 
  
  //**uart**//
    IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_TX_used
  (
    .O(dut_io_pads_gpioA_i_ival[17]),
    .IO(uart_tx),
    .I(dut_io_pads_gpioA_o_oval[17]),
    .T(~dut_io_pads_gpioA_o_oe[17])
  ); 

    IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_RX_used
  (
    .O(dut_io_pads_gpioA_i_ival[16]),
    .IO(uart_rx),
    .I(dut_io_pads_gpioA_o_oval[16]),
    .T(~dut_io_pads_gpioA_o_oe[16])
  );   

  // Disable gpioB for we don't use them



  //=================================================
  // JTAG IOBUFs

  wire iobuf_jtag_TCK_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TCK
  (
    .O(iobuf_jtag_TCK_o),
    .IO(mcu_TCK),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TCK_i_ival = iobuf_jtag_TCK_o ;
  PULLUP pullup_TCK (.O(mcu_TCK));

  wire iobuf_jtag_TMS_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TMS
  (
    .O(iobuf_jtag_TMS_o),
    .IO(mcu_TMS),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TMS_i_ival = iobuf_jtag_TMS_o;
  PULLUP pullup_TMS (.O(mcu_TMS));

  wire iobuf_jtag_TDI_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDI
  (
    .O(iobuf_jtag_TDI_o),
    .IO(mcu_TDI),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TDI_i_ival = iobuf_jtag_TDI_o;
  PULLUP pullup_TDI (.O(mcu_TDI));

  wire iobuf_jtag_TDO_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDO
  (
    .O(iobuf_jtag_TDO_o),
    .IO(mcu_TDO),
    .I(dut_io_pads_jtag_TDO_o_oval),
    .T(~dut_io_pads_jtag_TDO_o_oe)
  );

  //wire iobuf_jtag_TRST_n_o;
  //IOBUF
  //#(
  //  .DRIVE(12),
  //  .IBUF_LOW_PWR("TRUE"),
  //  .IOSTANDARD("DEFAULT"),
  //  .SLEW("SLOW")
  //)

  //=================================================
  // Assignment of IOBUF "IO" pins to package pins

  // Pins IO0-IO13
  // Shield header row 0: PD0-PD7

  // Use the LEDs for some more useful debugging things.

  // model select
  assign dut_io_pads_bootrom_n_i_ival  = 1'b1;   //
  assign dut_io_pads_dbgmode0_n_i_ival = 1'b1;
  assign dut_io_pads_dbgmode1_n_i_ival = 1'b1;
  assign dut_io_pads_dbgmode2_n_i_ival = 1'b1;
  //

 e203_soc_top dut
  (
    //System CLOCK
    .hfextclk(clk_16M),
    .hfxoscen(),

    //RTC CLOCK
    .lfextclk(CLK32768KHZ), 
    .lfxoscen(),

    //JTAG
    .io_pads_jtag_TCK_i_ival(dut_io_pads_jtag_TCK_i_ival),
    .io_pads_jtag_TMS_i_ival(dut_io_pads_jtag_TMS_i_ival),
    .io_pads_jtag_TDI_i_ival(dut_io_pads_jtag_TDI_i_ival),
    .io_pads_jtag_TDO_o_oval(dut_io_pads_jtag_TDO_o_oval),
    .io_pads_jtag_TDO_o_oe  (dut_io_pads_jtag_TDO_o_oe),

    //GPIO A
    .io_pads_gpioA_i_ival(dut_io_pads_gpioA_i_ival),
    .io_pads_gpioA_o_oval(dut_io_pads_gpioA_o_oval),
    .io_pads_gpioA_o_oe  (dut_io_pads_gpioA_o_oe),
    //GPIO B
    .io_pads_gpioB_i_ival(dut_io_pads_gpioB_i_ival),
    .io_pads_gpioB_o_oval(dut_io_pads_gpioB_o_oval),
    .io_pads_gpioB_o_oe  (dut_io_pads_gpioB_o_oe),

    //QPSI
    .io_pads_qspi0_sck_o_oval (),
    .io_pads_qspi0_cs_0_o_oval(),
    .io_pads_qspi0_dq_0_i_ival(),
    .io_pads_qspi0_dq_0_o_oval(),
    .io_pads_qspi0_dq_0_o_oe  (),
    .io_pads_qspi0_dq_1_i_ival(),
    .io_pads_qspi0_dq_1_o_oval(),
    .io_pads_qspi0_dq_1_o_oe  (),
    .io_pads_qspi0_dq_2_i_ival(),
    .io_pads_qspi0_dq_2_o_oval(),
    .io_pads_qspi0_dq_2_o_oe  (),
    .io_pads_qspi0_dq_3_i_ival(),
    .io_pads_qspi0_dq_3_o_oval(),
    .io_pads_qspi0_dq_3_o_oe  (),
    /*
    //QPSI
    .io_pads_qspi0_sck_o_oval (dut_io_pads_qspi0_sck_o_oval),
    .io_pads_qspi0_cs_0_o_oval(dut_io_pads_qspi0_cs_0_o_oval),

    .io_pads_qspi0_dq_0_i_ival(dut_io_pads_qspi0_dq_0_i_ival),
    .io_pads_qspi0_dq_0_o_oval(dut_io_pads_qspi0_dq_0_o_oval),
    .io_pads_qspi0_dq_0_o_oe  (dut_io_pads_qspi0_dq_0_o_oe),
    .io_pads_qspi0_dq_1_i_ival(dut_io_pads_qspi0_dq_1_i_ival),
    .io_pads_qspi0_dq_1_o_oval(dut_io_pads_qspi0_dq_1_o_oval),
    .io_pads_qspi0_dq_1_o_oe  (dut_io_pads_qspi0_dq_1_o_oe),
    .io_pads_qspi0_dq_2_i_ival(dut_io_pads_qspi0_dq_2_i_ival),
    .io_pads_qspi0_dq_2_o_oval(dut_io_pads_qspi0_dq_2_o_oval),
    .io_pads_qspi0_dq_2_o_oe  (dut_io_pads_qspi0_dq_2_o_oe),
    .io_pads_qspi0_dq_3_i_ival(dut_io_pads_qspi0_dq_3_i_ival),
    .io_pads_qspi0_dq_3_o_oval(dut_io_pads_qspi0_dq_3_o_oval),
    .io_pads_qspi0_dq_3_o_oe  (dut_io_pads_qspi0_dq_3_o_oe),
    */
    //RST_N
    .io_pads_aon_erst_n_i_ival(ck_rst),

//    //PMU
    .io_pads_aon_pmu_dwakeup_n_i_ival(),
    .io_pads_aon_pmu_vddpaden_o_oval (),
    .io_pads_aon_pmu_padrst_o_oval   (),

    //PMU
//    .io_pads_aon_pmu_dwakeup_n_i_ival(dut_io_pads_aon_pmu_dwakeup_n_i_ival),
//    .io_pads_aon_pmu_vddpaden_o_oval(dut_io_pads_aon_pmu_vddpaden_o_oval),
//    .io_pads_aon_pmu_padrst_o_oval    (dut_io_pads_aon_pmu_padrst_o_oval ),
    


    .io_pads_bootrom_n_i_ival        (dut_io_pads_bootrom_n_i_ival),

    .io_pads_dbgmode0_n_i_ival       (dut_io_pads_dbgmode0_n_i_ival),
    .io_pads_dbgmode1_n_i_ival       (dut_io_pads_dbgmode1_n_i_ival),
    .io_pads_dbgmode2_n_i_ival       (dut_io_pads_dbgmode2_n_i_ival) 
    
  );
  // Assign reasonable values to otherwise unconnected inputs to chip top

//  wire iobuf_dwakeup_o;
//  IOBUF
//  #(
//    .DRIVE(12),
//    .IBUF_LOW_PWR("TRUE"),
//    .IOSTANDARD("DEFAULT"),
//    .SLEW("SLOW")
//  )
//  IOBUF_dwakeup_n
//  (
//    .O(iobuf_dwakeup_o),
//    .IO(mcu_wakeup),
//    .I(1'b1),
//    .T(1'b1)
//  );
//  assign dut_io_pads_aon_pmu_dwakeup_n_i_ival = (~iobuf_dwakeup_o);



//  assign dut_io_pads_aon_pmu_vddpaden_i_ival = 1'b1;

  wire qspi0_sck;
  assign qspi0_sck = dut_io_pads_qspi0_sck_o_oval;
  assign qspi0_cs  = dut_io_pads_qspi0_cs_0_o_oval;
  assign qspi0_ui_dq_o = {
    dut_io_pads_qspi0_dq_3_o_oval,
    dut_io_pads_qspi0_dq_2_o_oval,
    dut_io_pads_qspi0_dq_1_o_oval,
    dut_io_pads_qspi0_dq_0_o_oval
  };
  assign qspi0_ui_dq_oe = {
    dut_io_pads_qspi0_dq_3_o_oe,
    dut_io_pads_qspi0_dq_2_o_oe,
    dut_io_pads_qspi0_dq_1_o_oe,
    dut_io_pads_qspi0_dq_0_o_oe
  };
  assign dut_io_pads_qspi0_dq_0_i_ival = qspi0_ui_dq_i[0];
  assign dut_io_pads_qspi0_dq_1_i_ival = qspi0_ui_dq_i[1];
  assign dut_io_pads_qspi0_dq_2_i_ival = qspi0_ui_dq_i[2];
  assign dut_io_pads_qspi0_dq_3_i_ival = qspi0_ui_dq_i[3];

  STARTUPE2
  #(
  .PROG_USR("FALSE"),
  .SIM_CCLK_FREQ(0.0)
  )  STARTUPE2_inst (
    .CFGCLK     (),
    .CFGMCLK    (),
    .EOS        (),
    .PREQ       (),
    .CLK        (1'b0),
    .GSR        (1'b0),
    .GTS        (1'b0),
    .KEYCLEARB  (1'b0),
    .PACK       (1'b0),
    .USRCCLKO   (qspi0_sck),  // First three cycles after config ignored, see AR# 52626
    .USRCCLKTS  (1'b0),       // 0 to enable CCLK output
    .USRDONEO   (1'b1),       // Shouldn't matter if tristate is high, but generates a warning if tied low.
    .USRDONETS  (1'b1)        // 1 to tristate DONE output
  );


endmodule