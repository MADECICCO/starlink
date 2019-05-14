      SUBROUTINE NDF1_IMPPL( PLACE, IPCB, STATUS )
*+
*  Name:
*     NDF1_IMPPL

*  Purpose:
*     Import an NDF placeholder.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_IMPPL( PLACE, IPCB, STATUS )

*  Description:
*     The routine imports a placeholder value into the NDF_ system,
*     validating it and converting it into a PCB index. If the
*     placeholder value is not valid, then an error will be reported.

*  Arguments:
*     PLACE = INTEGER (Given)
*        The placeholder to be imported.
*     IPCB = INTEGER (Returned)
*        Index to the placeholder entry in the PCB.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  If this routine is called with STATUS set, then a value of
*     zero will be returned for the IPCB argument, although no further
*     processing will occur.
*     -  A value of zero will also be returned for the IPCB argument if
*     the routine should fail for any reason.

*  Algorithm:
*     -  Set an initial value for the IPCB argument before checking the
*     inherited global status.
*     -  Check that the placeholder is positive. If not, then it is
*     invalid.
*     -  Decode the placeholder value into a PCB index.
*     -  Check that the placeholder value matches the PCB check count
*     and that the PCB slot is still in use.
*     -  If everything is OK, then return the PCB index.
*     -  Otherwise, report an error.

*  Copyright:
*     Copyright (C) 1989, 1990 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     6-OCT-1989 (RFWS):
*        Original, derived from the equivalent ARY_ system routine.
*     1-MAR-1990 (RFWS):
*        Removed un-referenced include file.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants
      INCLUDE 'NDF_ERR'          ! NDF_ error codes

*  Global Variables:
      INCLUDE 'NDF_PCB'          ! NDF_ Placeholder Control Block
*        PCB_CHK( NDF__MXPCB ) = INTEGER (Read)
*           Placeholder value used as a check count.
*        PCB_USED( NDF__MXPCB ) = LOGICAL (Read)
*           Whether a PCB entry is in use.

*  Arguments Given:
      INTEGER PLACE

*  Arguments Returned:
      INTEGER IPCB

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Temporary PCB index
      LOGICAL OK                 ! Whether the placeholder is valid

*.

*  Set an initial value for the IPCB argument.
      IPCB = 0

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  The placeholder is invalid if it is not positive.
      IF ( PLACE .LE. 0 ) THEN
         OK = .FALSE.

*  Otherwise, decode it into an index into the PCB (the inverse
*  algorithm to that used by NDF_PLACE to encode it).
      ELSE
         I = MOD( PLACE, NDF__MXPCB )
         IF ( I .EQ. 0 ) I = NDF__MXPCB

*  Check that the PCB entry contains the placeholder value as a check
*  count and is still in use.
         IF ( ( PCB_CHK( I ) .EQ. PLACE ) .AND. PCB_USED( I ) ) THEN
            OK = .TRUE.

*  If not, then the placeholder is invalid.
         ELSE
            OK = .FALSE.
         END IF
      END IF

*  If the placeholder is valid, then return the PCB index.
      IF ( OK ) THEN
         IPCB = I

*  Otherwise, report an error.
      ELSE
         STATUS = NDF__PLINV
         CALL MSG_SETI( 'BADPLACE', PLACE )
         CALL ERR_REP( 'NDF1_IMPPL_BAD',
     :   'NDF placeholder invalid; its value is ^BADPLACE ' //
     :   '(possible programming error).', STATUS )
      END IF

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_IMPPL', STATUS )

      END
