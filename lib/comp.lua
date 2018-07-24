
local ipairs = ipairs
local pairs = pairs

return function(modules)
	local _M = {}

	local init = {}
	local finish = {}
	for k, v in ipairs(modules) do
		for k1, v1 in pairs(v) do
			if k1 == "init" then
				init[#init+1] = v1
			elseif k1 == "finish" then
				finish[#finish+1] = v1
			else
				_M[k1] = v1
			end
		end
	end
	_M.init = function(...)
		for k, v in ipairs(init) do
			v(...)
		end
	end
	_M.finish = function(...)
		for k, v in ipairs(finish) do
			v(...)
		end
	end

	return _M
end
