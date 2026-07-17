const ui = require '@lutest/utils/ui'
const t = require '@lutest_release'

const function format_help(): string
	return table.concat({
		ui.accent.bold 'Lutest',
		ui.muted 'A modern test runner for Luau',
		'',
		ui.section 'Usage',
		'  lutest <command> [options]',
		'',
		ui.section 'Run tests',
		'  test [paths...]   Run test suites.',
		'  todo [paths...]   List todo tests without running them.',
		'  debug bundle      Inspect the Roblox bundle without uploading it.',
		'',
		ui.section 'Project',
		'  doctor            Check the project configuration and runtimes.',
		'  setup             Install project dependencies.',
		'  version           Print the installed Lutest version.',
		'',
		ui.section 'Shared options',
		'  --runtime <name>  Select lute or roblox. debug bundle: roblox only.',
		'                    Default: config or lute.',
		'  --config <path>   Read configuration from a specific file.',
		'  --dry-run          Discover test files without running them. test, todo only.',
	}, '\n')
end

const function print_help()
	print(format_help())
end

t.test('should format grouped command reference', function()
	const output = format_help()

	assert(output:find('A modern test runner for Luau', 1, true) ~= nil)
	assert(output:find('> Usage', 1, true) ~= nil)
	assert(output:find('> Run tests', 1, true) ~= nil)
	assert(output:find('> Project', 1, true) ~= nil)
	assert(output:find('> Shared options', 1, true) ~= nil)
	assert(output:find('install-package', 1, true) == nil)
	assert(
		output:find('test [paths...]   Run test suites.', 1, true)
			~= nil
	)
	assert(
		output:find(
			'debug bundle      Inspect the Roblox bundle without uploading it.',
			1,
			true
		) ~= nil
	)
	assert(
		output:find(
			'--dry-run          Discover test files without running them. test, todo only.',
			1,
			true
		) ~= nil
	)
	assert(output:find('> Try', 1, true) == nil)
end)

return {
	format_help = format_help,
	print_help = print_help,
}
