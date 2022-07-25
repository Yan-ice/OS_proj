QEMU_ROOT := qemu-5.0.0
OS := xv6-riscv

export QEMU = $(shell pwd)/$(QEMU_ROOT)/riscv64-softmmu/qemu-system-riscv64

all: xv6

qemu:
	cd $(OS) && \
	make qemu
qemu-gdb:
	cd $(OS) && \
	make qemu-gdb
qemu-build:
	cd $(QEMU_ROOT) \
	&& rm -rf *-linux-user *-softmmu \
	&& ./configure --target-list=riscv64-softmmu,riscv64-linux-user \
       	&& make -j$(nproc)

xv6:
	cd $(OS) && make
