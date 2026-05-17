![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Demoscene VGA (Tiny Tapeout)

<img width="1258" height="942" alt="image" src="https://github.com/user-attachments/assets/74638e19-93c6-46f1-9219-42639bcd0f27" />


- [Project datasheet](docs/info.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## What this project is

This design outputs a 640×480 VGA demo scene featuring three 128×128 “DVD-style” bouncing logos over a parallax checkerboard background. Optional effects include ripple warping/tinting and color cycling on bounces.

The top module is `tt_um_vga_sharc_demo` in `src/project.v`.

## Inputs and controls

- `ui_in[0]`: Enable checkerboard background
- `ui_in[1]`: Enable ripple warp + ring tint
- `ui_in[2]`: Enable color cycling on logo bounces
- `ui_in[5:0]`: Base checkerboard color when background is enabled

## Outputs

`uo_out` packs VGA sync and 2‑bit RGB channels:

`{hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}`

## How it works (high level)

- `hvsync_generator.v` provides VGA timing and pixel coordinates.
- `bitmap_rom.v` stores a 128×128 monochrome logo.
- `palette.v` maps 3‑bit color indices to 2‑bit-per‑channel RGB.
- `project.v` composites three logos over the animated background and updates motion once per frame.

## How to test

The cocotb testbench renders a few frames and optionally compares against reference images.

```zsh
cd /Users/macbook/chip_dev/sharc/sharc_ip/tiny-demoscene/test
make -B
```

The GitHub action will automatically build the ASIC files using [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## Resources

- [Tiny Tapeout documentation](https://tinytapeout.com)
- [Testing guide](https://tinytapeout.com/hdl/testing/)
