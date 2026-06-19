# ThunderID iOS SDKs — Agent Instructions

## Project overview

Swift package providing the ThunderID authentication SDK (`ThunderID`) and a SwiftUI component library (`ThunderIDSwiftUI`). The `Samples/Quickstart` directory contains a standalone demo app.

## Build & test

```bash
# Build and run tests
swift test

# Run SwiftLint (must pass before any PR)
swiftlint lint --strict
```

## SwiftLint compliance (required)

All code **must pass `swiftlint lint --strict` with zero violations**. The CI `lint` job runs this check on every PR and treats any violation as a build failure.

Configuration lives in [.swiftlint.yml](.swiftlint.yml). Key rules enforced:

| Rule | What to do |
|---|---|
| `line_length` | Keep lines ≤ 120 characters. Wrap long function signatures and call-sites across multiple lines. |
| `trailing_comma` | No trailing comma on the last element of a collection literal or argument list. |
| `sorted_imports` | Sort `import` statements alphabetically (`CryptoKit` before `Foundation`). |
| `statement_position` | `else`/`catch` must start on the same line as the closing `}` of the preceding block — use `} else {` style. |
| `trailing_closure` | Use trailing closure syntax whenever the last parameter is a closure: `Foo { }` not `Foo(bar: { })`. |
| `multiline_function_chains` | In a multi-line chain, each call must be on its own line — don't combine `.font(.title2).bold()` on one line. |
| `identifier_name` | Variable names must be 3–40 characters. Avoid single-letter loop variables like `i`; use `idx` or a descriptive name. |
| `cyclomatic_complexity` | Functions must have complexity ≤ 10. Extract branches into private helper methods. |
| `for_where` | Prefer `for x in collection where condition` over `for x in collection { if condition { ... } }`. |
| `file_length` | Files should be ≤ 500 lines. Split large files by extracting types into a companion file (e.g. `FooComponents.swift`). |
| `type_body_length` | Class/struct bodies should be ≤ 350 lines. Move private helpers to a `private extension`. |
| `trailing_newline` | Every file must end with exactly one newline character. |

### Practical checklist before finishing any change

1. Run `swiftlint lint --strict` locally and fix every reported violation.
2. Never use single-letter loop variables (`i`, `j`). Use `idx`, `row`, or a meaningful name.
3. Wrap any function signature or call longer than 120 chars across multiple lines with one parameter per line.
4. Put `else`/`else if` on the same line as the closing `}`: `} else {`.
5. When adding imports, keep them sorted alphabetically.
6. If a new file grows past ~450 lines, split it proactively.

## File layout

```
Sources/ThunderID/          Core SDK (auth, token, http layers)
Sources/ThunderIDSwiftUI/   SwiftUI component library
Samples/Quickstart/         Demo app (not part of the SDK)
Tests/                      Unit tests (excluded from SwiftLint)
.swiftlint.yml              Lint configuration
.github/workflows/          CI pipelines
```

## Code style

- Swift 5.9+, minimum deployment iOS 16 / macOS 13.
- No third-party dependencies in `Sources/` — only `Foundation`, `CryptoKit`, `SwiftUI`.
- Use `async/throws` over completion handlers.
- Mark internal helpers `private`; expose only intentional API as `public`.
