#+
#  Name:
#     StarAstCopy

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Copies an AST FrameSet from one image to another, thus setting
#     a new WCS system for the image.

#  Description:
#     This window accesses an existing image and opens it checking for
#     any WCS systems in its FITS headers. If any are found then the
#     user is offered the opportunity to test the system and to accept
#     it when they are happy.

#  Invocations:
#
#        StarAstCopy object_name [configuration options]
#
#     This creates an instance of a StarAstCopy object. The return is
#     the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this object.

#  Configuration options:
#     See itk_option define statements.

#  Methods:
#     See method definitions below.

#  Inheritance:
#     FileSelect (which allows the selection of a file).

#  Copyright:
#     Copyright (C) 1997 Central Laboratory of the Research Councils

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     10-DEC-1997 (PDRAPER):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual StarAstCopy {}

itcl::class gaia::StarAstCopy {

   #  Inheritances:
   #  -------------
   inherit util::FileSelect

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Unpack the FileSelect window until we're ready for it.
      pack forget $w_.fs

      #  And remove the control of the OK, filter and cancel buttons,
      #  we'll provide the functionality again at this level.
      place forget $fs(btnf).okf
      place forget $fs(btnf).ff
      place forget $fs(btnf).cf
      pack forget $fs(btnf)

      #  Remove options we're overriding from base class and then
      #  evaluate all options.
      itk_option remove FileSelect::filter_types
      eval itk_initialize $args

      #  Set the top-level window title.
      wm title $w_ "GAIA: Copy astrometry ($itk_option(-number))"

      #  Create the short help window.
      make_short_help

      #  Add the File menu.
      add_menubar
      set File [add_menubutton "File" left]
      configure_menubutton File -underline 0
      add_short_help $itk_component(menubar).file {File menu: close window}

      #  Set the exit menu items.
      $File add command -label {Cancel changes and close window} \
         -command [code $this cancel] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this cancel]
      $File add command -label {Accept changes and close window} \
         -command [code $this accept] \
         -accelerator {Control-a}
      bind $w_ <Control-a> [code $this accept]

      #  Add window help.
      global env gaia_library
      add_help_button $gaia_library/StarAst.hlp "Astrometry Overview..."
      add_short_help $itk_component(menubar).help \
         {Help menu: get some help about this window}
      add_help_button $gaia_library/StarAstCopy.hlp "On Window..."

      #  Create the button bar
      itk_component add actionframe {frame $w_.action}

      #  Add a button to filter the available files. 
      itk_component add filter {
	  button $itk_component(actionframe).filter -text Filter \
		  -command [code $this _filtercmd]
      }
      add_short_help $itk_component(filter) {Filter names in current directory}

      #  Add a button to close window and accept the new WCS.
      itk_component add accept {
         button $itk_component(actionframe).accept -text Accept \
            -command [code $this accept]
      }
      add_short_help $itk_component(accept) \
         {Accept copied astrometric calibration and close window}

      #  Add a button to test the WCS.
      itk_component add test {
         button $itk_component(actionframe).test -text Test \
            -command [code $this test]
      }
      add_short_help $itk_component(test) \
         {Copy astrometric calibration to image for test purposes}

      #  Add a button to close window and not accept the new WCS.
      itk_component add cancel {
         button $itk_component(actionframe).cancel -text Cancel \
            -command [code $this cancel]
      }
      add_short_help $itk_component(cancel) \
         {Close window and restore original astrometry calibration}

      #  Add a button to reset the entries and return to the original
      #  image WCS.
      itk_component add reset {
         button $itk_component(actionframe).reset -text Reset \
            -command [code $this reset_]
      }
      add_short_help $itk_component(reset) \
         {Reset image to original astrometric calibration}

      #  Reset image to original WCS.
      reset_

      #  Pack all widgets into place.
      pack $w_.fs -fill both -expand 1
      pack $itk_component(actionframe) -side bottom -fill x -pady 5 -padx 5
      pack $itk_component(accept) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(cancel) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(reset)  -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(filter) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(test)   -side right -expand 1 -pady 3 -padx 3
   }

   #  Destructor:
   #  -----------
   destructor  {
   }

   #  Methods:
   #  --------
   
   #  Withdraw this window without accepting any new WCS information.
   public method cancel {} {
      wm withdraw $w_

      #  Restore WCS system to the original (if available).
      if { $itk_option(-rtdimage) != {} } {
         catch {
            $itk_option(-rtdimage) astrestore original
         }
         notify_
      }
   }

   #  Withdraw window and write new WCS to image.
   public method accept {} {
       set_wcs_
       wm withdraw $w_
       $itk_option(-rtdimage) astfix
   }

   #  Test the WCS by making it the current system.
   public method test {} {
      set_wcs_
   }

   #  Reset the WCS of the displayed image back to the original
   #  version.
   protected method reset_ {} {
      catch {
         $itk_option(-rtdimage) astrestore original
      }
      notify_
   }

   #  Set the WCS system of the main image to be one based on the
   #  new image that is selected.
   protected method set_wcs_ {} {
      if { $itk_option(-rtdimage) != {} } {

	  #  Read the value of the image to be opened.
	  set file [$fs(select) get]

	  #  Deal with any slice information.
	  set image $file
	  set i1 [string last {(} $file]
	  set i2  [string last {)} $file]
	  if { $i1 > -1 && $i2 > -1 } {
	      incr i1 -1
	      set image [string range $image 0 $i1]
	  }
	  if {"$file" != ""} {
	      if {[file isfile $image]} {
		  #  Open the file, and get a WCS from it.
		  $itk_option(-rtdimage) astcopy $image
		  $itk_option(-rtdimage) astreplace
                  notify_
	      } else {
		  error_dialog "There is no file named '$file'" $w_
	      }
	  }
      }
   }

   #  Do the notify_cmd option if needed.
   protected method notify_ {} {
      if { $itk_option(-notify_cmd) != {} } { 
         eval $itk_option(-notify_cmd)
      }
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  Name of starrtdimage widget.
   itk_option define -rtdimage rtdimage RtdImage {} {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0 {}

   #  Names and extensions of known data types. Note this option 
   #  overrides those of the parent class and hence repeats its
   #  functionality.
   itk_option define -filter_types filter_types Filter_Types \
	   {{any *} {ndf *.sdf} {fits *.fit*}} {
       if {$_initialized} {
	   if { [info exists fs(filter_types)] } {
	       catch {destroy $fs(filter_types)}
	   }
	   if { $itk_option(-filter_types) != {} } {
	       set fs(filter_types) [LabelMenu $fs(filterf).types \
		       -text {File Type:}]
	       foreach pair "$itk_option(-filter_types)" {
		   set name [lindex $pair 0]
		   set type [lindex $pair 1]
		   $fs(filter_types) add -label $name \
			   -command [code $this set_filter_type $type]
	       }
	       pack $fs(filterf).types -side bottom -ipady 1m -anchor w
	   }
       }
   }
   
   #  Command to execute when the WCS is changed.
   itk_option define -notify_cmd notify_cmd Notify_Cmd {}

   #  Protected variables: (available to instance)
   #  --------------------


   #  Common variables: (shared by all instances)
   #  -----------------


#  End of class definition.
}
