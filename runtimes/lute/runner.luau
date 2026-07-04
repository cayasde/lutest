const core = require '@core'
const config = require '@runtimes/lute/config'
const discovery = require '@runtimes/lute/discovery'
const t = require '@lutest_release'
const path_utils = require '@lutest/utils/path'
const fs = require '@std/fs'
const luau = require '@std/luau'
const path = require '@std/path'

export type TestSpec = core.TestSpec
export type TestSuite = core.TestSuite
export type TestSuiteResult = core.TestSuiteResult
type LutestConfig = config.LutestConfig
type ModuleCache = { [string]: unknown }
type LoadingMap = { [string]: boolean }
type ExecutionState = {
	current_module: string?,
}
type RuntimeContextModule = {
	set_register: ((TestSpec) -> ()) -> (),
	clear_register: () -> (),
}

const CONTEXT_PATH = path_utils.normalize_path(
	path.join(path_utils.cwd(), 'lib/context.luau')
)

const function is_project_module(
	resolved_path: string,
	project_root: string
): boolean
	if resolved_path == project_root then return true end
	return resolved_path:sub(1, #project_root + 1) == `{project_root}/`
end

const function format_load_error(module_path: string, err: unknown): string
	const message = `failed to load '{module_path}': {tostring(err)}`
	return debug.traceback(message, 2)
end

const function create_runtime_register(
	tests: { TestSpec },
	execution_state: ExecutionState,
	suite_module_path: string
): (TestSpec) -> ()
	return function(test: TestSpec)
		if execution_state.current_module ~= suite_module_path then
			return
		end

		table.insert(tests, test)
	end
end

const function execute_module(
	module_path: string,
	suite_module_path: string,
	tests: { TestSpec },
	module_cache: ModuleCache,
	loading_modules: LoadingMap,
	execution_state: ExecutionState,
	project_config: LutestConfig
): unknown
	if module_cache[module_path] ~= nil then
		return module_cache[module_path]
	end
	if loading_modules[module_path] then
		error(
			`cyclic require detected while loading '{module_path}'`,
			0
		)
	end

	loading_modules[module_path] = true

	const env = table.clone(_G :: any)
	const project_root = path_utils.cwd()
	env.__lutest_register = create_runtime_register(
		tests,
		execution_state,
		suite_module_path
	)
	env._G = env
	env.require = function(require_path: string)
		const resolved_ok, resolved_result = pcall(function()
			return path_utils.normalize_path(
				path.format(
					luau.resolveModule(
						require_path,
						module_path
					)
				)
			)
		end)
		if not resolved_ok then return (require)(require_path) end

		const resolved_path = resolved_result :: string
		if not is_project_module(resolved_path, project_root) then
			return (require)(require_path)
		end

		return execute_module(
			resolved_path,
			suite_module_path,
			tests,
			module_cache,
			loading_modules,
			execution_state,
			project_config
		)
	end

	if module_path == suite_module_path and module_path ~= CONTEXT_PATH then
		const context = execute_module(
			CONTEXT_PATH,
			suite_module_path,
			tests,
			module_cache,
			loading_modules,
			execution_state,
			project_config
		) :: RuntimeContextModule
		context.set_register(env.__lutest_register)
	end

	const ok, result = xpcall(function()
		const previous_module = execution_state.current_module
		execution_state.current_module = module_path
		const source = fs.readFileToString(module_path)
		const chunk = luau.load(luau.compile(source), module_path, env)
		const chunk_result = chunk()
		execution_state.current_module = previous_module
		return chunk_result
	end, function(err)
		return err
	end)

	if module_path == suite_module_path and module_path ~= CONTEXT_PATH then
		const context =
			module_cache[CONTEXT_PATH] :: RuntimeContextModule?
		if context ~= nil then context.clear_register() end
	end

	if execution_state.current_module == module_path then
		execution_state.current_module = nil
	end

	loading_modules[module_path] = nil
	if not ok then error(result, 0) end

	module_cache[module_path] = result
	return result
end

const function load_module(
	module_path: string,
	project_config: LutestConfig
): (unknown, { TestSpec })
	const tests = {} :: { TestSpec }
	const module_cache = {} :: ModuleCache
	const loading_modules = {} :: LoadingMap
	const execution_state = {
		current_module = nil,
	} :: ExecutionState

	const ok, result = xpcall(function()
		return execute_module(
			module_path,
			module_path,
			tests,
			module_cache,
			loading_modules,
			execution_state,
			project_config
		)
	end, function(err)
		return format_load_error(module_path, err)
	end)

	if not ok then error(result, 0) end

	return result, tests
end

const function warn_missing_tests(
	module_path: string,
	project_config: LutestConfig
)
	print(
		`warning: module '{path_utils.relative_to_cwd(module_path)}' depends on {project_config.require} but registered no tests`
	)
end

const function create_suite(module_path: string, tests: { TestSpec }): TestSuite
	return {
		name = path_utils.relative_to_cwd(module_path),
		tests = tests,
	}
end

const function has_only_tests(suites: { TestSuite }): boolean
	for _, suite in suites do
		for _, test in suite.tests do
			if test.mode == 'only' then return true end
		end
	end

	return false
end

const function run_file(module_path: string): { TestSuiteResult }
	const project_config = config.load_config(path_utils.cwd())
	const resolved_module_path = path_utils.resolve_from_cwd(module_path)
	const _, tests = load_module(resolved_module_path, project_config)
	if #tests == 0 then
		warn_missing_tests(resolved_module_path, project_config)
		return {}
	end

	return { core.run(create_suite(resolved_module_path, tests)) }
end

const function run_files(paths: { string }): { TestSuiteResult }
	const project_config = config.load_config(path_utils.cwd())
	const suites = {} :: { TestSuite }

	for _, module_path in paths do
		const resolved_module_path =
			path_utils.resolve_from_cwd(module_path)
		const _, tests =
			load_module(resolved_module_path, project_config)
		if #tests == 0 then
			warn_missing_tests(resolved_module_path, project_config)
			continue
		end

		table.insert(suites, create_suite(resolved_module_path, tests))
	end

	const suite_results = {} :: { TestSuiteResult }
	const resolved_focus_only = has_only_tests(suites)

	for _, suite in suites do
		table.insert(
			suite_results,
			core.run(suite, {
				focus_only = resolved_focus_only,
			})
		)
	end

	return suite_results
end

const function run_discovered(paths: { string }): { TestSuiteResult }
	return run_files(discovery.discover_files(paths))
end

t.test('should not register tests from required dependencies', function()
	const temp_root =
		path_utils.resolve_path(path_utils.cwd(), 'dist/test-tmp')
	const temp_cwd =
		path_utils.resolve_path(temp_root, 'runner-dependency-tests')
	const suite_path =
		path_utils.normalize_path(path.join(temp_cwd, 'suite.luau'))
	const dependency_path = path_utils.normalize_path(
		path.join(temp_cwd, 'dependency.luau')
	)

	if fs.exists(temp_cwd) then
		fs.removeDirectory(temp_cwd, { recursive = true })
	end

	fs.createDirectory(temp_cwd, { makeParents = true })
	fs.writeStringToFile(
		dependency_path,
		[[
local t = require("@lutest_release")

t.test("dependency test", function()
	error("dependency test should not run")
end)

return {
	value = 41,
}
]]
	)
	fs.writeStringToFile(
		suite_path,
		[[
local dependency = require("./dependency")
local t = require("@lutest_release")

t.test("suite test", function()
	assert(dependency.value == 41)
end)

return dependency
]]
	)

	const _, tests = load_module(suite_path, {
		roots = { '.' },
		ignore = {},
		require = '@lutest_release',
		gitignore = true,
	})

	assert(#tests == 1)
	assert(tests[1].name == 'suite test')

	fs.removeDirectory(temp_cwd, { recursive = true })
end)

t.test('should respect the configured test lib require path', function()
	const temp_root =
		path_utils.resolve_path(path_utils.cwd(), 'dist/test-tmp')
	const temp_cwd =
		path_utils.resolve_path(temp_root, 'runner-custom-test-lib')
	const suite_path =
		path_utils.normalize_path(path.join(temp_cwd, 'suite.luau'))
	const test_lib_path = path_utils.normalize_path(
		path.join(temp_cwd, 'custom-test-lib.luau')
	)

	if fs.exists(temp_cwd) then
		fs.removeDirectory(temp_cwd, { recursive = true })
	end

	fs.createDirectory(temp_cwd, { makeParents = true })
	fs.writeStringToFile(
		test_lib_path,
		[[
local function test(name, fn)
	local context = require("@lib/context")

	context.register({
		name = name,
		mode = "run",
		fn = fn,
	})
end

return {
	version = "custom",
	test = test,
}
]]
	)
	fs.writeStringToFile(
		suite_path,
		[[
local t = require("./custom-test-lib")

t.test("suite test", function()
	assert(t.version == "custom")
end)

return t.version
]]
	)

	const result, tests = load_module(suite_path, {
		roots = { '.' },
		ignore = {},
		require = './custom-test-lib',
		gitignore = true,
	})

	assert(result == 'custom')
	assert(#tests == 1)
	assert(tests[1].name == 'suite test')

	fs.removeDirectory(temp_cwd, { recursive = true })
end)

return {
	run_file = run_file,
	run_files = run_files,
	run_discovered = run_discovered,
}
