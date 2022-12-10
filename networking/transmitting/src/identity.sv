`default_nettype none
`timescale 1ns / 1ps

module identity (
    input wire clk, // 50 MHz clock
    input wire rst, // System reset
    input wire axiiv, // Data valid input
    input wire [1:0] axiid, // Data input bus

    output logic axiov, // Output valid
    output logic [1:0] axiod // Output data bus
);
    // Device Address 69:69:5A:06:54:90
    logic [47:0] source_addr = 48'b01101001_01101001_01011010_00000110_01010100_10010000;
    // Destination Address 69:69:5A:06:54:91
    // logic [47:0] destination_addr = 48'b01101001_01101001_01011010_00000110_01010100_10010001;
    // Broadcast Address
    logic [47:0] destination_addr = 48'b11111111_11111111_11111111_11111111_11111111_11111111; 
    logic [15:0] ethertype = 16'b0000001_00000001;

    localparam IDLE = 0;
    localparam DEST = 1; // Destination
    localparam SOURCE = 2; // Source
    localparam ETHER = 3; // Length
    localparam READTRANSMIT = 4; // Data input valid and transmitting
    localparam TRANSMIT = 5; // Data input no longer valid and transmitting
    logic [2:0] state;

    logic [111:0] data_buf; // data stored while start of frame sent
    logic reading_data; // check signal to avoid errant data after going low
    int data_counter; // Need to count to 111 (112 bits)
    logic [5:0] cycle_counter; // Need to count to 56 (cycles)

    always_ff @(posedge clk) begin
        if (rst == 1'b1) begin
            axiov <= 1'b0;
            axiod <= 2'b0;
            data_counter <= 0;
            cycle_counter <= 6'b0;
            state <= IDLE;
        end
        case (state)
            IDLE: begin
                if (axiiv == 1'b1) begin
                    axiov <= 1'b1;
                    data_buf <= {110'b0, axiid};
                    reading_data <= 1'b1;
                    data_counter <= 1;

                    axiod <= destination_addr[47:46];
                    destination_addr <= {destination_addr[45:0], destination_addr[47:46]};
                    cycle_counter <= 0;

                    state <= DEST;
                end
            end
            DEST: begin
                cycle_counter <= cycle_counter + 1;
                if (cycle_counter < 23) begin // Send destination address
                    axiod <= destination_addr[47:46];
                    destination_addr <= {destination_addr[45:0], destination_addr[47:46]};
	        end else begin
                    axiod <= source_addr[47:46];
                    source_addr <= {source_addr[45:0], source_addr[47:46]};
                    cycle_counter <= 0;
                    state <= SOURCE;
		end
                if (axiiv == 1'b1 && reading_data == 1'b1) begin
                    data_buf <= {data_buf[109:0], axiid};
                    data_counter <= data_counter + 2;
                end else begin
                    reading_data <= 1'b0;
                end
            end
	    SOURCE: begin
		cycle_counter <= cycle_counter + 1;
		if (cycle_counter < 23) begin // Send source address
                    axiod <= source_addr[47:46];
                    source_addr <= {source_addr[45:0], source_addr[47:46]};
		end else begin
                    axiod <= ethertype[15:14];
                    ethertype <= {ethertype[13:0], ethertype[15:14]};
                    cycle_counter <= 0;
                    state <= ETHER;
		end
                if (axiiv == 1'b1 && reading_data == 1'b1) begin
                    data_buf <= {data_buf[109:0], axiid};
                    data_counter <= data_counter + 2;
                end else begin
                    reading_data <= 1'b0;
                end
	    end
	    ETHER: begin
		cycle_counter <= cycle_counter + 1;
		if (cycle_counter < 7) begin // Send ethertype
                    axiod <= ethertype[15:14];
                    ethertype <= {ethertype[13:0], ethertype[15:14]};
                end else begin // Send first data 
                    if (axiiv == 1'b1 && reading_data == 1'b1) begin // still reading
                        axiod <= data_buf[111:110];
                        data_buf <= {data_buf[109:0], axiid};
                        state <= READTRANSMIT;
                    end else begin // no longer reading i.e. static
                        reading_data <= 1'b0;
                        axiod <= {data_buf[data_counter], data_buf[data_counter-1]};
                        data_counter <= data_counter - 2;
                        state <= TRANSMIT;
                    end
                end
                if (cycle_counter < 7) begin 
                    if (axiiv == 1'b1 && reading_data == 1'b1) begin
                        data_buf <= {data_buf[109:0], axiid};
                        data_counter <= data_counter + 2;
                    end else begin
                        reading_data <= 1'b0;
                    end
                end
	    end
            READTRANSMIT: begin
                if (axiiv == 1'b1 && reading_data == 1'b1) begin
                    axiod <= data_buf[111:110];
                    data_buf <= {data_buf[109:0], axiid};
                end else begin
                    reading_data <= 1'b0;
                    axiod <= {data_buf[data_counter], data_buf[data_counter-1]};
                    data_counter <= data_counter - 2;
                    state <= TRANSMIT;
                end
            end
            TRANSMIT: begin
                if (data_counter > 0) begin
                    axiod <= {data_buf[data_counter], data_buf[data_counter-1]};
                    data_counter <= data_counter - 2;
                end else begin
                    axiov <= 1'b0;
                    data_counter <= 0;
                    cycle_counter <= 0;
                    state <= IDLE;
                end
            end
        endcase
    end
endmodule

`default_nettype wire
