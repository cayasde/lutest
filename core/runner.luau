const types = require("@core/types")

export type TestSpec = types.TestSpec
export type TestResult = types.TestResult
export type TestSuite = types.TestSuite
export type TestSuiteResult = types.TestSuiteResult

const function run_test(test: TestSpec): TestResult
	const ok, result = pcall(test.fn :: any)

	if ok then
		return {
			name = test.name,
			passed = true,
		}
	end

	return {
		name = test.name,
		passed = false,
		error_message = tostring(result),
	}
end

const function run(suite: TestSuite): TestSuiteResult
	const results = {} :: { TestResult }
	const total_tests = #suite.tests
	local passed = 0

	for _, test in suite.tests do
		const test_result = run_test(test)
		table.insert(results, test_result)

		if test_result.passed then
			passed += 1
		end
	end

	return {
		name = suite.name,
		total_tests = total_tests,
		passed_tests = passed,
		failed_tests = total_tests - passed,
		results = results,
	}
end

return {
	run = run,
}
