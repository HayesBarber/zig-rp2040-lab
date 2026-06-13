# 03 - `picotool`

It is kinda annoying to have to hold down the `BOOTSEL` button and disconnect/connect power everytime I want to flash. I think `picotool` can handle this.

## Exercise 6: No bootsel

Yes, `picotool` can do this. For example to reboot the device into bootsel mode:

```bash
picotool reboot -uf
```

The `-f` is to force the reboot (since the device is likely not in bootsel mode already). And the `-u` asks the device to reboot into bootsel mode (as compared to application mode if this flag was ommmitted).

It seems to be the case that whatever program currently flashed needs to have been built with USB support (e.g. `pico_enable_stdio_usb(hello-world 1)`)

`picotool` can also load programs, which may serve to consolidate commands even more. If the device has USB support and is currently running in application mode, this command will reboot into bootsel, load the program, and then reboot back into application mode:

```bash
picotool load -f blinky.uf2
```

If the device is _already in bootsel mode_, then `load` will only load into flash. The `-x` flag can be used to execute:

```bash
picotool load -x blinky.uf2
```

