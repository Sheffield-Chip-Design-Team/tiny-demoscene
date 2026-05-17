/*
 * Based on demos by Renaldas Zioma, Tom Verbeure and Uri Shaked.
 *
 * Multi-logo DVD-style bouncing:
 *  - ui_in[0] = checkerboard parallax background
 *  - ui_in[1] = diamond ripple effect
 *  - ui_in[2] = colour cycling on logo bounces
 *  - ui_in[5:0] used as checker base colour when ui_in[0] is high
*/

`default_nettype none
`define COLOR_WHITE 3'd7

module tt_um_vga_sharc_demo (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  localparam LOGO_SIZE      = 128;
  localparam DISPLAY_WIDTH  = 640;
  localparam DISPLAY_HEIGHT = 480;
  localparam NUM_LOGOS      = 3;
  localparam MAX_X          = DISPLAY_WIDTH  - LOGO_SIZE;  // 512
  localparam MAX_Y          = DISPLAY_HEIGHT - LOGO_SIZE;  // 352

  wire hsync, vsync;
  reg  [1:0] R, G, B;
  wire video_active;
  wire [9:0] pix_x, pix_y;

  wire cfg_checker = ui_in[0];
  wire cfg_ripple  = ui_in[1];
  wire cfg_color   = ui_in[2];

  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in[7:3], uio_in};

  hvsync_generator vga_sync_gen (
      .clk(clk), .reset(~rst_n),
      .hsync(hsync), .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x), .vpos(pix_y)
  );

  // -------------------------------------------------------
  // Frame counter + vsync edge detector
  // -------------------------------------------------------
  reg [9:0] frame_cnt;
  reg vsync_r;
  wire frame_tick = vsync && !vsync_r;

  always @(posedge clk) begin
    if (~rst_n) begin
      vsync_r   <= 0;
      frame_cnt <= 0;
    end else begin
      vsync_r <= vsync;
      if (frame_tick) frame_cnt <= frame_cnt + 10'd1;
    end
  end

  // -------------------------------------------------------
  // 16-bit Galois LFSR  (taps 16,15,13,4 — maximal length)
  // -------------------------------------------------------
  reg [15:0] lfsr;

  always @(posedge clk) begin
    if (~rst_n)
      lfsr <= 16'hACE1;
    else if (frame_tick)
      lfsr <= {1'b0, lfsr[15:1]} ^ (lfsr[0] ? 16'hB400 : 16'h0000);
  end

  function automatic [2:0] rand_speed;
    input [1:0] b;
    case (b)
      2'b00: rand_speed = 3'd1;
      2'b01: rand_speed = 3'd2;
      2'b10: rand_speed = 3'd3;
      2'b11: rand_speed = 3'd4;
    endcase
  endfunction

  // -------------------------------------------------------
  // Sine LUT — 64 entries, amplitude ±7, 5-bit two's-complement
  // Index wraps mod 64. Used for ripple warp and tint.
  // -------------------------------------------------------
  reg signed [4:0] sin_lut [0:63];

  initial begin
    sin_lut[ 0] = 5'sd0;  sin_lut[ 1] = 5'sd1;  sin_lut[ 2] = 5'sd1;  sin_lut[ 3] = 5'sd2;
    sin_lut[ 4] = 5'sd3;  sin_lut[ 5] = 5'sd3;  sin_lut[ 6] = 5'sd4;  sin_lut[ 7] = 5'sd4;
    sin_lut[ 8] = 5'sd5;  sin_lut[ 9] = 5'sd5;  sin_lut[10] = 5'sd6;  sin_lut[11] = 5'sd6;
    sin_lut[12] = 5'sd6;  sin_lut[13] = 5'sd7;  sin_lut[14] = 5'sd7;  sin_lut[15] = 5'sd7;
    sin_lut[16] = 5'sd7;  sin_lut[17] = 5'sd7;  sin_lut[18] = 5'sd7;  sin_lut[19] = 5'sd7;
    sin_lut[20] = 5'sd6;  sin_lut[21] = 5'sd6;  sin_lut[22] = 5'sd6;  sin_lut[23] = 5'sd5;
    sin_lut[24] = 5'sd5;  sin_lut[25] = 5'sd4;  sin_lut[26] = 5'sd4;  sin_lut[27] = 5'sd3;
    sin_lut[28] = 5'sd3;  sin_lut[29] = 5'sd2;  sin_lut[30] = 5'sd1;  sin_lut[31] = 5'sd1;
    sin_lut[32] = 5'sd0;  sin_lut[33] = -5'sd1; sin_lut[34] = -5'sd1; sin_lut[35] = -5'sd2;
    sin_lut[36] = -5'sd3; sin_lut[37] = -5'sd3; sin_lut[38] = -5'sd4; sin_lut[39] = -5'sd4;
    sin_lut[40] = -5'sd5; sin_lut[41] = -5'sd5; sin_lut[42] = -5'sd6; sin_lut[43] = -5'sd6;
    sin_lut[44] = -5'sd6; sin_lut[45] = -5'sd7; sin_lut[46] = -5'sd7; sin_lut[47] = -5'sd7;
    sin_lut[48] = -5'sd7; sin_lut[49] = -5'sd7; sin_lut[50] = -5'sd7; sin_lut[51] = -5'sd7;
    sin_lut[52] = -5'sd6; sin_lut[53] = -5'sd6; sin_lut[54] = -5'sd6; sin_lut[55] = -5'sd5;
    sin_lut[56] = -5'sd5; sin_lut[57] = -5'sd4; sin_lut[58] = -5'sd4; sin_lut[59] = -5'sd3;
    sin_lut[60] = -5'sd3; sin_lut[61] = -5'sd2; sin_lut[62] = -5'sd1; sin_lut[63] = -5'sd1;
  end

  // -------------------------------------------------------
  // Ripple: Manhattan distance from centre → wave phase
  //
  // dist = (|pix_x - 320| + |pix_y - 240|) >> 3
  //   → range 0..70, wraps mod 64 into the LUT
  // phase = (dist[5:0] + frame_cnt[5:0]) & 6'h3F
  //   → rings propagate outward each frame
  //
  // sin_val = sin_lut[phase]
  //   • Used as a signed X-warp on the checker layers (±7 px)
  //   • Sign bit used as a 1-bit tint toggle for concentric rings
  // -------------------------------------------------------
  wire [9:0] abs_dx = (pix_x >= 10'd320) ? (pix_x - 10'd320) : (10'd320 - pix_x);
  wire [9:0] abs_dy = (pix_y >= 10'd240) ? (pix_y - 10'd240) : (10'd240 - pix_y);
  wire [9:0] manhattan = abs_dx + abs_dy;

  wire [5:0] ripple_phase = (manhattan[8:3] + frame_cnt[5:0]) & 6'h3F;

  wire signed [4:0] sin_val = sin_lut[ripple_phase];

  // Ripple X warp: add sin_val to pix_x when sampling checker
  wire [9:0] warp_x = cfg_ripple
      ? (pix_x + {{5{sin_val[4]}}, sin_val})   // sign-extend 5-bit → 10-bit add
      : pix_x;

  // Ripple tint bit: sign of sin_val creates concentric bright/dark rings
  wire ripple_tint = cfg_ripple & sin_val[4];   // 1 when sin is negative (dark ring)

  // -------------------------------------------------------
  // Checkerboard parallax background
  // Checker layers use warp_x so the whole background undulates.
  // -------------------------------------------------------
  wire [9:0] layer_a_x = warp_x + frame_cnt * 10'd16;
  wire [9:0] layer_a_y = pix_y  + frame_cnt * 10'd2;

  wire [9:0] layer_b_x = warp_x + frame_cnt * 10'd7;
  wire [9:0] layer_b_y = pix_y  + frame_cnt + (frame_cnt >> 1);

  wire [9:0] layer_c_x = warp_x + frame_cnt * 10'd4;
  wire [9:0] layer_c_y = pix_y  + (frame_cnt >> 1);

  wire [9:0] layer_d_x = warp_x + frame_cnt * 10'd2;
  wire [9:0] layer_d_y = pix_y  + (frame_cnt >> 2);

  wire [9:0] layer_e_x = warp_x + (frame_cnt >> 1);
  wire [9:0] layer_e_y = pix_y  + (frame_cnt / 10'd6);

  wire layer_a = (layer_a_x[8] ^ layer_a_y[8]) &  ( pix_y[1] ^ pix_x[0]);
  wire layer_b = (layer_b_x[7] ^ layer_b_y[7]) &  (~pix_y[0] ^ pix_x[1]);
  wire layer_c =  layer_c_x[6] ^ layer_c_y[6];
  wire layer_d =  layer_d_x[5] ^ layer_d_y[5];
  wire layer_e = (layer_e_x[4] ^ layer_e_y[4]) &  ( pix_y[1] ^ pix_x[0]);

  // Base checker colours (same derivation as Renaldas Zioma's design)
  wire [5:0] bg_ca  = ~ui_in[5:0];
  wire [5:0] bg_cb  = bg_ca  ^ 6'b00_10_10;
  wire [5:0] bg_cc  = bg_cb  & 6'b10_10_10;
  wire [5:0] bg_cde = bg_cc >> 1;

  wire [5:0] checker_raw =
      layer_a ? bg_ca  :
      layer_b ? bg_cb  :
      layer_c ? bg_cc  :
      layer_d ? bg_cde :
      layer_e ? bg_cde :
                6'b00_00_00;

  // Apply ripple tint: darken every other wave ring by masking out LSBs
  wire [5:0] checker_rgb = ripple_tint ? (checker_raw & 6'b10_10_10) : checker_raw;

  // -------------------------------------------------------
  // Logo state
  // -------------------------------------------------------
  reg [9:0] logo_left [0:NUM_LOGOS-1];
  reg [9:0] logo_top  [0:NUM_LOGOS-1];
  reg       dir_x     [0:NUM_LOGOS-1];
  reg       dir_y     [0:NUM_LOGOS-1];
  reg [2:0] spd       [0:NUM_LOGOS-1];
  reg [2:0] color_idx [0:NUM_LOGOS-1];

  // -------------------------------------------------------
  // ROM + palette
  // -------------------------------------------------------
  wire [5:0] color_out [0:NUM_LOGOS-1];
  wire       pixel_val [0:NUM_LOGOS-1];
  wire [9:0] lx        [0:NUM_LOGOS-1];
  wire [9:0] ly        [0:NUM_LOGOS-1];

  genvar gi;
  generate
    for (gi = 0; gi < NUM_LOGOS; gi = gi + 1) begin : logo_inst
      assign lx[gi] = pix_x - logo_left[gi];
      assign ly[gi] = pix_y - logo_top[gi];

      bitmap_rom rom_i (
          .x(lx[gi][6:0]),
          .y(ly[gi][6:0]),
          .pixel(pixel_val[gi])
      );

      palette palette_i (
          .color_index(cfg_color ? color_idx[gi] : `COLOR_WHITE),
          .rrggbb(color_out[gi])
      );
    end
  endgenerate

  // -------------------------------------------------------
  // Pixel compositing — logos on top, ripple-tinted checker below
  // -------------------------------------------------------
  integer pi;
  reg       logo_hit;
  reg [5:0] logo_rgb;

  always @(posedge clk) begin
    if (~rst_n) begin
      R <= 0; G <= 0; B <= 0;
    end else begin
      logo_hit = 0;
      logo_rgb = 6'd0;

      if (video_active) begin
        for (pi = 0; pi < NUM_LOGOS; pi = pi + 1) begin
          if ((lx[pi][9:7] == 3'b000 && ly[pi][9:7] == 3'b000) && pixel_val[pi]) begin
            logo_hit = 1;
            logo_rgb = color_out[pi];
          end
        end

        if (logo_hit) begin
          R <= logo_rgb[5:4];
          G <= logo_rgb[3:2];
          B <= logo_rgb[1:0];
        end else if (cfg_checker) begin
          R <= checker_rgb[5:4];
          G <= checker_rgb[3:2];
          B <= checker_rgb[1:0];

        end else begin
          R <= 0; G <= 0; B <= 0;
        end
      end else begin
        R <= 0; G <= 0; B <= 0;
      end
    end
  end

  // -------------------------------------------------------
  // Physics — one update per frame
  // -------------------------------------------------------
  reg [9:0] nx  [0:NUM_LOGOS-1];
  reg [9:0] ny  [0:NUM_LOGOS-1];
  reg       ndx [0:NUM_LOGOS-1];
  reg       ndy [0:NUM_LOGOS-1];
  reg [2:0] nsp [0:NUM_LOGOS-1];
  reg [2:0] nci [0:NUM_LOGOS-1];

  integer i, j;

  always @(posedge clk) begin
    if (~rst_n) begin
      logo_left[0] <= 10'd20;  logo_top[0] <= 10'd20;  dir_x[0] <= 1; dir_y[0] <= 1; spd[0] <= 3'd1; color_idx[0] <= 3'd0;
      logo_left[1] <= 10'd380; logo_top[1] <= 10'd224; dir_x[1] <= 0; dir_y[1] <= 0; spd[1] <= 3'd2; color_idx[1] <= 3'd2;
      logo_left[2] <= 10'd200; logo_top[2] <= 10'd300; dir_x[2] <= 1; dir_y[2] <= 0; spd[2] <= 3'd3; color_idx[2] <= 3'd4;

    end else if (frame_tick) begin

      for (i = 0; i < NUM_LOGOS; i = i + 1) begin
        nx[i]  = logo_left[i];
        ny[i]  = logo_top[i];
        ndx[i] = dir_x[i];
        ndy[i] = dir_y[i];
        nsp[i] = spd[i];
        nci[i] = color_idx[i];
      end

      for (i = 0; i < NUM_LOGOS; i = i + 1) begin
        nx[i] = ndx[i] ? nx[i] + {7'd0, nsp[i]} : nx[i] - {7'd0, nsp[i]};
        ny[i] = ndy[i] ? ny[i] + {7'd0, nsp[i]} : ny[i] - {7'd0, nsp[i]};
      end

      for (i = 0; i < NUM_LOGOS; i = i + 1) begin
        if (!ndx[i] && nx[i] > 10'd511) begin
          nx[i]  = 10'd0;
          ndx[i] = 1;
          nsp[i] = rand_speed(lfsr[2*i +: 2]);
          nci[i] = nci[i] + 3'd1;
        end else if (ndx[i] && nx[i] >= MAX_X[9:0]) begin
          nx[i]  = MAX_X[9:0];
          ndx[i] = 0;
          nsp[i] = rand_speed(lfsr[2*i +: 2]);
          nci[i] = nci[i] + 3'd1;
        end

        if (!ndy[i] && ny[i] > 10'd479) begin
          ny[i]  = 10'd0;
          ndy[i] = 1;
          nsp[i] = rand_speed(lfsr[2*i+8 +: 2]);
          nci[i] = nci[i] + 3'd1;
        end else if (ndy[i] && ny[i] >= MAX_Y[9:0]) begin
          ny[i]  = MAX_Y[9:0];
          ndy[i] = 0;
          nsp[i] = rand_speed(lfsr[2*i+8 +: 2]);
          nci[i] = nci[i] + 3'd1;
        end
      end

      for (i = 0; i < NUM_LOGOS; i = i + 1) begin
        for (j = i + 1; j < NUM_LOGOS; j = j + 1) begin
          if ((nx[i] < nx[j] + LOGO_SIZE[9:0]) &&
              (nx[j] < nx[i] + LOGO_SIZE[9:0]) &&
              (ny[i] < ny[j] + LOGO_SIZE[9:0]) &&
              (ny[j] < ny[i] + LOGO_SIZE[9:0]))
          begin
            begin
              reg tmp_dx, tmp_dy;
              reg [2:0] tmp_sp;
              tmp_dx  = ndx[i]; ndx[i] = ndx[j]; ndx[j] = tmp_dx;
              tmp_dy  = ndy[i]; ndy[i] = ndy[j]; ndy[j] = tmp_dy;
              tmp_sp  = nsp[i]; nsp[i] = nsp[j]; nsp[j] = tmp_sp;
            end
            nci[i] = nci[i] + 3'd1;
            nci[j] = nci[j] + 3'd1;
          end
        end
      end

      for (i = 0; i < NUM_LOGOS; i = i + 1) begin
        logo_left[i]  <= nx[i];
        logo_top[i]   <= ny[i];
        dir_x[i]      <= ndx[i];
        dir_y[i]      <= ndy[i];
        spd[i]        <= nsp[i];
        color_idx[i]  <= nci[i];
      end

    end
  end

endmodule