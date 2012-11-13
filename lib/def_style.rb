#--
# Lackey set to OCTGN set package converter
# Copyright (c) 2012 Raohmaru

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Dvolatooc

  DEF_STYLE = <<EOF
card:
	width: 375
	height: 523
	background-color: white
	border-color: #cccccc
	border-radius: 8
	border-width: 12
	
name:
	x: 30
	y: 25
	width: 266
	height: 35	
	font-family: arial
	font-size: 30
	font-weight: bold
	text-color: black
	vertical-align: bottom
	stretch: true

value:
	x: 304
	y: 25
	width: 38
	height: 32	
	font-family: arial
	font-size: 30
	font-weight: bold
	text-color: #7f7f7f
	text-align: center

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
		Objeto: #0B0FB5

picture:
	x: 30
	y: 103
	width: 315
	height: 238
	
rules:
	x: 30
	y: 360
	width: 315
	height: 130	
	font-family: arial
	font-size: 18
	text-color: black
	multiline: true
	
flavor:
	x: 30
	y: 370
	width: 315
	height: 130	
	font-family: arial
	font-size: 16
	font-style: italic
	text-color: black
	multiline: true
	combined: rules
	
copyright:
	x: 30
	y: 490
	width: 250
	height: 14	
	font-family: arial
	font-size: 12
	text-color: black
	format: "Card by %s"
	
artist:
	x: 30
	y: 480
	width: 250
	height: 14	
	font-family: arial
	font-size: 12
	text-color: black
	format: "Art by %s"
	
number:
	x: 0
	y: 490
	width: 345
	height: 14	
	font-family: arial
	font-size: 12
	text-color: black
	text-align: right
	format: "%s-%s/%s"
EOF
end  # module Dvolatooc