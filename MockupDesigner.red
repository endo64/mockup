Red [
	Title:	"Mockup Designer"
	Author:	"Semseddin (Endo64) Moldibi"
	Needs:	View
	Date:	2017-11-20
]

system/view/auto-sync?: false
scale: 96.0 / system/view/metrics/dpi

digit:			charset [#"0" - #"9"]
base-color:		68.68.68
base-backcolor:	245.239.235
selected-face:	none
snap-size:		6x6
default-size:	216x36
default-font:	make font! [
	name:			system/view/fonts/system
	size:			11
	color:			base-color
	anti-alias?:	true
]
counters: [
	button	1
	check	1
	radio	1
	label	1
	combo	1
	field	1
]
merge: function ["Merge block" b [block!] /with c /quot] [
	c: any [c ","]
	if quot [c: rejoin ["'" c "'"]]
	s: copy ""
    s: head clear skip foreach v b [insert tail s rejoin [form v c]] negate length? c
    if quot [
        s: rejoin ["'" s "'"]
    ]
    s
]
set-grabber-pos: function [face] [
	;move find/same win/pane grabber tail win/pane	;this is necessary for ctrl-click (bring to front)	;BUG! widget sticks!
	grabber/offset: face/offset + face/size - (grabber/size / 2)
	either find [check radio label] face/widget-type [
		grabber/color: red
	] [
		grabber/color: green
	]
	show grabber
]
snap-to-grid: function [face] [
	face/offset: face/offset / snap-size * snap-size
	face/text: ""	;refresh (show doesn't work)
	set-grabber-pos face
]

do-on-wheel: function [face event] [
	direction: case [event/shift? [6x0] event/ctrl? [0x6] true [6x6]]
	face/size: face/size + (event/picked * direction)
	face/resize
	set-grabber-pos face
	show face
]

edit-table: function [] [
	do-ok: function [face event] [
		selected-face/cols: to integer! cols/text
		selected-face/rows: to integer! rows/text
		append clear selected-face/texts split area-headers/text newline
		selected-face/resize
		unview
	]
	txt: copy ""
	foreach text selected-face/texts [
		append txt rejoin [text newline]
	]
	view/flags compose [
		title "Edit Table"
		text "Columns"
		cols: field 20 (form selected-face/cols)
		text "Rows" right
		rows: field 20 (form selected-face/rows)
		return
		text "Headers"
		area-headers: area txt
		return
		button "OK" :do-ok
		button "Cancel" [unview]
		do [self/selected: cols]
	] [modal]
]

edit-text: has [fld do-ok] [
	txt: selected-face/widget-text
	do-ok: function [face event] [
		insert clear txt copy fld/text
		selected-face/resize
		set-grabber-pos selected-face
		selected-face/text: ""
		unview
	]
	view/flags compose [
		title "Enter text"
		fld: field 250 (copy txt) :do-ok on-key [if event/key = #"^[" [unview]]
		return
		button "OK" :do-ok
		button "Cancel" [unview]
		do [self/selected: fld]
	] [modal]
]

check-edge: function [face] [
	case/all [
		face/offset/x > (win/size/x - (snap-size/x * 4)) [face/offset/x: win/size/x - (snap-size/x * 4)]
		face/offset/y > (win/size/y - (snap-size/x * 4)) [face/offset/y: win/size/y - (snap-size/y * 4)]
		(diff: face/offset/x + face/size/x) <= (snap-size/x * 4) [face/offset/x: face/offset/x + (snap-size/x * 4) - diff]
		(diff: face/offset/y + face/size/y) <= (snap-size/x * 4) [face/offset/y: face/offset/y + (snap-size/y * 4) - diff]
	]
]

base-face!: make face! [
	type:			'base
	color:			red ; for debugging
	color:			none
	size:			default-size
	options:		[drag-on: 'down]
	font:			default-font
	draw-block:		[]
	widget-text:	none
	get-text-size:	function [/x /y] [
		size: size-text/with self pick reduce ["WWW" widget-text] empty? widget-text
		case [
			x	[size/x]
			y	[size/y]
			1	[size]
		]
	]
	do-draw: does [
		draw: compose bind draw-block self
		self/text: ""
	]
	resize: does [
		case/all [
			size/x < 36 [size/x: 36]
			size/y < 36 [size/y: 36]
		]
		do-draw
	]
	actors: object [
		on-alt-down: function [face event] [
			;TODO: aşağıdaki ifadeyi tek fonksiyonda topla
			set 'selected-face :face
			set-grabber-pos face
			grabber/visible?: true
			;
			;Edit text or table
			either selected-face/widget-type = 'table [edit-table] [if selected-face/widget-text [edit-text]]
			'done
		]
		on-down: function [face event] [
			old-face: :selected-face
			set 'selected-face :face
			win/selected: :face
			if event/ctrl? [
				move find/same win/pane face either event/shift? [win/pane] [back back tail win/pane]	;Why 2 back?
				show win
			]
			if all [
				event/shift?
				in face 'draw-block
			] [
				either pos: find face/draw-block [(checked)] [
					remove pos
				] [
					if chk: in face 'checked [
						append face/draw-block reduce [to paren! chk]
					]
				]
				face/do-draw
			]
			set-grabber-pos face
			grabber/visible?: true
			'done
		]
		on-up: function [face event] [
			snap-to-grid face
			show face
			'done
		]
		on-drag: function [face event] [
			set-grabber-pos face
			'done
		]
		on-drop: function [face event] [
			check-edge face
		]
	]
]

base-table: make base-face! [
	widget-text: "Table"
	widget-type: 'table
	cols: 6
	rows: 5
	size: default-size * 2x4
	draw-block:	[
		pen			(base-color)
		fill-pen	(base-backcolor - 10.10.10)
		line-width	2
		box			2x2 (size - 2x2) 4
		line-width	1
		pos:
	]
	texts: []
	repeat col cols [append texts rejoin ["Column " col]]
	resize*: :resize	;base resize
	resize: function [] [
		resize*
		pos: clear find/tail draw-block [pos:]
		step-x: size/x / cols
		step-y: size/y / rows
		repeat x cols [
			append draw-block compose [line (as-pair x * step-x  2) (as-pair x * step-x  size/y - 2)]
			append draw-block compose [
				text (as-pair x - 1 * step-x + 2 4) (form any [texts/:x ""])
			]
		]
		repeat y rows - 1 [
			append draw-block compose [line (as-pair 2  y * step-y) (as-pair size/x - 2  y * step-y)]
		]
		do-draw
	]
]

base-check: make base-face! [
	widget-text: "Check"
	widget-type: 'check
	resize:		does [size: 54x0 + get-text-size do-draw]
	checked:	[
		line		6x8 10x12
		line		10x12 14x6
	]
	draw-block:	[
		pen			(base-color)
		fill-pen	(base-backcolor - 10.10.10)
		line-width	2
		box			2x2 18x16 2
		text		24x2 (widget-text)
		(checked)
	]
]

base-combo: make base-face! [
	widget-text: "Combo"
	widget-type: 'combo
	resize:		does [size: as-pair max 120 size/x 36 do-draw]
	draw-block: [
		pen			(base-color)
		fill-pen	(base-backcolor - 10.10.10)
		line-width	2
		box			2x2 (size - 2x2) 4
		text		(as-pair scale * 12 scale * 10) (widget-text)
		pen			off
		fill-pen	(base-color)
		triangle	(as-pair size/x - 36 10) (as-pair size/x - 16 10) (as-pair size/x - 26 26)
	]
]

base-radio: make base-face! [
	widget-text: "Radio"
	widget-type: 'radio
	resize:		does [size: 48x2 + get-text-size do-draw]
	checked:	[
		circle		10x12 4
	]
	draw-block: [
		pen			(base-color)
		text		24x2 (widget-text)
		fill-pen	(base-backcolor)
		line-width	2
		circle		10x12 8
		pen			off
		fill-pen	(base-color)
		(checked)
	]
]

base-content: make base-face! [
	widget-type: 'content
	widget-text: "Content"
	size: default-size * 1x4
	draw-block:	[
		pen			(base-color)
		fill-pen	(base-backcolor + 20.20.20)
		box			2x2 (self/size - 2x2) 1
		line		2x2 (size - 2x2)
		line		(as-pair size/x - 2 2) (as-pair 2 size/y - 2)
	]
]

base-label: make base-face! [
	widget-text: "Label"
	widget-type: 'label
	resize: does [size: 10x0 + get-text-size do-draw]
	draw-block: [
		pen			off
		fill-pen	(base-backcolor - 0.0.1)	;draw a non-transparent box to be able to drag
		box			0x0 (self/size - 0x4)
		pen			(base-color)
		text 0x0	(widget-text)
	]
]

base-field: make base-face! [
	widget-text: "Field"
	widget-type: 'field
	resize: does [size: as-pair (max size/x get-text-size/x) (max size/y default-size/y + get-text-size/y + 2) do-draw]
	draw-block: [
		pen			(base-color)
		fill-pen	(base-backcolor - 10.10.10)
		line-width	2
		text		0x0	(widget-text)
		box			(as-pair 2 get-text-size/y + 1) (size - 2x2) 4
	]
]

base-button: make base-face! [
	widget-text: "Button"
	widget-type: 'button
	draw-block: [
		anti-alias	on
		line-join	round
		pen			(base-color)
		fill-pen	(base-backcolor - 10.10.10)
		line-width	2
		box			2x2 (self/size - 2x2) 4
		text		(size - get-text-size / 2) (widget-text)
	]
]

grabber: make face! [
	type:		'base
	visible?:	false
	size:		8x8
	offset:		0x0
	color:		orange
	options:	[drag-on: 'down]
	widget-type: none
	actors: object [
		on-drag: function [face event] [
			unless selected-face [exit]
			size: face/offset - selected-face/offset + (face/size / 2)
			selected-face/size: size + 3x3
			;snap face size
			selected-face/size: as-pair round/to size/x snap-size/x round/to size/y snap-size/y

			selected-face/resize
			snap-to-grid selected-face
			show selected-face
		]
		on-drop: function [face event] [set-grabber-pos selected-face]
		on-down: function [face event] ['done]
	]
]

win: make face! [
	type:	'window
	size:	800x600
	text:	"Mockup Designer"
	color:	base-backcolor
	flags:	[resize]
	pane:	reduce [grabber]
	actors:	object [
		on-wheel: function [face event] [
			if selected-face [
				do-on-wheel selected-face event
			]
		]
		on-down: function [face event] [
			if selected-face [
				;unselect
				set 'selected-face none
				grabber/visible?: false
				show grabber
			]
		]
		on-key: function [face event] [
			case [
				event/key = 'delete [
					either event/shift? [
						append clear win/pane grabber
					] [
						if selected-face [
							remove find/same win/pane selected-face
						]
					]
					set 'selected-face none
					grabber/visible?: false
					show face
					exit
				]

				event/key = #"^[" [unview]
				event/key = #" " [show win]

				;
				; Load project
				;
				event/key = #"^L" [
					if file: request-file/file %mockup.red [
						project: load file
						parse project [
							opt ['Red block!]
							some [
								[
									set wid 'table	set headers string!	set pos pair! set sz pair! set rc pair! |
									set wid word!	set txt string!		set pos pair! set sz pair!
								] (
									either wid = 'table [
										widget: make base-table [rows: rc/1 cols: rc/2 ]	;Rows x Cols
										widget/texts: split headers newline
									] [
										widget: make-widget get (to word! rejoin ["base-" form wid])
										widget/widget-text: txt
									]
									widget/size: sz
									widget/resize
									widget/do-draw
									widget/offset: pos
									insert back tail win/pane widget
								)
							]
						]
						show win
					]
				]

				;
				; Save as PNG
				;
				all [
					event/key = #"^S"
					event/shift?
				] [
					if file: request-file/save/filter/file ["*.png" "*.png" "All files" "*.*"] %mockup.png [
						;hide grabber
						set 'selected-face none
						grabber/visible?: false
						show face

						;save window image to file
						if img: to-image win [
							save/as file img 'PNG
							img: none
						]
					]
				]

				;
				; Save project
				;
				event/key = #"^S" [
					project: make block! 1024
					foreach widget win/pane [
						if widget/widget-type [
							if widget/widget-type = 'table [
								insert clear widget/widget-text merge/with widget/texts "^/"
							]
							append project reduce [
								widget/widget-type
								widget/widget-text
								widget/offset
								widget/size
							]
							if widget/widget-type = 'table [
								append project as-pair widget/rows widget/cols
							]
						]
					]
					if all [
						not empty? project
						file: request-file/save/filter/file ["*.red" "*.red" "All files" "*.*"] %mockup.red
					] [
						parse project [
							some [pos: word! (new-line pos true) | skip]
						]
						save/header file project compose [
							title:	"Mockup Designer Project File"
							date:	(now)
							author:	(any [get-env "USERNAME" ""])
						]
					]
				]

				all [
					event/key = #"?"
					selected-face
				] [
					dump-face selected-face
				]

				all [
					event/key = #"^M"
					selected-face
				] [
					;? selected-face/draw-block
					if selected-face [
						widget: make-widget selected-face [color: red]
						;widget: make-widget base-button
						widget/resize
						widget/offset: random 100x100
						add-widget widget
						;insert back tail win/pane widget
						;show win
						;probe length? win/pane
						exit
						widget/resize
						probe same? widget selected-face
						widget/text: form random 1000
						widget/offset: selected-face/offset + 40x40
						add-widget widget
					]
				]

				all [
					selected-face
					find [up down left right] event/key
				] [
					selected-face/offset: selected-face/offset + switch event/key [
						up		[snap-size * 0x-1]
						down	[snap-size * 0x1 ]
						left	[snap-size * -1x0]
						right	[snap-size * 1x0 ]
					]
					check-edge selected-face
					set-grabber-pos selected-face
					show selected-face
					exit
				]

				parse d: form event/key [digit] [
					if widget: pick [
						base-label
						base-field
						base-button
						base-combo
						base-content
						base-radio
						base-check
						base-table
					] to integer! d [
						unless widget [exit]
						;widget: make get widget [bind draw-block self]

						widget: make-widget get widget

						widget/resize
						either selected-face [
							widget/offset: selected-face/offset + as-pair 0 selected-face/size/y + snap-size/y
							if widget/offset/y > win/size/y [
								widget/offset/y: win/size/y - widget/size/y
								widget/offset/x: min widget/offset/x + (3 * snap-size/y) (win/size/x - (3 * snap-size/y))
							]
						] [
							widget/offset: random 100x100
						]
						snap-to-grid widget
						add-widget widget
					]
				]
			]
			;show face
		]
	]
]

add-widget: function [widget] [
	set 'selected-face :widget
	insert back tail win/pane widget
	move find/same win/pane grabber tail win/pane
	show win
]

make-widget: function [widget] [
	widget: make widget [draw-block widget ]
	;Apply counter
	if counter: find/tail counters widget/widget-type [
		append widget/widget-text make string! reduce [" " counter/1]
		change counter counter/1 + 1
	]
	widget
]

view/no-wait win

do-events
quit
