      SUBROUTINE NDF1_CCPY( CIN, COUT, STATUS )
*+
*  Name:
*     NDF1_CCPY

*  Purpose:
*     Copy a character string, checking for truncation.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_CCPY( CIN, COUT, STATUS )

*  Description:
*     The routine copies a character string from one variable to
*     another (following the rules of Fortran character assignment) and
*     checking for truncation of trailing non-blank characters. If such
*     truncation occurs, then an error is reported and a STATUS value
*     set.

*  Arguments:
*     CIN = CHARACTER * ( * ) (Given)
*        The input character string.
*     COUT = CHARACTER * ( * ) (Returned)
*        The output character variable to receive the string.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  Copy the string with an assignment statement.
*     -  If there are characters remaining, check they are all blank.
*     If not, then report an error.

*  Copyright:
*     Copyright (C) 1989 Science & Engineering Research Council.
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
*     3-OCT-1989 (RFWS):
*        Original, derived from the equivlent ARY_ system routine.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_ERR'          ! NDF_ error codes

*  Arguments Given:
      CHARACTER * ( * ) CIN

*  Arguments Returned:
      CHARACTER * ( * ) COUT

*  Status:
      INTEGER STATUS             ! Global status

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Copy the string.
      COUT = CIN

*  If characters remain uncopied, then test to see if they are blank.
*  Report an error if they are not.
      IF ( LEN( CIN ) .GT. LEN( COUT ) ) THEN
         IF ( CIN( LEN( COUT ) + 1 : ) .NE. ' ' ) THEN
            STATUS = NDF__TRUNC
            CALL MSG_SETC( 'STRING', COUT )
            CALL ERR_REP( 'NDF1_CCPY_STR',
     :      'Character string truncated: ''^STRING''.', STATUS )
            CALL ERR_REP( 'NDF1_CCPY_TRNC',
     :      'Output character variable is too short to accommodate ' //
     :      'the returned result (possible programming error).',
     :      STATUS )
         END IF
      END IF

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_CCPY', STATUS )

      END
