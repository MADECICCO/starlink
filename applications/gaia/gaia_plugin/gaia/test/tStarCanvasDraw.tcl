#!/bin/sh
# the next line restarts using a special startup script to setup the env \
exec ../demos/gaia.sh "$0" "$@"

source test.tcl

# for debugging: print all errors on stderr 
catch {tkerror}
rename tkerror tkerror__
proc tkerror {msg} {
    global errorInfo
    puts stderr "$errorInfo"
    tkerror__ "error: $msg"
}

util::setXdefaults

# test class for CanvasDraw widget

itcl::class tStarCanvasDraw {
    inherit TopLevelWidget

    constructor {args} {
	# add a menubar
	add_menubar
	
	# canvas
	itk_component add canvas {
	    CanvasWidget $w_.canvas \
		-canvasbackground black
	}
	pack $itk_component(canvas) -fill both -expand 1
	set canvas [$itk_component(canvas) component canvas]

	# canvas draw tool
	itk_component add draw {
	    StarCanvasDraw $w_.draw	\
		-canvas $canvas \
		-withdraw 1 \
		-transient 1 \
		-center 0
	} 

	# add menu items
	add_menu_items 
	
	# test itcl-2.0 option handling with canvas images
	#set image [image create photo -file mickey.gif]
	#$canvas create image 40 40 -image $image -anchor nw

	wm geometry $w_ 500x500

	eval itk_initialize $args
    }


    method add_menu_items {} {
	set m [add_menubutton File]
	$m add command -label "Test" -command [code $this dynamic 1 2 3]
	$m add command -label "Print" -command [code $this print]
	$m add command -label "Exit" -command exit

	set m [add_menubutton Graphics]
	$m add command -label "Toolbox..." -command [code $itk_component(draw) center_window]
	$m add separator
	$itk_component(draw) add_menuitems $m
    }

    
    # print the contents of the canvas (without the image)

    method print {} {
	utilReUseWidget CanvasPrint $w_.print
    }


    # just a test for defining methods ....
    ::foreach i {one way to add dynamic methods} {
	method $i {args} [::format {puts "called method %s with args $args"} $i]
    }
}

util::TopLevelWidget::start tStarCanvasDraw
