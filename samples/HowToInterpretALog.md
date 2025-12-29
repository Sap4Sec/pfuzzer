# How to interpret analysis results
This document describes how to interpret PFuzzer's output. For this running example we take sample `f3cf71782257f1edae634541b12889c40f328609671889c9b12047d412a94d2d` from the dataset year `2018`.

For a detailed description of the log structure and per-line labels, refer to [InTraceLabels](legend/InTraceLabels.md). This document uses the terminology listed in it.

The sample-specific `notes.txt` for this sample is available [here](2018/f3cf71782257f1edae634541b12889c40f328609671889c9b12047d412a94d2d). It highlights findings for the first (non-mutated) execution versus later fuzzing stages, and includes extra context (e.g., family name) plus manually annotated observations.

## Phase 1
In Phase 1 (especially the first run), the main elements to inspect are:
* Environmental-information APIs collected for fuzzing in later runs:
    ```
	[*] To fuzz: GetModuleFileNameA 11611 402D5B RegOpenKeyExA 14950 403A66 RegQueryValueExA 14987 403A8B GetUserNameA 15071 403ADF GetModuleFileNameA 15277 403BAD
    ```
	Note: `TimeDelayAPIs` and `TimeQueryAPIs` are label names used to group timing-delay APIs (e.g., `Sleep`) and timing-query APIs (e.g., `GetTickCount`). They are kept under unified names because the applied mutation is consistent across all instances of the same category.
* IoC-related API calls observed during execution:
    ```
	IoC APIs: LoadLibraryA @ 402D47
	IoC APIs: RegOpenKeyExA @ 403A66
    ```

For this sample, PFuzzer identified 5 environmental information-accessing APIs being called (and to fuzz later), and observed 2 IoC-related APIs being called. At this stage, the IoC set does not appear sufficient to characterize the sample’s behavior, indicating that additional analysis is needed. Phase 2 typically reveals previously hidden behaviors.

## Phase 2
In Phase 2 runs, the most useful signals to inspect are:
* New IoCs (if any), which indicate behavior observed only under mutation (i.e., PFuzzer unlocked an execution path not previously taken).
* The mutations applied to reach and unveil that additional activity.
* Shorter executions (relative to the initial run), which can indicate early-exit behavior triggered by environmental checks or a broken dependency caused by a mutation.

In this sample, the second execution reveals new activity:
```
	IoC APIs: LoadLibraryA @ 402D47
	IoC APIs: RegOpenKeyExA @ 403A66
	IoC APIs: CreateFileA @ 402319
	IoC APIs: LoadLibraryA @ 40216C
	IoC APIs: CreateFileA @ 4023FC
	IoC APIs: MoveFileA @ 402535
	IoC APIs: CreateFileA @ 4025C6
	IoC APIs: CopyFileA @ 402C2E
	IoC APIs: RegCreateKeyExA @ 40296D
	IoC APIs: RegSetValueExA @ 402A44
	IoC APIs: CreateFileA @ 40117D
	IoC APIs: CreateFileA @ 40103F
	IoC APIs: WriteFile @ 4010DF
	IoC APIs: CreateFileA @ 401C07
	IoC APIs: CreateFileA @ 401C64
	IoC APIs: SetFileTime @ 401C7E
	IoC APIs: MoveFileExA @ 402CBC
	IoC APIs: CreateProcessA @ 40152F
	IoC APIs: MoveFileExA @ 40134F
	IoC APIs: MoveFileExA @ 40137F
```

The associated mutations for this run are:
```
 |  GetModuleFileNameA - 11611 - 402D5B - 0 - 0
 |  RegOpenKeyExA - 14950 - 403A66 - 3 - 0
 |  RegQueryValueExA - 14987 - 403A8B - 0 - 0
 |  GetUserNameA - 15071 - 403ADF - 1 - 26
 |  GetModuleFileNameA - 15277 - 403BAD - 1 - 3
```

Here, PFuzzer forced `RegOpenKeyExA` to fail. By checking the Phase 1 logs, the key being opened was `HARDWARE\DESCRIPTION\System`, followed by `RegQueryValueExA` (presumably querying `SystemBiosVersion`). This is a common environment check used to detect virtualization (e.g., searching for `VBOX`).

This interpretation is consistent with the subsequent execution (iteration number 3): RegOpenKeyExA is left untouched (no forced failure), and the sample returns to the early-exit behavior already observed in Phase 1.

In later executions, this same check can often be bypassed either by:
* Retargeting the opened key to something that does not expose `SystemBiosVersion`, or
* Mutating the value query operation (`RegQueryValueExA`) directly.

The end of each execution (except for runs that PFuzzer aborts, for example upon a crash or when the timeout is reached) contains a recap of the run in a consistent, well-formatted block, which is usually the fastest way to compare executions at a glance.

Note: in the next update to the repository, we will make available scripts to automate extraction of the key elements and document their usage here.
