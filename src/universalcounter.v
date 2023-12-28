module dut_circuit (
    input module_sel,activator,clkin,sel_mode,mode_updown,
    input [3:0] step,target,init,
    output wire done,start1,start2,stop1,stop2,active1,active2,
    output wire [3:0] counter_val
);
    controlpath c1(module_sel,eq,carry1,carry2,clkin,activator,poweron1,poweron2,ldi,lds,ldt,mulen,compen,adden,stop1,stop2,rst,done);
    datapath d1(clkin,rst,poweron1,poweron2,sel_mode,stop1,stop2,ldt,ldi,lds,module_sel,mulen,mode_updown,compen,adden,step,target,init,carry1,carry2,eq,start1,start2,counter_val);
    assign active1=(module_sel==0)?(start1&(~stop1)&poweron1):0;
    assign active2=(module_sel==1)?(start2&(~stop2)&poweron2):0;
endmodule
module mode_demuxer (
    input module_sel,clkin,
    output wire clk0,clk1
);
    assign clk0=(module_sel==0)?clkin:0;
    assign clk1=(module_sel==1)?clkin:0;
endmodule
module datapath (
    input clkin,rst,poweron1,poweron2,sel_mode,stop1,stop2,ldt,ldi,lds,module_sel,mulen,mode_updown,compen,adden,
    input [3:0] step,target,init,
    output wire carry1,carry2,eq,start1,start2,
    output wire [3:0] counter_val
);
    wire [3:0] count_val1,count_val2,init_val,target_val,step_val,mul_val;
    mode_demuxer md11(module_sel,clkin,clk0,clk1);
    dut_async dut11(clk1,rst,poweron2,sel_mode,stop2,count_val2,start2);
    dut_sync dut12(clk0,rst,poweron1,sel_mode,stop1,count_val1,start1);
    store_reg ini11(ldi,clkin,rst,init,init_val);
    store_reg tar11(ldt,clkin,rst,target,target_val);
    store_reg step11(lds,clkin,rst,step,step_val);
    multiplier m11(mulen,clkin,rst,module_sel,count_val1,count_val2,step_val,mul_val,carry1);
    adder a11(adden,rst,clkin,mul_val,init_val,mode_updown,counter_val,carry2);
    comparator c11(clkin,rst,compen,counter_val,target_val,eq);
endmodule
module controlpath (
    input module_sel,eq,carry1,carry2,clkin,activator,
    output reg poweron1,poweron2,ldi,lds,ldt,mulen,compen,adden,stop1,stop2,rst,done
);
    reg [3:0]state;
    parameter s0=4'b0000,s1=4'b0001,s2=4'b0010,s3=4'b0011,s4=4'b0100,s5=4'b0101,s6=4'b0110,s7=4'b0111,s8=4'b1000 ;
    always @(posedge clkin) begin
        if(activator==1)
        begin
            state=s0;
        end
    end
    // begin poweron=0;ldi=0;lds=0;ldt=0;mulen=0;compen=0;stop=0;rst=0;done=0; end
    always @(posedge clkin) begin
        case (state)
            s0:begin if(activator==1)begin state=s0;end if(module_sel==1) state<=s1;else if(module_sel==0) state<=s6;else state<=s0; end
            s1:begin if(activator==1)begin  state=s0;end else state<=s2; end
            s2:begin if(activator==1)begin  state=s0;end else state<=s3;end
            s3:begin if(activator==1)begin  state=s0;end else if (module_sel==0) begin state<=s8;end else if (module_sel==1) begin state<=s4;end else state<=s3; end
            s4:begin if(activator==1)begin state=s0;end if((carry1==1)|(carry2==1)) state<=s7;else state<=s4;if((eq==1)) state<=s5;else state<=s4; end
            s5:begin if(activator==1)begin state=s0;end else state<=s5;  end
            // to showthat the stateMachine is concluded
            s6:begin if(activator==1)begin state=s0;end else state<=s2;  end
            s7:begin if(activator==1)begin state=s0;end else state<=s7; end
            s8:begin if(activator==1)begin state=s0;end if((carry1==1)|(carry2==1)) state<=s7;else state<=s8;if((eq==1)) state<=s5;else state<=s8; end
            default: state<=s0;
        endcase
    end
    always @(state,posedge clkin) begin
        case (state)
            s0: begin poweron1=0;poweron2=0;ldi=0;lds=0;ldt=0;mulen=0;compen=0;adden=0;stop1=0;stop2=0;rst=0;done=0; end
            s1: begin poweron1=0;poweron2=0;ldi=0;lds=0;ldt=0;mulen=0;compen=0;adden=0;stop1=0;stop2=0;rst=1;done=0; end
            s6: begin poweron1=0;poweron2=0;ldi=0;lds=0;ldt=0;mulen=0;compen=0;adden=0;stop1=0;stop2=0;rst=1;done=0; end
            s2: begin poweron1=0;poweron2=0;ldi=1;lds=1;ldt=1;mulen=0;compen=0;adden=0;stop1=0;stop2=0;rst=0;done=0; end
            s3: begin if (module_sel==0) begin
                poweron1=1;poweron2=0;ldi=0;lds=0;ldt=0;mulen=1;compen=1;adden=1;rst=0;done=0;
            end
            else if (module_sel==1) begin
                poweron1=0;poweron2=1;ldi=0;lds=0;ldt=0;mulen=1;compen=1;adden=1;rst=0;done=0;
            end 
            end
            s4: begin poweron1=0;poweron2=1;ldi=0;lds=0;ldt=0;rst=0;done=0;end 
            s5: begin if(module_sel==0)begin poweron1=1;poweron2=0; end else if(module_sel==0)begin poweron1=0;poweron2=1; end done=1; end
            s7: begin if(module_sel==0)begin poweron1=1;poweron2=0; end else if(module_sel==0)begin poweron1=0;poweron2=1; end ldi=0;lds=0;ldt=0;mulen=0;compen=0;adden=0;rst=0;done=0; end
            s8: begin poweron1=1;poweron2=0;ldi=0;lds=0;ldt=0;rst=0;done=0;end
            
            default:begin poweron1=0;poweron2=0;ldi=0;lds=0;ldt=0;mulen=0;compen=0;adden=0;stop1=0;stop2=0;rst=0;done=0;end
        endcase
    end
    // asynchronous interrupt
    always @(eq) begin
        if (eq==1) begin
            mulen=0;compen=0;adden=0;
            if (module_sel==0) begin
                stop1=1;
            end
            else if (module_sel==1) begin
                stop2=1;
            end
        end
        else
        begin
            mulen=1;compen=1;adden=1;stop1=0;stop2=0;
        end
    end
endmodule
module dut_sync (
    input clkin,rst,poweron1,sel_mode,stop,
    output wire [3:0] count_val,output wire start
);
    clock_mux cl1(clkin,sel_mode,stop,poweron1,clk);
    bit4synccounter a1(clk,clr,set,count_val);
    pulse_control c1(poweron1,clk,stop,rst,set,clr,start);
endmodule
module dut_async (
    input clkin,rst,poweron2,sel_mode,stop,
    output wire [3:0] count_val,
    output wire start
);
    clock_mux cl1(clkin,sel_mode,stop,poweron2,clk);
    bit4asynccounter a1(clk,clr,set,count_val);
    pulse_control c1(poweron2,clk,stop,rst,set,clr,start);
endmodule
module pulse_control (
    input poweron,clkin,rst,stop,
    output reg set,clr,start
);
    reg [2:0] nxt_state,prev_state;
    parameter s0 = 2'b00,s1=2'b01,s2=2'b10,s3=2'b11;
    always @(rst) begin
        if (rst==1) begin
            prev_state<=s0;
        
        end
    end
    always @(posedge clkin) begin
        case (prev_state)
            s0:begin if(poweron==1) prev_state<=s1; else prev_state<=s0; start =0;end
            s1:begin if(poweron==1) prev_state<=s2; else  prev_state<=s1;start =0;  @(negedge clkin); begin start =1;end end
            s2:begin if(poweron==1) prev_state<=s3; else prev_state<=s2; end
            s3:begin prev_state<=s3; end 
            default: prev_state<=s0;
        endcase
    end
    always @(prev_state) begin
        case (prev_state)
            s0:begin set=1;clr=0; end
            s1:begin set=1;clr=0; end
            s2:begin set=1;clr=0; end
            s3:begin set=1;clr=1; end 
            default: begin set=1;clr=1; end 
        endcase
    end
endmodule

module bit4asynccounter (
    input clk,clr,set,
    output wire[3:0] count_val
);  
    wire highline;
    wire q0,q1,q2,q3;
    wire q0bar,q1bar,q2bar,q3bar;
    assign highline=1;
    jkflipflop ff1(highline,highline,clk,clr,set,q0,q0bar);
    jkflipflop ff2(highline,highline,q0,clr,set,q1,q1bar);
    jkflipflop ff3(highline,highline,q1,clr,set,q2,q2bar);
    jkflipflop ff4(highline,highline,q2,clr,set,q3,q3bar);
    assign count_val={q3,q2,q1,q0};
endmodule

module bit4synccounter (
    input clk,clr,set,
    output wire[3:0] count_val
);
    wire highline;
    wire q0,q1,q2,q3,jkin3,jkin4;
    wire q0bar,q1bar,q2bar,q3bar;
    assign highline=1;
    jkflipflop ff1(highline,highline,clk,clr,set,q0,q0bar);
    jkflipflop ff2(q0,q0,clk,clr,set,q1,q1bar);
    and g1(jkin3,q0,q1);
    jkflipflop ff3(jkin3,jkin3,clk,clr,set,q2,q2bar);
    and g2(jkin4,jkin3,q2);
    jkflipflop ff4(jkin4,jkin4,clk,clr,set,q3,q3bar);
    assign count_val={q3,q2,q1,q0};
endmodule

module jkflipflop (
    input j,k,clk,clr,set,
    output reg q,
    output wire qbar
);
    parameter memory_mode = 2'b00,reset_mode=2'b01,set_mode=2'b10,toggle_mode=2'b11;
    always @(negedge clk) begin
        if (clr==1 & set==1) begin
            case ({j,k})
                memory_mode:begin q<=q; end
                reset_mode: begin q<=1'b0; end
                set_mode:begin q<=1'b1; end
                toggle_mode:begin q<=~q; end
                default:q<=q;
            endcase
        end
        else begin q<=q; end
    end
    assign qbar=~q;
    always @(clr,set) begin
        if (clr==0) begin
            q<=0;
        end
        if (set==1) begin
            q<=0;
        end
    end
endmodule
module clock_mux (
    input clkin,sel_mode,stop,poweron,
    output reg clkout
);
    // sel_ mode 0-> negedge 1->posedge
    always @(*) begin
       if (stop==1) begin
        clkout<=0;
    end
    else if (stop==0) begin
        if (poweron==1) begin
            if (sel_mode==0) 
            begin
                clkout<=clkin;
            end
            else if (sel_mode==1) 
            begin
                clkout<=~clkin;
            end
            else 
            begin
                clkout<=0;
            end 
        end
        else if (poweron==0) begin
            clkout<=0;
        end
    end
    else begin
        clkout<=0;
    end 
    end
endmodule
module multiplier (
    input mulen,clkin,rst,module_sel,
    input [3:0] count_val1,count_val2,
    input [3:0] step_val,
    output reg [3:0] mul_val,
    output reg carry1
);
    always @(count_val1,count_val2,clkin) begin
        if (rst==1) begin
            carry1<=0;
            mul_val<=0;
        end
        else if (rst==0) begin
        if (mulen==1) begin
            if (module_sel==0) begin
               {carry1,mul_val}<=count_val1*step_val; 
            end
            else if (module_sel==1) begin
                {carry1,mul_val}<=count_val2*step_val;
            end
        end
        else begin
            mul_val<=mul_val;
            carry1<=carry1;
        end 
        end
    end
endmodule
module comparator (
    input clkin,rst,compen,
    input [3:0] counter_val,target_val,
    output reg eq
);
    always @(clkin) begin
        if (rst==1) begin
            eq<=0;
        end
        else if (rst==0) begin
            if (compen==1) begin
               if (counter_val==target_val) begin
                eq<=1;
            end 
            end
        end
    end
endmodule
module adder (
    input adden,rst,clkin,
    input [3:0] mul_val,init_val,
    input mode_updown,
    output reg [3:0] counter_val,
    output reg carry2
);
    always @(mul_val,clkin) begin
        if (rst==1) begin
            carry2<=0;
            counter_val<=0;
        end
        else if (rst==0) begin
           if (adden==1) begin
            // up
            if (mode_updown==0) begin
                {carry2,counter_val}<=init_val+mul_val;
            end
            else if (mode_updown==1) begin
                {carry2,counter_val}<=init_val-mul_val;
            end    
        end
        end
    end
endmodule
module store_reg (
    input enable,clkin,rst,
    input [3:0] din,
    output reg [3:0] dout
);
    always @(posedge clkin) begin
        if (rst==1) begin
            dout<=0;
        end
        else if (rst==0) begin
           if (enable==1) begin
            dout<=din;
        end
        else begin
            dout<=dout;
        end 
        end
    end
endmodule

