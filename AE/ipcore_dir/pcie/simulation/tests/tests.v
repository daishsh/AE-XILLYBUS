//-----------------------------------------------------------------------------
//
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Spartan-6 Integrated Block for PCI Express
// File       : tests.v
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tests ();

  reg [255:0] testname;
  integer test_vars [31:0];
  reg [7:0] expect_cpld_payload [4095:0];
  reg [7:0] expect_msgd_payload [4095:0];
  reg [7:0] expect_memwr_payload [4095:0];
  reg [7:0] expect_memwr64_payload [4095:0];
  reg [7:0] expect_cfgwr_payload [3:0];
  reg expect_status;
  reg expect_finish_check;

  initial begin
    if ($value$plusargs("TESTNAME=%s", testname))
      $display("Running test {%0s}......", testname);
    else
    begin
      // $display("[%t] %m: No TESTNAME specified!", $realtime);
      // $finish(2);
      testname = "sample_smoke_test0";
      $display("Running default test {%0s}......", testname);
    end
    expect_status = 0;
    expect_finish_check = 0;

    // Payload data initialization.
    board.RP.tx_usrapp.TSK_USR_DATA_SETUP_SEQ;

    //Test starts here
    if (testname == "dummy_test")
    begin
      $display("[%t] %m: Invalid TESTNAME: %0s", $realtime, testname);
      $finish(2);
    end
  else if(testname == "sample_smoke_test0")
  begin


      board.RP.tx_usrapp.TSK_SIMULATION_TIMEOUT(5050);

      //System Initialization
      board.RP.tx_usrapp.TSK_SYSTEM_INITIALIZATION;

  



      $display("[%t] : Expected Device/Vendor ID = %x", $realtime, board.RP.tx_usrapp.DEV_VEN_ID);

      //--------------------------------------------------------------------------
      // Read core configuration space via PCIe fabric interface
      //--------------------------------------------------------------------------

      $display("[%t] : Reading from PCI/PCI-Express Configuration Register 0x00", $realtime);

      board.RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_READ(board.RP.tx_usrapp.DEFAULT_TAG, 12'h0, 4'hF);
      board.RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
      if  (board.RP.tx_usrapp.P_READ_DATA != board.RP.tx_usrapp.DEV_VEN_ID) begin
          $display("[%t] : TEST FAILED --- Data Error Mismatch, Write Data %x != Read Data %x", $realtime,
                                      board.RP.tx_usrapp.DEV_VEN_ID, board.RP.tx_usrapp.P_READ_DATA);
      end
      else begin
          $display("[%t] : TEST PASSED --- Device/Vendor ID %x successfully received", $realtime, board.RP.tx_usrapp.P_READ_DATA);
      end

      //--------------------------------------------------------------------------
      // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
      // BusMstr in the command register
      //--------------------------------------------------------------------------
      board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
      board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
      board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

      expect_finish_check = 1;

    $finish;
  end


  else if(testname == "sample_smoke_test1")
  begin

      // This test use tlp expectation tasks.

      board.RP.tx_usrapp.TSK_SIMULATION_TIMEOUT(5050);

      //System Initialization
      board.RP.tx_usrapp.TSK_SYSTEM_INITIALIZATION;
  
  fork
    begin
      //--------------------------------------------------------------------------
      // Read core configuration space via PCIe fabric interface
      //--------------------------------------------------------------------------

      $display("[%t] : Reading from PCI/PCI-Express Configuration Register 0x00", $realtime);

      board.RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_READ(board.RP.tx_usrapp.DEFAULT_TAG, 12'h0, 4'hF);
      board.RP.tx_usrapp.DEFAULT_TAG = board.RP.tx_usrapp.DEFAULT_TAG + 1;
      board.RP.tx_usrapp.TSK_TX_CLK_EAT(100);
    end
      //---------------------------------------------------------------------------
      // List Rx TLP expections
      //---------------------------------------------------------------------------
    begin
      test_vars[0] = 0;

      $display("[%t] : Expected Device/Vendor ID = %x", $realtime, board.RP.tx_usrapp.DEV_VEN_ID);

      expect_cpld_payload[0] = board.RP.tx_usrapp.DEV_VEN_ID[7:0];
      expect_cpld_payload[1] = board.RP.tx_usrapp.DEV_VEN_ID[15:8];
      expect_cpld_payload[2] = board.RP.tx_usrapp.DEV_VEN_ID[23:16];
      expect_cpld_payload[3] = board.RP.tx_usrapp.DEV_VEN_ID[31:24];
      board.RP.com_usrapp.TSK_EXPECT_CPLD(
        3'h0, //traffic_class;
        1'b0, //td;
        1'b0, //ep;
        2'h0, //attr;
        10'h1, //length;
        16'h0000, //completer_id;
        3'h0, //completion_status;
        1'b0, //bcm;
        12'h4, //byte_count;
        16'h01a0, //requester_id;
        8'h0, //tag;
        7'b0, //address_low;
        expect_status //expect_status;
      );

      if (expect_status)
        test_vars[0] = test_vars[0] + 1;
    end
  join

    expect_finish_check = 1;

    if (test_vars[0] == 1)
      $display("[%t] : TEST PASSED --- Finished transmission of PCI-Express TLPs", $realtime);
    else
      $display("[%t] : TEST FAILED --- Haven't Received All Expected TLPs", $realtime);

      //--------------------------------------------------------------------------
      // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
      // BusMstr in the command register
      //--------------------------------------------------------------------------
      board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
      board.RP.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
      board.RP.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

    $finish;
  end
    else begin
      $display("[%t] %m: Error: Unrecognized TESTNAME: %0s", $realtime, testname);
      $finish(2);
    end
  end

endmodule

