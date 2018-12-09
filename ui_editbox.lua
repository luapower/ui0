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

editbox.focusable = true
editbox.text_selectable = true
editbox.text_editable = true

--features

editbox.password = false

--metrics & colors

editbox.text_align_x = 'left'
editbox.align_y = 'center'
editbox.padding = 4
editbox.padding_left = 0
editbox.padding_right = 1
editbox.min_ch = 16
editbox.w = 180
editbox.h = 24
editbox.border_color = '#000'

editbox.tags = 'standalone'

ui:style('editbox standalone, editbox_scrollbox standalone', {
	border_color = '#333',
})

ui:style('editbox standalone', {
	border_width_bottom = 1,
})

ui:style('editbox_scrollbox standalone', {
	border_width = 1,
})

--keep the same padding for the multiline editbox.
ui:style('editbox_scrollbox > editbox', {
	padding = 0,
	padding_left = 0,
	padding_right = 0,
})
ui:style('editbox_scrollbox', {
	padding = 1,
})
ui:style('editbox_scrollbox > scrollbox_view', {
	padding = 3,
	padding_left = 5,
	padding_right = 5,
})

ui:style([[
	editbox standalone :focused,
	editbox_scrollbox standalone :child_focused
]], {
	border_color = '#fff',
	background_color = '#040404', --to cover the shadow
})

ui:style('editbox standalone :focused', {
	shadow_blur = 1,
	shadow_y = 4,
	shadow_color = '#111',
})

--animation

ui:style([[
	editbox standalone, editbox_scrollbox standalone,
	editbox standalone :hot, editbox_scrollbox standalone :hot
]], {
	transition_border_color = true,
	transition_duration_border_color = .5,
})

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

--multiline mode: wrap the editbox in a scrollbox.

editbox:stored_property'multiline'
editbox:instance_only'multiline'

function editbox:get_multiline()
	return self._multiline and not self.password
end

ui:style('editbox multiline', {
	text_align_x = 'left',
	text_align_y = 'top',
})

editbox.scrollbox_class = ui.scrollbox

function editbox:create_scrollbox()
	return self.scrollbox_class(self.parent, {
		tags = 'editbox_scrollbox',
		content = self,
		editbox = self,
		auto_w = true,
		min_cw = self.min_cw,
		min_ch = self.min_ch,
		x = self.x,
		y = self.y,
		w = self.w,
		h = self.h,
	}, self.scrollbox)
end

function editbox:after_set_multiline(multiline)
	if multiline then
		self.scrollbox = self:create_scrollbox()
		self:settag('multiline', true)
		if self.tags.standalone then
			self:settag('standalone', false)
			self.scrollbox:settag('standalone', true)
		end
		self.clip_content = false --enable real (strict) bounding box
		self.layout = 'textbox'
	else
		self.layout = false
		self.nowrap = true
		self.clip_content = false
		if self.scrollbox then
			self:settag('multiline', false)
			if self.scrollbox.tags.standalone then
				self:settag('standalone', true)
			end
			self.parent = self.scrollbox.parent
			self.scrollbox:free()
			self.scrollbox = false
		end
	end
end

--sync'ing

function editbox:text_visible()
	return true --always sync, even for the empty string.
end

function editbox:caret_rect()
	local cursor = self.selection.cursor2
	local x, y, w, h = cursor:rect()
	if self.password then
		x, y = self:text_to_mask(x, y)
		w = self.insert_mode and self:password_char_advance_x() or 1
		if cursor:rtl() then
			x = x - w
		end
	end
	return snap(x), snap(y), w, h
end

function editbox:caret_scroll_rect()
	local x, y, w, h = self:caret_rect()
	--enlarge the caret rect to contain the line spacing.
	local line = self.selection.cursor2.seg.line
	local y = y + line.ascent - line.spaced_ascent
	local h = line.spaced_ascent - line.spaced_descent
	return x, y, w, h
end


--password mask drawing & hit testing

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
	return self.selection.segments.text_runs[1].font_size * .75
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
	local segs = self.selection.segments
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
		self.visible = ed.text_len == 0
			and (not ed.show_cue_when_focused or ed.focused)
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
		y = y + editbox.h + 10
		if y + editbox.h + 10 > win.ch then
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

	--password, scrolling, left align (the only alignment supported)
	ui:editbox{
		x = x, y = y, parent = win,
		text = s,
		password = true,
		text_align_x = 'right', --overriden!
	}
	xy()

	--invalid font
	ui:editbox{
		x = x, y = y, parent = win,
		font = 'Invalid Font,20',
	}
	xy()

	ui:add_font_file('media/fonts/amiri-regular.ttf', 'Amiri')

	--rtl
	ui:editbox{
		x = x, y = y, parent = win,
		font = 'Amiri,20',
		text = 'السَّلَامُ عَلَيْكُمْ',
		text_align_x = 'right',
		text_dir = 'rtl',
	}
	xy()

	--multiline
	ui:editbox{
		x = x, y = y, parent = win,
		h = 100,
		parent = win,
		text = ('HelloWorldHelloWorldHelloWorld! '):rep(20),
		multiline = true,
	}
	xy()

	--multiline rtl
	ui:editbox{
		x = x, y = y, parent = win,
		h = 100,
		parent = win,
		text = 'HelloHelloHelloWorld! Enter\nLine2 Par\u{2029}NextPar', --(('Hello World!! '):rep(2)..'Enter \n'):rep(1),
		multiline = true,
		cue = 'Type text here...',
	}
	xy()

	ui:add_font_file('media/fonts/amiri-regular.ttf', 'Amiri')
	ui:editbox{
		x = x, y = y, parent = win,
		h = 200,
		parent = win,
		font = 'Amiri,22',
		unique_offsets = false,
		line_spacing = .9,
		text = 'As-salāmu ʿalaykum! ال [( مف )] اتيح Hello Hello Hello Hello World! 123 السَّلَامُ عَلَيْكُمْ',
		multiline = true,
		cue = 'Type text here...',
	}
	xy()

end) end
