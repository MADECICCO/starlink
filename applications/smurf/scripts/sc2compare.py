#!/usr/bin/env python

'''
*+
*  Name:
*     sc2compare

*  Purpose:
*     Compare two SCUBA-2 maps for equivalence.

*  Language:
*     python (2.7 or 3.*)

*  Description:
*     This script compares two SCUBA_2 maps using a variety of tests.
*     If any of the tests indicate that the two maps are significantly
*     different in any way, then a report is made describing the
*     differences and stored in the text file specified by parameter
*     REPORT (the report is not displayed on the screen). No report
*     file is created if no significant differences are found. A flag
*     indicating if any differences were found is stored in output
*     parameter SIMILAR on exit.
*
*     The tests are performed by the kappa:ndfcompare task, which is
*     used to compare the main map NDFs, and then the two extension
*     NDFs - MORE.SMURF.WEIGHTS and MORE.SMURF.EXP_TIME. See the
*     documentation for kappa:ndfcompare in SUN/95 for further
*     information about the comparison process.

*  Usage:
*     sc2compare in1 in2 [report] [retain] [msg_filter] [ilevel]
*                [glevel] [logfile]

*  Parameters:
*     GLEVEL = LITERAL (Read)
*        Controls the level of information to write to a text log file.
*        Allowed values are as for "ILEVEL". The log file to create is
*        specified via parameter "LOGFILE. ["NONE"]
*     ILEVEL = LITERAL (Read)
*        Controls the level of information displayed on the screen by the
*        script. It can take any of the following values (note, these values
*        are purposefully different to the SUN/104 values to avoid confusion
*        in their effects):
*
*        - "NONE": No screen output is created
*
*        - "CRITICAL": Only critical messages are displayed such as warnings.
*
*        - "PROGRESS": Extra messages indicating script progress are also
*        displayed.
*
*        - "ATASK": Extra messages are also displayed describing each atask
*        invocation. Lines starting with ">>>" indicate the command name
*        and parameter values, and subsequent lines hold the screen output
*        generated by the command.
*
*        - "DEBUG": Extra messages are also displayed containing unspecified
*        debugging information. In addition scatter plots showing how each Q
*        and U image compares to the mean Q and U image are displayed at this
*        ILEVEL.
*
*        ["PROGRESS"]
*     IN1 = NDF (Read)
*        The first SCUBA_2 map.
*     IN2 = NDF (Read)
*        The second SCUBA_2 map.
*     LOGFILE = LITERAL (Read)
*        The name of the log file to create if GLEVEL is not NONE. The
*        default is "<command>.log", where <command> is the name of the
*        executing script (minus any trailing ".py" suffix), and will be
*        created in the current directory. Any file with the same name is
*        over-written. []
*     MSG_FILTER = LITERAL (Read)
*        Controls the default level of information reported by Starlink
*        atasks invoked within the executing script. This default can be
*        over-ridden by including a value for the msg_filter parameter
*        within the command string passed to the "invoke" function. The
*        accepted values are the list defined in SUN/104 ("None", "Quiet",
*        "Normal", "Verbose", etc). ["Normal"]
*     REPORT = _LOGICAL (Read)
*        The name of a text file in which to store the report describing
*        the differences between IN1 and IN2. No file is created if no
*        differences are found. ["sc2compare.rep"]
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]
*     SIMILAR = _LOGICAL (Write)
*        An output parameter that is set TRUE if no significant
*        differences were found between IN1 and IN2, and FALSE otherwise.

*  Copyright:
*     Copyright (C) 2015 East Asian Observatory.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     DSB: David S. Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     20-MAY-2015 (DSB):
*        Original version
*-
'''

import os
import math
import starutil
from starutil import invoke
from starutil import NDG
from starutil import Parameter
from starutil import ParSys
from starutil import msg_out
from starutil import AtaskError

#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  A function to clean up before exiting. Delete all temporary NDFs etc,
#  unless the script's RETAIN parameter indicates that they are to be
#  retained. Also delete the script's temporary ADAM directory.
def cleanup():
   global retain
   ParSys.cleanup()
   if retain:
      msg_out( "Retaining temporary files in {0}".format(NDG.tempdir))
   else:
      NDG.cleanup()


#  Catch any exception so that we can always clean up, even if control-C
#  is pressed.
try:

#  Declare the script parameters. Their positions in this list define
#  their expected position on the script command line. They can also be
#  specified by keyword on the command line. No validation of default
#  values or values supplied on the command line is performed until the
#  parameter value is first accessed within the script, at which time the
#  user is prompted for a value if necessary. The parameters "MSG_FILTER",
#  "ILEVEL", "GLEVEL" and "LOGFILE" are added automatically by the ParSys
#  constructor.
   params = []
   params.append(starutil.ParNDG("IN1", "The first SCUBA-2 map"))
   params.append(starutil.ParNDG("IN2", "The second SCUBA-2 map"))
   params.append(starutil.Par0S("REPORT", "Text file in which to "
                 "put the report", "sc2compare.rep", noprompt=True))
   params.append(starutil.Par0L("RETAIN", "Retain temporary files?",
                 False, noprompt=True))

#  Set he default value for GLEVEL parameter, created by the ParSys
#  constructor. This means that no logfile will be created by default.
   starutil.glevel = starutil.NONE

#  Initialise the parameters to hold any values supplied on the command
#  line.
   parsys = ParSys( params )

#  Get the two input maps.
   in1 = parsys["IN1"].value
   in2 = parsys["IN2"].value

#  See if temp files are to be retained.
   retain = parsys["RETAIN"].value

#  Get the name of any report file to create.
   report = parsys["REPORT"].value

#  Create an empty list to hold the lines of the report.
   report_lines = []

#  Use kappa:ndfcompare to compare the main NDFs holding the map data
#  array. Include a check that the root ancestors of the two maps are the
#  same. Always create a report file so we can echo it to the screen.
   report0 = os.path.join(NDG.tempdir,"report0")
   invoke( "$KAPPA_DIR/ndfcompare in1={0} in2={1} report={2} skiptests=! "
           "accdat=5E-6 accvar=5E-6 quiet".format(in1,in2,report0) )

#  See if any differences were found. If so, append the lines of the
#  report to the report_lines list.
   similar = starutil.get_task_par( "similar", "ndfcompare" )
   if not similar:
      with open(report0) as f:
         report_lines.extend( f.readlines() )

#  Now compare the WEIGHTS extension NDF (no need for the roots ancestor
#  check since its already been done).
   report1 = os.path.join(NDG.tempdir,"report1")
   invoke( "$KAPPA_DIR/ndfcompare in1={0}.more.smurf.weights "
           "in2={1}.more.smurf.weights report={2} quiet".format(in1,in2,report1) )

#  See if any differences were found. If so, append the report to any
#  existing report.
   if not starutil.get_task_par( "similar", "ndfcompare" ):
      similar = False
      report_lines.append("\n\n{0}\n   Comparing WEIGHTS arrays....\n".format("-"*80))
      with open(report1) as f:
         report_lines.extend( f.readlines() )

#  Likewise compare the EXP_TIME extension NDF.
   report2 = os.path.join(NDG.tempdir,"report1")
   invoke( "$KAPPA_DIR/ndfcompare in1={0}.more.smurf.exp_time "
           "in2={1}.more.smurf.exp_time report={2} quiet".format(in1,in2,report2) )

   if not starutil.get_task_par( "similar", "ndfcompare" ):
      similar = False
      report_lines.append("\n\n{0}\n   Comparing EXP_TIME arrays....\n".format("-"*80))
      with open(report2) as f:
         report_lines.extend( f.readlines() )

#  Display the final result.
   if similar:
      msg_out( "No differences found between {0} and {1}".format(in1,in2))
   else:
      msg_out( "Significant differences found between {0} and {1}".format(in1,in2))

#  If required write the report describing the differences to a text file.
      if report:
         with open(report,"w") as f:
            f.writelines( report_lines )
      msg_out( "   (report written to file {0}).".format(report))

#  Write the output parameter.
   starutil.put_task_par( "similar", "sc2compare", similar, "_LOGICAL" )

#  Remove temporary files.
   cleanup()

#  If an StarUtilError of any kind occurred, display the message but hide the
#  python traceback. To see the trace back, uncomment "raise" instead.
except starutil.StarUtilError as err:
#  raise
   print( err )
   cleanup()

# This is to trap control-C etc, so that we can clean up temp files.
except:
   cleanup()
   raise

