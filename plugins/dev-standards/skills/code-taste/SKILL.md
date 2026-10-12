---
name: code-taste
description: Joshua's code style and review standards. Use whenever writing, refactoring, or reviewing code in any language (TypeScript, JavaScript, Python, Go, C++), and load it from pr-review as the standard to review against.
---

# Code Taste

Code should read like a book. A reader should understand every function top to bottom without decoding clever syntax. One philosophy applies everywhere. When a rule conflicts with a language's established standard or the project's existing convention, the language or project wins, and the deviation table at the bottom says how each rule translates.

## Readability over cleverness

- Use `if` statements. No ternaries for assignment, return values, or control flow.
- No one-line arrow functions. Every arrow function gets a block body with an explicit `return`, callbacks included.
- Loops over `reduce`. Use `for...of` (or the language's plain loop). `map` and `filter` are fine for a simple transform when the callback has a block body. A chain of more than two array calls becomes a loop.
- Early returns over nesting. Put guard clauses at the top of the function. Nesting deeper than two levels inside a function means something should be extracted.
- Destructuring in parameters is fine.
- If a line needs a second read to understand, rewrite it plainly even if it gets longer.

```ts
// No
const label = isActive ? "On" : "Off";
const total = items.reduce((sum, item) => sum + item.price, 0);

// Yes
let label = "Off";
if (isActive) {
  label = "On";
}

let total = 0;
for (const item of items) {
  total += item.price;
}
```

## Structure (Clean Code)

- A function does one thing. If describing it needs the word "and", split it.
- Organize code into classes, top down: public entry points first, then the helpers they call, in the order they're called (stepdown rule).
- Make things reusable within reason. Extract logic once a real second use exists. Don't build abstractions for hypothetical callers.
- Data access goes through a repository layer. No queries or raw client calls in business logic.
- Exactly one config module reads environment variables. Nothing else touches `process.env`, `os.environ`, `os.Getenv`, or `getenv`.
- Tests mirror the source tree.

## Documentation

- Every export has a doc comment: a one-line summary, each parameter, the return value, and what it throws.
- Inline comments explain why, not what. If a comment is needed to explain what, rename or restructure instead.

```ts
/**
 * Loads a pipeline definition from disk and validates it.
 * @param path Absolute path to the pipeline JSON file.
 * @returns The validated pipeline.
 * @throws PipelineValidationError if the file fails schema validation.
 */
export async function loadPipeline(path: string): Promise<Pipeline> {
```

## Naming

- Booleans are `isX` or `hasX`.
- Abbreviations only when universally understood with no loss of context (`id`, `url`, `config`). `usr`, `mgr`, `ctx2`, `tmpVal` are not.
- File and folder names follow lint and the language or project convention. No extra rules beyond that.

## Errors

- Throw errors. Use the project's custom error class (or a subclass of it) so errors carry context.
- Avoid try/catch. Async calls go through the project's callout helper, which centralizes the catch and keeps the call site linear.
- try/catch is acceptable only inside that helper and at true process boundaries (request handler, CLI entry point, worker loop) where errors get translated into responses or logs.

## Types (TypeScript)

- `type` by default.
- `interface` only for plain object shapes where it's actually needed (for example a class `implements` it). Keep interface usage limited overall.
- No `any`. Use `unknown` and narrow.

## Language deviations

| Rule | TS / JS | Python | Go | C++ |
|---|---|---|---|---|
| Doc comments | JSDoc on every export | Docstring on every public function and class (project style, default Google) | GoDoc comment starting with the identifier name on every exported identifier | Doxygen `/** */` on every public declaration in headers |
| Booleans | `isX`, `hasX` | `is_x`, `has_x` | `isX`, `hasX` (`IsX` when exported) | `isX`, `hasX`, or project casing |
| No ternary | `if` | No `a if cond else b`, write the `if` | Language has none | No `?:` |
| Loop over reduce | `for...of` | Plain `for` over `functools.reduce`. One simple comprehension is fine, nested comprehensions are not | Plain loops are already the standard | Range-for over `std::accumulate` with a lambda |
| No one-line functions | Block-bodied arrow functions | No lambdas assigned to names, use `def` | n/a | Named functions over multi-step lambdas |
| Classes, top down | Classes | Classes | Structs with methods, grouped by package. Stepdown order still applies | Classes |
| Errors | Throw custom `Error` subclass, call async through the callout helper | Raise custom exception subclass, try/except only at boundaries | Errors are values. Return `error`, wrap with `%w`, use custom error types. `if err != nil` is the language standard and is not a violation | Follow core's existing convention (exceptions or status returns), custom types derived from the project base |
| Config | Central config module | Central settings module | Config package, values passed in | Config object passed in, never `getenv` in logic |
