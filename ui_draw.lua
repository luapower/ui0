
--themed drawing API
--Written by Cosmin Apreutesei. Public Domain.

local color = require'color'
local glue = require'glue'

local draw = {}

function draw:new()
	local o = {}
	for k,v in pairs(self) do
		o[k] = v
	end
	return o
end

draw.themes = {}
draw.default = {} --theme defaults, declared inline

draw.themes.dark = glue.inherit({
	window_bg     = '#000000',
	faint_bg      = '#ffffff33',
	normal_bg     = '#ffffff4c',
	normal_fg     = '#ffffff',
	default_bg    = '#ffffff8c',
	default_fg    = '#ffffff',
	normal_border = '#ffffff66',
	hot_bg        = '#ffffff99',
 	hot_fg        = '#000000',
	selected_bg   = '#ffffff',
	selected_fg   = '#000000',
	disabled_bg   = '#ffffff4c',
	disabled_fg   = '#999999',
	error_bg      = '#ff0000b2',
	error_fg      = '#ffffff',
}, draw.default)

draw.themes.light = glue.inherit({
	window_bg     = '#ffffff',
	faint_bg      = '#00000033',
	normal_bg     = '#0000004c',
	normal_fg     = '#000000',
	default_bg    = '#0000008c',
	default_fg    = '#000000',
	normal_border = '#00000066',
	hot_bg        = '#00000099',
	hot_fg        = '#ffffff',
	selected_bg   = '#000000e5',
	selected_fg   = '#ffffff',
	disabled_bg   = '#0000004c',
	disabled_fg   = '#666666',
	error_bg      = '#ff0000b2',
	error_fg      = '#ffffff',
}, draw.default)

draw.default_theme = draw.themes.dark
draw.theme = draw.default_theme

--themed color setting (stateful, so private API)

local function parse_color(c, g, b, a)
	if type(c) == 'string' then
		return color.string_to_rgba(c)
	elseif type(c) == 'table' then
		local r, g, b, a = unpack(c)
		return r, g, b, a or 1
	else
		return c, g, b, a or 1
	end
end

function draw:_setcolor(color, g, b, a)
	self.cr:rgba(parse_color(self.theme[color] or color, g, b, a))
end

--themed font setting (stateful, so private API)

local function parse_font(font, default_font)
	local name, size, weight, slant =
		font:match'([^,]*),?([^,]*),?([^,]*),?([^,]*)'
	local t = {}
	t.name = assert(str(name) or default_font:match'^(.-),')
	t.size = tonumber(str(size)) or default_font:match',(.*)$'
	t.weight = str(weight) or 'normal'
	t.slant = str(slant) or 'normal'
	return t
end

local fonts = setmetatable({}, {__mode = 'kv'})

local function load_font(font, default_font)
	font = font or default_font
	local t = fonts[font]
	if not t then
		if type(font) == 'string' then
			t = parse_font(font, default_font)
		elseif type(font) == 'number' then
			t = parse_font(default_font, default_font)
			t.size = font
		end
		fonts[font] = t
	end
	return t
end

draw.default.default_font = 'Open Sans,14'

function draw:_setfont(font)
	font = load_font(self.theme[font] or font, self.theme.default_font)
	self:_backend_load_font(font.name, font.weight, font.slant)
	self.cr:font_size(font.size)
	font.extents = font.extents or self.cr:font_extents()
	return font
end

--themed stateless fill & stroke

function draw:fill(color)
	self:_setcolor(color or 'normal_bg')
	self.cr:fill()
end

function draw:stroke(color, line_width)
	self:_setcolor(color or 'normal_fg')
	self.cr:line_width(line_width or 1)
	self.cr:stroke()
end

function draw:fillstroke(fill_color, stroke_color, line_width)
	if fill_color and stroke_color then
		self:_setcolor(fill_color)
		self.cr:fill_preserve()
		self:stroke(stroke_color, line_width)
	elseif fill_color then
		self:fill(fill_color)
	elseif stroke_color then
		self:stroke(stroke_color, line_width)
	else
		self:fill()
	end
end

--themed stateless basic shapes

function draw:rect(x, y, w, h, ...)
	self.cr:rectangle(x, y, w, h)
	self:fillstroke(...)
end

function draw:dot(x, y, r, ...)
	self:rect(x-r, y-r, 2*r, 2*r, ...)
end

function draw:circle(x, y, r, ...)
	self.cr:circle(x, y, r)
	self:fillstroke(...)
end

function draw:line(x1, y1, x2, y2, ...)
	self.cr:move_to(x1, y1)
	self.cr:line_to(x2, y2)
	self:stroke(...)
end

function draw:curve(x1, y1, x2, y2, x3, y3, x4, y4, ...)
	self.cr:move_to(x1, y1)
	self.cr:curve_to(x2, y2, x3, y3, x4, y4)
	self:stroke(...)
end

--themed multi-line self-aligned and box-aligned text

local function round(x)
	return math.floor(x + 0.5)
end

local function text_args(self, s, font, color, line_spacing)
	s = tostring(s)
	font = self:_setfont(font)
	self:_setcolor(color or 'normal_fg')
	local line_h = font.extents.height * (line_spacing or 1)
	return s, font, line_h
end

function draw:text_extents(s, font, line_h)
	font = self:_setfont(font)
	local w, h = 0, 0
	for s in glue.lines(s) do
		local tw, th, ty = self:_backend_text_extents(s)
		w = math.max(w, tw)
		h = h + ty
	end
	return w, h
end

function draw:_draw_text(x, y, s, align, line_h) --multi-line text
	local cr = self.cr
	for s in glue.lines(s) do
		if align == 'right' then
			local tw = self:_backend_text_extents(s)
			cr:move_to(x - tw, y)
		elseif not align or align == 'center' then
			local tw = self:_backend_text_extents(s)
			cr:move_to(x - round(tw / 2), y)
		elseif align == 'left' then
			cr:move_to(x, y)
		else
			asser(false, 'invalid align')
		end
		self:_backend_show_text(s)
		y = y + line_h
	end
end

function draw:text(x, y, s, font, color, align, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)
	self:_draw_text(x, y, s, align, line_h)
end

function draw:textbox(x, y, w, h, s, font, color, halign, valign, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)

	self.cr:save()
	self.cr:rectangle(x, y, w, h)
	self.cr:clip()

	if halign == 'right' then
		x = x + w
	elseif not halign or halign == 'center' then
		x = x + round(w / 2)
	end

	if valign == 'top' then
		y = y + font.extents.ascent
	else
		local lines_h = 0
		for _ in glue.lines(s) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = y + h - font.extents.descent
		elseif not valign or valign == 'center' then
			local h1 = h + font.extents.ascent - font.extents.descent + lines_h
			y = y + round(h1 / 2)
		else
			assert('invalid valign')
		end
		y = y - lines_h
	end

	self:_draw_text(x, y, s, halign, line_h)

	self.cr:restore()
end

--themed GUI shapes

draw.default.border_width = 1

function draw:border(x, y, w, h, ...)
	local b = self.theme.border_width
	self.cr:rectangle(x-b, y-b, w+2*b, h+2*b)
	self:stroke(...)
end

return draw
