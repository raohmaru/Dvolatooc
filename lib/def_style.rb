module Dvolatooc

  DEF_STYLE = <<EOF
card:
	width: 375
	height: 523
	background-color: white
	border-color: 
		Acción: #D90000
		Action: #D90000
		Objeto: #0B0FB5
		Thing: #0B0FB5
		default: black
	border-radius: 8
	border-width: 12

drawing:
	title_line: 
		//		cmd    color  size x1,y1  x2,y2
		Acción: stroke(#D90000, 6, 30,71, 345,71)
		Action: stroke(#D90000, 6, 30,71, 345,71)
		Objeto: stroke(#0B0FB5, 6, 30,71, 345,71)
		Thing: stroke(#0B0FB5, 6, 30,71, 345,71)
		default: stroke(#666666, 6, 30,71, 345,71)
	bottom_line: stroke(#333333, 1, 30,485, 345,485)
	
name:
	x: 30
	y: 25
	width: { if value.empty? then 310 else 269 end }
	height: 35	
	font-family: arial
	font-size: 30
	font-weight: bold
	text-color: black
	vertical-align: bottom
	stretch: true

value:
	x: 309
	y: 25
	width: 38
	height: 32	
	font-family: arial
	font-size: 30
	font-weight: bold
	text-color: #7f7f7f
	text-align: right

supertype:
	x: 30
	y: 77
	width: 345
	height: 22	
	font-family: arial
	font-size: 18
	font-weight: bold
	text-color:
		Acción: #D90000
		Action: #D90000
		Objeto: #0B0FB5
		Thing: #0B0FB5
		default: #666666

picture:
	x: 30
	y: 103
	width: 315
	height: 220
	
rules:
	x: 30
	y: 342
	width: 315
	height: 138
	font-family: arial
	font-size: 18
	text-color: black
	multiline: true
	stretch: true
	
flavor:
	x: 30
	y: 352
	width: 315
	height: 138
	font-family: arial
	font-size: 16
	font-style: italic
	text-color: #555555
	multiline: true
	combined: rules
	
creator:
	x: 30
	y: 492
	width: 250
	height: 14	
	font-family: arial
	font-size: 12
	text-color: black
	format: "Card by %s"
	
artist:
	x: 30
	y: 492
	width: 250
	height: 14	
	font-family: arial
	font-size: 12
	text-color: black
	format: "Art by %s"
	combined: creator right
	
number:
	x: 0
	y: 492
	width: 345
	height: 14	
	font-family: arial
	font-size: 12
	text-color: black
	text-align: right
	format: "%s-%s/%s"
EOF
end  # module Dvolatooc