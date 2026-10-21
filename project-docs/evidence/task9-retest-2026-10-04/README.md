# Task 9 re-test files (4 October 2026)

Pods used for the Task 9 re-test requested by the industry supervisor.
Run on the DSYS601-fresh-test VM.

| File | Tests | Expected alert |
|---|---|---|
| memory-near-limit-test.yaml | Container held near its memory limit | DSYS601ContainerMemoryNearLimit |
| memory-oom-test.yaml | Container asks for 200M with a 128Mi limit (killed: OOMKilled) | Restart / crash alerts |
| notready-test.yaml | Readiness probe on a path that does not exist | DSYS601PodNotReady |

These are kept as evidence of the re-test. The maintained lab versions
(with images pinned by digest) are in the `tests/` folder at the repo root.
