return {
	version = 2,
	dependencies = {
		['lutest@v0.1.10'] = {
			installPath = 'Packages/lutest@v0.1.10',
			name = 'lutest',
			rev = 'v0.1.10',
			source = 'https://github.com/cayasde/lutest',
			sourceKind = 'github',
			dependencies = {
				lutest = 'lutest@v0.1.10',
			},
		},
	},
	packages = { 'lutest@v0.1.10' },
}
