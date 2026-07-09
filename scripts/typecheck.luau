const process = require '@std/process'

type StringSet = { [string]: boolean }

const PROJECT_PREFIXES = {
	'core/',
	'cli/',
	'lib/',
	'runtimes/',
	'scripts/',
	'utils/',
}

const ANALYZE_ARGS = {
	'luau-lsp',
	'analyze',
	'--platform=standard',
	'--flag',
	'LuauSolverV2=true',
	'--ignore',
	'.github/**',
	'--ignore',
	'.husky/**',
	'--ignore',
	'.tmp/**',
	'--ignore',
	'.vscode/**',
	'--ignore',
	'dist/**',
	'--ignore',
	'docs/**',
	'--ignore',
	'node_modules/**',
	'--ignore',
	'Packages/**',
	'--ignore',
	'luau_packages/**',
	'--ignore',
	'vendor/**',
	'--ignore',
	'**/.lute/**',
	'core',
	'cli',
	'lib',
	'runtimes',
	'scripts',
	'utils',
}

const function normalize_line(line: string): string
	return (line:gsub('\\', '/'))
end

const function is_project_diagnostic_start(line: string): boolean
	const normalized = normalize_line(line)

	for _, prefix in PROJECT_PREFIXES do
		if normalized:sub(1, #prefix) == prefix then return true end
	end

	return false
end

const function split_lines(output: string): { string }
	const lines = {} :: { string }

	for _, line in output:split '\n' do
		if line:sub(-1) == '\r' then
			table.insert(lines, line:sub(1, -2))
			continue
		end

		table.insert(lines, line)
	end

	return lines
end

const function flush_current_block(
	filtered: { string },
	seen_blocks: StringSet,
	current_block: { string }
)
	if #current_block == 0 then return end

	const key = table.concat(current_block, '\n')
	if seen_blocks[key] then return end

	seen_blocks[key] = true

	for _, line in current_block do
		table.insert(filtered, line)
	end

	table.insert(filtered, '')
end

const function collect_project_diagnostics(output: string): { string }
	const filtered = {} :: { string }
	const seen_blocks = {} :: StringSet
	local current_block = {} :: { string }
	local keep_block = false

	for _, line in split_lines(output) do
		if line == '' then
			flush_current_block(
				filtered,
				seen_blocks,
				current_block
			)
			current_block = {}
			keep_block = false
			continue
		end

		if is_project_diagnostic_start(line) then
			flush_current_block(
				filtered,
				seen_blocks,
				current_block
			)
			current_block = { line }
			keep_block = true
			continue
		end

		if keep_block then table.insert(current_block, line) end
	end

	flush_current_block(filtered, seen_blocks, current_block)

	while #filtered > 0 and filtered[#filtered] == '' do
		table.remove(filtered)
	end

	return filtered
end

const function main()
	const result = process.run(ANALYZE_ARGS)
	const diagnostics =
		collect_project_diagnostics(result.stdout .. result.stderr)

	if #diagnostics > 0 then
		print(table.concat(diagnostics, '\n'))
		process.exit(1)
	end

	print 'Typecheck passed for project-owned files.'
end

main()
