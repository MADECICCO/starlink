#+
#  Name:
#     StarAstReference

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Defines a class that create a toolbox for creating a WCS system
#     for an image using reference positions.

#  Description:
#     This class create a toolbox which allows the creation of an
#     AST WCS. The method used is to get a minimal set of system and
#     projection information from the user (including the Equinox) and
#     then to relate a series of positions on the image with X, Y and
#     Lat, Long. Using the projection and table coordinate system
#     information a simple FrameSet to map from sky coordinates to
#     image coordinates is created, which is in turn refined (twice)
#     using a linear fit from the image coordinates that this produces
#     to the X and Y positions actually given. Note that little
#     control over the linear fit is given (needs at least an offset and
#     magnification anyway), except to exclude shear terms or define
#     that the axes are already aligned (hence no PC matrix). 
#
#     Note that the celestial coordinate system of the fit is
#     restricted to being that of the reference positions (which are
#     displayed in the table). If this needs to be changed then an
#     additional level of control is available via the StarAstSystem
#     toolbox.

#  Invocations:
#
#        StarAstReference object_name [configuration options]
#
#     This creates an instance of a StarAstReference object. The return is
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
#     TopLevelWidget.

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     19-DEC-1997 (PDRAPER):
#        Original version.
#     20-JAN-1998 (PDRAPER):
#        Rewrite to separate image coordinate system information from 
#        image related stuff.
#     {enter_further_changes_here}

#-

#.

itk::usual StarAstReference {}

itcl::class gaia::StarAstReference {

   #  Inheritances:
   #  -------------
   inherit util::TopLevelWidget

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Evaluate any options.
      eval itk_initialize $args

      #  Set the top-level window title.
      wm title $w_ \
         "GAIA: Fit astrometry reference positions ($itk_option(-number))"

      #  One off initializations.
      set_projp_

      #  Create the short help window.
      make_short_help

      #  Add the File menu.
      add_menubar
      set File [add_menubutton "File" left]
      configure_menubutton File -underline 0
      add_short_help $itk_component(menubar).file {File menu: close window}

      #  And the options to save and read reference positions.
      $File add command -label {Write positions to file...} \
         -command [code $this save_positions_] \
         -accelerator {Control-s}
      bind $w_ <Control-s> [code $this save_positions_]
      $short_help_win_ add_menu_short_help $File \
         {Write positions to file...}\
         {Write the displayed positions out to an ordinary text file}

      $File add command -label {Read positions from a file...} \
         -command [code $this read_positions_] \
         -accelerator {Control-r}
      bind $w_ <Control-r> [code $this read_positions_]
      $short_help_win_ add_menu_short_help $File \
         {Read positions from a file...} \
      {Read a suitable set of positions from an ordinary text file}

      #  Set the exit menu items.
      $File add command -label {Cancel changes and close window   } \
         -command [code $this cancel] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this cancel]
      $File add command -label {Accept changes and close window   } \
         -command [code $this accept] \
         -accelerator {Control-a}
      bind $w_ <Control-a> [code $this accept]

      #  Add window help.
      global env gaia_library
      add_help_button $gaia_library/StarAst.hlp "Astrometry Overview..."
      add_help_button $gaia_library/StarAstReference.hlp "On Window..."
      add_short_help $itk_component(menubar).help \
         {Help menu: get some help about this window}

      # Edit menu
      set Edit [add_menubutton Edit]

      #  Options menu. Set the fittype. Used to refine the initial
      #  guess to the reference positions, only control offerred is to
      #  stop any shear terms.
      set m [add_menubutton Options]
      add_short_help $itk_component(menubar).options {Set additional options}
      $m add cascade -label {Fit options} -menu [menu $m.fittype]
      $short_help_win_ add_menu_short_help $m {Fit options} \
         {Set the type of fit used to match the positions}
      set fithelp(3) {Assume axes are aligned}
      set fithelp(4) {Use one image scale with rotation}
      set fithelp(5) {Allow shearing terms}
      foreach i {3 4 5} {
         $m.fittype add radiobutton \
            -value $i \
            -label $fithelp($i) \
            -variable [scope values_($this,fittype)] \
            -command [code $this configure -fittype $i]
      }
      
      #  Allow the user to define the less useful values.
      $m add command -label {Additional parameters...   } \
	      -command [code $this show_additional_] \
	      -accelerator {Control-p}
      bind $w_ <Control-p> [code $this show_additional_]
      $short_help_win_ add_menu_short_help $m \
	      {Additional parameters...   } \
	      {Set reference pixel positions, latpole and longpole}

      #  Switch between moving graphics markers globally.
      $m add checkbutton -label {Markers move individually} \
         -command [code $this set_coupled_] \
	 -variable [scope values_($this,coupled)] \
	 -onvalue 0 -offvalue 1
      $short_help_win_ add_menu_short_help $m \
         {Markers move individually} \
      {Markers move individually or all together}

      #  Markers menu
      set Markers [add_menubutton Markers]

      #  Add the table for displaying the reference coordinate
      #  positions and some basic controls for convenience. Also
      #  adds to the edit menu and the markers menu which controls
      #  the apperance of the graphics markers.
      itk_component add table {
         StarAstTable $w_.table \
		 -editmenu $Edit \
		 -markmenu $Markers \
		 -rtdimage $itk_option(-rtdimage) \
		 -canvas $itk_option(-canvas) \
		 -image $itk_option(-image) \
		 -notify_cmd [code $this fix_equinox_]
      }
      add_short_help $itk_component(table) \
         {Reference sky positions and their ideal/current X,Y places}

      #  Add entry widgets that specify the coordinate types, system
      #  etc. of the table values.
      itk_component add space1 {
         LabelRule $w_.space1 -text "Parameters for table coordinates:"
      }

      #  Coordinate type for the table data (both CTYPES).
      itk_component add ctype {
         LabelMenu $w_.ctype -relief raised \
	    -valuewidth $vwidth_ \
	    -labelwidth $lwidth_ \
	    -text "Coordinate type:"
      }
      add_short_help $itk_component(ctype) \
         {Type of coordinates in table}
      foreach {lname value ctype1 ctype2} $ctypemap_ {
         $itk_component(ctype) add \
            -label $lname \
            -value $value \
            -command [code $this set_ctype_ $value]
      }

      #  RADECSYS, EQUINOX and EPOCH of table values.
      itk_component add system {
         util::LabelMenu $w_.system \
            -relief raised \
	    -labelwidth $lwidth_ \
	    -valuewidth $vwidth_ \
	    -text "Coordinate system:"
      }
      add_short_help $itk_component(system) \
	      {Table coordinates frame of reference for RA/Dec systems}
      foreach {system needequinox needepoch} $systemattrib_ {
	  $itk_component(system) add \
		  -command [code $this set_system_ $system $needequinox $needepoch] \
		  -label $system \
		  -value $system
      }

      #  Equinox, J2000 or B1950 usually.
      itk_component add equinox {
         LabelEntryMenu $w_.equinox \
            -textvariable [scope values_($this,equinox)] \
	    -labelwidth $lwidth_ \
	    -valuewidth $vwidth_ \
	    -text "Equinox:"
      }
      add_short_help $itk_component(equinox) \
         {Equinox of table coordinates ((B/J)decimal years)}
      foreach equinox $equinoxmap_ {
         $itk_component(equinox) add \
            -label $equinox \
            -value $equinox \
            -command [code $this set_equinox_ $equinox]
      }

      #  Epoch, only needed for FK4 really.
      itk_component add epoch {
         LabelEntryMenu $w_.epoch \
            -textvariable [scope values_($this,epoch)] \
	    -labelwidth $lwidth_ \
	    -valuewidth $vwidth_ \
	    -text "Epoch:"
      }
      add_short_help $itk_component(epoch) \
         {Epoch of table coordinates ((B/J)decimal years)}
      foreach equinox $equinoxmap_ {
         $itk_component(epoch) add \
            -label $equinox \
            -value $equinox \
            -command [code $this set_epoch_ $equinox]
      }

      #  Add a section to get the projection type and any necessary
      #  PROJP parameters (note we don't allow ZPN as this requires
      #  another 8 PROJP's!
      itk_component add space2 {
         LabelRule $w_.space2 -text "Image parameters:"
      }
      itk_component add proj {
	  LabelMenu $w_.proj -relief raised \
		  -labelwidth $lwidth_ \
		  -valuewidth 40 \
		  -text "Projection type:"
      }
      add_short_help $itk_component(proj) \
	      {Method used to project celestial sphere onto image}
      foreach {label value} $projectmap_ {
	  $itk_component(proj) add \
		  -label "$label ($value)" \
		  -value $value \
		  -command [code $this set_proj_ $value]
      }
      itk_component add projp1 {
         LabelEntry $w_.projp1 \
		 -textvariable [scope values_($this,projp1)] \
		 -labelwidth $lwidth_ \
		 -valuewidth $vwidth_ \
		 -text "projp1:"
      }
      add_short_help $itk_component(projp1) \
	      {First projection parameter (PROJP1)}

      itk_component add projp2 {
	  LabelEntry $w_.projp2 \
		  -textvariable [scope values_($this,projp2)] \
		  -labelwidth $lwidth_ \
		  -valuewidth $vwidth_ \
		  -text "projp2:"
      }
      add_short_help $itk_component(projp2) \
         {Second projection parameter (PROJP2)}

      #  Check if X axes is to be associated with longitude or
      #  latitude axis.
      itk_component add xislong {
         LabelMenu $w_.xislong -relief raised \
            -labelwidth $lwidth_ \
            -valuewidth $vwidth_ \
            -text "X coordinate type:"
      }
      add_short_help $itk_component(xislong) \
         {Celestial coordinate type of image X axis}
      $itk_component(xislong) add -label "RA/Longitude" -value 1 \
         -command [code $this set_xislong_ 1]
      $itk_component(xislong) add -label "Dec/Latitude" -value 0 \
         -command [code $this set_xislong_ 0]

      #  Make window for additional items.
      make_additional_

      #  Create the button bar
      itk_component add actionframe {frame $w_.action}

      #  Add a button to close window and accept the new WCS.
      itk_component add accept {
         button $itk_component(actionframe).accept -text Accept \
            -command [code $this accept]
      }
      add_short_help $itk_component(accept) \
         {Accept new astrometric calibration and close window}

      #  Add a button to test the WCS.
      itk_component add test {
         button $itk_component(actionframe).test -text {Fit/Test} \
            -command [code $this test]
      }
      add_short_help $itk_component(test) \
         {Perform astrometric calibration fit and assign result to image}

      #  Add a button to close window and not accept the new WCS.
      itk_component add cancel {
         button $itk_component(actionframe).cancel -text Cancel \
            -command [code $this cancel]
      }
      add_short_help $itk_component(cancel) \
         {Close window and restore original astrometric calibration}

      #  Add a button to reset the entries and return to the original
      #  image WCS.
      itk_component add reset {
         button $itk_component(actionframe).reset -text Reset \
            -command [code $this reset_]
      }
      add_short_help $itk_component(reset) \
         {Reset image and window to defaults}

      #  Add a scrollbox to display results of fit.
      itk_component add results {
         Scrollbox $w_.results -height 3
      }
      add_short_help $itk_component(results) {Results of fit}

      #  Reset all fields (thereby initialising them).
      reset_

      #  Pack all other widgets into place.
      pack $itk_component(table) -side top -fill both -expand 1
      pack $itk_component(space1) -side top -fill x -pady 5 -padx 5
      pack $itk_component(ctype) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(system) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(equinox) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(epoch) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(space2) -side top -fill x -pady 5 -padx 5
      pack $itk_component(proj) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(projp1) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(projp2) -side top -pady 1 -padx 1 -anchor w
      pack $itk_component(xislong) -side top -pady 1 -padx 1 -anchor w

      pack $itk_component(results) -side bottom -fill x -pady 3 -padx 3

      pack $itk_component(actionframe) -side bottom -fill x -pady 3 -padx 3
      pack $itk_component(accept) -side right -expand 1 -pady 1 -padx 1
      pack $itk_component(cancel) -side right -expand 1 -pady 1 -padx 1
      pack $itk_component(reset)  -side right -expand 1 -pady 1 -padx 1
      pack $itk_component(test)   -side right -expand 1 -pady 1 -padx 1
   }

   #  Destructor:
   #  -----------
   destructor  {
      $itk_component(table) delete
      if { [winfo exists $add_] } {
         $add_ delete
      }
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
            notify_
         }
      }
      set testing_ 0
      clear_
   }

   #  Withdraw window and write new WCS to image -- permanently.
   public method accept {} {
      if { !$testing_ } {
         set_wcs_
      }
      wm withdraw $w_
      clear_
      set testing_ 0
      $itk_option(-rtdimage) astfix
   }

   #  Test the WCS by making it the current system.
   public method test {} {
      set_wcs_
      set testing_ 1
   }

   #  Reset all fields to their default values and retore the original
   #  image WCS.
   protected method reset_ {} {
      $itk_component(xislong) configure -value 1
      set_xislong_ 1

      $itk_component(ctype) configure -value Equatorial
      set_ctype_ Equatorial

      set_proj_ -TAN
      $itk_component(proj) configure -value -TAN

      set_equinox_ 2000
      set_epoch_ 2000
      set_system_ FK5 1 0

      set values_($this,projp1) {}
      $itk_component(projp1) configure -value {}
      set values_($this,projp2) {}
      $itk_component(projp2) configure -value {}

      set values_($this,crpix1) [expr [$itk_option(-rtdimage) width]/2]
      $add_.crpix1 configure -value $values_($this,crpix1) 
      set values_($this,crpix2) [expr [$itk_option(-rtdimage) height]/2]
      $add_.crpix2 configure -value $values_($this,crpix2) 

      set values_($this,longpole) {}
      $add_.longpole configure -value {}
      set values_($this,latpole) {}
      $add_.latpole configure -value {}

      set values_($this,coupled) 0
      set_coupled_

      #  Restore WCS system to the original (if available).
      if { $itk_option(-rtdimage) != {} } {
         catch {
            $itk_option(-rtdimage) astrestore original
         }
	 $itk_component(table) update_x_and_y
         notify_
      }
      set testing_ 0
   }

   #  Set the WCS system of the main image to be one based on the
   #  values given in the entry fields and then do a fit to the X and
   #  Y positions.
   protected method set_wcs_ {} {

      #  Method is simple. Read all the values and construct a FITS
      #  channel filled with cards. Then attempt to create an AST
      #  object which can be used to replace the existing WCS system.
      #  Then refine it a couple of times more to get an accurate 
      #  reference pixel position.
      if { $itk_option(-rtdimage) != {} } {

         #  See if preferred longitude direction is along the X axis.
         if { $values_($this,xislong) } {
            set reversed 0
         } else {
            set reversed 1
         }
         lassign [wcs_stats_ $reversed] mean1 mean2 xscale_ yscale_
         if { $itk_option(-fittype) == 4 } {
            #  Just one magnification, so make same for both axes
            #  preserving sign.
            set yscale_ [expr $xscale_*$yscale_/abs($yscale_)]
         }
         create_wcs_ $reversed $mean1 $mean2 $xscale_ $yscale_ 0.0

         #  Now refine the WCS to produce a good solution. Note we
         #  reset the angle as each refinement is an incremental
         #  change in this.
         set angle_ 0.0
	 refine_ 0

         #  Now we repeat the above, but using the better fit derive
         #  the initial conditions. This refines the reference
         #  position to be correct and adds in the rotation angle.
         lassign [$itk_option(-rtdimage) astpix2wcs \
                     $values_($this,crpix1) \
                     $values_($this,crpix2)] crval1 crval2
         create_wcs_ $reversed $crval1 $crval2 $xscale_ $yscale_ [expr -1.0*$angle_]
	 refine_ 1
      }
   }


   #  Create a WCS from the FITS description that we've got and some 
   #  initial values.
   protected method create_wcs_ {reversed crval1 crval2 xscale yscale angle} {
      set image $itk_option(-rtdimage)
      set chan [$image astcreate]

      #  Set the basic elements. If needed swap the sense.
      if { $reversed } {
         $image aststore $chan CTYPE1 "'$values_($this,ctype2)$values_($this,proj)'"
         $image aststore $chan CTYPE2 "'$values_($this,ctype1)$values_($this,proj)'"
         $image aststore $chan CRVAL1 $crval2
         $image aststore $chan CRVAL2 $crval1
         $image aststore $chan CROTA1 $angle
      } else {
         $image aststore $chan CTYPE1 "'$values_($this,ctype1)$values_($this,proj)'"
         $image aststore $chan CTYPE2 "'$values_($this,ctype2)$values_($this,proj)'"
         $image aststore $chan CRVAL1 $crval1
         $image aststore $chan CRVAL2 $crval2
         $image aststore $chan CROTA2 $angle
      }
      $image aststore $chan CDELT1 $xscale_
      $image aststore $chan CDELT2 $yscale_
      
      #  Add the reference point (usually approximate).
      $image aststore $chan CRPIX1 $values_($this,crpix1)
      $image aststore $chan CRPIX2 $values_($this,crpix2)
      
      #  Only record a RADECSYS if needed.
      if { $values_($this,system) != {} } {
         if { $values_($this,ctype) == "Equatorial" } {
            $image aststore $chan RADECSYS "'$values_($this,system)'"
         }
      }

      #  Most systems need an equinox (if B/J present use string).
      if { $values_($this,equinox) != {} } {
         if { [regexp {J(.*)|B(.*)} $values_($this,equinox) all value] } {
            $image aststore $chan EQUINOX "'$values_($this,equinox)'"
         } else {
            $image aststore $chan EQUINOX $values_($this,equinox)
         }
      }

      #  And a MJD to go with it (note conversion of B/J/G date to MJD).
      if { $values_($this,epoch) != {} } {
         $image aststore $chan MJD-OBS [find_epoch_ $values_($this,epoch)]
      }
      
      #  If needed for this projection, and available add the PROJP
      #  values.
      if { $projpmap_($values_($this,proj),1) } {
         if { $values_($this,projp1) != {} } {
            $image aststore $chan PROJP1 $values_($this,projp1)
         }
      }
      if { $projpmap_($values_($this,proj),2) } {
         if { $values_($this,projp2) != {} } {
            $image aststore $chan PROJP2 $values_($this,projp2)
         }
      }
      
      #  If set add LONGPOLE and LATPOLE.
      if { $values_($this,longpole) != {} } {
         $image aststore $chan LONGPOLE $values_($this,longpole)
      }
      if { $values_($this,latpole) != {} } {
         $image aststore $chan LATPOLE $values_($this,latpole)
      }
      
      #  Read the channel to create an AST object and then replace
      #  the current WCS using it.
      $image astread $chan
      $image astreplace
      $image astdelete $chan
   }

   #  Perform a refinement on the current positions.
   protected method refine_ {update} {

      #  Extract the contents of the TableList and create the
      #  current projected image coordinates. Also keep a list of
      #  positions which these are expected to correspond to.
      set nrows [$itk_component(table) total_rows]
      set contents [$itk_component(table) get_contents]
      set newcoords {}
      set oldcoords {}
      set npoint 0

      #  If the association X-RA is reversed then flip x and y.
      for { set i 0 } { $i < $nrows } { incr i } {
         lassign [lindex $contents $i] id ra dec newx newy
         if { [ catch { $itk_option(-rtdimage) \
                           astwcs2pix $ra $dec } msg ] == 0 } {
            lassign $msg oldx oldy
            incr npoint
            lappend newcoords $newx $newy
            lappend oldcoords $oldx $oldy
         }
      }
      if { $npoint > 0 } {
         set ret 1
         busy {
            if { [catch { $itk_option(-rtdimage) astrefine image \
                             $itk_option(-fittype) \
                             $oldcoords $newcoords } errmsg] == 0 } {

               #  Succeeded, so record the new estimates of the image
               #  scale and then, if requested update the X and Y
               #  positions and make a report on the fit.
               $itk_option(-rtdimage) astreplace
               notify_
               set xscale_ [expr $xscale_/[lindex $errmsg 9]]
               set yscale_ [expr $yscale_/[lindex $errmsg 10]]
               set angle_  [expr [lindex $errmsg 12]+$angle_]
               if { $update } { 
                  set fitqual [$itk_component(table) update_x_and_y 1]

                  #  Report the results of the fit.
                  report_result_ "Rms of fit = $fitqual (pixels)" \
                     "x,y scales = [expr $xscale_*3600.0] \
                                   [expr $yscale_*3600.0] (arcsec/pixel)" \
                     "orientation = $angle_ (degrees)"
               }
            } else {
               error_dialog "$errmsg"
               set ret 0
            }
         }
      } else {
         error_dialog {Sorry there are no valid positions available}
      }
   }

   #  Record the value of the selected RADECSYS and configure the
   #  equinox entry window appropriately.
   protected method set_system_ {value needequinox needepoch} {
       set values_($this,system) $value
       $itk_component(system) configure -value $value
       if { ! $needequinox } {
	   $itk_component(equinox) configure -value {}
	   $itk_component(equinox) configure -state disabled
       } else {
	   set default [lindex $systemmap_ [expr [lsearch $systemmap_ $value]+1]]
	   $itk_component(equinox) configure -value $default
	   $itk_component(equinox) configure -state normal
       }
       if { ! $needepoch } {
	   $itk_component(epoch) configure -value {}
	   $itk_component(epoch) configure -state disabled
       } else {
	   set default [lindex $systemmap_ [expr [lsearch $systemmap_ $value]+1]]
	   $itk_component(epoch) configure -value $default
	   $itk_component(epoch) configure -state normal
       }
   }

   #  Set the value of the table coordinate types. Also disable the
   #  system selection unless the type is Equatorial (this means we
   #  should also check the equinox and epoch fields for dependency).
   protected method set_ctype_ {value} {
      
      #  Get the ctypes associated with this system.
      set ctype1 [lindex $ctypemap_ [expr [lsearch $ctypemap_ $value]+1]]
      set ctype2 [lindex $ctypemap_ [expr [lsearch $ctypemap_ $value]+2]]
      set values_($this,ctype) $value
      set values_($this,ctype1) $ctype1
      set values_($this,ctype2) $ctype2
      if { $value == "Equatorial" } {
         $itk_component(system) configure -state normal
         set text [[$itk_component(system) component mb] cget -text]
         if { $text == "Ecliptic" || $text == "Galactic" } { 
            set_system_ FK5 1 0
         }
      } else {
         $itk_component(system) configure -state disabled
         if { $value == "Ecliptic" } {
            set_system_ {} 1 0
            [$itk_component(system) component mb] configure -text Ecliptic
         } else {
            set_system_ {} 0 0
            [$itk_component(system) component mb] configure -text Galactic
         }
         set values_($this,system) {}
      }
   }

   #  Set the value of the equinox entry window.
   protected method set_equinox_ {value} {
      set values_($this,equinox) $value
      $itk_component(equinox) configure -value $values_($this,equinox)
      $itk_component(table) configure -equinox $values_($this,equinox)
   }

   #  Set the value of the epoch entry window.
   protected method set_epoch_ {value} {
      set values_($this,epoch) $value
      $itk_component(epoch) configure -value $values_($this,epoch)
   }

   #  Translate an epoch like B1950 to an MJD.
   protected method find_epoch_ {value} {
      if {[regexp {J(.*)} $value all decyears]} {
         set julian 1
      } elseif {[regexp {B(.*)} $value all decyears]} {
         set julian 0
      } elseif { $value < 1984.0 } { 
         set julian 0
         set decyears $value
      } else {
         set julian 1
         set decyears $value
      }
      if { $julian } { 
         return  [expr 51544.5+($decyears-2000.0)*365.25]
      } else {
         return  [expr 15019.81352+($decyears-1900.0)*365.242198781]
      }
   }

   #  Fix the value of the equinox to a catalogue value. Note epoch
   #  assumed to be the same.
   protected method fix_equinox_ {equinox} {
      set_equinox_ $equinox
      set_epoch_ $equinox
      if { $values_($this,equinox) < 1984 } {
         set_system_ FK4 1 1
      }  else {
         set_system_ FK5 1 0
      }
   }

   #  Set the projection type. Also enables the PROJP section if
   #  necessary.
   protected method set_proj_ {proj} {
      set values_($this,proj) $proj
      if { $projpmap_($proj,1) } {
         $itk_component(projp1) configure -state normal
      } else {
	 $itk_component(projp1) configure -value {}
         $itk_component(projp1) configure -state disabled
      }
      if { $projpmap_($proj,2) } {
         $itk_component(projp2) configure -state normal
      } else {
	 $itk_component(projp2) configure -value {}
         $itk_component(projp2) configure -state disabled
      }
   }

   #  Set which PROJP parameters are required for which projections.
   protected method set_projp_ {} {
      if { ![info exists projpmap_(-TAN,1)] } {
         set projpmap_(-TAN,1) 0
         set projpmap_(-TAN,2) 0
         set projpmap_(-SIN,1) 1
         set projpmap_(-SIN,2) 1
         set projpmap_(-ARC,1) 0
         set projpmap_(-ARC,2) 0
         set projpmap_(-AZP,1) 1
         set projpmap_(-AZP,2) 0
         set projpmap_(-STG,1) 0
         set projpmap_(-STG,2) 0
         set projpmap_(-ZEA,1) 0
         set projpmap_(-ZEA,2) 0
         set projpmap_(-AIR,1) 1
         set projpmap_(-AIR,2) 0
         set projpmap_(-CYP,1) 1
         set projpmap_(-CYP,2) 1
         set projpmap_(-CAR,1) 0
         set projpmap_(-CAR,2) 0
         set projpmap_(-MER,1) 0
         set projpmap_(-MER,2) 0
         set projpmap_(-CEA,1) 1
         set projpmap_(-CEA,2) 0
         set projpmap_(-COP,1) 1
         set projpmap_(-COP,2) 1
         set projpmap_(-COD,1) 1
         set projpmap_(-COD,2) 1
         set projpmap_(-COE,1) 1
         set projpmap_(-COE,2) 1
         set projpmap_(-COO,1) 1
         set projpmap_(-COO,2) 1
         set projpmap_(-BON,1) 1
         set projpmap_(-BON,2) 0
         set projpmap_(-PCO,1) 0
         set projpmap_(-PCO,2) 0
         set projpmap_(-GLS,1) 0
         set projpmap_(-GLS,2) 0
         set projpmap_(-PAR,1) 0
         set projpmap_(-PAR,2) 0
         set projpmap_(-AIT,1) 0
         set projpmap_(-AIT,2) 0
         set projpmap_(-MOL,1) 0
         set projpmap_(-MOL,2) 0
         set projpmap_(-CSC,1) 0
         set projpmap_(-CSC,2) 0
         set projpmap_(-QSC,1) 0
         set projpmap_(-QSC,2) 0
         set projpmap_(-TSC,1) 0
         set projpmap_(-TSC,2) 0
      }
   }

   #  Derive useful statistics about the RA/Dec and X,Y positions
   #  (meanra, meandec, xscale, yscale). Note that if requested then
   #  the association between X-Y and RA-Dec is reversed.
   protected method wcs_stats_ {{reversed 0}} {
      set nrows [$itk_component(table) total_rows]
      set contents [$itk_component(table) get_contents]
      set radec ""
      set xy ""
      if { ! $reversed } {
         for { set i 0 } { $i < $nrows } { incr i } {
            lassign [lindex $contents $i] id ra dec x y
            append radec "$ra $dec "
            append xy "$x $y "
         }
      } else {
         for { set i 0 } { $i < $nrows } { incr i } {
            lassign [lindex $contents $i] id ra dec x y
            append radec "$ra $dec "
            append xy "$y $x "
         }
      }
      return [$itk_option(-rtdimage) astbootstats \
                 $radec $xy $values_($this,crpix1) $values_($this,crpix2)]
   }

   #  Clear the graphics markers from canvas.
   protected method clear_ {} {
       $itk_component(table) clear_marks
   }

   #  Enter a report in the results window.
   protected method report_result_ {args} {
      $itk_component(results) clear all
      foreach line "$args" {
         $itk_component(results) insert end $line
      }
   }

   #  Read and write reference positions to a file.
   protected method read_positions_ {} {
      $itk_component(table) read_from_file
   }
   protected method save_positions_ {} {
      $itk_component(table) write_to_file
   }

   #  Do the notify_cmd option if needed.
   protected method notify_ {} {
      if { $itk_option(-notify_cmd) != {} } {
         eval $itk_option(-notify_cmd)
      }
   }

   #  Create a toplevel windows displaying additional options.
   protected method make_additional_ {} {
      set add_ [TopLevelWidget $w_.add \
                   -transient $itk_option(-transient) \
                   -withdraw 1 \
                   -center 0]

      #  Set the top-level window title.
      wm title $add_ \
         "GAIA: Additional parameters ($itk_option(-number))"

      #  Create the short help window.
      $add_ make_short_help

      #  Add the File menu.
      $add_ add_menubar
      set File [$add_ add_menubutton "File" left]
      $add_ configure_menubutton File -underline 0
      $add_ add_short_help [$add_ component menubar].file \
         {File menu: close window}
      $File add command -label {Close window   } \
         -command [code $this hide_additional_] \
         -accelerator {Control-c}
      bind $add_ <Control-c> [code $this hide_additional_]

      $add_ itk_component add space1 {
         LabelRule $add_.space1 -text "Additional parameters:"
      }
      #  Reference pixels
      $add_ itk_component add crpix1 {
         LabelEntry $add_.crpix1 \
            -labelwidth $lwidth_ \
            -valuewidth $vwidth_ \
            -text "X Reference pixel:" \
            -textvariable [scope values_($this,crpix1)]
      }
      $add_ add_short_help $add_.crpix1 \
         {Estimated X coordinate of image reference pixel (1,1 is centre of first pixel)}

      $add_ itk_component add crpix2 {
         LabelEntry $add_.crpix2 \
            -labelwidth $lwidth_ \
            -valuewidth $vwidth_ \
            -text "Y Reference pixel:" \
            -textvariable [scope values_($this,crpix2)]
      }
      $add_ add_short_help $add_.crpix2 \
         {Estimated Y coordinate of image reference pixel (1,1 is centre of first pixel)}

      # Longpole AND latpole.
      $add_ itk_component add longpole {
         LabelEntry $add_.longpole \
            -text "Longpole:" \
            -labelwidth $lwidth_ \
            -valuewidth $vwidth_ \
            -textvariable [scope values_($this,longpole)]
      }
      $add_ add_short_help $add_.longpole \
         {Longitude of table system northpole}
      $add_ itk_component add latpole {
         LabelEntry $add_.latpole \
            -text "Latpole:" \
            -labelwidth $lwidth_ \
            -valuewidth $vwidth_ \
            -textvariable [scope values_($this,latpole)]
      }
      $add_ add_short_help $add_.latpole \
         {Latitude of table system northpole}

      #  Add a button to close window.
      $add_ itk_component add accept {
         button $add_.close -text Close \
            -command [code $this hide_additional_]
      }
      $add_ add_short_help $add_.close {Close window}

      pack $add_.space1 -side top -pady 1 -padx 1 -fill x 
      pack $add_.crpix1 -side top -pady 1 -padx 1 -anchor w
      pack $add_.crpix2 -side top -pady 1 -padx 1 -anchor w
      pack $add_.longpole -side top -pady 1 -padx 1 -anchor w
      pack $add_.latpole -side top -pady 1 -padx 1 -anchor w
      pack $add_.close -expand 1 -side bottom -pady 1 -padx 1
   }

   #  Show the additional parameters window.
   protected method show_additional_ {} {
      if { ! [winfo exists $add_] } { 
         make_additional_
      }
      $add_ configure -center 1
   }

   #  Hide the additional parameters window.
   protected method hide_additional_ {} {
      if { [winfo exists $add_] } { 
         wm withdraw $add_
      }
   }

   #  Set xislong variable to a value.
   protected method set_xislong_ {value} {
      set values_($this,xislong) $value
   }

   #  Set marker movement policy.
   protected method set_coupled_ {} {
       $itk_component(table) configure -coupled $values_($this,coupled)
   }

   #  Configuration options
   #  =====================

   #  Name of starrtdimage widget.
   itk_option define -rtdimage rtdimage RtdImage {}

   #  Name of the canvas holding the starrtdimage widget.
   itk_option define -canvas canvas Canvas {}

   #  Name of the RtdImage widget or derived class.
   itk_option define -image image Image {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0

   #  The type of fit to be used when refining the coordinate system.
   itk_option define -fittype fittype Fittype 5 {
      set values_($this,fittype) $itk_option(-fittype)
   }

   #  Command to execute when the WCS is changed.
   itk_option define -notify_cmd notify_cmd Notify_Cmd {}

   #  Protected variables: (available to instance)
   #  --------------------

   #  Default values of the controls.
   protected variable default_

   #  The known types of coordinates and their FITS synonyms.
   protected variable ctypemap_ \
      { {Equatorial (RA/Dec)} {Equatorial} {RA--} {DEC-} \
        {Ecliptic (Long/Lat)} {Ecliptic} {ELON} {ELAT} \
        {Galactic (Long/Lat)} {Galactic} {GLON} {GLAT} \
        {SuperGalactic (Long/Lat)} {SuperGalactic} {SLON} {SLAT}}
   #  Not implemented helioecliptic.

   #  The available projections and their long descriptions (note no
   #  ZPN, requires too many PROJP's).
   protected variable projectmap_ \
      { {Gnomic (tangent plane)} -TAN {Orthographic} -SIN
         {Zenithal equidistant} -ARC {Zenithal perspective} -AZP
         {Sterographic} -STG
         {Zenithal equal-area} -ZEA {Airy} -AIR
         {Cylindrical perspective} -CYP {Cartesian} -CAR {Mercator} -MER
         {Cylindrical equal area} -CEA {Conical perspective} -COP
         {Conical equidistant} -COD {Conical equal-area} -COE
         {Conical orthomorthic} -COO {Bonne's equal area} -BON
         {Polyconic} -PCO {Sinusoidal} -GLS {Parabolic} -PAR
         {Hammer-Aitoff} -AIT {Mollweide} -MOL
         {Cobe Quadtrilaterized Spherical Cube} -CSC
         {Quadtrilaterized Spherical Cube} -QSC
         {Tangential Spherical Cube} -TSC}

   #  Names of all the possible RA/DEC fundermental coordinate
   #  systems. The values following these are the need for an equinox
   #  and an epoch.
   protected variable systemattrib_ \
      {FK5 1 0 FK4 1 1 FK4-NO-E 1 1 GAPPT 0 1}

   #  Array of the various system names and their default
   #  equinoxes and the initialising list.
   protected variable systemmap_ {FK5 J2000 FK4 B1950 FK4-NO-E B1950 GAPPT {} }

   #  Names of sensible some equinoxes.
   protected variable equinoxmap_ {J2000.0 B1950.0}

   #  Widths of various fields.
   protected variable vwidth_ 20
   protected variable lwidth_ 20

   #  Whether a WCS system is being tested or not.
   protected variable testing_ 0

   #  Scales used in initial WCS system.
   protected variable xscale_ 1.0
   protected variable yscale_ 1.0

   #  Rotation angle.
   protected variable angle_ 0.0

   #  Name of additional toplevel window.
   protected variable add_ {}

   #  Common variables: (shared by all instances)
   #  -----------------

   #  Which PROJP parameters are required for which projections.
   common projpmap_

   #  Variable to share amongst all widgets. This is indexed by the
   #  object name ($this)
   common values_

#  End of class definition.
}
