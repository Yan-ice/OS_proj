/** @file
  Master header file for SecCore.

  Copyright (c) 2014, Intel Corporation. All rights reserved.<BR>
  SPDX-License-Identifier: BSD-2-Clause-Patent

**/

#ifndef _SEC_CORE_H_
#define _SEC_CORE_H_


#include <PiPei.h>

#include <Ppi/TopOfTemporaryRam.h>

#include <Library/BaseLib.h>
#include <Library/DebugLib.h>
#include <Library/PcdLib.h>
#include <Library/BaseMemoryLib.h>
#include <Library/FspPlatformSecLib.h>
#include <Library/FspPlatformInfoLib.h>
#include <Library/UefiCpuLib.h>
#include <Library/PeCoffGetEntryPointLib.h>
#include <Library/PeCoffExtraActionLib.h>
#include <Library/DebugAgentLib.h>

#include <FspApi.h>
#include <FspInfoHeader.h>

#define SEC_IDT_ENTRY_COUNT  34

typedef struct _SEC_IDT_TABLE {
  //
  // Reserved 8 bytes preceding IDT to store EFI_PEI_SERVICES**, since IDT base
  // address should be 8-byte alignment.
  // Note: For IA32, only the 4 bytes immediately preceding IDT is used to store
  // EFI_PEI_SERVICES**
  //
  UINT64            PeiService;
  UINT64            IdtTable[SEC_IDT_ENTRY_COUNT];
} SEC_IDT_TABLE;

/**
  Entry point to the C language phase of SEC. After the SEC assembly
  code has initialized some temporary memory and set up the stack,
  the control is transferred to this function.

  @param[in] SizeOfRam           Size of the temporary memory available for use.
  @param[in] TempRamBase         Base address of temporary ram
  @param[in] BootFirmwareVolume  Base address of the Boot Firmware Volume.
**/
VOID
EFIAPI
SecStartup (
  IN UINT32                   SizeOfRam,
  IN UINT32                   TempRamBase,
  IN VOID                     *BootFirmwareVolume
  );

/**
  Find and return Pei Core entry point.

  It also find SEC and PEI Core file debug information. It will report them if
  remote debug is enabled.

  @param[in]  BootFirmwareVolumePtr  Point to the boot firmware volume.
  @param[out] PeiCoreEntryPoint      Point to the PEI core entry point.

**/
VOID
EFIAPI
FindAndReportEntryPoints (
  IN  EFI_FIRMWARE_VOLUME_HEADER       *BootFirmwareVolumePtr,
  OUT EFI_PEI_CORE_ENTRY_POINT         *PeiCoreEntryPoint
  );

/**
  Autogenerated function that calls the library constructors for all of the module's
  dependent libraries.  This function must be called by the SEC Core once a stack has
  been established.

**/
VOID
EFIAPI
ProcessLibraryConstructorList (
  VOID
  );

#endif