local comp = require "comp"

return function()
	return comp({
		require "game.role",
		require "game.club",
		require "game.gm",
	})
end
