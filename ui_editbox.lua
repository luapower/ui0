--go @ luajit ui_editbox.lua

--Edit Box widget based on tr.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local tr = require'tr'
local glue = require'glue'

local push = table.insert
local pop = table.remove
clamp = glue.clamp
snap = glue.snap

local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox
editbox.iswidget = true

--features

editbox.password = false

--metrics & colors

editbox.text_align_x = 'auto'
editbox.align_y = 'center'
editbox.min_ch = 1000
editbox.w = 180
editbox.h = 1000

editbox.tags = 'standalone'

ui:style('editbox standalone > editbox_border', {
	visible = true,
})

--animation

ui:style('editbox standalone, editbox standalone :hot', {
	transition_border_color = true,
	transition_duration_border_color = .5,
})

editbox.focusable = true
editbox.text_selectable = true
editbox.text_editable = true
editbox.nowrap = true
editbox.clip_content = true

--filtering the input text.

--filter newlines and ASCII control chars from the text.
function editbox:override_filter_input_text(inherited, s)
	if not self.multiline then
		return
			s:gsub('\u{2029}', ' ') --PS
			 :gsub('\u{2028}', ' ') --LS
			 :gsub('[%z\1-\31\127]', '')
	else
		return inherited(self, s)
	end
end

--password mask drawing & hit testing

function editbox:override_caret_rect(inherited)
	local x, y, w, h = inherited(self)
	if self.password then
		x, y = self:text_to_mask(x, y)
		w = self.insert_mode and self:password_char_advance_x() or 1
		if cursor:rtl() then
			x = x - w
		end
		x = snap(x)
		y = snap(y)
	end
	return x, y, w, h
end

--Password masking works by drawing fixed-width dots in place of actual
--characters. Because cursor placement and hit-testing must continue
--to work over these markers, we have to translate from "text space" (where
--the original cursor positions are) to "mask space" (where the fixed-width
--visual cursor positons are) in order to draw the cursor and the selection
--rectangles. We also need to translate back to text space for hit-testing.

--compute the text-space to mask-space mappings on each text sync.
function editbox:sync_password_mask()
	if not self.selection then return end
	local segs = self.selection.segments
	if segs.lines.pw_cursor_is then return end
	segs.lines.pw_cursor_is = {}
	segs.lines.pw_cursor_xs = {}
	local i = 0
	for _,x in segs:cursor_xs() do
		segs.lines.pw_cursor_is[snap(x, 1/256)] = i
		segs.lines.pw_cursor_xs[i] = x
		i = i + 1
	end
end

function editbox:password_char_advance_x()
	--TODO: maybe use the min(w, h) of the "M" char here?
	return self.text_selection.segments.text_runs[1].font_size * .75
end

--convert "text space" cursor coordinates to "mask space" coordinates.
--NOTE: input must be an exact cursor position.
function editbox:text_to_mask(x, y)
	if self.password then
		local segs = self.selection.segments
		local line_x = segs:line_pos(1)
		local i = segs.lines.pw_cursor_is[snap(x - line_x, 1/256)]
		x = line_x + i * self:password_char_advance_x()
	end
	return x, y
end

--convert "mask space" coordinates to "text space" coordinates.
--NOTE: input can be arbitrary but output is snapped to a cursor position.
function editbox:mask_to_text(x, y)
	if self.password then
		local segs = self:sync_text_shape()
		local line_x = segs:line_pos(1)
		local w = self:password_char_advance_x()
		local i = snap(x - line_x, w) / w
		local i = clamp(i, 0, #segs.lines.pw_cursor_xs)
		x = line_x + segs.lines.pw_cursor_xs[i]
	end
	return x, y
end

function editbox:draw_password_char(cr, i, w, h)
	cr:new_path()
	cr:circle(w / 2, h / 2, math.min(w, h) * .3)
	cr:rgba(self.ui:rgba(self.text_color))
	cr:fill()
end

function editbox:draw_password_mask(cr)
	local w = self:password_char_advance_x()
	local h = self.ch
	local segs = self.text_selection.segments
	local x = segs:line_pos(1)
	cr:save()
	cr:translate(x, 0)
	for i = 0, #segs.lines.pw_cursor_xs-1 do
		self:draw_password_char(cr, i, w, h)
		cr:translate(w, 0)
	end
	cr:restore()
end

function editbox:override_draw_text(inherited, cr)
	if self.password then
		self:draw_password_mask(cr)
	else
		inherited(self, cr)
	end
end

function editbox:after_sync_text_align()
	if self.password then
		self:sync_password_mask()
	end
end

--border layer

local border = ui.layer:subclass'editbox_border'
editbox.border_layer_class = border

border.border_width_bottom = 1
border.border_color = '#000'

ui:style('editbox standalone > editbox_border', {
	border_color = '#333',
	border_width_bottom = 1,
})

ui:style('editbox standalone :focused > editbox_border', {
	border_color = '#fff',
	background_color = '#040404', --to cover the shadow
})

ui:style('editbox standalone :focused > editbox_border', {
	shadow_blur = 1,
	shadow_y = 4,
	shadow_color = '#111',
})

function editbox:create_border_layer()
	return self.border_layer_class(self.ui, {
		parent = self,
		editbox = self,
		activable = false,
	}, self.border_layer)
end

function editbox:after_init(ui, t)
	self.border_layer = self:create_border_layer()
end

--cue layer

editbox.show_cue_when_focused = false

ui:style('editbox > cue_layer', {
	text_color = '#666',
})

function editbox:get_cue()
	return self.cue_layer.text
end
function editbox:set_cue(s)
	self.cue_layer.text = s
end
editbox:instance_only'cue'

editbox.cue_layer_class = ui.layer

editbox:init_ignore{cue=1}

function editbox:create_cue_layer()
	local cue_layer = self.cue_layer_class(self.ui, {
		tags = 'cue_layer',
		parent = self,
		editbox = self,
		activable = false,
		nowrap = true,
	}, self.cue_layer)

	function cue_layer:before_sync_layout()
		local ed = self.editbox
		self.visible =
			(not ed.show_cue_when_focused or ed.focused)
			and ed.text_len == 0
		if self.visible then
			self.text_align_x = ed.text_align_x
			self.text_align_y = ed.text_align_y
			self.w = ed.cw
			self.h = ed.ch
		end
	end

	return cue_layer
end

function editbox:after_init(ui, t)
	self.cue_layer = self:create_cue_layer()
	self.cue = t.cue
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	win.x = 500
	win.w = 300
	win.h = 900

	ui:add_font_file('media/fonts/FSEX300.ttf', 'fixedsys')
	local x, y = 10, 10
	local function xy()
		local editbox = win.view[#win.view]
		y = y + 30 + 10
		if y + 30 + 10 > win.ch then
			x = x + editbox.y + 10
		end
	end

	local s = 'abcd efgh ijkl mnop qrst uvw xyz 0123 4567 8901 2345'

	--defaults all-around.
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
		cue = 'Type text here...',
	}
	xy()

	--maxlen: truncate initial text. prevent editing past maxlen.
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
		maxlen = 5,
	}
	xy()

	--right align
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
		text_align_x = 'right',
	}
	xy()

	--center align
	ui:editbox{
		x = x, y = y, parent = win,
		text = 'Hello World!',
		text_align_x = 'center',
	}
	xy()

	--scrolling, left align
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
	}
	xy()

	--scrolling, right align
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
		text_align_x = 'right',
	}
	xy()

	--scrolling, center align
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
		text_align_x = 'center',
	}
	xy()

	local s = '0123 4567 8901 2345'

	--[[
	--password, scrolling, left align (the only alignment supported)
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
		password = true,
		text_align_x = 'right', --overriden!
	}
	xy()
	]]

	--invalid font
	ui:editbox{
		x = x, y = y, parent = win,
		font = 'Invalid Font,20',
	}
	xy()

	ui:add_font_file('media/fonts/amiri-regular.ttf', 'Amiri')

	--rtl, align=auto
	ui:editbox{
		x = x, y = y, parent = win,
		font = 'Amiri,20',
		text = 'السَّلَامُ عَلَيْكُمْ',
	}
	xy()

end) end
