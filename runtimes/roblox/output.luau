const version = require '@core/version'
const ui = require '@lutest/utils/ui'

const function non_interactive_prefix(): string
	return `lutest({ui.accent 'roblox'})@{version.VALUE}`
end

return {
	non_interactive_prefix = non_interactive_prefix,
}
