/* SPDX-License-Identifier: GPL-3.0-only */
/*
 * abi_gate.c - Compile-time determinism gate for the WZD shared ABI.
 *
 * Pins the golden layout constants of contract version 0.1.0. This unit
 * must compile clean, with zero warnings, on every supported target:
 *
 *   gcc -std=c11 -m64 -Wall -Wextra -Werror
 *   gcc -std=c11 -m32 -Wall -Wextra -Werror   (needs gcc-multilib)
 *   cl   /std:c11 /W4 /WX   (x64 and x86)
 *
 * A layout drift stops being a runtime pairing failure in a consumer and
 * becomes a compile error here, on every target, in every PR.
 */

#include "WzdAbiVersion.h"
#include "WzdIoctl.h"
#include "WzdTelemetry.h"

/*
 * Golden constants for contract 0.1.0 (docs/ABI-CONTRACT.md section 8).
 * They change only with a deliberate, reviewed layout change that bumps
 * WzdAbiVersion.h and re-blesses tests/abi_gate/ABI_FINGERPRINT.txt in
 * the same PR.
 */

/* Process lifecycle record: 3172 bytes, fixed layout. */
_Static_assert(sizeof(WZD_PROCESS_EVENT) == 3172,
    "WZD_PROCESS_EVENT layout drifted from the 0.1.0 contract");

/* Shared ring buffer: 1024 slots, 3252416 bytes total. */
_Static_assert(sizeof(WZD_RING_BUFFER) == 3252416,
    "WZD_RING_BUFFER layout drifted from the 0.1.0 contract");

/* IOCTL codes are never recycled and never collide (contract section 4). */
_Static_assert(IOCTL_WZD_TEST_CONNECTION != IOCTL_WZD_MAP_MEMORY,
    "IOCTL codes must stay distinct");

int main(void)
{
    /* Nothing to run: the assertions above are the test. */
    return 0;
}
