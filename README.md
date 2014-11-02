WS2812B
=======

This is a demo project demonstrating the control of a string of individually
addressable LEDs using an FPGA.  The target board is a cheap Cyclone 4 board
sourced on EBay but the project should be trivial to port to pretty much any
FPGA with a spare IO pin.

Checkout instructions
=====================

Since ZPUFlex is incorporated as a submodule, you'll need to check out
the current codebase like so:

> git clone https://github.com/robinsonb5/WS2812B.git

> cd WS2812

> git submodule init

> git submodule update

