--go @ luajit -jp=a *

local time = require'time'
local ui = require'ui'
local win = ui:window{x = 700, y = 100, cw = 1200, ch = 700, visible = false, autoquit=true}
function win:keyup(key) if key == 'esc' then self:close() end end

ui.maxfps = 60

local function fps_function()
	local count_per_sec = 2
	local frame_count, last_frame_count, last_time = 0, 0
	return function()
		last_time = last_time or time.clock()
		frame_count = frame_count + 1
		local time = time.clock()
		if time - last_time > 1 / count_per_sec then
			last_frame_count, frame_count = frame_count, 0
			last_time = time
		end
		return last_frame_count * count_per_sec
	end
end

local fps = fps_function()

win.native_window:on('repaint', function(self)
	self:title(string.format('%d fps', fps()))
end)

if ... == 'ui_demo' and not DEMO then --loaded via require()
	return function(test)
		test(ui, win)
		win:show()
		ui:run()
		ui:free()
	end
end

local function test_window_layer()
	ui:style('window_view :hot', {
		background_color = '#080808',
		transition_background_color = true,
		transition_duration = 0.1,
	})
end

local function test_layers()

	ui:style('window_view', {
		background_color = '#fff',
	})

	ui:style('layer1', {
		transition_duration = 1,
		transition_background_colors = true,
		transition_shadow_blur = true,
		transition_rotation = true,
	})

	ui:style('layer1 :hot', {
		--border_color_left = '#fff',
		background_colors = {'#0f0', .5, '#f0f'},
		transition_background_colors = true,
		transition_duration_background_colors = 1,
		transition_duration = 1,
		--transition_ease = 'quad out',
		shadow_blur = 40,
		transition_shadow_blur = true,
		transition_rotation = true,
		rotation = 30,
	})

	local layer1 = ui:layer{
		x = 50,
		y = 50,
		w = 500,
		h = 200,
		tags = 'layer1',
		parent = win,

		--clip_content = true,
		--clip_content = false,
		  clip_content = 'background',

		border_width = 10,
		border_color = '#fff2',

		border_color_left   = '#f008',
		border_color_right  = '#ff08',
		border_color_top    = '#0ff8',
		border_color_bottom = '#f0f8',

		--border_width_left = 100,
		--border_width_right = 40,
		--border_width_top = 10,
		--border_width_bottom = 100,

		border_offset = -1,

		corner_radius = 10,
		corner_radius_top_left = 10,
		corner_radius_top_right = 100,
		corner_radius_bottom_right = 50,
		corner_radius_bottom_left = 10,
		corner_radius_kappa = 1,

		--background_type = 'color',
		background_color = '#00f',

		--background_type = 'gradient',
		background_type = 'radial_gradient',
		background_colors = {'#f00', 1, '#00f'},

		--background_type = 'image',
		background_image = 'media/jpeg/autumn-wallpaper.jpg',

		background_clip_border_offset = 0,

		--linear gradients
		background_x1 = 0,
		background_y1 = 0,
		background_x2 = 0,
		background_y2 = 100,

		--radial gradients
		background_cx1 = 250,
		background_cy1 = 100,
		background_r1 = 0,
		background_cx2 = 250,
		background_cy2 = 100,
		background_r2 = 100,

		--background_scale_cx = 150,
		--background_x = -800,
		--background_y = -800,
		background_scale = 1,
		background_rotation_cx = 250,
		background_rotation_cy = 100,
		background_rotation = 10,

		--padding = 20,
		--padding_left = 10,
		--padding_right = 10,
		--padding_top = 10,
		--padding_bottom = 10,

		rotation = 0,
		rotation_cx = 250,
		rotation_cy = 100,
		scale = 1.2,
		scale_cx = 50,
		scale_cy = 50,

		shadow_color = '#f00',
		shadow_blur = 1,
		shadow_x = 15,
		shadow_y = 15,
	}

	local layer2 = ui:layer{
		visible = true,
		tags = 'layer2',
		parent = layer1,
		clip_content = false,
		x = 10,
		y = 10,
		w = 200,
		h = 200,
		border_color = '#0ff',
		--border_width = 5,
		background_color = '#ff0',
		--rotation = 0,
		--padding = 20,
	}

	--function layer1:draw_border() end

	function layer1:after_draw_content()
		do return end
		local dr = self.window.dr
		local cr = dr.cr
		local ox, oy = self:from_origin(0, 0)
		cr:translate(ox, oy)
		self:border_path(-1)
		self:border_path(1)
		cr:translate(-ox, -oy)
		local rule = cr:fill_rule()
		cr:fill_rule'even_odd'
		local hit = cr:in_fill(self.mouse_x, self.mouse_y)
		print(hit)
		dr:fill('#fff', 5)
		cr:fill_rule(rule)
	end

	ui:style('xlayer :hot', {
		background_color = '#0ff',
		border_color_left = '#ff0',
		transition_duration = 1,
		transition_border_color_left = true,
	})

end

local function test_css()

	ui:style('*', {
		custom_all = 11,
	})

	ui:style('button', {
		custom_field = 42,
	})

	ui:style('button b1', {
		custom_and = 13,
	})

	ui:style('b1', {
		custom_and = 16, --comes later: overwrite (no specificity)
	})

	ui:style('button', {
		custom_and = 22, --comes later: overwrite (no specificity)
	})

	ui:style('p1 > p2 > b1', {
		custom_parent = 54, --comes later: overwrite (no specificity)
	})


	--ui:style('*', {transition_speed = 1/0})
	--ui:style('*', {font_name = 'Roboto Condensed', font_weigt = 'bold', font_size = 24})
	--b1:update_styles()
	--b2:update_styles()

	local p1 = ui:element{name = 'p1', tags = 'p1'}
	local p2 = ui:element{name = 'p2', tags = 'p2', parent = p1}

	local b1 = ui:button{parent = p2, name = 'b1', tags = 'b1', x = 10, y = 10, w = 100, h = 26}
	local b2 = ui:button{parent = p2, name = 'b2', tags = 'b2', x = 20, y = 20, w = 100, h = 26}
	local sel = ui:selector('p1 > p2 > b1')
	assert(sel:selects(b1) == true)
	print('b1.custom_all', b1.custom_all)
	print('b2.custom_all', b2.custom_all)
	print('b1.custom_field', b1.custom_field)
	print('b1.custom_and', b1.custom_and)
	print('b2.custom_and', b2.custom_and)
	--print('b2.custom_and', b2.custom_and)
	--ui:style('button', {h = 26})

	local b1 = ui:button{parent = win, name = 'b1', tags = 'b1', text = 'B1',
		x = 10, y = 10, w = 100, h = 26}
	local b2 = ui:button{parent = win, name = 'b2', tags = 'b2', text = 'B2',
		x = 20, y = 50, w = 100, h = 26}

	b1.z_order = 2
end

local function test_drag()

	--win.native_window:show()
	--win.native_window:frame_rect(nil, 100, nil, 400)

	--local win = app:window{x = 840, y = 500, w = 900, h = 400, visible = false}
	--local win = ui:window{native_window = win}

	ui:style('test', {
		border_width = 10,
		--border_color = '#333',
	})

	ui:style('test :active', {
		border_color = '#fff',
	})

	ui:style('test :hot', {
		background_color = '#ff0',
	})

	ui:style('test :dragging', {
		background_color = '#00f',
	})

	ui:style('test :dropping', {
		background_color = '#f0f',
	})

	ui:style('test :drag_source', {
		border_color = '#0ff',
	})

	ui:style('test :drop_target', {
		border_color = '#ff0',
	})

	ui:style('test :drag_layer', {
		border_width = 20,
		border_color = '#ccc',
	})

	local layer1 = ui:layer{
		tags = 'layer1 test',
		x = 50, y = 50, w = 200, h = 200,
		parent = win,
		z_order = 1,
		background_color = '#f66',
		clip_content = false,
		rotation_cx = 100,
		rotation_cy = 100,
		rotation = 80,
	}

	local layer2 = ui:layer{
		tags = 'layer2 test',
		x = 300,	y = 50, w = 200, h = 200,
		parent = win,
		z_order = 0,
		background_color = '#f00',
		rotation = 10,
	}

	local layer = ui:layer{
		tags = 'drag_layer test',
		x = 50, y = 0, w = 100, h = 100,
		parent = layer1,
		z_parent = win,
		z_order = 20,
	}

	for _,layer in ipairs{layer1, layer2, layer} do

		layer.drag_threshold = 0

		function layer:start_drag(button, mx, my, area)
			print('start_drag          ', button, mx, my, area)
			--self.parent = self.window
			self:to_front()
			return self
		end

		function layer:drop(widget, mx, my, area)
			print('drop              ', widget.id, mx, my, area)
			local x, y = self:to_content(widget:to_other(self, 0, 0))
			--widget.parent = self
			widget.x = x
			widget.y = y
		end

		function layer:accept_drop_widget(drop_target, mx, my, area)
			local accept = drop_target ~= self
			--print('accept_drop_widget', self.id, drop_target.id, mx, my, area, '->', accept)
			return accept
		end

		function layer:enter_drop_target(drop_target, mx, my, area)
			print('enter_drop_target', self.id, drop_target.id, mx, my, area)
		end

		function layer:leave_drop_target(drop_target)
			print('leave_drop_target', self.id, drop_target.id)
		end

		function layer:accept_drag_widget(drag_widget, mx, my, area)
			local accept = drag_widget ~= self
			--print('accepts_drag_widget', drag_object.id, mx, my, area, '->', accept)
			return accept
		end

		function layer:after_drag(mx, my)
			print('drag             ', self.id, mx, my)
			--local mx, my = self:to_window(mx, my)
			--self.x = mx
			--self.y = my
			--self:invalidate()
		end

		--function layer1:drag(button, mx, my, area) end --stub
		--function layer1:drop(drag_object, mx, my, area) end --stub
		--function layer1:cancel(drag_object) end --stub

		function layer:mousedown(mx, my, area)
			--print('mousedown', time.clock(), self.id, button, mx, my, area)
			self.active = true
		end

		function layer:mouseup(mx, my, area)
			self.active = false
		end
		--function layer:mousemove(...) print('mousemove', time.clock(), self.id, ...) end
		--function layer:mouseup(...) print('mouseup', time.clock(), self.id, ...) end

	end

	win.native_window:show()
end

local function test_text()

	local layer = ui:layer{
		x = 100, y = 100,
		w = 200, h = 200,
		text = 'gftjim;\nqTv\nxyZ',
		text_color = '#fff',
		font_size = 36,
		border_width = 1,
		border_color = '#fff',
		parent = win,
	}

	function layer:after_draw_content()
		local cr = self.window.cr
		cr:rgb(1, 1, 1)
		cr:line_width(1)
		cr:rectangle(self:text_bounding_box())
		cr:stroke()
	end

end

local function test_flexbox_inside_null()

	local parent = ui:layer{
		parent = win,
		x = 100, y = 100,
		w = 200, h = 200,
		border_width = 1,
		border_color = '#333',
	}

	local textwrap = ui:layer{
		parent = parent,
		text = 'Hello World! Hello World! Hello World! Hello World! \nxxxxxxxxxxx\nxxxxxxxxx\nxxxxx\nxxxxxxxxxxxxx',
		w = 100,
		h = 100,
		--align = 'b r',
		--min_w = 100,
		--max_w = 1000,
		--min_h = 150,
		--max_h = 1/0,
		layout = 'flexbox',
		border_width = 10,
		padding = 10,
	}
end

local function test_flexbox()

	local flex = ui:layer{
		parent = win,
		layout = 'flexbox',
		flex_wrap = true,
		flex_axis = 'y',
		align_main = 'stretch',
		align_cross = 'center',
		align_lines = 'start',
		border_width = 20,
		padding = 20,
		border_color = '#333',
		x = 40, y = 40,
		min_cw = win.cw - 120,
		min_ch = win.ch - 120,
		xx = 0,
		style = {
			transition_duration = 1,
			transition_times = 1/0,
			xx = 100,
			transition_xx = true,
		},
	}

	flex:inherit()

	for i = 1, 50 do
		local r = math.random(10)
		local b = ui:layer{
			parent = flex,
			layout = 'textbox',
			border_width = 1,
			min_cw = r * 12,
			min_ch = r * 6,
			break_after = i == 50,
			break_before = i == 50,
			--padding = 10,
			--flex_align = i == 3 and 'stretch' or i == 1 and 'bottom' or 'baseline',
			--layout = 'text_wrap',
			--text = ('x'):rep(r) .. ' ' .. ('x'):rep(10-r),
			flex_fr = r,
			--font_size = 10 + i * 3,
		}

		b:inherit()
	end

	function win:client_resized()
		flex.min_cw = win.cw - 120
		flex.min_ch = win.ch - 120
		self:invalidate()
	end

end

local function test_grid_layout()

	local grid = ui:layer{
		parent = win,

		layout = 'grid',
		grid_wrap = 5,
		grid_flow = 'yrb',
		--grid_cols = {10, 1, 1, 5, 10},
		grid_col_gap = 10,
		grid_row_gap = 5,
		grid_align_cols = 'space_around',
		grid_align_rows = 'space_around',

		border_width = 20,
		padding = 20,
		border_color = '#333',
		x = 40, y = 40,
		min_cw = win.cw - 120,
		min_ch = win.ch - 120,
	}

	for i = 1, 10 do
		local r = math.random(10)
		local b = ui:layer{
			parent = grid,
			layout = 'textbox',
			border_width = 1,
			text = i..' '..('xx'):rep(r),

			grid_col_span = i % 2 + 1,
			grid_row_span = 2 - i % 2,
		}
	end

	function win:client_resized()
		grid.min_cw = win.cw - 120
		grid.min_ch = win.ch - 120
		self:invalidate()
	end

end

local function test_widgets_flex()

	win.view.layout = 'grid'
	win.view.padding = 40
	win.view.grid_wrap = 3
	win.view.grid_col_gap = 20
	win.view.grid_row_gap = 20
	win.view.grid_rows = {0}

	ui:button{
		parent = win,
		text = 'Imma button',
	}

	ui:checkbox{
		parent = win,
		label =  {text = 'Check me', nowrap = false},
		checked = true,
	}

	ui:choicebutton{
		parent = win,
		values = {
			'Choose me',
			'No, me!',
			{text = 'Me, me, me!', value = 'val3'},
		},
		button = {nowrap = true},
		selected = 'val3',
	}

	ui:radiobutton{
		parent = win,
		label =  {text = 'Radio me'},
		checked = true,
		radio_group = 1,
		align = 'right',
	}

	ui:slider{
		parent = win,
		position = 3, size = 10,
		step_labels = {Low = 0, Medium = 5, High = 10},
		step = 2,
	}

	ui:tablist{
		parent = win,
		tabs = {
			{title = {text = 'Tab 1-1'}},
			{title = {text = 'Tab 1-2'}},
		},
	}

	ui:tablist{
		parent = win,
		tabs = {
			{title = {text = 'Tab 2-1'}},
			{title = {text = 'Tab 2-2'}},
		},
	}

	local s = [[
Lorem ipsum dolor sit amet, quod oblique vivendum ex sed. Impedit nominavi maluisset sea ut. Utroque apeirian maluisset cum ut. Nihil appellantur at his, fugit noluisse eu vel, mazim mandamus ex quo.

Mei malis eruditi ne. Movet volumus instructior ea nec. Vel cu minimum molestie atomorum, pro iudico facilisi et, sea elitr partiendo at. An has fugit assum accumsan.

Ne mea nobis scaevola partiendo, sit ei accusamus expetendis. Omnium repudiandae intellegebat ad eos, qui ad erant luptatum, nec an wisi atqui adipiscing. Mei ad ludus semper timeam, ei quas phaedrum liberavisse his, dolorum fierent nominavi an nec. Quod summo novum eam et, ullum choro soluta nec ex. Soleat conceptam pro ut, enim audire definiebas ad nec. Vis an equidem torquatos, at erat voluptatibus eam.]]

	local sb = ui:scrollbox{
		parent = win,
		auto_w = true,
		content = {
			layout = 'textbox',
			text_align_x = 'left',
			text_align_y = 'top',
			text = s,
		},
	}

	ui:editbox{
		parent = win,
	}

	local rows = {}
	for i = 1,20 do table.insert(rows, {i, i}) end
	ui:grid{
		parent = win,
		rows = rows,
		cols = {
			{text = 'col1', w = 150},
			{text = 'col2', w = 150},
		},
		freeze_col = 2,
		--multi_select = true,
		--cell_select = true,
		--cell_class = ui.editbox,
		--editable = true,
	}

	--[==[
	ui:editbox{
		parent = win,
		multiline = true,
	}

	ui:dropdown{
		parent = win,
		picker = {rows = {'Row 1', 'Row 2', 'Row 3'}},
	}
	]==]

end

--test_css()
--test_layers()
--test_drag()
--test_text()
--test_flexbox()
--test_grid_layout()
test_widgets_flex()
win:show()
ui:run()
ui:free()
