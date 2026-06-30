local core = require '@core'
local reporter = require '@core/reporter'

type TestSpec = core.TestSpec

local smoke_tests = {
	{
		name = 'reports failed assertion for unequal numbers',
		fn = function()
			assert(
				1 == 2,
				'expected 1 to equal 2 for failure reporting'
			)
		end,
	},
	{
		name = 'marks successful assertion as passed',
		fn = function()
			assert(1 == 1, 'expected 1 to equal 1 for passing case')
		end,
	},
	{
		name = 'records multiple failing assertions independently',
		fn = function()
			assert(
				1 == 2,
				'expected 1 to equal 2 for second failure case'
			)
		end,
	},
} :: { TestSpec }

local arithmetic_tests = {
	{
		name = 'adds matching values successfully',
		fn = function()
			assert(2 + 2 == 4, 'expected 2 + 2 to equal 4')
		end,
	},
	{
		name = 'flags incorrect subtraction result',
		fn = function()
			assert(10 - 3 == 8, 'expected 10 - 3 to equal 8')
		end,
	},
	{
		name = 'keeps multiplication checks isolated',
		fn = function()
			assert(3 * 3 == 9, 'expected 3 * 3 to equal 9')
		end,
	},
} :: { TestSpec }

local string_tests = {
	{
		name = 'joins strings in order',
		fn = function()
			assert(
				'lu' .. 'test' == 'lutest',
				'expected concatenated string to equal lutest'
			)
		end,
	},
	{
		name = 'reports mismatched string length',
		fn = function()
			assert(
				#'reporter' == 7,
				'expected reporter string length to equal 7'
			)
		end,
	},
	{
		name = 'matches repeated string values',
		fn = function()
			assert(
				string.rep('a', 3) == 'aaa',
				'expected repeated string to equal aaa'
			)
		end,
	},
} :: { TestSpec }

local suite_results = {
	core.run {
		name = 'core runner smoke example',
		tests = smoke_tests,
	},
	core.run {
		name = 'arithmetic behavior example',
		tests = arithmetic_tests,
	},
	core.run {
		name = 'string behavior example',
		tests = string_tests,
	},
}

for _, suite_result in suite_results do
	reporter.print_suite_result(suite_result)
end
