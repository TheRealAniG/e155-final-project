// Matches origin/MCU f9d239d, spiSendCarState(): SPI mode 0, MSB first.
// CS low: A5 Xhi Xlo Yhi Ylo Chi Clo Shi Slo XOR(bytes 0..8).
// All logic runs on clk; asynchronous SPI pins are synchronized before use.
// Require SCK high/low and CS setup/idle >= four clk periods (3 MHz max
// at 24 MHz clk). No timeout between bits; CS high aborts partial packets.
module spi_pose_receiver (
    input logic clk, reset_n,
    input logic spi_sck, spi_mosi, spi_cs_n,
    output logic pose_valid, packet_error,
    output logic signed [10:0] pose_x, pose_y,
    output logic signed [9:0] pose_cos, pose_sin
);
    (* ASYNC_REG = "TRUE", syn_preserve = 1 *) logic [1:0] sck_sync, cs_sync, mosi_sync;
    logic sck_last, cs_last;
    logic [79:0] packet;
    logic [6:0] bit_count;
    logic overflow;
    logic [7:0] checksum;
    wire sck_rise = sck_sync[1] && !sck_last;
    wire cs_fall = !cs_sync[1] && cs_last;
    wire cs_rise = cs_sync[1] && !cs_last;
    wire signed [15:0] x_word = packet[71:56];
    wire signed [15:0] y_word = packet[55:40];
    wire signed [15:0] cos_word = packet[39:24];
    wire signed [15:0] sin_word = packet[23:8];
    wire fields_fit = x_word >= -16'sd1024 && x_word <= 16'sd1023 &&
                      y_word >= -16'sd1024 && y_word <= 16'sd1023 &&
                      cos_word >= -16'sd256 && cos_word <= 16'sd256 &&
                      sin_word >= -16'sd256 && sin_word <= 16'sd256;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sck_sync <= 0; cs_sync <= '1; mosi_sync <= 0;
            sck_last <= 0; cs_last <= 1;
        end else begin
            sck_sync <= {sck_sync[0], spi_sck};
            cs_sync <= {cs_sync[0], spi_cs_n};
            mosi_sync <= {mosi_sync[0], spi_mosi};
            sck_last <= sck_sync[1];
            cs_last <= cs_sync[1];
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            packet <= 0; bit_count <= 0; overflow <= 0; checksum <= 0;
            pose_valid <= 0; packet_error <= 0;
            pose_x <= 96; pose_y <= 96; pose_cos <= 256; pose_sin <= 0;
        end else begin
            pose_valid <= 0;
            packet_error <= 0;
            if (cs_fall) begin
                packet <= 0; bit_count <= 0; overflow <= 0; checksum <= 0;
            end else if (cs_rise) begin
                // Commit only at transaction end: never publish an overlong,
                // partial, corrupt, or unrepresentable packet to the renderer.
                if (bit_count == 80 && !overflow && packet[79:72] == 8'ha5 &&
                    checksum == 0 && fields_fit) begin
                    pose_x <= x_word[10:0]; pose_y <= y_word[10:0];
                    pose_cos <= cos_word[9:0]; pose_sin <= sin_word[9:0];
                    pose_valid <= 1;
                end else if (bit_count != 0 || overflow) packet_error <= 1;
                bit_count <= 0;
            end else if (!cs_sync[1] && sck_rise) begin
                if (bit_count < 80) begin
                    packet <= {packet[78:0], mosi_sync[1]};
                    bit_count <= bit_count + 1'b1;
                    if (bit_count[2:0] == 7)
                        checksum <= checksum ^ {packet[6:0], mosi_sync[1]};
                end else overflow <= 1;
            end
        end
    end
endmodule
