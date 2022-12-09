`default_nettype none
`timescale 1ns / 1ps

module firewall (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic axiov,
    output logic [1:0] axiod
);
     // Device Address 69:69:5A:06:54:91
    logic [47:0] device_addr = 48'b01101001_01101001_01011010_00000110_01010100_10010001;
    logic [47:0] broadcast_addr = 48'b11111111_11111111_11111111_11111111_11111111_11111111;
    logic [47:0] read_addr;
    logic [5:0] counter;

    localparam IDLE = 0;
    localparam READ = 1; // read address, determine once full
    localparam HEADERWAIT = 2; // address matches, wait to finish header
    localparam FORWARD = 3; // forwarding data
    localparam IGNORE = 4;
    logic [2:0] state;

    always_ff @(posedge clk) begin
        if (rst) begin
            read_addr <= 48'b0;
            counter <= 0;
            state <= IDLE;
        end
        case (state)
            IDLE: begin
                if (axiiv == 1'b1) begin
                    read_addr <= {46'b0, axiid};
                    counter <= 0;
                    state <= READ;
                end
            end
            READ: begin
                if (axiiv == 1'b1) begin
                    if (counter == 23) begin
                        if (read_addr == device_addr || read_addr == broadcast_addr) begin
                            counter <= counter + 1;
                            state <= HEADERWAIT;
                        end else begin
                            state <= IGNORE;
                        end
                    end else begin
                        read_addr <= {read_addr[45:0], axiid};
                        counter <= counter + 1;
                    end
                end else begin
                    counter <= 0;
                    state <= IDLE;
                end
            end
            HEADERWAIT: begin
                if (axiiv == 1'b1) begin
                    if (counter == 55) begin
                        state <= FORWARD;
                    end else begin
                        counter <= counter + 1;
                    end
                end else begin
                    counter <= 0;
                    state <= IDLE;
                end
            end
            FORWARD: begin
                if (axiiv == 1'b0) begin 
                    state <= IDLE;
                    read_addr <= 48'b0;
                    counter <= 0;
                end
            end
            IGNORE: begin
                if (axiiv == 1'b0) begin
                    state <= IDLE;
                    read_addr <= 48'b0;
                    counter <= 0;
                end
            end
        endcase
    end

    always_comb begin
        if (rst == 1'b1) begin 
            axiod = 2'b00;
            axiov = 1'b0;
        end else begin
            axiod = ((read_addr == device_addr || read_addr == broadcast_addr) && counter == 55) ? axiid : 2'b00; 
            axiov = ((read_addr == device_addr || read_addr == broadcast_addr) && counter == 55) ? axiiv : 1'b0; 
        end
    end

endmodule

`default_nettype wire