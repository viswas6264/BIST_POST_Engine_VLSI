`timescale 1ns/1ps

module post_bist_tb;
    reg clk = 0;
    reg reset = 1;
    reg [3:0] a_vec = 4'b0000;
    reg [3:0] b_vec = 4'b0000;
    reg cin_vec = 0;
    
    wire [3:0] sum;
    wire cout;
    wire [3:0] rand_num;
    wire [7:0] syndrome;
    reg [7:0] golden_syndrome;
    reg [7:0] faulty_syndrome;

    adder uut_adder (.a(a_vec), .b(b_vec), .cin(cin_vec), .sum(sum), .cout(cout));
    lfsr uut_lfsr (.clk(clk), .reset(reset), .rand_num(rand_num));
    signature_analyzer uut_sig (.clk(clk), .reset(reset), .response({cout, sum}), .syndrome(syndrome));

    always #5 clk = ~clk;

    initial begin
        // --- Added for EPWave waveform dumping ---
        $dumpfile("dump.vcd");
        $dumpvars;
        // ----------------------------------------

        // ----------------------------------------------------
        // PHASE 1: GOLDEN RUN (Fault-Free Reference)
        // ----------------------------------------------------
        $display("==================================================");
        $display("PHASE 1: RUNNING GOLDEN REFERENCE (FAULT-FREE CUT)");
        $display("==================================================");
        
        reset = 1;
        #10 reset = 0;

        repeat (15) begin
            @(posedge clk);
            #1;
            a_vec   = rand_num;
            b_vec   = rand_num ^ 4'b1010;
            cin_vec = rand_num[0];
            $display("CYCLE [GOOD] | a=%b b=%b cin=%b | sum=%b cout=%b | syn=%h", 
                     a_vec, b_vec, cin_vec, sum, cout, syndrome);
        end

        @(posedge clk);
        #1;
        golden_syndrome = syndrome;
        $display(">>> Golden Syndrome Captured: 0x%02X\n", golden_syndrome);

        // ----------------------------------------------------
        // PHASE 2: FAULT INJECTION (Stuck-At-0 on internal carry net c2)
        // ----------------------------------------------------
        $display("==================================================");
        $display("PHASE 2: INJECTING STUCK-AT-0 FAULT ON NET 'c2'");
        $display("==================================================");
        
        force uut_adder.c2 = 1'b0;

        reset = 1;
        #10 reset = 0;

        repeat (15) begin
            @(posedge clk);
            #1;
            a_vec   = rand_num;
            b_vec   = rand_num ^ 4'b1010;
            cin_vec = rand_num[0];
            $display("CYCLE [FAULT] | a=%b b=%b cin=%b | sum=%b cout=%b | syn=%h", 
                     a_vec, b_vec, cin_vec, sum, cout, syndrome);
        end

        @(posedge clk);
        #1;
        faulty_syndrome = syndrome;
        release uut_adder.c2;

        $display(">>> Faulty Syndrome Captured: 0x%02X\n", faulty_syndrome);

        // ----------------------------------------------------
        // PHASE 3: AUTOMATIC BIST VERDICT
        // ----------------------------------------------------
        $display("==================================================");
        $display("PHASE 3: POST-BIST VERDICT");
        $display("==================================================");
        $display("Golden Signature : 0x%02X", golden_syndrome);
        $display("Faulty Signature : 0x%02X", faulty_syndrome);
        
        if (golden_syndrome !== faulty_syndrome) begin
            $display("DIAGNOSTIC VERDICT: [PASS] - Fault Successfully Detected!");
            $display("Syndrome mismatch confirms 100%% observability of net 'c2'.");
        end else begin
            $display("DIAGNOSTIC VERDICT: [FAIL] - Fault Masked / Undetected.");
        end
        $display("==================================================");

        $finish;
    end
endmodule
