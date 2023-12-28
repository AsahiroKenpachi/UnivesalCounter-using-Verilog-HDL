// The following test bench is used to show the working of the Universal Counter

// ************************************************************PIN MEANING***************************************************************//
// Activator:Master Reset
// Module_sel[0 for Synchronus and 1 for asynchronous]
// Sel_mode[0 for negedge triggerring]
// Mode_updown[0 for up count 1 for down count];
// Step[To Describe the value to be increments]
// Init[To Describe the value from which it mustt be counted]
// Target[To Describe the final value]
// **************************************************************************************************************************************
// *******************************************************LIMITATION*********************************************************************
// Lowest Possible Value:4'b0000
// Highest Possible Value:4'b1111
// The input parameter condition: (Target - Init)%step == 0
// The Counter ceases To count when Overflow or Underflow occurs
// It can be further modified To work as a Frequency Counter , PWM Generator based upon user requirement and it is confiurable at the top most abstraction for Datapath and Control Path
// *****************************************************************************************************************************************

`include "unviresal_counter.v"
module tb ();
    reg module_sel,activator,clkin,sel_mode,mode_updown;
    reg [3:0] step,target,init;
    wire done,start1,start2,stop1,stop2,active1,active2;
    wire [3:0] counter_val;
    dut_circuit meow(module_sel,activator,clkin,sel_mode,mode_updown,step,target,init,
    done,start1,start2,stop1,stop2,active1,active2,counter_val);
    // Frequency of clkin is 1+1=2sec
    // When You try to change modes(posedege/ negedge) The active signal will show momentary blink to represent the change in state
    initial begin
        clkin=0;
        #1;
        forever begin
            clkin=~clkin;
            #1;
        end
    end
    initial begin
        activator=1;
        #2;
        activator=0;
        #2;
        module_sel=1;sel_mode=0;mode_updown=0;step=2;init=4'b1111;target=4'b1001;
        #100;
        activator=1;
        #2;
        activator=0;
        #2;
        module_sel=0;sel_mode=0;mode_updown=1;step=2;init=4'b1001;target=4'b1111;
        #100;
        $finish();
    end
    initial begin
        $dumpfile("signal.vcd");
        $dumpvars(0,tb);
    end
endmodule
