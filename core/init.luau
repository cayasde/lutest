const types = require("@self/types")
const runner = require("@self/runner")
const reporter = require("@self/reporter")

export type TestSpec = types.TestSpec
export type PassedTestResult = types.PassedTestResult
export type FailedTestResult = types.FailedTestResult
export type TestResult = types.TestResult
export type TestSuite = types.TestSuite
export type TestSuiteResult = types.TestSuiteResult
export type TestRunner = types.TestRunner

return {
	run = runner.run,
	format_suite_result = reporter.format_suite_result,
	print_suite_result = reporter.print_suite_result,
}
