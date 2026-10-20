# openspec-schemas

The canonical copy of `spec-driven-longish`, a workflow schema for
[OpenSpec](https://github.com/Fission-AI/OpenSpec). Projects vendor it by
copy, and a user-level link serves projects that have no copy yet.

## What it adds over `spec-driven`

The schema builds on OpenSpec's built-in `spec-driven` schema, at the version
named in `UPSTREAM`. Its main additions are below; the schema's own
instructions carry the full rules.

- **Clarification interview.** Before the proposal is drafted, a mandatory
  interview settles scope, capability placement, acceptance criteria and
  constraints, and the proposal records the outcome in its
  `## Scope & Decisions` section. Proposing drafts several coupled artifacts
  in one step, so a wrong scope caught in the interview costs minutes instead
  of a rewrite.
- **The `summary` artifact.** `summary.md` describes the change in plain
  language for readers outside engineering, such as product owners and
  managers. It requires the proposal, design and tasks, so it comes last.
- **Scenario-retitle rule.** OpenSpec's delta grammar cannot rename a
  scenario, so a stale scenario title is corrected by editing the project's
  main spec directly: title text only, scenario bodies and count unchanged,
  and each retitle recorded as a FROM/TO pair.
- **Sanctioned direct edits.** Spec changes normally go through a change's
  deltas. The schema lists the few edits allowed directly in a project's
  main specs under `openspec/specs/`: scenario retitles, replacing a `TBD`
  Purpose, bringing requirement descriptions within the 500-character limit,
  and amending the project's own workflow or CI specs to follow a change in
  the shared workflow. Every requirement keeps its title and its scenarios,
  new ones may be added, and each edit is recorded in the change's
  `design.md` or, outside a change, in the commit message. Only the last
  kind may change what a requirement means.

## Layout

```
schemas/spec-driven-longish/schema.yaml    the schema
schemas/spec-driven-longish/templates/     proposal, spec, design, tasks, summary
UPSTREAM                                   upstream version last merged in
CHANGELOG.md                               dated entries
tests/schema.test.sh                       the checks, one command
```

## Vendoring

A project carries its own copy of the schema:

1. Copy `schemas/spec-driven-longish` into the project's `openspec/schemas/`,
   giving `openspec/schemas/spec-driven-longish/schema.yaml`.
2. Set `schema: spec-driven-longish` in the project's `openspec/config.yaml`.

OpenSpec resolves a project's own copy before any other, and the copy is
committed with the project, so everyone working on it, and its CI, gets the
same schema. The unit of vendoring is a commit of this repository, which is
why `CHANGELOG.md` has dated entries rather than versions.

A copy synced by `openspec-fleet schema-sync` (the maintainer's fleet
tooling, not part of this repository) carries a lineage sidecar,
`openspec/schemas/spec-driven-longish/SOURCE`, naming the commit it came
from:

```
repo: https://github.com/akalongman/openspec-schemas
path: schemas/spec-driven-longish
commit: <40 hex characters>
```

`SOURCE` is written only by `openspec-fleet schema-sync`, never by hand. The
sync refuses to run from a clone with uncommitted changes under `schemas/`,
so the recorded commit holds exactly the content that was copied.

## User-level link

OpenSpec looks for a schema in the project's `openspec/schemas/` first, then
at the user level, then among its built-in schemas. A link at the user level
therefore serves every project without its own copy, such as a new
repository, and `openspec-fleet schema-sync` reads the schema through it.

The link is `~/.local/share/openspec/schemas/spec-driven-longish`
(`$XDG_DATA_HOME/openspec/schemas/` when `XDG_DATA_HOME` is set,
`%LOCALAPPDATA%\openspec\schemas\` on Windows), pointing at
`schemas/spec-driven-longish` in a clone of this repository. Remove any
earlier copy at that path first, since `ln -s` onto an existing directory
puts the link inside it.

On macOS, Linux and WSL, from the root of a clone:

```sh
dir="${XDG_DATA_HOME:-$HOME/.local/share}/openspec/schemas"
mkdir -p "$dir"
ln -s "$PWD/schemas/spec-driven-longish" "$dir/spec-driven-longish"
```

On Windows, in PowerShell from the root of a clone (a junction needs no
administrator rights):

```powershell
$dir = "$env:LOCALAPPDATA\openspec\schemas"
if ($env:XDG_DATA_HOME) { $dir = "$env:XDG_DATA_HOME\openspec\schemas" }
New-Item -ItemType Directory -Force -Path $dir | Out-Null
New-Item -ItemType Junction -Path "$dir\spec-driven-longish" -Target "$PWD\schemas\spec-driven-longish"
```

`openspec schema which spec-driven-longish`, run in a project, shows which
copy it resolves.

## Tests

```sh
bash tests/schema.test.sh
```

A passing run prints `N run, 0 failed` and exits 0. The schema checks need
the OpenSpec CLI installed. The test checks that:

- the schema validates in a throwaway project (`openspec schema validate`);
- the tasks table is specified identically in the tasks instruction and in
  the apply instruction;
- no token from a denylist of project-specific words appears in the schema;
- `apply.requires` names existing artifacts, and `summary` requires the
  proposal, design and tasks;
- the templates equal the installed OpenSpec package's for the version in
  `UPSTREAM`, apart from the `## Scope & Decisions` section in `proposal.md`
  and `summary.md`, which upstream does not have; with another version
  installed, this check is skipped with a notice;
- `UPSTREAM` names the merged version, and the README, changelog and license
  are in place.

## License

MIT, see `LICENSE`.
