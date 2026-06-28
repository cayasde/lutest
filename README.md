# Lutest

Lutest is a test runner for Luau code, with a focus on `luau`, `lute`, and Roblox runtimes.

It runs tests against real runtime behavior instead of leaning on engine mocks for most validation.

On Roblox, the long-term plan is to integrate with [Roblox Open Cloud Luau Execution](https://create.roblox.com/docs/cloud/reference/features/luau-execution) and use Luau session tasks to run tests in a headless Studio-style workflow for development and CI.

It should also support tests written close to the module under test, including internal or non-exported behavior, without forcing public-only APIs or dependency injection just to make testing possible. That is closer to how tests are commonly written in [Rust](https://rust-lang.org/) projects.

## Status

Lutest will remain under constant change while the project is still in its early stages.

Expect experimental work, and do not treat releases as final or stable yet.

Breaking changes may happen in any release for now.

## Setup

Install the pinned tools with:

```powershell
mise install
```

## License

Lutest is distributed under the terms of the [MIT License](LICENSE).
