const types = require '@core/types'

export type TestSpec = types.TestSpec
export type TestMode = types.TestMode

const active_tests = {} :: { TestSpec }
local active = false

const function clear_active_tests()
	while #active_tests > 0 do
		table.remove(active_tests)
	end
end

const function begin(_module_identity: string)
	active = true
	clear_active_tests()
end

const function register(test: TestSpec)
	if not active then return end
	table.insert(active_tests, test)
end

const function collect(): { TestSpec }
	return active_tests
end

const function clear()
	active = false
	clear_active_tests()
end

const function is_active(): boolean
	return active
end

return {
	begin = begin,
	clear = clear,
	collect = collect,
	is_active = is_active,
	register = register,
}
