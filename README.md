# zig-rp2040-lab

The goal of this repo is to build a preemptive scheduler in Zig for a Raspberry Pi Pico

Zig version: 0.16.0

This is for learning purposes

### Datasheets

- [RP2040](https://pip-assets.raspberrypi.com/categories/814-rp2040/documents/RP-008371-DS-1-rp2040-datasheet.pdf)
- [Pico W](https://pip-assets.raspberrypi.com/categories/686-raspberry-pi-pico-w/documents/RP-008312-DS-1-pico-w-datasheet.pdf)

### Roadmap

- [x] Boot Sequence
- [x] SDK interop
- [x] Picotool
- [x] Timer interrupts
- [x] Exception entry and register stacking
- [x] PendSV interrupt
- [x] Multicore
- [x] Spinlocks
- [x] Linker scripts
- [x] crt0
- [x] zrt0
- [x] System clocks
- [x] Serial communication
- [x] Task registration API
- [ ] Scheduler algorithm(s)
  - [x] Super loop
  - [x] Round robin
  - [ ] ...
- [x] Context switch
- [ ] Task blocking
- [ ] Telemetry
- [ ] Synthetic workload / profiling
- [x] Heap allocator
- [ ] Multicore scheduling
  - [ ] Mutual exclusion

