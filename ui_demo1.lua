
local ui = require'ui'

local win = ui:window{
	w = 800, h = 600,
}

function win:keydown(key)
	if key == 'esc' then
		self:close()
	end
end

local layer = ui:layer{
	parent = win,
	x = 100, y = 100,
	w = 200, h = 200,
	border_width = 10,
	border_color = '#fff',
	border_color_left = '#f00',
}

ui:run()
