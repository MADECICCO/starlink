#+
#  Name:
#     Stilts

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Invokes STILTS command to do things with tables.

#  Description:
#     Provides methods for invoking the external STILTS script.
#     It is assumed to be present in $::env(STILTS_DIR).

#  Configuration options:
#
#        -debug
#
#     Boolean flag which controls whether the "-debug" flag is to be
#     applied when STILTS is executed.  See SUN/256.
#
#        -verbose
#
#     Boolean flag which controls whether the "-verbose" flag is to be
#     applied when STILTS is executed.  See SUN/256.

#  Copyright:
#     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
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
#     MBT: Mark Taylor
#     {enter_new_authors_here}
            
#  History:
#     8-AUG-2006 (MBT):
#        Original version.
#     {enter_further_changes_here}

#- 
   
itcl::class gaia::Stilts {

   constructor {args} {
      eval configure $args
      set sbin {}
      if {[info exists ::env(STILTS_DIR)]} {
         set sbin $::env(STILTS_DIR)/stilts
      }
      if {[file isfile $sbin] && [file executable $sbin]} {
         set stilts_bin_ $sbin
      }
   }

   #  Returns true if a working STILTS binary has been found, and hence
   #  the execute method is expected to work.
   public method is_working {} {
      return [expr {$stilts_bin_ != ""}]
   }

   #  Executes a STILTS command.  The stilts_cmd argument is the name of
   #  the STILTS command to execute, e.g. "tpipe".  See SUN/256 for
   #  more information.
   public method execute {stilts_cmd args} {
      if {[is_working]} {
         set execargs [concat $stilts_bin_ $stilts_flags_ $stilts_cmd $args]
         return [eval exec $execargs]
      } else {
         set warning {No executable file ${STILTS_DIR}/stilts}
         if {!$warned_} {
            set warned_ 1
            error_dialog $warning
         }
         error $warning
      }
   }

   #  Ensures that the stilts_flags_ variable is up to date.
   protected method configure_flags_ {} {
      set sf ""
      if {$debug} {
         lappend sf -debug
      }
      if {$verbose} {
         lappend sf -verbose
      }
      set stilts_flags_ $sf
   }

   #  Configuration options: (public variables)
   #  ----------------------

   public variable debug {0} {
      configure_flags_
   }

   public variable verbose {0} {
      configure_flags_
   }


   #  Protected variables: (available to instance)
   #  --------------------

   #  Path to STILTS executable.
   protected variable stilts_bin_ {}

   #  Flags array for STILTS command.
   protected variable stilts_flags_ {}

   #  Protected common varabiables:
   #  -----------------------------

   #  Wnether a warning about non-functional STILTS has been posted yet.
   protected common warned_ 0
}
