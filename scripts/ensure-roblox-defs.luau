const fs = require '@std/fs'
const json = require '@std/json'
const net = require '@std/net'
const process = require '@std/process'

type JsonObject = { [string]: any }

const VSCODE_SETTINGS_PATH = '.vscode/settings.json'
const ROBLOX_DEFS_DIRECTORY = '.cache/luau-lsp'
const ROBLOX_DEFS_CACHE_PATH = '.cache/luau-lsp/globalTypes.roblox.d.luau'

const function read_editor_settings(): JsonObject?
	if not fs.exists(VSCODE_SETTINGS_PATH) then return nil end

	const settings_source = fs.readFileToString(VSCODE_SETTINGS_PATH)
	const settings_value = json.deserialize(settings_source)

	return json.asObject(settings_value)
end

const function get_setting_string(settings: JsonObject?, key: string): string?
	if settings == nil then return nil end

	const value = settings[key]
	if typeof(value) == 'string' then return value end

	return nil
end

const function get_definition_files(settings: JsonObject?): JsonObject?
	if settings == nil then return nil end

	const value = settings['luau-lsp.types.definitionFiles']
	if typeof(value) == 'table' then return value :: JsonObject end

	return nil
end

const function is_http_url(value: string): boolean
	return value:sub(1, 7) == 'http://' or value:sub(1, 8) == 'https://'
end

const function resolve_roblox_definitions_source(settings: JsonObject?): string?
	if
		get_setting_string(settings, 'luau-lsp.platform.type')
		~= 'roblox'
	then
		return nil
	end

	const definition_files = get_definition_files(settings)
	if definition_files == nil then return nil end

	const roblox_definitions = definition_files['@roblox']
	if typeof(roblox_definitions) == 'string' then
		return roblox_definitions
	end

	return nil
end

const function ensure_http_cache(url: string)
	if fs.exists(ROBLOX_DEFS_CACHE_PATH) then
		print 'Roblox definitions cache is ready.'
		return
	end

	fs.createDirectory(ROBLOX_DEFS_DIRECTORY, { makeParents = true })

	local response = nil :: net.Response?
	local ok, result = pcall(function()
		return net.request(url)
	end)

	if ok then response = result :: net.Response end

	if not ok or response == nil then
		error(
			`Could not download Roblox definitions from '{url}'. Run this command again when the network is available.`
		)
	end

	const resolved_response = response :: net.Response

	if not resolved_response.ok then
		error(
			`Could not download Roblox definitions from '{url}' (HTTP {resolved_response.status}).`
		)
	end

	fs.writeStringToFile(ROBLOX_DEFS_CACHE_PATH, resolved_response.body)
	print 'Roblox definitions cache is ready.'
end

const function main()
	const settings = read_editor_settings()
	const source = resolve_roblox_definitions_source(settings)

	if source == nil then
		print 'No explicit Roblox definitions source is configured.'
		return
	end

	if is_http_url(source) then
		ensure_http_cache(source)
		return
	end

	if not fs.exists(source) then
		error(
			`Configured Roblox definitions file '{source}' does not exist.`
		)
	end

	print 'Roblox definitions file is available.'
end

local ok, err = pcall(main)

if not ok then
	print(tostring(err))
	process.exit(1)
end
