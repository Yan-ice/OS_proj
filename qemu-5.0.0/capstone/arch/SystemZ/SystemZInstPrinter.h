/* Capstone Disassembly Engine */
/* By Nguyen Anh Quynh <aquynh@gmail.com>, 2013-2014 */

#ifndef CS_SYSZINSTPRINTER_H
#define CS_SYSZINSTPRINTER_H

#include "../../MCInst.h"
#include "../../MCRegisterInfo.h"
#include "../../SStream.h"

void SystemZ_printInst(MCInst *MI, SStream *O, void *Info);

void SystemZ_post_printer(csh ud, cs_insn *insn, char *insn_asm, MCInst *mci);

#endif
