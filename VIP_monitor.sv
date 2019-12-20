//--------------------------------------
//--------------------------------------
class VipAxiUvmMonitor extends uvm_monitor;
  //Register to Factory
  `uvm_component_utils(VipAxiUvmMonitor)
  //Internal variables
  cAxiUvmTransaction coAxiUvmTransaction;
  Monitor_cb         coMonitor_cb;
  // Declare event that enable callback function
  event aw_chanel_event, ar_chanel_event, w_chanel_event, r_chanel_event, resp_chanel_event;

  // AXI version
  `ifndef AXI4_SPEC_VERSION
    logic axi3_ver = 1;
  else 
    logic axi4_ver = 1;
  //Declare analysis ports
  uvm_analysis_port #(cAxiUvmTransaction) ap_AxiAddrAWChannel; 
  uvm_analysis_port #(cAxiUvmTransaction) ap_AxiAddrARChannel; 
  uvm_analysis_port #(cAxiUvmTransaction) ap_AxiDataWChannel;
  uvm_analysis_port #(cAxiUvmTransaction) ap_AxiDataRChannel;
  uvm_analysis_port #(cAxiUvmTransaction) ap_AxiRspChannel;
  //Declare the monitored interfaces
  virtual interface ifAxiMaster vifAxiMaster;
	//Constructor
	function new (string name = "VipAxiMonitor", uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
        //Check the AXI connection
		if(!uvm_config_db#(virtual interface ifAxiMaster)::get(this,"","vifAxiMaster",vifAxiMaster)) begin
			`uvm_error("VipAxiMonitor","Can NOT get vifAxiMaster!!!")
		end
		
        //Create objects and analysis ports
		ap_AxiAddrAWChannel = new("ap_AxiAddrAWChannel", this);	
		ap_AxiAddrARChannel = new("ap_AxiAddrARChannel", this);	
	    ap_AxiDataWChannel = new("ap_AxiDataWChannel", this);
		ap_AxiDataRChannel = new("ap_AxiDataRChannel", this);
	    ap_AxiRspChannel = new("ap_AxiRspChannel", this);
        coAxiUvmTransaction = cAxiUvmTransaction::type_id::create("coAxiUvmTransaction",this);
	    coMonitor_cb = Monitor_cb::type_id::create("coMonitor_cb", this);
	endfunction
  //
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork
		    begin
			   while(1) begin
		            collect;
                    //User can collect write address information after address channel hanshake
		            wait(aw_channel_event.trigger);
		            coMonitor_cb.aw_transaction(coAxiUvmTransaction);
		            //User can collect read address information after address channel hanshake
		            wait(ar_channel_event.trigger);
		            coMonitor_cb.ar_transaction(coAxiUvmTransaction);
					//User can collect write data information after data channel hanshake
		            wait(w_channel_event.trigger);
		            coMonitor_cb.w_transaction(coAxiUvmTransaction);
		            //User can collect read data information after data channel hanshake
		            wait(r_channel_event.trigger);
		            coMonitor_cb.r_transaction(coAxiUvmTransaction);
					//User can collect resp data information after resp channel hanshake
		            wait(resp_channel_event.trigger);
		            coMonitor_cb.resp_transaction(coAxiUvmTransaction);
					
				end
			end
			// exit loop when reach timeout
			begin
                wait($time = timeout);
				`uvm_warning("TIME_OUT", $sformatf("exit get information", $time)
			end
	    join_any
		disable fork;
  endtask: run_phase	
	//On each clock, detect a valid transaction
  // -> get the valid transaction
  // -> send the transaction to analysis port
  virtual task collect()
		fork
			// do parallel five channels
			aw_chanel();
			aw_chanel();
			w_channel();
			r_channel();
			resp_channel();
		join_any
	endtask: collect

	
	task aw_channel();
		@(posedge vifAxiMaster.aclk) begin
	         //Get information from Axi address channel on Axi interface
            if(vifAxiMaster.AWVALID && vifAxiMaster.AWREADY) begin
									
	            coAxiUvmTransaction.AWVALID <=  vifAxiMaster.AWVALID;
	            coAxiUvmTransaction.AWREADY <=  vifAxiMaster.AWREADY;
                   coAxiUvmTransaction.AWADDR[ADDR_WIDTH -1:0] <=  vifAxiMaster.AWVALID[ADDR_WIDTH -1:0];
	            coAxiUvmTransaction.AWID[ID_WIDTH-1:0] <=  vifAxiMaster.AWID[ID_WIDTH-1:0];
	            coAxiUvmTransaction.AWBURST[1:0] <=  vifAxiMaster.AWBURST[1:0];
	            coAxiUvmTransaction.AWLEN[BURST_LENGTH_WIDTH-1:0] <=  vifAxiMaster.AWLEN[BURST_LENGTH_WIDTH-1:0];
	            coAxiUvmTransaction.AWSIZE[2:0] <=  vifAxiMaster.AWSIZE[2:0];
	            //Send the transaction to analysis port
                   ap_AxiAddrAWChannel.write(coAxiUvmTransaction);
				// Trigger event when detect aw_chanel
				-> aw_channel_event;
            end
		end
	endtask : aw_channel
	
	task ar_channel();
		@(posedge vifAxiMaster.aclk) begin
			if (vifAxiMaster.ARVALID && vifAxiMaster.ARREADY) begin
				
				coAxiUvmTransaction.ARVALID =  vifAxiMaster.ARVALID;
				coAxiUvmTransaction.ARREADY =  vifAxiMaster.ARREADY;
				coAxiUvmTransaction.ARADDR[ADDR_WIDTH -1:0] =  vifAxiMaster.ARVALID[ADDR_WIDTH -1:0];
				coAxiUvmTransaction.ARID[ID_WIDTH-1:0] =  vifAxiMaster.ARID[ID_WIDTH-1:0];
				coAxiUvmTransaction.ARBURST[1:0] =  vifAxiMaster.ARBURST[1:0];
				coAxiUvmTransaction.ARLEN[BURST_LENGTH_WIDTH-1:0] =  vifAxiMaster.ARLEN[BURST_LENGTH_WIDTH-1:0];
				coAxiUvmTransaction.ARSIZE[2:0] =  vifAxiMaster.ARSIZE[2:0];
				//Send the transaction to analysis port
				ap_AxiAddrARChannel.write(coAxiUvmTransaction);
				//Trigger event when detect ar_chanel
				-> aw_channel_event;
			end
		end
	endtask: ar_channel
  
	task w_channel();
		@(posedge vifAxiMaster.aclk) begin
	      //Get information from Axi data channel on Axi interface
			if(vifAxiMaster.WVALID && vifAxiMaster.WREADY) begin
	  
				coAxiUvmTransaction.WVALID <=  vifAxiMaster.WVALID;
				coAxiUvmTransaction.WREADY <=  vifAxiMaster.WREADY;
				if (axi3_ver) begin
					coAxiUvmTransaction.WID[ID_WIDTH-1:0] <=  vifAxiMaster.WID[ID_WIDTH-1:0];
				end
				coAxiUvmTransaction.WDATA[DATA_WIDTH-1:0] <=  vifAxiMaster.WDATA[DATA_WIDTH-1:0];
				coAxiUvmTransaction.WSTRB[DATA_WIDTH/8-1:0] <=  vifAxiMaster.WSTRB[DATA_WIDTH/8-1:0];
				coAxiUvmTransaction.WLAST <=  vifAxiMaster.WLAST;
				if (axi4_ver) begin
					coAxiUvmTransaction.WUSER[USER_WIDTH-1:0] <=  vifAxiMaster.WUSER[USER_WIDTH-1:0];
				end
				//Send the transaction to analysis port 
				ap_AxiDataWChannel.write(coAxiUvmTransaction);
				//Trigger even when detect w_channel
				-> w_channel_event;
			end
		end
	endtask:w_channel
	
	task r_channel();
		@(posedge vifAxiMaster.aclk) begin
			if (vifAxiMaster.RVALID && vifAxiMaster.RREADY) begin
				
				coAxiUvmTransaction.RVALID =  vifAxiMaster.RVALID;
				coAxiUvmTransaction.RREADY =  vifAxiMaster.RREADY;
				coAxiUvmTransaction.RID[ID_WIDTH-1:0] =  vifAxiMaster.RID[ID_WIDTH-1:0];
				coAxiUvmTransaction.RDATA[DATA_WIDTH-1:0] =  vifAxiMaster.RDATA[DATA_WIDTH-1:0];
				coAxiUvmTransaction.RRESP[1:0] =  vifAxiMaster.RRESP[1:0];
				coAxiUvmTransaction.RLAST =  vifAxiMaster.RLAST;
				if (axi4_ver) begin
					coAxiUvmTransaction.RUSER[USER_WIDTH-1:0] <=  vifAxiMaster.RUSER[USER_WIDTH-1:0];
				end
				//Send the transaction to analysis port
				ap_AxiDataRChannel.write(coAxiUvmTransaction);
				//Trigger even when detect w_channel
				-> r_channel_event;
			end
		end
	endtask:r_channel
	
	task resp_channel();
		@(posedge vifAxiMaster.aclk) begin
			//Get information from Axi resp channel on Axi interface
			if(vifAxiMaster.BVALID && vifAxiMaster.BREADY) begin
				
				coAxiUvmTransaction.BVALID <=  vifAxiMaster.BVALID;
				coAxiUvmTransaction.BREADY <=  vifAxiMaster.BREADY;
				coAxiUvmTransaction.BID[ID_WIDTH-1:0] <=  vifAxiMaster.BID[ID_WIDTH-1:0];
				coAxiUvmTransaction.BRESP[1:0] <=  vifAxiMaster.BRESP[1:0];
				if (axi4_ver) begin
					coAxiUvmTransaction.BUSER[USER_WIDTH-1:0] <=  vifAxiMaster.BUSER[USER_WIDTH-1:0];
				end
				//Send the transaction to analysis port
				ap_AxiRspChannel.write(coAxiUvmTransaction);
				//Trigger when detect response chennel
				-> resp_channel_event;
			end
		end
	endtask:resp_channel

endclass
