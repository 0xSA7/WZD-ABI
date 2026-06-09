/* SPDX-License-Identifier: GPL-3.0-only */
/*
 * WzdAbiVersion.h - Canonical ABI version triple for the WZD boundary.
 *
 * Packing (docs/ABI-CONTRACT.md section 2), 32 bits total:
 *
 *   bits 31..24  major, 8 bits: refuse-to-pair changes
 *   bits 23..8   minor, 16 bits: additive-only changes
 *   bits  7..0   patch, 8 bits: no effective ABI change
 *
 * Bump rules live in docs/ABI-CONTRACT.md sections 2 and 6: any change
 * to the preprocessed header surface travels with a bump of this file
 * in the same PR, plus a changelog entry in section 8.
 */

#ifndef WZD_ABI_VERSION_H
#define WZD_ABI_VERSION_H

#define WZD_ABI_VERSION_MAJOR 0
#define WZD_ABI_VERSION_MINOR 1
#define WZD_ABI_VERSION_PATCH 0

#define WZD_ABI_VERSION \
    ((WZD_ABI_VERSION_MAJOR << 24) | \
     (WZD_ABI_VERSION_MINOR << 8)  | \
     (WZD_ABI_VERSION_PATCH))

#endif /* WZD_ABI_VERSION_H */
