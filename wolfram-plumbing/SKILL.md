---
name: wolfram-plumbing
description: 'Examine internal implementations of Wolfram Language built-in functions when documentation is insufficient. Uses DefinitionString to reveal actual function definitions, sub-functions, and implementation patterns.'
argument-hint: 'Function name to inspect (e.g., "LinearModelFit", "Classify", "EntityValue")'
---

# Wolfram Language Function Plumbing

## When to Use
- Documentation (wolfram-docs skill) does not explain a behavior, option, or edge case
- Debugging unexpected or undocumented behavior of a built-in
- Finding out which internal sub-functions a built-in dispatches to, and why
- Learning implementation patterns used inside the Wolfram Language

## Procedure

### 1. Evaluate via wolfram-eval

Run all code with the **wolfram-eval** skill (scratch `.wls` file + `wolframscript -file`). If no Wolfram
evaluation is available, tell the user this skill needs it and stop. Every run is a fresh kernel, so each
script must load the utility again.

### 2. Load DefinitionString and inspect the target

```wolfram
Get[FileNameJoin[{$HomeDirectory, ".claude", "skills", "wolfram-plumbing", "utils", "DefinitionString.wl"}]];

Print[DefinitionString[LinearModelFit]];
Print[DefinitionString["StatisticalModeling`FittedModel`LinearFit`Private`iLinFit3"]];   (* string form *)
Print[DefinitionString[{"Echo", "Language`EchoDump`echoPrint"}]];                    (* several in one run *)
```

- `DefinitionString` is `HoldFirst`. Pass a symbol literally, or a **string** with the full name. Never pass a
  variable that holds the name, because `DefinitionString[s]` inspects `s` itself. Use `DefinitionString[Evaluate[s]]`
  or the list form instead.
- Batch the symbols for one drill-down step into a single script with the list form. That saves a kernel start per symbol.
- Output can be large: Dataset is about 28K characters, and Classify's full chain is much more. For anything non-trivial,
  write it to a file and read or grep the parts you need instead of printing it:
  ```wolfram
  Export["<scratch>/plumbing/Dataset.txt", DefinitionString[Dataset], "Text"];
  ```
- Option `"LineWidth" -> n` (default 120) controls wrapping.

### 3. Read the output

```
Symbol: System`StringPadLeft
Printed without context: System` and GeneralUtilities`Strings`PackagePrivate`
Other contexts are printed in full or with these aliases: c1` = ..., c2` = ...
Notes: ...                      (only when relevant)

Attributes[...] = {...}
<all DownValues / UpValues / SubValues / OwnValues / FormatValues / Options, formatted>
```

- **Bare symbols** are either System` or the context in the second header line. That context is the most frequently
  used non-System context, usually the implementation's private context. For example, `iStringPad` above is
  ``GeneralUtilities`Strings`PackagePrivate`iStringPad``.
- **Aliases** (`c1``, ...) are used only for long contexts. Short ones like ``Internal` ``, ``Developer` `` and
  ``System`Private` `` are printed in full. Aliases are textual and differ per call, so **expand them back to the full
  context** before passing a name to DefinitionString.
- Symbols ending in `$` or `$nnn` are Module or pattern locals, not functions to drill into.
- **Notes** flag three cases:
  - Kernel (C) code that is not shown.
  - A Locked + ReadProtected symbol (nothing can be shown).
  - A definition that is still an autoload stub. Call the function once with simple arguments, then retry.
- `(no definitions)` means a wrong name, a wrong context, or a pure kernel function. Check with `Names["*`name"]`.

### 4. Drill down

Follow the sub-functions that matter for the question, using their full names. Stop when you reach:
- kernel-level code (a Note says so, or only Attributes are shown)
- self-explanatory operations
- enough understanding to answer the question

Don't map the whole call tree when the question concerns one branch. Trace the arguments or option that the
user cares about.

Some internal functions only get definitions after first use. If one looks empty, call the public function with a simple
input earlier in the same script, then run DefinitionString again.

### 5. Report

Use this structure, scaled to the question. A narrow question deserves a short answer with the relevant snippet.

#### **Main Implementation Pattern**
High-level approach, e.g. "argument parsing → dispatch on argument count → specialized implementations".

#### **Key Sub-Functions**
- `SubFunction1` (full context on first mention): role and behavior

#### **Execution Flow**
1. Input processing and validation
2. Option handling and defaults
3. Core computation dispatch
4. Result processing

#### **Special Handling**
Edge cases, error and message paths, fallbacks, caching or other performance tricks.

#### **Implementation Notes**
Where kernel code takes over, version caveats (state `$Version`), anything surprising.

Quote the relevant definition snippets. Readers trust the code more than a paraphrase of it.

## Limitations
- Only the Wolfram Language layer is visible. Kernel (C) code, linked libraries and external calls are not.
- `Locked` + `ReadProtected` symbols (rare, e.g. `I`) cannot be shown.
- Implementations change between versions, and occasionally without notice. Mention `$Version` when the answer depends on the details.
- Context aliasing is plain text substitution. In rare cases it also rewrites a string literal that contains a context name.
- Inspection is read-only: ReadProtected is removed inside `Internal`InheritedBlock` and restored afterwards. Don't
  modify revealed definitions.
