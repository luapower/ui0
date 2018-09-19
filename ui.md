
<warn>Work in Progress</warn>

## `local ui = require'ui'`

Extensible UI toolkit written in Lua with layouts, styles and animations.

## Features

  * OMG widgets!
    * an editable grid that can scroll millions of rows at 60 fps?
	 * a tab list with animated, moveable, draggable, dockable tabs?
	 * a code editor in Lua?
	 * run the demos!
  * consistent Unicode text rendering and editing with [tr].
  * transition-based animations.
  * cascading styles with `> parent` and `:state` selectors.
  * constraint-based, container-based and flow-based layouts.
  * affine transforms.

## Programming Features

  * [object system][oo] with virtual properties and method overriding hooks.
  * layer class containing all the mechanisms necessary for making widgets.
  * comprehensive event-based drag & drop API.

## Example

~~~

~~~

## User API

### UI Object

-------------------------------------- ---------------------------------------
`ui:free()`                            free the ui object and resources
__message loop__
`ui:clock() -> time`
`ui:run(func)`
`ui:poll(timeout)`
`ui:stop()`
`ui:quit()`
`ui:get_autoquit()`
`ui:set_autoquit(aq)`
`ui:get_maxfps()`
`ui:set_maxfps(fps)`
`ui:runevery(t, f)`
`ui:runafter(t, f)`
`ui:sleep(s)`
__app activation__
`ui:get_app_active()`
`ui:activate_app()`
`ui:get_app_visible()`
`ui:set_app_visible(v)`
`ui:hide_app()`
`ui:unhide_app()`
__keyboard state__
`ui:key(query)`
`ui:get_caret_blink_time()`
__displays__
`ui:get_displays()`
`ui:get_main_display()`
`ui:get_active_display()`
__clipboard__
`ui:getclipboard(type)`
`ui:setclipboard(s, type)`
__open/save dialogs__
`ui:opendialog(t)`
`ui:savedialog(t)`
__single-app instance__
`ui:set_app_id(id)`
`ui:get_app_id(id)`
`ui:app_already_running()`
`ui:wakeup_other_app_instances()`
`ui:check_single_app_instance()`
__color parsing__
`ui:rgba(s) -> r, g, b, a`
__font handling__
`ui:add_font_file(...)`
`ui:add_mem_font(...)`
-------------------------------------- ---------------------------------------

### Elements

-------------------------------------- ---------------------------------------
__selectors__

TODO

__stylesheets__

TODO

__attribute types__

TODO

__transition animations__

TODO

__interpolators__

TODO

__element lists__

TODO

__tags & styles__

`elem.stylesheet`

`elem:settag(tag, on)`

`elem:settags('+tag1 -tag2 ...')`

__attribute transitions__

`elem.transition_duration = 0`

`elem.transition_ease = 'expo out'`

`elem.transition_delay = 0`

`elem.transition_repeat = 1`

`elem.transition_speed = 1`

`elem.transition_blend =` \
	`'replace_nodelay'`

`elem:transition(attr, val, dt, ` \
   `ease, duration, ease, delay,` \
   `times, backval, blend)`

`elem:transitioning(attr) -> t|f`
-------------------------------------- ---------------------------------------

### Windows

-------------------------------------- ---------------------------------------
`ui:window{...} -> win`

`win:free()`

__parent/child relationship__

`win.parent`

`win:to_parent(x, y)`

`win:from_parent(x, y)`

__native methods__

`frame_rect, client_rect,` \           these map directly to [nw] features \
`client_to_frame, frame_to_client,` \  so they are documented there.
`closing, close, show, hide,` \
`activate, minimize, maximize,` \
`restore, shownormal, raise, lower,` \
`to_screen, from_screen`

__native properties__

`x, y, w, h, cx, cy, cw, ch,` \        these map directly to [nw] features \
`min_cw, min_ch, max_cw, max_ch,` \    so they are documented there.
`autoquit, visible, fullscreen,` \
`enabled, edgesnapping, topmost,` \
`title, dead, closeable,` \
`activable, minimizable,`
`maximizable, resizeable,` \
`fullscreenable, frame,` \
`transparent, corner_radius,`
`sticky, dead, active, isminimized,` \
`ismaximized, display, cursor`

__element query interface__

`win:find(sel) -> elem_list`

`win:each(sel, f)`

__mouse state__

`win.mouse_x, win.mouse_y`

`win:mouse_pos() -> x, y`

__drawing__

`win:draw(cr)`

`win:invalidate()`

__frameless windows__

`win.move_layer`
-------------------------------------- ---------------------------------------

### Layers

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

## Widgets

-------------------------------------- ---------------------------------------
__input__
`ui:editbox(...)`                      editbox
`ui:dropdown(...)`                     drop-down
`ui:slider(...)`                       slider
`ui:checkbox(...)`                     check box
`ui:radiobutton(...)`                  radio button
`ui:choicebutton(...)`                 multi-choice button
`ui:colorpicker(...)`                  calendar
`ui:calendar(...)`
__output__
`ui:image(...)`                        image
`ui:progressbar(...)`                  progress bar
__input/output__
`ui:grid(...)`                         editable grid
__action__
`ui:button(...)`                       button
`ui:menu(...)`                         menu
__containers__
`ui:scrollbar(...)`                    scroll bar
`ui:scrollbox(...)`                    scroll box
`ui:popup(...)`                        pop-up window
`ui:tablist(...)`                      tab list
-------------------------------------- ---------------------------------------

__TIP:__ Widgets are implemented in separate modules. Run each module
standalone to see a demo of the widgets implemented in the module.

### Editbox

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Drop-down

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Slider

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Check box

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Radio button

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Multi-choice button

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Calendar

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Image

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Progress bar

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Editable grid

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Button

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Menu

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Scroll bar

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Scroll box

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Pop-up window

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------

### Tab list

-------------------------------------- ---------------------------------------
TODO
-------------------------------------- ---------------------------------------
