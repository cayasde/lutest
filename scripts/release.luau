const fs = require '@std/fs'
const path = require '@std/path'
const process = require '@std/process'
const system = require '@std/system'

const DEFAULT_ENTRY = 'cli/init.luau'
const DEFAULT_BUNDLE_OUTPUT = 'dist/release-bundle/main.luau'
const DEFAULT_BINARY_OUTPUT = if system.win32
	then 'dist/lutest.exe'
	else 'dist/lutest'
const DEFAULT_CONFIG = 'darklua-bundle.json5'
const DARKLUA_WINDOWS_PATH = 'vendor/darklua/target/debug/darklua.exe'
const DARKLUA_UNIX_PATH = 'vendor/darklua/target/debug/darklua'

const function normalize_path(value: path.Pathlike): string
	const formatted = path.format(path.normalize(value))
	return (formatted:gsub('\\', '/'))
end

const function resolve_path(cwd: string, value: string): string
	if path.isAbsolute(value) then return normalize_path(value) end

	return normalize_path(path.join(cwd, value))
end

const function ensure_directory(directory: string)
	if directory == '' or directory == '.' then return end
	if fs.exists(directory) then return end

	fs.createDirectory(directory, {
		makeParents = true,
	})
end

const function darklua_binary_path(cwd: string): string
	const candidate = if system.win32
		then DARKLUA_WINDOWS_PATH
		else DARKLUA_UNIX_PATH
	return resolve_path(cwd, candidate)
end

const function build_darklua_if_needed(cwd: string): string
	const binary_path = darklua_binary_path(cwd)
	if fs.exists(binary_path) then return binary_path end

	const result = process.run({
		'cargo',
		'build',
		'--manifest-path',
		resolve_path(cwd, 'vendor/darklua/Cargo.toml'),
	}, {
		cwd = cwd,
		stdio = 'inherit',
	})

	if result.exitcode ~= 0 then process.exit(result.exitcode) end

	if not fs.exists(binary_path) then
		error(`missing darklua binary '{binary_path}' after build`, 0)
	end

	return binary_path
end

const function bundle_entry(
	cwd: string,
	entry_path: string,
	bundle_path: string,
	config_path: string
)
	if not fs.exists(entry_path) then
		error(`missing entry module '{entry_path}'`, 0)
	end

	if not fs.exists(config_path) then
		error(`missing darklua config '{config_path}'`, 0)
	end

	ensure_directory(normalize_path(path.dirname(bundle_path)))

	const darklua_path = build_darklua_if_needed(cwd)
	const result = process.run({
		darklua_path,
		'process',
		entry_path,
		bundle_path,
		'--config',
		config_path,
	}, {
		cwd = cwd,
		stdio = 'inherit',
	})

	if result.exitcode ~= 0 then process.exit(result.exitcode) end
	print(`bundled entry: {bundle_path}`)
end

const function compile_bundle(
	cwd: string,
	bundle_path: string,
	binary_path: string
)
	if not fs.exists(bundle_path) then
		error(`missing bundled entry '{bundle_path}'`, 0)
	end

	ensure_directory(normalize_path(path.dirname(binary_path)))

	if fs.exists(binary_path) then fs.remove(binary_path) end

	const result = process.run({
		'lute',
		'compile',
		bundle_path,
		'--output',
		binary_path,
	}, {
		cwd = cwd,
		stdio = 'inherit',
	})

	if result.exitcode ~= 0 then process.exit(result.exitcode) end
	print(`built binary: {binary_path}`)
end

const cwd = normalize_path(process.cwd())
const entry_path = resolve_path(cwd, process.args[2] or DEFAULT_ENTRY)
const bundle_path = resolve_path(cwd, process.args[3] or DEFAULT_BUNDLE_OUTPUT)
const binary_path = resolve_path(cwd, process.args[4] or DEFAULT_BINARY_OUTPUT)
const config_path = resolve_path(cwd, DEFAULT_CONFIG)

bundle_entry(cwd, entry_path, bundle_path, config_path)
compile_bundle(cwd, bundle_path, binary_path)
