#+
#  Name:
#     GaiaCupidImporter

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Creates a toolbox for importing a 3D catalogue created by the
#     CUPID application.

#  Description:
#     Imports a CUPID catalogue allowing the selection of the RA and Dec
#     axes columns and the columns that determine the extent of the
#     clump.

#  Invocations:
#
#        GaiaCupidImporter object_name [configuration options]
#
#     This creates an instance of a GaiaCupidImporter object. The return is
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
#    See itk_option define lines below.

#  Methods:
#     See method definitions below.

#  Inheritance:
#     TopLevelWidget.

#  Copyright:
#     Copyright (C) 2009 Science and Technology Facilities Council.
#     All Rights Reserved.

#  Licence:
#     This program is free software; you can redistribute it and/or
#     modify it under the terms of the GNU General Public License as
#     published by the Free Software Foundation; either version 2 of the
#     License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be
#     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
#     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
#     02111-1307, USA

#  Authors:
#     PWD: Peter Draper (JAC, Durham University)
#     {enter_new_authors_here}

#  History:
#     26-MAR-2009 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaCupidImporter {}

itcl::class gaia::GaiaCupidImporter {

   #  Inheritances:
   #  -------------

   inherit util::TopLevelWidget

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Catalog handler.
      set astrocat_ [astrocat $w_.cat]

      #  Evaluate any options
      eval itk_initialize $args

      #  Set up for 3D or 2D import.
      tune_

      #  Set the top-level window title.
      wm title $w_ "GAIA: import CUPID catalogue ($itk_option(-number))"

      #  Create the short help window.
      make_short_help
      $itk_component(short_help) configure -width 40

      #  Add File menu for usual stuff.
      add_menubar
      set File [add_menubutton "File"]
      configure_menubutton File -underline 0

      #  Option to close window.
      $File add command -label {Close window   } \
         -command [code $this close] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this close]

      #  Add window help.
      add_help_button cupidimport "On Window..."

      #  Add control for selecting the CUPID catalogue.
      itk_component add chooser {
         LabelFileChooser $w_.chooser \
            -text "Catalogue:" \
            -labelwidth 8 \
            -valuewidth 27 \
            -textvariable [scope itk_option(-catalogue)] \
            -command [code $this configure -catalogue] \
            -filter_types $itk_option(-filter_types) \
            -chooser_title "Choose a CUPID catalogue"
      }
      pack $itk_component(chooser) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(chooser) \
         {Name of the input catalogue, must be generated by CUPID}

      #  Series of dropdown boxes allowing the selection of the
      #  columns to use for world coordinates etc.
      foreach {label name} $coltypes_ {
         itk_component add $name {
            LabelMenu $w_.$name \
               -text "$label:" \
               -relief raised \
               -labelwidth 8 \
               -valuewidth 30
         }
         add_short_help $itk_component($name) \
            {Select a column for this value}

         pack $itk_component($name) -side top -ipadx 1m -ipady 1m \
            -anchor w -expand 1 -fill x

         #  Add the possible values. Fixed to CUPID values.
         foreach {colname index} $colnames_ {
            $itk_component($name) add \
               -command [code $this set_column $name $index] \
               -label $colname \
               -value $index
         }
      }

      #  Or use the STC shape.
      itk_component add stc {
         StarLabelCheck $w_.stc \
            -text "STC shape:" \
            -onvalue 1 -offvalue 0 \
            -labelwidth 8 \
            -variable [scope itk_option(-use_stc)]
      }
      pack $itk_component(stc) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(stc) {Draw STC shapes if available}

      #  Add buttons to import the catalogue and close the window.
      itk_component add actionframe {frame $w_.action}
      pack $itk_component(actionframe) -side bottom -fill x -pady 3 -padx 3

      itk_component add import {
         button $itk_component(actionframe).import -text Import\
               -command [code $this import_]
      }
      add_short_help $itk_component(import) \
         {Import catalogue, display in a window and overlay the image plane}
      pack $itk_component(import) -side left -expand 1 -pady 1 -padx 1

      #  Add a button to close window.
      itk_component add close {
         button $itk_component(actionframe).close -text Close \
               -command [code $this close]
      }
      add_short_help $itk_component(close) {Close window}
      pack $itk_component(close) -side left -expand 1 -pady 1 -padx 1
   }

   #  Destructor:
   #  -----------
   destructor  {
      if { [info exists tranwcs_] && $tranwcs_($catwin) != 0 } {
         catch {gaiautils::astannul $tranwcs_($catwin)}
      }
   }

   #  Methods:
   #  --------

   #  Called after UI is completed.
   public method init {} {
      set_defaults_
   }

   #  Withdraw this window.
   public method close {} {
      wm withdraw $w_
   }

   #  Set the default selections for columns.
   protected method set_defaults_ {} {
      $itk_component(ra) configure -value $ra_col_
      set index_(ra) $ra_col_
      $itk_component(dec) configure -value $dec_col_
      set index_(dec) $dec_col_
   }

   #  Set the column number used for a column type.
   public method set_column {name index} {
      set index_($name) $index
   }

   #  Import a given table.
   public method open {cat} {
      configure -catalogue $cat
      import_
   }

   #  Import the current table.
   protected method import_ {} {
      if { $itk_option(-catalogue) == {} } {
         warning_dialog "No catalogue has been selected" $w_
         return
      }
      if { ! [::file exists $itk_option(-catalogue)] } {
         warning_dialog "Catalogue '$itk_option(-catalogue)' doesn't exist" $w_
         return
      }
      gaia::GaiaSearch::allow_searches 0

      #  If this catalogue is already open and displayed we need to kill
      #  it to make sure the new info is used.
      set catalogue $itk_option(-catalogue)
      if { [info exists catwin_($catalogue)] } {
         $catwin_($catalogue) clear
         $catwin_($catalogue) remove_catalog
         destroy $catwin_($catalogue)
      }

      #  Now also clear any existing info data.
      if { ! [catch "$astrocat_ entry get $catalogue"] } {
         #  Catalogue already known, remove as may not match setup.
         $astrocat_ entry remove $catalogue
      }
      create_entry_ $catalogue

      #  Check this is a CUPID catalogue.
      $astrocat_ open $catalogue
      set headings [$astrocat_ headings]
      if { ! [string first "Peak1" $headings] == -1 } {
         $astrocat_ close
         error_dialog "Not a CUPID catalogue: $catalogue" $w_
         return
      }

      #  Now open the catalogue window.
      set catwin [gaia::GaiaSearch::new_local_catalog $catalogue \
                     [code $image_] ::gaia::GaiaSearch 0 catalog $w_\
                     [code $this set_cat_info_ $catalogue]]
      if { $catwin != {} } {
         set catwin_($catalogue) $catwin
      } else {
         set catwin $catwin_($catalogue)
      }

      #  Do we have STC?
      set have_stc_($catwin) 0
      set shape_col [lsearch -exact $headings Shape]
      if { $shape_col != -1 } {
         set have_stc_($catwin) 1
         set stc_col_ $shape_col
      } else {
         set have_stc_($catwin) 0
         set stc_col_ -1
      }

      #  Make sure slice coordinate is set for 3D import.
      if { $threed_ } {
         $itk_option(-gaiacube) set_cupid_coord 0
      }

      #  And display the catalogue. Note wait for the realization.
      wait_ "$catwin set_maxobjs 2000"
      gaia::GaiaSearch::allow_searches 1
      set_plot_symbol_ $catwin

      $catwin search
   }

   #  Set the columns in which the various coordinates are found. This
   #  is called just after the catalogue is opened so that we can apply
   #  the UI preferences (otherwise the catalogue meta-data is prefered).
   protected method set_cat_info_ {catalogue} {
      set id_col 0
      set ra_col $index_(ra)
      set dec_col $index_(dec)
      set x_col -1
      set y_col -1

      $astrocat_ entry update [list "id_col $id_col"] $catalogue
      $astrocat_ entry update [list "ra_col $ra_col"] $catalogue
      $astrocat_ entry update [list "dec_col $dec_col"] $catalogue
      $astrocat_ entry update [list "x_col -1"] $catalogue
      $astrocat_ entry update [list "y_col -1"] $catalogue
      $astrocat_ entry update [list "stc_col $stc_col_"] $catalogue
   }

   #  Wait for a command to return 1 (non-blocking?).
   protected method wait_ {cmd} {
      set ok [eval $cmd]
      if { ! $ok } {
         after 500
         update idletasks
         wait_ $cmd
      }
   }

   #  Define a basic symbol {COORD} is the coordinate of the current slice
   #  when doing a 3D import. This should be in catalogue spectral coordinates.
   #
   #  {SCALE} is a scale factor (sizes are sigmas, so 2 + 3 should be typical).
   #  Sizes are in arcsec for celestial coordinates.
   protected method set_plot_symbol_ {catwin} {

      #  XXX hack, parameterise this.
      set ::cupid(SCALE) 1.0

      if { $threed_ } {
         set cond {($Cen3 > ($%%cupid(COORD) - ($Size3*$%%cupid(SCALE)))) && ($Cen3 < ($%%cupid(COORD) + ($Size3*$%%cupid(SCALE))))}
         if { $itk_option(-use_stc) && $have_stc_($catwin) } {
            set symbol1 [list PIDENT Shape Cen3 Size1 Size2 Size3]
            set symbol2 [list stcshape green {} {} {} $cond]
            set symbol3 [list 1 {deg 2000.0}]
         } else {
            #  STC may be available, but not used for this import.
            set have_stc_($catwin) 0
            set symbol1 [list PIDENT Cen3 Size1 Size2 Size3]
            set symbol2 [list rectangle green {$Size2/$Size1} {} {} $cond]
            set symbol3 [list {$Size1/3600.0*$%%cupid(SCALE)} {deg 2000.0}]
         }

         #  Attach coordinates for ::cupid(COORD) transforms.
         attach_coord_ $catwin

      } else {
         if { $itk_option(-use_stc) && $have_stc_($catwin) } {
            set symbol1 [list PIDENT Shape Size1 Size2]
            set symbol2 [list stcshape green {} {} {} {}]
            set symbol3 [list 1 {deg 2000}]
         } else {
            #  STC may be available, but not used for this import.
            set have_stc_($catwin) 0
            set symbol1 [list PIDENT Size1 Size2]
            set symbol2 [list rectangle green {$Size2/$Size1} {} {} {}]
            set symbol3 [list {$Size1/3600.0*$%%cupid(SCALE)} {deg 2000}]
         }
      }
      $catwin set_symbol $symbol1 $symbol2 $symbol3
   }

   #  Create a initial entry describing the catalogue (used so that
   #  coordinate columns may be set before opening the real catalogue).
   protected method create_entry_ {catalogue} {
      set fname [full_name_ $catalogue]
      $astrocat_ entry add \
         [list "serv_type local" "long_name $fname" \
             "short_name $catalogue" "url $fname"]
   }

   #  Expand name to full path relative to current directory.
   protected method full_name_ {name} {
      if { "[string index $name 0]" != "/"} {
         set fname [pwd]/$name
      } else {
         set fname $name
      }
      return $fname
   }

   #  Refresh all catalogues that are displaying.
   public method replot {} {
      foreach {name catwin} [array get catwin_] {
         if { [winfo exists $catwin] && [wm state $catwin] != "withdrawn" } {
            $catwin plot
            ::update idletasks
         }
      }
   }

   #  Return a list of the imported catalogues. Instances of GaiaSearch.
   #  If requested only active, i.e. currently open instances will be
   #  returned.
   public method get {active} {
      set result {}
      if { [info exists catwin_] } {
         if { $active } {
            foreach {name catwin} [array get catwin_] {
               if { [wm state $catwin] != "withdrawn" } {
                  lappend result $catwin
               }
            }
         } else {
            foreach {name catwin} [array get catwin_] {
               lappend result $catwin
            }
         }
      }
      return $result
   }

   #  Return if a catalogue should be drawn using STC.
   public method using_stc {catwin} {
      if { [info exists have_stc_($catwin)] } {
         return $have_stc_($catwin)
      }
      return 0
   }

   #  Tune the various settings for 2 or 3D import.
   protected method tune_ {} {
      if { $threed_ } {
         set coltypes_ "RA ra Dec dec"
         set colnames_ "Peak1 1 Peak2 2 Peak3 3 Cen1 4 Cen2 5 Cen3 6"
         set ra_col_ 4
         set dec_col_ 5
      } else {
         set coltypes_ "RA ra Dec dec"
         set colnames_ "Peak1 1 Peak2 2 Cen1 3 Cen2 4"
         set ra_col_ 3
         set dec_col_ 4
      }
   }

   #  Set the extraction coordinate. Use when working in 3D and want only
   #  detections in the current slice shown.
   public method set_coord {coord} {
      if { $threed_ } {
         foreach {name catwin} [array get catwin_] {
            if { [winfo exists $catwin] && [wm state $catwin] != "withdrawn" &&
                 [info exists tranwcs_] && [info exists tranwcs_($catwin)] } {
               if { $tranwcs_($catwin) != 0 } {
                  #  Transform the coordinate into catalogue coordinates.
                  lassign [gaiautils::asttrann $tranwcs_($catwin) 1 \
                              "1 1 $coord"] c1 c2 c3
                  set coord $c3
               }
            }

            #  XXX but this is shared by all catalogues... So just do one
            #  or use another way.
            set ::cupid(COORD) $coord
         }
      } else {
         set ::cupid(COORD) $coord
      }
   }

   #  Re-attach all the catalogue WCS's to the cube. This is used so that the
   #  CUPID spectral coordinate can be set to match an extraction
   #  position. See set_coord. This should be called for new cubes and when
   #  cubes have their coordinate systems changed.
   public method attach_coords {} {
      if { $threed_ } {
         foreach {name catwin} [array get catwin_] {
            attach_coord_ $catwin
         }
      }
   }

   #  Attach the coordinates of a given catalogue window to that of the
   #  cube displayed in the associated gaiacube.
   protected method attach_coord_ {catwin} {

      #  Get cube WCS.
      set wcs [[$itk_option(-gaiacube) get_cubeaccessor] getwcs]
      if { $wcs == 0 || $wcs == {} } {
         return
      }

      if { [info exists tranwcs_] && $tranwcs_($catwin) != 0 } {
         catch {gaiautils::astannul $tranwcs_($catwin)}
      }
      set comments [$catwin comments]
      set tranwcs 0
      if { $comments != {} } {
         set astref [gaia::GaiaSearch::get_kaplibs_frameset $comments]
         if { $astref != 0 } {
            #  Want transformation from current coordinates of the catalogue
            # to current coordinates of the cube. So we connect them, going
            # ideally via SKY-DSBSPECTRUM or PIXEL coordinates.
            set wcs_current [gaiautils::astget $wcs "Current"]
            set wcs_base [gaiautils::astget $wcs "Base"]
            set tranwcs [gaiautils::astconvert $wcs $astref \
                            "SKY-DSBSPECTRUM,PIXEL,"]

            #  Restore any changes made by astconvert.
            gaiautils::astset $wcs "Current=$wcs_current"
            gaiautils::astset $wcs "Base=$wcs_base"
            gaiautils::astannul $astref
         }
      }
      set tranwcs_($catwin) $tranwcs
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  The Gaia instance for overlaying the catalogue. Only define
   #  this or -gaiacube, not both.
   itk_option define -gaia gaia Gaia {} {
      if { $itk_option(-gaia) != {} } {
         set image_ [$itk_option(-gaia) get_image]
         set threed_ 0
      }
   }

   #  The GaiaCube instance. If not set then a 2D import is assumed.
   itk_option define -gaiacube gaiacube GaiaCube {} {
      if { $itk_option(-gaiacube) != {} } {
         configure -gaia [$itk_option(-gaiacube) cget -gaia]
         set threed_ 1
      }
   }

   #  The catalogue.
   itk_option define -catalogue catalogue Catalogue {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0

   #  Filters for selecting files.
   itk_option define -filter_types filter_types Filter_types {{FITS *.FIT}}

   #  Prefer to use STC shapes as markers.
   itk_option define -use_stc use_stc Use_Stc 1

   #  Protected variables: (available to instance)
   #  --------------------

   #  Whether import is for 3D or 2D.
   protected variable threed_ 1

   #  Column names versus index chosen to represent them.
   protected variable index_

   #  Catalogue windows used for display.
   protected variable catwin_

   #  AST references for framesets that transform from a given spectral
   #  coordinate system to that of the catalogue.
   protected variable tranwcs_

   #  Image display elements.
   protected variable gaia_ {}
   protected variable image_ {}

   #  Local astrocat command.
   protected variable astrocat_ {}

   #  Does currently importing catalogue have a Shape column.
   protected variable have_stc_

   #  Special column types, display and window names.
   protected variable coltypes_ "RA ra Dec dec"

   #  CUPID column names we may use, plus the column index.
   protected variable colnames_ \
      "Peak1 1 Peak2 2 Peak3 3 Cen1 4 Cen2 5 Cen3 6"

   #  Various default column position.s
   protected variable ra_col_ -1
   protected variable dec_col_ -1
   protected variable stc_col_ -1

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
