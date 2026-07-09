const process = require '@std/process'
const help = require '@self/help'
const reporter = require '@core/reporter'
const lute = require '@runtimes/lute'

const function collect_cli_args(): { string }
	const args = {} :: { string }

	for index = 2, #process.args do
		table.insert(args, process.args[index])
	end

	return args
end

type ParsedCommand = {
	kind: 'help' | 'test' | 'error',
	paths: { string }?,
	message: string?,
}

const function wants_help(args: { string }): boolean
	for _, arg in args do
		if arg == '-h' or arg == '--help' then return true end
	end

	return false
end

const function collect_paths(args: { string }, start_index: number): { string }
	const paths = {} :: { string }

	for index = start_index, #args do
		table.insert(paths, args[index])
	end

	return paths
end

const function parse_command(args: { string }): ParsedCommand
	if wants_help(args) then return {
		kind = 'help',
	} end

	const command = args[1]
	if command == nil then
		return {
			kind = 'error',
			message = 'missing command',
		}
	end

	if command == 'test' then
		return {
			kind = 'test',
			paths = collect_paths(args, 2),
		}
	end

	return {
		kind = 'error',
		message = `unknown command '{command}'`,
	}
end

const function has_failures(results: { reporter.TestSuiteResult }): boolean
	for _, result in results do
		if result.failed_tests > 0 then return true end
	end

	return false
end

const function main()
	const args = collect_cli_args()
	const command = parse_command(args)

	if command.kind == 'help' then
		help.print_help()
		process.exit(0)
	end

	if command.kind == 'error' then
		print(command.message :: string)
		print ''
		help.print_help()
		process.exit(1)
	end

	const results = lute.run_discovered(command.paths :: { string })
	if #results == 0 then
		print 'no test modules found'
		process.exit(1)
	end

	reporter.print_run_result(results)

	process.exit(if has_failures(results) then 1 else 0)
end

main()
