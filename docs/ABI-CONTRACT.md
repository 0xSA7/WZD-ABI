# WZD Shared ABI Contract
Status: ACTIVE · Version: 0.1.0 · Applies to: every WZD-* component crossing the kernel/user boundary.

1. Purpose
WatchZork is split-brain by design: privileged logic lives in kernelcomponents, orchestration and decisions live in user components. The onlything binding the two halves is the shared ABI defined in this repository.This document is the normative contract for that boundary.

Canonical artifacts:

Artifact	Role
WzdIoctl.h	IOCTL codes, request/response structures
WzdTelemetry.h	Telemetry record layouts (kernel -> user)
WzdAbiVersion.h	Contract version consumed by pairing checks
Every WZD-* repo MUST consume these headers from a pinned commit of thisrepository (vendored copy or submodule). Local redefinition of sharedtypes is a contract violation even if the bytes happen to match.

2. Versioning
WZD_ABI_VERSION packs major(8) | minor(16) | patch(8).

MAJOR - breaking change: struct shrink/reorder, IOCTL code change orremoval, semantic change. Mixed-major pairing MUST be refused at runtime.
MINOR - additive only: new IOCTL codes, fields appended with sizeguards, new capability flags. Older-minor consumers keep working.
PATCH - no effective ABI change (comments, docs, build fixes).
Pre-1.0: a breaking change MAY ship as a MINOR bump, but only with aCONTRACT-CHANGE entry in section 8 and a passing abi-gate.

3. Structural rules
Fixed-width types only (UINT32, UINT64, ...). No size_t, nopointers across the boundary - offsets or opaque handles only.
Natural alignment, no #pragma pack on shared structs. Padding must beexplicit; consumers treat unknown fields as opaque Reserved bytes.
Every telemetry record starts with a header carrying Version andRecordSize. Consumers validate RecordSize before reading and skipunknown versions instead of failing.
Every shared struct gets a compile-time size assertion in this repo(landed incrementally per struct).
4. IOCTL contract
Codes are built with CTL_CODE on a WZD-owned device type. Codes arenever recycled; retired codes stay reserved.
Every IOCTL defines an exact input/output size contract. The drivervalidates InputBufferLength / OutputBufferLength before touchingbuffers and completes with STATUS_INVALID_PARAMETER on mismatch.
Buffered vs direct method per IOCTL is part of the contract and isdocumented next to the code definition.
5. Telemetry contract
Delivery is best-effort: the kernel MAY drop records under pressure andMUST expose drop counters. Gaps are not corruption; consumersresynchronize on record headers using RecordSize.
Records carry a monotonic per-source sequence number for loss detection.
6. Change process
Any PR moving the ABI surface must pass the abi-gate workflow: thegate fingerprints the preprocessed headers, and a fingerprint changewithout a WzdAbiVersion.h bump fails CI.
Intentional changes bump the version in the same PR and update section 8.
Reviewers treat any fingerprint change as a breaking-change review.
7. Runtime pairing rule
During handshake both sides exchange WZD_ABI_CURRENT_VERSION:major mismatch -> refuse to start; peer minor higher -> compatibility mode(additive features off); local minor higher -> operate normally.

8. Changelog
Version	Change	Notes
0.1.0	Initial contract: versioning, structural/IOCTL/telemetry rules	#3
