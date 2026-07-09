const process = require '@std/process'
const errors = require '@core/errors'
const command = require '@self/command'
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

const function has_failures(results: { reporter.TestSuiteResult }): boolean
	for _, result in results do
		if result.failed_tests > 0 then return true end
	end

	return false
end

const function print_lutest_error(message: string)
	print(errors.display_error(message))
end

const function main()
	const args = collect_cli_args()
	const parsed_command = command.parse_command(args)

	if parsed_command.kind == 'help' then
		help.print_help()
		process.exit(0)
	end

	if parsed_command.kind == 'error' then
		print_lutest_error(parsed_command.message :: string)
		print ''
		help.print_help()
		process.exit(1)
	end

	local results = nil :: { reporter.TestSuiteResult }?
	local runtime_error = nil :: string?
	const ok = xpcall(function()
		results =
			lute.run_discovered(parsed_command.paths :: { string })
	end, function(err)
		runtime_error = tostring(err)
		return runtime_error
	end)

	if not ok then
		const message = runtime_error :: string
		if errors.is_lutest_error(message) then
			print_lutest_error(message)
		else
			print_lutest_error(
				errors.internal_error(
					'The runner crashed while preparing test suites.',
					{
						where = 'runner',
						how_to_fix = 'This looks like a Lutest bug. Please report it with the command, project config, and stack trace below.',
						details = message,
					}
				)
			)
		end

		process.exit(1)
	end

	const resolved_results = results :: { reporter.TestSuiteResult }
	if #resolved_results == 0 then
		print_lutest_error(
			errors.usage_error('No test files were discovered.', {
				where = if #(
							parsed_command.paths :: { string }
						) > 0
					then `lutest test {table.concat(
						parsed_command.paths :: { string },
						' '
					)}`
					else 'lutest test',
				how_to_fix = 'Pass an existing test file or directory, or update `discovery.roots` in `lutest.toml`.',
			})
		)
		process.exit(1)
	end

	reporter.print_run_result(resolved_results)

	process.exit(if has_failures(resolved_results) then 1 else 0)
end

main()
