
#define PTE uint64_t
#define PPN uint32_t

unsigned char PTE_get_D(PTE pte);

/* 记得在注释写上标志位的作用！ */
void PTE_set_D(PTE pte, unsigned char value);

//void set_X()
//.....
//


PPN PTE_get_ppn(PTE e);

void PTE_set_ppn(PTE pte, PPN value);
