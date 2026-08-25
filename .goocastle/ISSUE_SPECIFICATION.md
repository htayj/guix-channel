# Unattended issue specifications

Policy data returned by the API is copied and deeply immutable, so changing caller-owned section arrays cannot alter later configurations.

Generated issue workflows require every selected `ready-for-agent` issue to have:

- a level-two `## Context` section describing the problem, affected behavior, or constraints;
- a level-two `## Acceptance criteria` section with at least one non-empty Markdown list item.

Do not use `TBD`, `TODO`, `N/A`, or title-only issue bodies. Run `goocastle explain-readiness ISSUE_NUMBER` before adding `ready-for-agent`; it reports the policy and body digests without retaining the issue body.

If validation fails, remove or correct the ready label while the issue is being triaged, then add the missing sections or criteria and rerun the read-only check. A dependency or Gooflow routing error is evaluated alongside this specification check, before any branch, worktree, sandbox, or new task journal is created.

For an established repository, audit legacy bodies with `goocastle migrate-issue-specifications PROJECT`. It is a dry run by default; review the compatible, migratable, and manual-review results, then use `--write` only for unambiguous body-only heading conversions. Summaries also report written, skipped/raced, and failed write outcomes. Issue metadata is preserved and repeated runs are idempotent. Edit manual cases and rerun `goocastle explain-readiness ISSUE_NUMBER`.

The default policy is recorded in `.goocastle/config.json`. It may require additional sections or longer context/criteria. Set `issueSpecification.mode` to `disabled` only for an explicitly reviewed legacy repository; generated runs print a warning and body changes are still recorded by digest.

Minimum lengths are measured after Markdown cleanup in Unicode code points, not UTF-16 code units or UTF-8 bytes. Astral characters count once, while combining marks count as separate code points; validation errors report the configured code-point minimum.

If a resumed task reports that its specification changed, inspect `goocastle status` and the preserved branch. Restore the original issue criteria, or make the audited decision explicit with `GOOCASTLE_SPECIFICATION_OVERRIDE=1 goocastle resume PROJECT` after reviewing the new criteria.
