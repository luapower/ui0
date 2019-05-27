
local time = require'time'
local ui = require'ui'
ui.use_google_fonts = true
ui = ui()

local win = ui:window{
	w = 800, h = 600,
	--transparent = true, frame = false,
}

function win:keydown(key)
	if key == 'esc' then
		self:close()
	end
end

win.view.padding = 20

local scale = 2
local pad = 0

local layer = ui:layer{

	parent = win,

	--stable init order for interdependent properties
	cx = 100 * scale,
	cy = 100 * scale,
	x = 0, y = 0,
	w = 0, h = 0,
	cw = 200 - pad * 2,
	ch = 200 - pad * 2,

	--has no effect on null layouts
	min_cw = 400,
	min_ch = 300,

	--padding_left = 20,
	padding = pad,

	rotation = 0,
	rotation_cx = -80,
	rotation_cy = -80,

	scale = scale,
	scale_cx = 100,
	scale_cy = 100,

	snap_x = true,
	snap_y = false,

	--border_width_right = 1,
	border_width = 10,
	--border_color_left = '#f00',
	border_color = '#fff',
	corner_radius_bottom_right = 30,
	corner_radius = 5,

	border_dash = {4, 3},
	border_dash_offset = 1,

	--background_type = 'color',
	background_color = '#639',

	background_type = 'gradient',
	background_x1 = 0,
	background_y1 = 0,
	background_x2 = 0,
	background_y2 = 1,
	background_r1 = 50,
	background_r2 = 100,
	background_color_stops = {0, '#ff0'}, --, 1, '#0ff'},

	background_scale = 100,

	--text = 'Hello',
	font = 'Open Sans Bold',
	font_size = 100,

	clip_content = 'padding',
	opacity = 0.5,
	--operator = 'xor',

	shadow_color = '#000',
	shadow_x = 2,
	shadow_y = 2,
	shadow_blur = 1,
	shadow_content = true,
	shadow_inset = true,

}

function win:before_draw()
	local r = time.clock() * 60
	--layer.rotation = r
	--layer.x = 100 + r % 10
	--layer.y = 100 + r % 10
	--layer.border_dash_offset = r
	self:invalidate()
end

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

--keep showing fps in the titlebar every second.
ui:runevery(1, function()
	if win.dead then
		ui:quit()
	else
		win:invalidate()
	end
end)


ui:run()

ui:free()

require'layerlib_h'.memreport()

--[[

		set_border_line_to=1,

		get_background_image=1,
		set_background_image=1,

		get_background_hittable    =1,
		get_background_operator    =1,
		get_background_clip_border_offset=1,
		get_background_x           =1,
		get_background_y           =1,
		get_background_rotation    =1,
		get_background_rotation_cx =1,
		get_background_rotation_cy =1,
		get_background_scale       =1,
		get_background_scale_cx    =1,
		get_background_scale_cy    =1,
		get_background_extend      =1,

		set_background_hittable    =1,
		set_background_operator    =1,
		set_background_clip_border_offset=1,
		set_background_x           =1,
		set_background_y           =1,
		set_background_rotation    =1,
		set_background_rotation_cx =1,
		set_background_rotation_cy =1,
		set_background_scale       =1,
		set_background_scale_cx    =1,
		set_background_scale_cy    =1,
		set_background_extend      =1,

		--shadows

		get_shadow_x       =1,
		get_shadow_y       =1,
		get_shadow_color   =1,
		get_shadow_blur    =1,
		get_shadow_passes  =1,
		get_shadow_inset   =1,
		get_shadow_content =1,

		set_shadow_x       =1,
		set_shadow_y       =1,
		set_shadow_color   =1,
		set_shadow_blur    =1,
		set_shadow_passes  =1,
		set_shadow_inset   =1,
		set_shadow_content =1,

		--text

		get_text_utf32=1,
		get_text_utf32_len=1,
		set_text_utf32=1,

		set_text_utf8=1,
		get_text_utf8=1,
		get_text_utf8_len=1,

		get_text_maxlen=1,
		set_text_maxlen=1,

		get_text_span_count=1,
		set_text_span_count=1,

		get_text_span_feature_count=1,
		clear_text_span_features=1,
		get_text_span_feature=1,
		add_text_span_feature=1,

		get_text_span_offset            =1,
		get_text_span_font_id           =1,
		get_text_span_font_size         =1,
		get_text_span_script            =1,
		get_text_span_lang              =1,
		get_text_span_dir               =1,
		get_text_span_line_spacing      =1,
		get_text_span_hardline_spacing  =1,
		get_text_span_paragraph_spacing =1,
		get_text_span_nowrap            =1,
		get_text_span_color             =1,
		get_text_span_opacity           =1,
		get_text_span_operator          =1,

		set_text_span_offset            =1,
		set_text_span_font_id           =1,
		set_text_span_font_size         =1,
		set_text_span_script            =1,
		set_text_span_lang              =1,
		set_text_span_dir               =1,
		set_text_span_line_spacing      =1,
		set_text_span_hardline_spacing  =1,
		set_text_span_paragraph_spacing =1,
		set_text_span_nowrap            =1,
		set_text_span_color             =1,
		set_text_span_opacity           =1,
		set_text_span_operator          =1,

		get_text_align_x=1,
		get_text_align_y=1,

		set_text_align_x=1,
		set_text_align_y=1,

		get_text_caret_width=1,
		get_text_caret_color=1,
		get_text_caret_insert_mode=1,
		get_text_selectable=1,

		set_text_caret_width=1,
		set_text_caret_color=1,
		set_text_caret_insert_mode=1,
		set_text_selectable=1,

		--layouts

		set_layout_type=1,
		get_layout_type=1,

		get_align_items_x =1,
		get_align_items_y =1,
		get_item_align_x  =1,
		get_item_align_y  =1,

		set_align_items_x =1,
		set_align_items_y =1,
		set_item_align_x  =1,
		set_item_align_y  =1,

		get_flex_flow=1,
		set_flex_flow=1,

		get_flex_wrap=1,
		set_flex_wrap=1,

		get_fr=1,
		set_fr=1,

		get_break_before=1,
		get_break_after=1,

		set_break_before=1,
		set_break_after=1,

		get_grid_col_fr_count=1,
		get_grid_row_fr_count=1,

		set_grid_col_fr_count=1,
		set_grid_row_fr_count=1,

		get_grid_col_fr=1,
		get_grid_row_fr=1,

		set_grid_col_fr=1,
		set_grid_row_fr=1,

		get_grid_col_gap=1,
		get_grid_row_gap=1,

		set_grid_col_gap=1,
		set_grid_row_gap=1,

		get_grid_flow=1,
		set_grid_flow=1,

		get_grid_wrap=1,
		set_grid_wrap=1,

		get_grid_col=1,
		get_grid_row=1,

		set_grid_col=1,
		set_grid_row=1,

		get_grid_col_span=1,
		get_grid_row_span=1,

		set_grid_col_span=1,
		set_grid_row_span=1,
]]


