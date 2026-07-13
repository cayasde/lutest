const types = require '@core/types'
const executor = require '@core/executor'
const t = require '@lutest_release'
const path_utils = require '@lutest/utils/path'

export type TestSpec = types.TestSpec
export type TestResult = types.TestResult
export type TestSuite = types.TestSuite
export type TestSuiteResult = types.TestSuiteResult
export type FailedTestResult = types.FailedTestResult

type RunOptions = {
	focus_only: boolean,
}

const function runnable_test_spec(
	name: string,
	mode: 'run' | 'skip' | 'only',
	fn: () -> (),
	scope: types.TestScope?
): TestSpec
	return {
		name = name,
		mode = mode,
		fn = fn,
		scope = scope,
	} :: TestSpec
end

const function todo_test_spec(name: string): TestSpec
	return {
		name = name,
		mode = 'todo',
	} :: TestSpec
end

const function test_scope(name: string): types.TestScope
	return {
		name = name,
		hooks = {
			before_all = {},
			before_each = {},
			after_each = {},
			after_all = {},
		},
	}
end

const function shorten_workspace_paths(message: string): string
	const normalized_cwd = path_utils.cwd()
	const backslash_cwd = normalized_cwd:gsub('/', '\\')
	local shortened = message
	shortened = shortened:gsub(normalized_cwd .. '/', '')
	shortened = shortened:gsub(backslash_cwd .. '\\', '')
	return shortened
end

const function run(suite: TestSuite, options: RunOptions?): TestSuiteResult
	const result = executor.run(suite, options)
	for _, test_result in result.results do
		if test_result.kind ~= 'failed' then continue end
		test_result.error_message =
			shorten_workspace_paths(test_result.error_message)
	end
	for _, failure in result.lifecycle_failures or {} do
		failure.error_message =
			shorten_workspace_paths(failure.error_message)
	end
	return result
end

t.test('should run suite hooks around each test', function()
	const events = {} :: { string }
	const scope = test_scope 'Inventory'
	table.insert(scope.hooks.before_all, function()
		table.insert(events, 'before all')
	end)
	table.insert(scope.hooks.before_each, function()
		table.insert(events, 'before each')
	end)
	table.insert(scope.hooks.after_each, function()
		table.insert(events, 'after each')
	end)
	table.insert(scope.hooks.after_all, function()
		table.insert(events, 'after all')
	end)

	const result = run {
		name = 'inventory.luau',
		tests = {
			runnable_test_spec('first', 'run', function()
				table.insert(events, 'first')
			end, scope),
			runnable_test_spec('second', 'run', function()
				table.insert(events, 'second')
			end, scope),
		},
	}

	assert(
		table.concat(events, ', ')
			== 'before all, before each, first, after each, before each, second, after each, after all'
	)
	assert(result.passed_tests == 2)
	assert(result.results[1].name == 'Inventory > first')
end)

t.test('should report before all once and skip affected tests', function()
	const scope = test_scope 'Inventory'
	const failing_hook: types.HookFn = function()
		error 'database unavailable'
	end
	table.insert(scope.hooks.before_all, failing_hook)

	const result = run {
		name = 'inventory.luau',
		tests = {
			runnable_test_spec(
				'first',
				'run',
				function(): () end,
				scope
			),
			runnable_test_spec(
				'second',
				'run',
				function(): () end,
				scope
			),
		},
	}

	assert(result.skipped_tests == 2)
	assert(result.failed_tests == 0)
	const failures = result.lifecycle_failures or {}
	assert(#failures == 1)
	assert(failures[1].hook_name == 'before_all')
end)

t.test('should focus on only tests', function()
	local ran_non_only = false
	local ran_only = false

	const run_test_spec = runnable_test_spec('run test', 'run', function()
		ran_non_only = true
	end)

	const only_test_spec = runnable_test_spec(
		'only test',
		'only',
		function()
			ran_only = true
		end
	)

	const result = run {
		name = 'suite',
		tests = { run_test_spec, only_test_spec },
	}

	assert(ran_non_only == false)
	assert(ran_only == true)
	assert(result.results[1].kind == 'skipped')
	assert(result.results[2].kind == 'passed')
	assert(result.skipped_tests == 1)
	assert(result.passed_tests == 1)
end)

t.test('should keep todo tests as todo under only focus', function()
	const only_test_spec = runnable_test_spec(
		'only test',
		'only',
		function() end
	)

	const todo_spec = todo_test_spec 'todo test'

	const result = run {
		name = 'suite',
		tests = { only_test_spec, todo_spec },
	}

	assert(result.results[1].kind == 'passed')
	assert(result.results[2].kind == 'todo')
	assert(result.todo_tests == 1)
end)

t.test('should count mixed results correctly', function()
	local ran_passed = false
	local ran_skipped = false

	const passed_test_spec = runnable_test_spec(
		'passed test',
		'run',
		function()
			ran_passed = true
		end
	)

	const failed_test_spec = runnable_test_spec(
		'failed test',
		'run',
		function(): ()
			error 'boom'
		end
	)

	const skipped_test_spec = runnable_test_spec(
		'skipped test',
		'skip',
		function()
			ran_skipped = true
		end
	)

	const todo_spec = todo_test_spec 'todo test'

	const tests = {
		passed_test_spec,
		failed_test_spec,
		skipped_test_spec,
		todo_spec,
	}

	const result = run({
		name = 'suite',
		tests = tests,
	}, { focus_only = false })

	assert(ran_passed == true)
	assert(ran_skipped == false)
	assert(result.total_tests == 4)
	assert(result.passed_tests == 1)
	assert(result.failed_tests == 1)
	assert(result.skipped_tests == 1)
	assert(result.todo_tests == 1)
end)

t.test('should preserve result order', function()
	const first_test_spec = runnable_test_spec(
		'first test',
		'run',
		function() end
	)

	const second_test_spec = runnable_test_spec(
		'second test',
		'skip',
		function() end
	)

	const third_test_spec = todo_test_spec 'third test'

	const result = run({
		name = 'suite',
		tests = { first_test_spec, second_test_spec, third_test_spec },
	}, { focus_only = false })

	assert(result.results[1].name == 'first test')
	assert(result.results[1].kind == 'passed')
	assert(result.results[2].name == 'second test')
	assert(result.results[2].kind == 'skipped')
	assert(result.results[3].name == 'third test')
	assert(result.results[3].kind == 'todo')
end)

t.test('should capture thrown errors as failed results', function()
	const failing_test_spec = runnable_test_spec(
		'failing test',
		'run',
		function(): ()
			error 'boom'
		end
	)

	const result = run({
		name = 'suite',
		tests = { failing_test_spec },
	}, { focus_only = false })

	assert(result.results[1].kind == 'failed')
	assert(result.failed_tests == 1)
	const failed_result = result.results[1] :: FailedTestResult
	assert(failed_result.error_message:find('boom', 1, true) ~= nil)
end)

t.test('should shorten workspace paths in failed error messages', function()
	const cwd = path_utils.cwd()
	const result = run({
		name = 'suite',
		tests = {
			runnable_test_spec(
				'failing test',
				'run',
				function(): ()
					error(
						`{cwd}/core/errors.luau:205: assertion failed!`
					)
				end
			),
		},
	}, { focus_only = false })

	const failed_result = result.results[1] :: FailedTestResult
	assert(
		failed_result.error_message:find(
			'core/errors.luau:205: assertion failed!',
			1,
			true
		) ~= nil
	)
	assert(failed_result.error_message:find(cwd, 1, true) == nil)
end)

return {
	run = run,
}
