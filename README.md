# OSHChip_Blinky_Demo
Basic demo and Makefile for gcc, gdb development with the OSHChip

# Building
```
NRF_SDK_PATH=/path/to/sdk make
```

# Flashing
Make sure you have [pyOCD] installed before running.

```
make flash
```

# Debugging
Using `screen` if helpful for this step.
```
screen
[CTRL-a c] # create new buffer
make startdebug
[CTRL-a n] # switch to next buffer
make gdb
```

[pyOCD]: https://github.com/mbedmicro/pyOCD
