const types = require '@core/types'

export type TestSpec = types.TestSpec
export type TestSuite = types.TestSuite

const function test(name: string, fn: () -> ()): TestSpec
	return {
		name = name,
		fn = fn,
	}
end

const function suite(name: string, tests: { TestSpec }): TestSuite
	return {
		name = name,
		tests = tests,
	}
end

return {
	suite = suite,
	test = test,
}
