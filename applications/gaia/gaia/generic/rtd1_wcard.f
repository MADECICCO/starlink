      SUBROUTINE RTD1_WCARD( CARD, NCARD, BLOCK, STATUS )
*+
* Name:
*    RTD1_WCARD

*  Purpose:
*     Writes a FITS card without checking.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL RTD1_WCARD( CARD, NCARD, BLOCK, STATUS )

*  Description:
*     This routine writes a FITS card  into the "FITS block" by
*     appending it just before the 'END' keyword. No checking is 
*     made.

*  Arguments:
*     CARD = CHARACTER * ( * ) (Given)
*        The complete CARD to copy into the FITS block.
*     NCARD = INTEGER (Given)
*        The number of elements (cards) in BLOCK.
*     BLOCK( NCARD ) = CHARACTER * ( * ) (Given and Returned)
*        The FITS block (note this is passed at this point so that it is
*        before the other *(*) characters which allows this array to be
*        mapped -- see SUN/92).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils

*  Authors:
*     PWD: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     22-NOV-1996 (PWD):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER NCARD
      CHARACTER * ( * ) CARD

*  Arguments Given and Returned:
      CHARACTER * ( * ) BLOCK( NCARD )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop variable
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Scan the BLOCK until the END keyword is located. 
      DO 1 I = 1, NCARD
         IF ( BLOCK( I ) .EQ. 'END' ) THEN 
            IF ( I .NE. NCARD ) THEN 
               BLOCK( I ) = CARD
               BLOCK( I + 1 ) = 'END'
            END IF
         END IF
 1    CONTINUE
      END
