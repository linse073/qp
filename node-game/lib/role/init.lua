local comp = require "comp"

return function()
	return comp({
		require "role.role",
		require "role.club",
	})
end