const types = require '@core/types'
const registry = require '@self/registry'

export type TestSpec = types.TestSpec
export type TestMode = types.TestMode

const function get_runtime_register(): ((TestSpec) -> ())?
	const candidate = (_G :: any).__lutest_register
	if type(candidate) ~= 'function' then return nil end

	return candidate
end

const function register_spec(spec: TestSpec)
	const runtime_register = get_runtime_register()
	if runtime_register ~= nil then
		runtime_register(spec)
		return
	end

	if not registry.is_active() then return end
	registry.register(spec)
end

const function test(name: string, fn: () -> ()): TestSpec
	const spec = {
		name = name,
		mode = 'run',
		fn = fn,
	}

	register_spec(spec)
	return spec
end

const function skip(name: string, fn: () -> ()): TestSpec
	const spec = {
		name = name,
		mode = 'skip',
		fn = fn,
	}

	register_spec(spec)
	return spec
end

const function only(name: string, fn: () -> ()): TestSpec
	const spec = {
		name = name,
		mode = 'only',
		fn = fn,
	}

	register_spec(spec)
	return spec
end

const function todo(name: string): TestSpec
	const spec = {
		name = name,
		mode = 'todo',
	}

	register_spec(spec)
	return spec
end

return {
	test = test,
	skip = skip,
	only = only,
	todo = todo,
}
