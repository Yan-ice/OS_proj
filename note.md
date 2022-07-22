状态控制寄存器组(csr)，存放satp

Path: /target/riscv/cpu.h

```c
struct CPURISCVState {
    target_ulong gpr[32];
    uint64_t fpr[32]; /* assume both F and D extensions */
    target_ulong pc;
    target_ulong load_res;
    target_ulong load_val;

    target_ulong frm;

    target_ulong badaddr;
    target_ulong guest_phys_fault_addr;

    target_ulong priv_ver;
    target_ulong misa;
    target_ulong misa_mask;

    uint32_t features;

#ifdef CONFIG_USER_ONLY
    uint32_t elf_flags;
#endif




static void enable_paging(void) {
    write_csr(satp, (0x8000000000000000) | (boot_satp >> RISCV_PGSHIFT));
}


// physical address of boot-time page directory
uintptr_t boot_satp;
    
#define RISCV_PGSHIFT 12
```



一级页表首地址(在OS里)：

在kern/mm/pmm.c

```
boot_page_table_sv39:
    # 0xffffffff_c0000000 map to 0x80000000 (1G)
    # 前 511 个页表项均设置为 0 ，因此 V=0 ，意味着是空的(unmapped)
    .zero 8 * 511
    # 设置最后一个页表项，PPN=0x80000，标志位 VRWXAD 均为 1
    .quad (0x80000 << 10) | 0xcf # VRWXAD
```

```
boot_pgdir = (pte_t*)boot_page_table_sv39;
boot_satp = PADDR(boot_pgdir);
```

boot_satp为常驻页表首地址的虚拟地址