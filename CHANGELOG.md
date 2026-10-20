# Changelog

## 2026-10-20

- Canonical `spec-driven-longish` schema created from the tsmulms copy,
  merged with upstream `spec-driven` 1.14.3.
- Adopted from upstream 1.14.3: the 500-character requirement rule and
  its split procedure, `## Purpose` on new capabilities, capability
  research, `skip_specs`, one spec file at a time, deferrable-only open
  questions and verification in every task.
- Moved out, for projects to carry in their own configuration: one
  client's migration rules, its examples and its spec-loss guard
  detail; "What shipped" keeps generic categories.
- Fixed: the schema description, `## Scope & Decisions` in the proposal
  template, the capability-spec table rule stated inline, one tasks
  table specification shared by tasks and apply, pull request wording,
  and capability research before the placement question.
- New rules: apply validates the change and the project's specs strictly
  before the work is declared complete; one list of sanctioned direct
  spec edits with shared invariants.
- Progressive disclosure: the interview and file-boundary rationales are
  cut to one sentence each.
