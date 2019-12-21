//-------------------------------------------
// This class define basic callback function
// support user can altering or get the behavior of the transaction
// without modifying the transaction.
//------------------------------------------- 
typedef class cAxiUvmTransaction;
class Monitor_cb extends uvm_callback;
   //Declare transaction instance
   cAxiUvmTransaction coAxiTransaction;
   
   // Register to factory
   `uvm_object_utils(Monitor_cb)
   // Create constructor 
   function new(string name = "Monitor_cb", uvm_component parent = null );
		super.new(name,parent);
   endfunction
   // Create empty virtual task, 

   // This task contain information of addr channel after the driver send to DUT
   virtual task aw_transaction(cAxiUvmTransaction trans);
    //empty
   endtask
   // This task contain information of data channel before the driver send to DUT
   virtual task ar_transaction(cAxiUvmTransaction trans);
    //empty
   endtask
   // This task contain information of data channel after the driver send to DUT
   virtual task w_transaction(cAxiUvmTransaction trans);
     //empty     
   endtask
   // This task contain information of response channel before the driver send to DUT
   virtual task r_transaction(cAxiUvmTransaction trans);
     //empty     
   endtask
   // This task contain information of response channel after the driver send to DUT
   virtual task resp_transaction(cAxiUvmTransaction trans);
     //empty     
   endtask
endclass
