# SDD ledger — plan: docs/superpowers/plans/202610201517-moon-textstat-移植-核心库-plan.md

Archived from the (gitignored) SDD workspace before it was removed, so the task→commit map,
the two user decisions, and the deferred/parked items stay traceable from the repository.
Content below is verbatim.

workspace: /f/moonbit比赛/moon_textstat/.superpowers/sdd/202610201517-moon-textstat-移植-核心库-plan
branch: sdd/moon-textstat-core (created from main@62ba1b7)
module-root: lib (T-01 decision: docs/superpowers/plans/logs/T-01-repo-state.md)
env-check: SKIP (repo declares no toolchain.versions)
batches: B0=[T-06,T-07,T-08]; B1=[T-09..T-24]; B2=[T-25..T-33]; B3=[T-34,T-35]; B4=[T-36..T-42]; B5=[T-43..T-51]; B6=[T-52,T-53,T-54]
batch-concurrency: none — every task writes inside lib/**, so same-batch pairs share paths and are run serially (parallel-execution rule: unresolved overlap degrades to serial)
Task 1: complete (docs/superpowers/plans/logs/T-01-repo-state.md)
Task 2: complete (docs/superpowers/plans/logs/T-02.log)
Task 3: complete (docs/superpowers/plans/logs/baseline.md)
Task 4: complete (docs/superpowers/plans/logs/T-04.log)
Task 5: complete (commit 061bc9d; docs/superpowers/plans/logs/T-05.log)
Task 6: fix round 1/5 (critical en_GB trim gap + 3 important addressed; commit 8c752ad)
Task 6: complete (commits 62ba1b7..8c752ad, review clean; primary 48,202 + supplement 21,782)
Task 7: minor (deferred): l3 EXT test spot-checks only 4/31 tokens; no list-order/uniqueness assertions; cells_for_group("all") returns empty; all_cells shares nested EList arrays
Task 7: complete (commits 8c752ad..7e402d3, review approved; 366 cells, groups 88/40/64/96/66/12)
Task 8: minor (deferred): log §9 cleanliness wording; trimmed transcript; 11 vs 10 command cap
Task 8: complete (commit 5d3ad2b, review approved; regeneration byte-identical 6/6)
B0: complete (T-06..T-08; native check/build/test green; data identity green)
Task 9: complete (commit 209cd7c, review approved; 19 fields + defaults)
Task 10: fix round 1/5 (UTF-16 length → code points; C0 whitespace; commit b126bb9)
Task 10: complete (commits 209cd7c..b126bb9, re-review pass; 31/31 tests)
Task 11: minor (deferred): BMP word-char approximation wording; boundary tests for over/under-count
Task 11: complete (commit a6a425b, review pass; 35/35 tests)
Task 12: fix round 1/5 (tokenizer made package-private; alternation comment; edge tests; commit 7f26880)
Task 12: complete (commits a6a425b..7f26880, re-review pass; 42/42 tests)
Task 13: minor (deferred): test comment says "ten" hyphenated compounds, actually eight
Task 13: complete (commit 3bfe7b6, review pass; 45/45)
Task 14: minor (deferred): dead `discarded` counter; imprecise end-of-text doc; two edge probes only in log
Task 14: complete (commit 4f208a8, review pass; 47/47)
Task 15: fix round 1/5 (silent [] -> raise; parse abort; de/hu quirk vectors; log numbers; commit 215410b)
Task 15: complete (commits 4f208a8..215410b, re-review pass; 62/62)
Task 16: complete (commit cbb5e30, review pass; 68/68)
Task 17: minor (deferred): stale doc reference to hyphenate_positions
Task 17: complete (commit 0688cde, review pass; 71/71)
Task 18: complete (commit b4775cb, review pass; 74/74)
Task 19: complete (commit 34d5b65; 77/77)
Task 20: fix round 1/5 (drop test-only helper; temp suppression documented; root asserts; commit 1f39017)
Task 20: complete (commits 34d5b65..1f39017, re-review pass; 84/84)
Task 21: minor (deferred): easy_words doc inconsistency; internal threshold default is root (intentional); E-28 fixture text omits `read`
Task 21: complete (commit 29df18e, review pass; 92/92)
Task 22: minor (deferred): unique first-occurrence order not directly asserted; non-unique oracle sequences only by length
Task 22: complete (commit dd0e129, review pass; 96/96)
Task 23: complete (commit 53ccd2b, review pass; 99/99)
Task 24: DEVIATION — implementer dispatch hit the daily usage limit twice; controller implemented + self-checked (log §5)
Task 24: complete (commits 53ccd2b..3019707; 101/101; review subagent deferred)
B1: complete (T-09..T-24)
Task 25: minor (deferred): two doc comments about EN/pt; test literal self-count; no uppercase-root test
Task 25: complete (commit b624021, review pass; 105/105)
Task 26: complete (commit cb47bf6, review pass; 108/108; association order pinned)
Task 27: minor (deferred): test comment 3→2 syllables; "1-2 ulp" should be up to 3; log floor(-3.01) typo
Task 27: complete (commit 37be102, review pass; 111/111)
Task 28: minor (deferred): report wording on pl/hu cells; easy-only ar case unasserted; 1-ulp prose
Task 28: complete (commit 5f70446, review pass; 115/115; E-28 37.127272727272725 9 4)
Task 29: complete (commit da544c7, review pass; 119/119; deviation: @math.pow + core/math import)
Task 30: complete (commit c891a9e, review pass; 124/124; plan line 914 contradicted by oracle, recorded)
Task 31: minor (deferred): helper-level wbtest coverage gap; report/log task-count mismatch
Task 31: complete (commit 48e0f41, review pass; 127/127)
Task 32: minor (deferred): zero-branch wording; committed empty-token/i_text>100 test absent (temp probe only)
Task 32: complete (commit ea82dd4, review pass; 131/131)
Task 33: minor (deferred): two doc numbers wrong (dedup values; "every language")
Task 33: complete (commit c3c5948, review pass; 135/135)
B2: complete (T-25..T-33)
Task 34: complete (commit 9a34347, review pass; 140/140)
Task 35: complete (commit e95e1c1, review pass; 145/145; MetricFailure text with metric+lang+reason)
B3: complete (T-34..T-35)
DECISION (2026-10-22, user): allow ONE native exit shim in cmd/gate; A-8.3 becomes whitelist (exactly 1 extern, in lib/cmd/gate/exit.mbt) — docs/superpowers/plans/logs/T-36-exit-shim-decision.md
Task 36: fix round 1/5 (line-2 report, set semantics, hardening; commit 5c93b75)
Task 36: complete (commits e95e1c1..5c93b75, re-review pass; 366/366 all groups)
DECISION 2 (2026-10-22, user): gate-only file-write FFI for failure records + @env.now; A-8.3 hits must be inside lib/cmd/gate
Task 37: complete (commit cc0ffd0; report PASS, 155/155; seven-field records + IEEE bit patterns; A-5.3 injected:true deferred to T-38 and closed there)
Task 38: fix round 1/5 (stdout reduced to the two contract lines; commit 4dd943a)
Task 38: complete (commits fbfd440..4dd943a; 155/155; inject=1 -> cells=366 passed=365 EXIT=1; inject=0 -> passed=366 EXIT=0)
Task 39: complete (commit a7e1711, docs-only; 365-cell truncation -> EXIT=2 proven on a scratch copy; 155/155)
Task 40: implementation present but uncommitted at a7e1711 (bench.mbt untracked + main.mbt/moon.pkg/samples.mbt modified); controller verified bench runs=100 median_ms=9.553 stable=true warmup_ms=8.877 EXIT=0; dispatching implementer to verify + commit
Task 40: fix round 1/5 (reviewer: no automated test for bench logic + unguarded 19-field coverage Important; guard counted evaluations not comparisons; format_ms Int32 overflow — all fixed in commit 969b78b)
Task 40: complete (commits a7e1711..969b78b; bench runs=100 median_ms=8.497 stable=true warmup_ms=8.933 EXIT=0; 162 tests in this task's scope; --group=selfcheck 366/366 EXIT=0)
Task 40: minor (deferred): --bench + --group=all/--inject=0 rejected EXIT=2 is stricter than AD §6; bench exit code 1 for a perf-budget miss and the bench report-line format are not registered in AD §3.2/§6; core/bench pulls core/test+debug+json into the gate binary; bench word-list comparison is order-sensitive while compare.mbt uses set semantics
Task 47: complete (commit 866d9f2, docs-only; A-8.3 whitelist audit: extern=5 + @env.=2, all inside lib/cmd/gate, 0 forbidden surface)
Task 51: fix round 1/5 (three rows reclassified from 不迁移 to gate-side indirect with file:line evidence; commit 1eb0cd4)
Task 51: complete (commit 1eb0cd4, docs-only; 57 rows, split 14/26/3/1/7/1/5, gate 30 / not-migrated 27, 19/19 [ALIGN] on the gate side)
Task 41: complete (commit eb5dc55; --group=data cells=30 passed=30 floor=366 EXIT=0; negative case EXIT=1 with 1 seven-field record; 170/170 tests; extern=5 @env.=2)
Task 47: fix round 1/5 (enumeration pasted 76 of 79; corrected to the reproducible 78-tracked-at-866d9f2 + 1 untracked listing, R11 command count 5->7, §2.1 dated; commit a78b92c)
Task 47: complete (commits 866d9f2..a78b92c, docs-only; A-8.3 whitelist: extern=5 + @env.=2 all inside lib/cmd/gate, forbidden surface 0)
Task 51: complete (commit 1eb0cd4, review approved; 57 rows, split 14/26/3/1/7/1/5, gate 30 / not-migrated 27, 19/19 [ALIGN] on the gate side)
B4: complete (T-36..T-42)
Task 41: fix round 1/5 (reviewer Approved with 2 Important + 8 Minor: literal-vs-payload hash disclosure, duplicated 7-field schema, tautological tests, unexercised data-path floor, record/floor order, duplicated blocks, hand-rolled sort, comma-list lang, untimed data init, AD §6 cells-vs-floor exception — all fixed or registered; commit 9b25a08)
Task 41: complete (commits eb5dc55..9b25a08; --group=data cells=30 passed=30 EXIT=0; payload tamper EXIT=1; below-floor EXIT=2; 169 tests)
Task 42: complete (commit 3385779, review Needs fixes -> fix round dispatched; fields=19/19 cells=366 counter=9 score=9 word_list=1; 179 tests)
Task 43: fix round 1/5 (README broke moon fmt --check EXIT=255; fixed in commit 40a7d8b) ; review Approved
Task 43: complete (commits 80eaf30..40a7d8b; 8 formula values printed, all bit-for-bit equal to lib/gate/data/l3_data.mbt for short_simple_sentence; path-dependency run surface proven; A-7.1 still [LOCAL_DEAD_LINK])
Task 44: complete (commits 831bd4b..aabfe74; 8/8 metadata, repository=https://gitcode.com/vicoproplus/moon_textstat from real origin, no files key, fmt regression fixed)
Task 46: fix round 1/5 (template leftovers deleted: lib/AGENTS.md + lib/cmd/main/** provenance 061bc9d; commit b80a4ca; 94/94 zip entries allowed; deletion recorded as a deviation since the brief's file surface was read-only)
Task 46: complete (commits 0b1fc42..b80a4ca, review Approved)
Task 48: complete (commit 259f968, review Approved; moon tree lists only the module, no Python/nltk/pyphen)
Task 49: complete (commit 96cad01, review Approved as a qualified pass; two stdout SHA-256 equal; PE import table proves no network DLL; no admin-level network block — documented as not proven)
Task 50: complete (commit b93795b; js backend 未执行 — PATH node is a broken .bunpm shim to a nonexistent D:\nvm4w\bun, so AD §3.5 precondition unmet; the same generated JS run directly under bun gives 34/34 passing, so 255 is environmental, not a cross-backend defect)
Task 45: complete (commit 25756af; NOTICE delivered with MIT / textstat MIT 0.7.13 / CMUdict BSD-2-Clause-style / pyphen MPL-1.1 per-file + source pointer; registered open item: hyph_de_DE.dic declares LGPL 2.0+ and LPPL, not MPL)
B4: complete (T-36..T-42)
B5: complete (T-43..T-51)
FinalReview: whole-branch review 62ba1b7..18ce248 (75 commits, 149 files) dispatched in two halves (code / docs)
FinalReview A (code): Ready with follow-ups — 0 Critical, 4 Important (unrequested exported AnalyzeOptions surface; subgroup cells<n floor=366 exit 0 exception registered nowhere; --bench exit 1 with no records; literal-vs-payload SHA limitation not surfaced), 7 Minor
FinalReview B (docs): Not ready — 3 Critical (NOTICE missing required license copies MPL 1.1 s3.1 / LGPL / CMUdict disclaimer while moon.mod declares plain MIT; T-46 read-only surface deleted without ratification; README instructs `moon add` which 404s), 5 Important, deferred must-fix: T-21 E-28 fixture label, T-45 licensing, T-46 ratification
FinalReview: fix wave 1 dispatched (single fix agent, full findings list)
FinalReview: doc/licensing fix wave complete (commit 3b95636; NOTICE now carries MPL 1.1 + LGPL 2.1 + de_DE header + CMUdict disclaimer; README path-dependency note; P-LICENSE ruling requested, T-54 blocked)
FinalReview: residuals R1-R3 closed (commit 41eaffc; gate .mbti regenerated; T-50 counts 35/145; copy-cost doc corrected)
