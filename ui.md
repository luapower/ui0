
## `local ui = require'ui'`

Extensible UI toolkit written in Lua with widgets, layouts, styles and animations.

## Status

See [issues](https://github.com/luapower/ui/issues)
and [milestones](https://github.com/luapower/ui/milestones).

## Highlights

  * editable grid that can scroll millions of rows at 60 fps.
  * tab list with animated, moveable, draggable, dockable tabs.
  * extensible rich text editor with BiDi support.
  * consistent Unicode [text rendering][tr] and editing on all platforms.
  * customization with cascading styles, inheritance and composition.
  * declarative transition animations.
  * flexbox and css-grid-like layouts.

## Example

~~~{.lua}
local ui = require'ui'

local win = ui:window{
	cw = 500, ch = 300,
	title = 'UI Demo',
}

ui:button{
	x = 100,
	y = 100,
	parent = win,
	text = 'Close',
	cancel = true,
}

ui:run()
~~~

## Class hierarchy

  * `oo.Object` - [oo]'s base class
     * `ui.object` - ui's base class. includes the [events] mixin.
        * `ui` - this module, also serving as the app singleton
        * `ui.selector` - element selectors
        * `ui.element_list` - lists of elements
        * `ui.stylesheet` - stylesheets
        * `ui.transition` - attribute transitions
        * `ui.element` - adds styling and transitions to objects
           * `ui.window` - top-level windows: a thin layer over [nw]'s windows
              * `ui.popup` - frameless pop-up windows
           * `ui.layer` - the basic UI building block
              * `ui.window.view_class` - a window's top layer
              * any widget

## The ui module/singleton

The [ui] singleton is a thin facade over [nw]'s app singleton. It allows
creating OS windows, quitting the app, creating timers, using the clipboard,
adding fonts, etc.

-------------------------------------- ---------------------------------------
__native properties__

`autoquit, maxfps, app_active,`        these map directly to [nw] app features
`app_visible, caret_blink_time,`       except they are exposed as properties
`displays, main_display,`              instead of methods like in [nw].
`active_display, app_id`

__native methods__

`run, poll, stop, quit, runevery,`     these map directly to [nw] app
`runafter, sleep, activate_app,`       methods.
`hide_app, unhide_app, key,`
`getclipboard, setclipboard,`
`opendialog, savedialog,`
`app_already_running,`
`wakeup_other_app_instances,`
`check_single_app_instance`

__native events__

`quitting, activated, deactivated,`    these map directly to [nw] app
`wakeup, hidden, unhidden,`            events.
`displays_changed`

__font registration__

`ui:add_font_file(...)`                see [tr] for `tr:add_font_file(...)`

`ui:add_mem_font(...)`                 see [tr] for `tr:add_mem_font(...)`
-------------------------------------- ---------------------------------------

## Elements

Elements are objects with styling and transitions and a standard constructor.
Windows and layers are both elements so everything in this section applies
to both.

### Constructing elements

Unlike normal objects, elements have a standardized constructor which takes
the `ui` singleton as arg#1 followed by any number of tables whose fields
are first merged into a single table and then copied over to the element in
lexicographic order. This means that:

  * unknown fields are not discarded, which makes for a convenient way to
  create layers or windows with custom fields.
  * properties are set (i.e. setters are called) in a stable
  (albeit arbitrary) order.
    * this order can be altered with the class method
	 `:init_priority{field->priority}` to accomodate any dependencies between
	 properties.
	 * some properties can be excluded from being automatically set this way
	 with the class method `:init_ignore{field->true}`, in which case they
	 must be set manually in the constructor.
  * the constructor `:init(ui, t)` receives `ui` followed by the merged arg
  table which is also set up to inherit the class, thus providing transparent
  access to defaults.

### Styling

Cascade styling is a mechanism for applying multiple attribute value sets
to matching sets of elements based on matching tag combinations.

#### Tags

Selecting elements for styling is based on element tags only, which are
equivalent to CSS classes (there is no concept of ids or other things to
match on other than tags).

Elements can be initialized with the attribute `tags = 'tag1 tag2 ...'`
similar to the html class attribute. Tags can also be added/removed later
with `elem:settag(tagname, true|false)` or `elem:settags('+tag1 -tag2 ...')`.
A class can also specify additional default tags with
`myclass.tags = 'tag1 tag2 ...'`.

Tags matching the entire hierarchy of class names up to and including
`'element'` are created automatically for each element, so every layer gets
the `'element'` and `'layer'` tags, etc.

#### Selectors

Selector syntax differs from CSS:

  * simple selectors: `'tag1 tag2'` -- in CSS: `.tag1.tag2`
  * parent-child selectors: `'tag1 > tag2'` -- in CSS: `tag1 tag2`

#### Styles

Styles can be added with `ui:style(selector, attr_values)` which adds them
to the default stylesheet `ui.element.stylesheet`. Inline styles can be
set with the `style` attribute when creating the element.

Styles are updated automatically on the next repaint. They can also be
updated manually with `elem:sync_styles()`.

#### Stylesheets

Use `ss = ui:stylesheet()` to create a new stylesheet
and `ss:style(selector, attr_values)` to add styles to it.
Replace `ui.element.stylesheet` to change the styling of the entire app.
Replace `ui.button.stylesheet` to change the styling of all buttons.
Pass `stylesheet` when creating an element to set that element's stylesheet.
Use `ss1:add_stylesheet(ss2)` to add the styles of a stylesheet to another
stylesheet.

#### State tags

Tags that start with `:` are special and are only used for tagging
states like `:hot` and `:selected`. Styles containing such tags are applied
only after all styles containing only normal tags are applied. It's like if
styles containing state tags were added to a second stylesheet that was
included after the default one. This allows overriding base styles without
resetting any matching state styles, so for instance, declaring a new style
for `'mybutton'` will not affect the syle set previously for `'mybutton :hot'`.

### Transition animations

Transitions are about gradually changing the value of an element attribute
from its current value to a new value using linear interpolation. Every
attribute can be animated like that providing it has a data type that can be
interpolated. Currently, numbers, colors and color gradients can be
interpolated, but more data types and interpolator functions can be added
if needed (see the code for that).

Transitions can be created manually with:

~~~{.lua}
	elem:transition(
		attr, val, [duration], [ease], [delay],
		[times], [backval], [blend], [speed], [from]
	)
~~~

or they can be defined declaratively in styles:

-------------------------------- ------------------ ------------------------------------------------------------------
`transition_<attr>`              `nil`              set to `true` to enable transitions for an attribute
`transition_duration`            `0` (disabled)     animation duration (seconds)
`transition_ease`                `'expo out'`       easing function and way (see [easing])
`transition_delay`               `0`                delay before starting (seconds)
`transition_repeat`              `1`                repeat times
`transition_speed`               `1`                speed factor
`transition_blend`               `'replace'`        blend function: `'replace'`, `'restart'`, `'wait'`
-------------------------------- ------------------ ------------------------------------------------------------------

Transition parameters can also be specified for each attribute with
`transition_<param>_<attr>`, eg. `transition_duration_opacity = 2`.


## Windows

[ui] windows are a thin facade over [nw] windows.

Windows are elements, so all element methods and properties apply.

-------------------------------------- ---------------------------------------
`ui:window{...} -> win`                create a window. see [nw] for options.

`win:close()`                          close a window.

`win:free()`                           close & free a window.

__native properties__

`x, y, w, h, cx, cy, cw, ch,`          these map directly to [nw] window
`min_cw, min_ch, max_cw, max_ch,`      features except they are exposed as
`autoquit, visible, fullscreen,`       properties instead of methods like
`enabled, edgesnapping, topmost,`      in [nw].
`title, dead, closeable,`
`activable, minimizable,`
`maximizable, resizeable,`
`fullscreenable, frame,`
`transparent, corner_radius,`
`sticky, dead, active, isminimized,`
`ismaximized, display, cursor`

__native methods__

`frame_rect, client_rect,`             these map directly to [nw] window
`client_to_frame, frame_to_client,`    methods.
`closing, close, show, hide,`
`activate, minimize, maximize,`
`restore, shownormal, raise, lower,`
`to_screen, from_screen`

__native events__

`activated, deactivated, wakeup,`      these map directly to [nw] window
`shown, hidden,`                       events.
`minimized, unminimized,`
`maximized, unmaximized,`
`entered_fullscreen,`
`exited_fullscreen,`
`changed, sizing,`
`frame_rect_changed, frame_moved,`
`frame_resized,`
`client_moved, client_resized,`
`magnets,`
`free_cairo, free_bitmap,`
`scalingfactor_changed`

__element query interface__

`win:find(sel) -> elem_list`           find elements in a window based on a css selector.

`win:each(sel, f)`                     run `f(elem)` for each element selected by a selector.

__mouse state__

`win.mouse_x, win.mouse_y` \           mouse position at the time of last mouse event.
`win:mouse_pos() -> x, y`

__drawing__

`win:sync()`                           synchronize the window and its contents.

`win:draw(cr)`                         draw the window's view layer.

`win:invalidate()`                     request a window repaint.

__child windows__

`win.parent`                           a layer on a different window which this window is positioned relative to.

`win:to_parent(x, y) -> x, y`          convert coords from window's client space to its parent space

`win:from_parent(x, y) -> x, y`        convert coords from window's parent space to its client space

__frameless windows__

`win.move_layer`                       layer which by dragging it moves the window.
-------------------------------------- ---------------------------------------

## Layers

Similar to HTML divs, layers encapsulate all the positioning, drawing,
clipping, hit-testing and input infrastructure necessary for implementing
widgets, and can also be used standalone as layout containers, text labels
or other presentation elements.

Layers are elements, so all element methods and properties apply.

### Configuration

The following attributes can be used to initialize a layer and can also be
changed freely at runtime to change its behavior or appearance.

------------------------------------ ------------------ ------------------------------------------------------------------
__position in layer hierarchy__
`parent`                             `false`            parent: for positioning (if pos_parent=false), painting and clipping
`layer_index`                        `1/0`              preferred index in parent's child list: `1=backmost`, `1/0=frontmost`
`pos_parent`                         `false`            positioning parent (`false` means use `parent`)
__behavior__
`visible`                            `true`             visible and occupies space in the layout
`enabled`                            `true`             looks enabled and can receive input
`activable`                          `true`             can be clicked and hovered (set as hot)
`vscrollable`                        `false`            enable mouse wheel when hot and not focused
`hscrollable`                        `false`            enable mouse horiz. wheel when hot and not focused
`scrollable`                         `false`            can be hit for vscroll or hscroll
`focusable`                          `false`            can be focused
`draggable`                          `true`             can be dragged (still needs to respond to `start_drag()`)
`background_hittable`                `true`             background area receives mouse input even when there's no background
`mousedown_activate`                 `false`            activate/deactivate on left mouse down/up
`drag_threshold`                     `0`                moving distance before start dragging
`max_click_chain`                    `1`                2 for getting doubleclick events, etc.
`tabgroup`                           `0`                tab group, for tab-based navigation
`tabindex`                           `0`                tab order in tab group, for tab-based navigation
`taborder_algorithm`                 `'xy'`             tab order algorithm: `'xy'`, `'yx'`
__content box__
`padding`                            `0`                padding for all sides
`padding_<side>`                     `false`            `left`/`right`/`top`/`bottom` padding override
__sizing & positioning__
`layout`                             `false`            layout model: `false` (none), `'textbox'`, `'flexbox'`, `'grid'`
`min_cw, min_ch`                     `0`                minimum content-box size for flexible layouts
__layout=false__
`x, y, w, h`                         `0`                fixed position & size
__flexbox layout__
`flex_axis`                          `'x'`              main axis of flow: `'x'`, `'y'`
`flex_wrap`                          `false`            line-wrap content
`align_main/_cross/_lines`           `'stretch'`        `'stretch'`, `'start'`/`'t[op]'`/`'l[eft]'`, `'end'`/`'b[ottom]'`/`'r[ight]'`, `'c[enter]'`
`align_main`                         `'stretch'`        main-axis align: `'space_between'`, `'space_around'`, `'space_evenly'`
`align_cross`                        `'stretch'`        cross-axis align: `'baseline'`
`align_lines`                        `'stretch'`        content-align: `'space_between'`, `'space_around'`, `'space_evenly'`
`align_cross_self`                   `false`            item `align_cross` override
`fr`                                 `1`                item stretch fraction for `align_main='stretch'`
__grid layout__
`grid_flow`                          `'x'`              main axis & direction for automatic positioning: `'x'`, `'y'`, `'xr'`, `'yr'`, `'xb'`, `'yb'`, `'xrb'`, `'yrb'`
`grid_wrap`                          `1`                number of rows/columns on the main axis of flow
`grid_cols`                          `{}`               column size fractions `{fr1, ...}` for `align_x='stretch'`
`grid_rows`                          `{}`               row size fractions `{fr1, ...}` for `align_y='stretch'`
`col_gap`                            `0`                gap size between columns
`row_gap`                            `0`                gap size between rows
`grid_pos`                           `nil`              element position in grid: `'[row][/span] [col][/span]'`
`align_x`                            `'stretch'`        `'stretch'`, `'start'`/`'l[eft]'`, `'end'`/`'r[ight]'`, `'c[enter]'`, `'space_between'`, `'space_around'`, `'space_evenly'`
`align_y`                            `'stretch'`        `'stretch'`, `'start'`/`'t[op]'`, `'end'`/`'b[ottom]'`, `'c[enter]'`, `'space_between'`, `'space_around'`, `'space_evenly'`
`align_x_self`, `align_y_self`       `false`            item `align_x` and `align_y` overrides
__transparency & clipping__
`opacity`                            `1`                overall opacity (0..1)
`clip_content`                       `false`            content clip area: `'padding'`/`true`, `'background'`, `false` (don't clip)
__borders__
`border_width`                       `0`                border thickness for all sides
`border_width_<side>`                `false`            `left`/`right`/`top`/`bottom` border thickness override
`corner_radius`                      `0`                border corner radius for all corners
`corner_radius_<corner>`             `false`            `top_left`/`top_right`/`bottom_left`/`bottom_right` corner radius override
`border_color`                       `'#fff'`           border color
`border_color_<side>`                `false`            `left`/`right`/`top`/`bottom` border color override
`border_dash`                        `false`            border dash pattern: `{length1, ...}`
`border_offset`                      `-1`               border stroke position rel. to box edge (-1=inside..1=outside)
`corner_radius_kappa`                `1.2`              smoother rounded corners (1=circle arc)
__background__
`background_type`                    `'color'`          `false`, `'color'`, `'gradient'`, `'radial_gradient'`, `'image'`
`background_x, background_y`         `0`                background offset coords
`background_rotation`                `0`                background rotation angle (radians)
`background_rotation_cx/cy`          `0`                background rotation center coords
`background_scale`                   `1`                background scale factor
`background_scale_cx/cy`             `0`                background scale factor: axis override
`background_color`                   `false`            solid color
`background_colors`                  `false`            gradient: `{[offset1], color1, ...}`
`background_x1/y1/x2/y2`             `0`                linear gradient: end-point coords
`background_cx1/cy1/cx2/cy2`         `0`                radial gradient: end-point coords
`background_r1/r2`                   `0`                radial gradient: radii
`background_image`                   `false`            background image file (requires [libjpeg])
`background_operator`                `'over'`           cairo blending operator
`background_clip_border_offset`      `1`                like `border_offset` but for clipping the background
__shadow__
`shadow_x, shadow_y`                 `0`                shadow offset coords
`shadow_color`                       `'#000'`           shadow color
`shadow_blur`                        `0`                shadow blur size (0=disable)
__text__
`text`                               `false`            text, wrapped around `cw`
`font`                               `'Open Sans,14'`   font spec: `'name [weight] [slant], size'`
`font_name`                          `false`            font override: name
`font_weight`                        `false`            font override: weight (`100..900`, `'bold'`, etc.)
`font_slant`                         `false`            font override: slant (`'italic'`, `'normal'`)
`font_size`                          `false`            font override: size
`text_color`                         `'#fff'`           text color
`line_spacing`                       `1`                multiply factor over line height for lines
`paragraph_spacing`                  `2`                multiply factor over line height for paragraphs
`text_dir`                           `'auto'`           BiDi base direction: `'auto'`, `'rtl'`, `'ltr'`
`nowrap`                             `false`            disable automatic line wrapping
`text_operator`                      `'over'`           blending operator (see [cairo])
`text_align`                         `'c c'`            text x & y alignments: `'l[eft]|c[enter]|r[ight] t[op]|c[enter]|b[ottom]'`
`text_align_x`                       `false`            text x-align override: `'l[eft]'`, `'c[enter]'`, `'r[ight]'`
`text_align_y`                       `false`            text y-align override: `'t[op]'`, `'c[enter]'`, `'b[ottom]'`
__tooltip__
`tooltip`                            `false`            native tooltip text (false=none)
__rotation & scaling__
`rotation`                           `0`                rotation angle (radians)
`rotation_cx, rotation_cy`           `0`                rotation center coordinates
`scale`                              `1`                scale factor
`scale_x, scale_y`                   `false`            scale factor: axis overrides
`scale_cx, scale_cy`                 `0`                scaling center coordinates
------------------------------------ ------------------ ------------------------------------------------------------------

### Box model

  * layers can be nested, which affects their painting order, clipping and
  positioning relative to each other.
  * layers have a "box" defined by their `x, y, w, h`, and a "content box"
  (aka "client rect") which is the same box adjusted by paddings.
  * layers are positioned and clipped relative to their parent's content box.
  * unlike HTML, the content box is _not_ affected by the size of borders.
  * borders can be drawn at an offset relative to the layer's box and the
  border's thickness.
  * the contents of a layer can be clipped by its padding box, by the inner
  contour of its border, or it can be left unclipped.
  * a layer's background is always clipped.

### Layer hierarchy

  * layers keep their children in their array part which also dictates their paint order.
  * layers can be moved around in the hierarchy by changing their `parent` property.
  * layers can change their paint order with `:to_front()`, `:to_back()` or
  by setting their `layer_index` property directly.
  * painting order can also be set for all children by sorting the parent
  layer with `table.sort()`.

------------------------------------------------- ------------------------------------------------------------------
`mouse_x, mouse_y`                                mouse coords from the last mouse event
`window`                                          layer's window
`to_back()`                                       set `layer_index` to 1
`to_front()`                                      set `layer_index` to 1/0
`each_child(func)`                                calls `func(layer)` for each child, recursively, depth-first
`children() -> iter() -> layer`
`add_layer(layer, [index])`                       add a child
`remove_layer(layer)`                             remove a child
------------------------------------------------- ------------------------------------------------------------------

### Runtime state

-------------------------------- ---------------- ------------------------------------------------------------------
`enabled`                        r/w              enabled and all parents are enabled too
`active`                         r/w              the mouse is captured
`hot`                            r/o              mouse pointer is over the layer
`focused`                        r/o              has keyboard focus
-------------------------------- ---------------- ------------------------------------------------------------------

### Layer geometry

------------------------------------------------- ------------------------------------------------------------------
__derived geometry__
`border_inner_x/_y/_w/_h`                         border's inner contour box
`border_outer_x/_y/_w/_h`                         border's outer contour box
`baseline`                                        text's baseline
`pw, ph`                                          total horizontal and vertical paddings
`pw1, pw2, ph1, ph2`                              paddings for each side
`cw, ch`                                          content box size
`cx, cy`                                          box's center coords
`x2, y2`                                          box's bottom-right corner coords
__coord converters__
`abs_matrix() -> mt`                              box matrix in window space
`from_box_to_parent(x, y) -> x, y`                convert point from own box space to parent content space.
`from_parent_to_box(x, y) -> x, y`                convert point from parent content space to own box space.
`to_parent(x, y) -> x, y`                         convert point from own content space to parent content space.
`from_parent(x, y) -> x, y`                       convert point from parent content space to own content space.
`to_window(x, y) -> x, y`
`from_window(x, y) -> x, y`
`to_screen(x, y) -> x, y`
`from_screen(x, y) -> x, y`
`to_other(widget, x, y) -> x, y`                  convert point from own content space to other's content space.
`from_other(widget, x, y) -> x, y`                convert point from other's content space to own content space
------------------------------------------------- ------------------------------------------------------------------

### Events

------------------------------------------------- ------------------------------------------------------------------
__mouse__
`activated()`                                     layer activated (mouse captured)
`deactivated()`                                   layer deactivated
`mousemove(x, y, area)`                           mouse moved
`mouseenter(x, y, area)`                          mouse entered
`mouseleave()`                                    mouse left
`[right|middle]mousedown(x, y, area)`             mouse left/right/middle button pressed
`[right|middle]mouseup(x, y, area)`               mouse left/right/middle button depressed
`[right|middle]click(x, y, area)`                 mouse left/right/middle button clicked
`[right|middle]doubleclick()`                     mouse left/right/middle button double-clicked
`[right|middle]tripleclick()`                     mouse left/right/middle button triple-click
`[right|middle]quadrupleclick()`                  mouse left/right/middle button quadruple-click
`mousewheel(delta, x, y, area, pdelta)`           mouse wheel turned
__keyboard__
`gotfocus()`                                      layer focused
`lostfocus()`                                     layer unfocused
`keydown(key)`                                    key pressed
`keyup(key)`                                      key released
`keypress(key)`                                   key pressed (on repeat)
`keychar(s)`                                      utf-8 sequence entered
__drag & drop__
`drag(x, y)`
`enter_drop_target(widget, area)`
`leave_drop_target(widget)`
`end_drag(drag_widget)`
`drop(widget, x, y, area)`
`started_dragging()`
`ended_dragging()`
__layer hierarchy__
`layer_added(layer, index)`                       a child layer was added
`layer_removed(layer)`                            a child layer was removed
------------------------------------------------- ------------------------------------------------------------------

### Mouse interaction

  * layers must be set as `activable` in order to receive mouse events.
  * a layer is `hot` when the mouse is over it or when it's `active`.
  * a layer must set `active` on `mousedown` and must reset it on `mouseup`
  in order to have the mouse _captured_ while a mouse button is down;
  this can be done automatically by statically setting `mousedown_activate`.
  * while a layer is `active`, it continues to be `hot` and receive
  `mousemove` events even when the mouse is outside its hit test area or
  outside the window even (that is, the mouse is captured).
  * a layer must be `active` in order to receive drag & drop events.

### Keyboard interaction

  * layers must be set as `focusable` in order to receive keyboard events.
  * keyboard events are only received by the focused layer.
  * return `true` in a `keydown` event to eat up a key stroke so that it
  isn't used by other actions: this is how key conflicts are solved.

### Layouting

Layouting deals with sizing and positioning layers on screen automatically
to accomodate both the content size and the window size. Layers of different
layout types and properties can be mixed freely in a layer hierarchy with
some caveats:

  * non-layouted children of non-layouted layers _are not_ sized by their
  parent and do not size themselves either, thus these layers must be sized
  and positioned manually by setting their `x, y, w, h`.
  * layouted children of non-layouted layers _are not_ sized by their
  parent and must thus set their `min_cw, min_ch`, otherwise they will size
  themselves to the minimum allowed by their children.
  * non-layouted children of layouted layers _are_ sized by their parent
  and must thus set their `min_cw, min_ch`, otherwise they may shrink
  to nothing since they don't resize themselves to contain their content.
  * layouts with wrapping content (nowrap = false, flex_wrap = true) are
  solved on one axis completely before solving on the other axis. This only
  works properly if all the wrappable content has either horizontal flow
  (so the whole layout is width-in-height-out) or vertical flow (so the
  whole layout is height-in-width out). Mixed flows will cause the contents
  which wrap perpendicularly to overflow their container (browsers have this
  limitation too). Setting `min_cw, min_ch` on the cross-flow layers can be
  used to alleviate the problem on a case-by-case basis.

#### No layout

Layers without a layout (layout = false) don't touch their box or their
children's boxes, but instead ask their children to layout themselves.

#### Textbox layouts

Freestanding textbox layers (whose parent is not layouted) size themselves
to contain their `text` property which is line-wrapped on their `min_cw`.

#### Flexbox layouts

Flexbox layers use an algorithm similar to the CSS flexbox algorithm
to size themselves and to size and position their children recursively.

#### Grid layouts

Grid layers use an algorithm similar to the CSS grid algorithm to size
themselves and to size and position their children recursively.

### The top layer

All windows have a top layer in their `view` field. Its size is kept in sync
with the window's client area and it is configured to clear the window's
bitmap on every repaint:

-------------------------------- ---------------- ------------------------------------------------------------------
`background_color`               '#040404'        a default color that works with transparent windows
`background_operator`            'source'         makes it clear the background
-------------------------------- ---------------- ------------------------------------------------------------------

User-created layers must ultimately be atteched to the window's view (or to
the window itself which will attach them to the window's view) in order to be
visible and respond to user input. The view is the only layer whose `parent`
is a window, not another layer.

## Widgets

Widgets are layers (usually containing other layers) with custom styling
and behavior and additional properties, methods and events. Widgets can be
extended by subclassing and overriding and can be re-styled with `ui:style()`
or by assigning them a different stylesheet.

-------------------------------------- ---------------------------------------
__input__
`ui:editbox(...)`                      create an editbox
`ui:dropdown(...)`                     create a drop-down
`ui:slider(...)`                       create a slider
`ui:checkbox(...)`                     create a check box
`ui:radiobutton(...)`                  create a radio button
`ui:choicebutton(...)`                 create a multi-choice button
`ui:colorpicker(...)`                  create a calendar
`ui:calendar(...)`
__output__
`ui:image(...)`                        create an image
`ui:progressbar(...)`                  create a progress bar
__input/output__
`ui:grid(...)`                         create a grid
__action__
`ui:button(...)`                       create a button
`ui:menu(...)`                         create a menu
__containers__
`ui:scrollbar(...)`                    create a scroll bar
`ui:scrollbox(...)`                    create a scroll box
`ui:popup(...)`                        create a pop-up window
`ui:tablist(...)`                      create a tab list
-------------------------------------- ---------------------------------------

__TIP:__ Widgets are implemented in separate modules. Run each module
standalone to see a demo of the widgets implemented in the module.

## Editboxes

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Drop-downs

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Sliders

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Check boxes

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Radio buttons

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Multi-choice buttons

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Calendars

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Images

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Progress bars

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Editable grids

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Buttons

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Menus

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Scroll bars

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Scroll boxes

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Pop-up windows

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Tab lists

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

# Creating new widgets

The API for creating and extending widgets is larger and more complex
than the API for instantiating and using existing widgets. This is normal,
since widgets are supposed to encapsulate complex user interaction patterns
as well as provide customizable presentation and behavior.

The main topics that need to be understood in order to create new widgets are:

 * the [object system][oo] and its extensibility mechanisms:
	* subclassing and instantiation
	* virtual properties
	* method overriding
 * the [event system][events].
 * the `ui.object` class and its meta-programming utilities (decorators).
 * the `ui.element` class and the way its constructor works.
 * the `ui.layer` class and its visual model:
	* layer hierarchies with relative affine transforms and clipping
	* borders, backgrounds, shadows, aligned text
	* hit testing
	* layouting, for making the widgets elastic
 * the `ui.window` and `ui.layer` classes, which together provide an input API:
   * routing mouse events to the hot widget; mouse capturing
	* routing keyboard events to the focused widget; tab-based navigation
	* the drag & drop API (event-based)

## The `object` base class

  * created with [oo]; inherits oo.Object; published as `ui.object`.
  * inherits the [events] mixin.
  * common ancestor of all classes.

## Method & property decorators

These are meta-programming facilities exposed as class methods for creating
or enhancing the behavior of properties and methods in specific ways.

### `object:memoize(method_name)`

Memoize a method (which must be single-return-value).

### `object:forward_events(obj, events)`

Forward some events (`{event_name1, ...}`) from `obj` to `self`,
i.e. install event handlers in `obj` which forward events to `self`.

### `object:stored_property(prop, [priv])`

Create a r/w property which reads/writes from a "private field" (`priv` which
defaults to `_<prop>`).

### `object:nochange_barrier(prop)`

Change a property so that its setter is only called when the value changes.

### `object:track_changes(prop)`

Change a property so that its setter is only called when the value changes
and also `<prop>_changed` event is fired.

### `object:instance_only(prop)`

Inhibit a property's getter and setter when using the property on the class.
instead, set a private var on the class which serves as default value.
NOTE: use this decorator only _after_ defining the getter and setter.

### `object:enum_property(prop, values)`

Validate a property when being set against a list of allowed values.

## Error reporting

### `object:warn(fmt, ...)`

Issue a warning on `stderr`.

### `object:check(ret, fmt, ...) -> ret|nil`

Issue a warning if `ret` is falsey or return `ret`.

## Submodule autoloading

### `object:autoload(t)`

See [glue].autoload.
