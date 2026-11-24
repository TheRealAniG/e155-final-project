module tb_spi_pose;
    timeunit 1ns; timeprecision 1ps;
    logic clk = 0, reset_n = 0, sck = 0, mosi = 0, cs_n = 1;
    logic valid, error, vblank = 0, active;
    logic signed [10:0] x, y, car_x, car_y;
    logic signed [9:0] c, s, car_c, car_s;
    int accepted = 0, rejected = 0;
    always #20.833 clk = ~clk; // 24 MHz FPGA, asynchronous SPI stimulus.
    spi_pose_receiver dut (.clk(clk), .reset_n(reset_n), .spi_sck(sck),
        .spi_mosi(mosi), .spi_cs_n(cs_n), .pose_valid(valid), .packet_error(error),
        .pose_x(x), .pose_y(y), .pose_cos(c), .pose_sin(s));
    frame_pose frame_dut (.clk(clk), .reset_n(reset_n), .vblank_tick(vblank),
        .pose_valid(valid), .pose_x(x), .pose_y(y), .pose_cos(c), .pose_sin(s),
        .demo_x(11'sd96), .demo_y(11'sd96), .demo_cos(10'sd256), .demo_sin(10'sd0),
        .spi_active(active), .car_x(car_x), .car_y(car_y), .car_cos(car_c), .car_sin(car_s));
    always @(negedge clk) begin
        if (valid) accepted++;
        if (error) rejected++;
    end
    // Construct exactly as Ani's C sender, including big-endian int16 fields.
    function automatic logic [79:0] packet(input int px, py, pc, ps);
        logic [79:0] result;
        logic [7:0] sum;
        result = {8'ha5, 16'(px), 16'(py), 16'(pc), 16'(ps), 8'h00};
        sum = 0;
        for (int b = 1; b < 10; b++) sum ^= result[b*8 +: 8];
        result[7:0] = sum;
        return result;
    endfunction
    task automatic transfer(input logic [79:0] data, input int bits = 80,
                            input realtime half_period = 200.0);
        #73; cs_n = 0; #250;
        for (int b = 0; b < bits; b++) begin
            mosi = b < 80 ? data[79-b] : 1'b1;
            #(half_period); sck = 1;
            #(half_period); sck = 0;
            if (b % 8 == 7) #79; // MCU software gaps between bytes.
        end
        #50; cs_n = 1; #350;
    endtask
    task automatic check_pose(input int px, py, pc, ps);
        if (int'(x) != px || int'(y) != py || int'(c) != pc || int'(s) != ps)
            $fatal(1, "Decoded pose got %0d,%0d,%0d,%0d", x, y, c, s);
    endtask
    task automatic commit_frame;
        @(negedge clk); vblank = 1;
        @(negedge clk); vblank = 0;
    endtask
    task automatic bad_transfer(input logic [79:0] data, input int bits = 80);
        int old_count;
        logic [41:0] old_pose;
        old_count = accepted;
        old_pose = {x,y,c,s};
        transfer(data, bits);
        if (accepted != old_count || {x,y,c,s} !== old_pose)
            $fatal(1, "Invalid transaction published a pose");
    endtask
    initial begin
        logic [79:0] bad_header;
        #111; reset_n = 1; #350;
        // SCK activity while deselected must not create packets.
        repeat (90) begin #200; sck = ~sck; end
        sck = 0; #350;
        if (accepted != 0 || active) $fatal(1, "Idle traffic changed state");

        transfer(packet(320, 240, 256, 0));
        if (accepted != 1) $fatal(1, "Valid 2.5 MHz packet not accepted");
        check_pose(320,240,256,0);
        if (active || car_x != 96) $fatal(1, "Pose changed before blanking");
        commit_frame();
        if (!active || car_x != 320 || car_y != 240 || car_c != 256 || car_s != 0)
            $fatal(1, "First frame commit failed");

        bad_transfer(packet(100,120,0,-256) ^ 80'h01); // checksum mismatch
        bad_header = packet(100,120,0,-256);
        bad_header[79:72] = 8'h5a;
        bad_header[7:0] ^= 8'hff; // correct XOR, but wrong marker
        bad_transfer(bad_header);
        bad_transfer(packet(100,120,0,-256), 79);
        bad_transfer(packet(100,120,0,-256), 40);
        bad_transfer(packet(100,120,0,-256), 81);
        bad_transfer(packet(100,120,0,-256), 88);
        bad_transfer(packet(32767,120,0,-256));
        bad_transfer(packet(100,-1025,0,-256));
        bad_transfer(packet(100,120,257,0));
        bad_transfer(packet(100,120,0,-257));
        commit_frame();
        if (car_x != 320 || car_y != 240) $fatal(1, "Bad packet changed frame pose");
        if (rejected != 10) $fatal(1, "Expected ten rejected packets, got %0d", rejected);

        // Recover immediately; marker bytes inside payload are just data.
        transfer(packet(165,421,-256,0),80,170.0); // near supported 3 MHz limit
        transfer(packet(-1024,1023,0,-256),80,213.7);
        check_pose(-1024,1023,0,-256);
        if (car_x != 320) $fatal(1, "Mid-frame update");
        commit_frame();
        if (car_x != -1024 || car_y != 1023 || car_c != 0 || car_s != -256)
            $fatal(1, "Newest pending pose or signed fields failed");

        // A packet-valid pulse coincident with blanking must commit immediately.
        fork
            transfer(packet(96,96,181,181),80,1700.0);
            begin
                @(posedge valid); @(negedge clk); vblank = 1;
                @(negedge clk); vblank = 0;
            end
        join
        if (car_x != 96 || car_y != 96 || car_c != 181 || car_s != 181)
            $fatal(1, "Same-edge frame commit failed");

        // Reset aborts a partial transfer and returns to autonomous demo.
        cs_n = 0; #300;
        repeat (17) begin #200; sck = 1; #200; sck = 0; end
        reset_n = 0; #100; cs_n = 1; #100; reset_n = 1; #350;
        if (active || car_x != 96 || car_c != 256) $fatal(1, "Reset fallback failed");
        transfer(packet(544,384,0,256));
        check_pose(544,384,0,256);
        commit_frame();
        if (!active || car_x != 544 || car_s != 256) $fatal(1, "Reset recovery failed");
        $display("PASS: SPI mode 0, C packet layout, signed fields, checksum, framing, recovery and atomic frame commit");
        $finish;
    end
    initial begin #5ms; $fatal(1, "SPI test timeout"); end
endmodule
