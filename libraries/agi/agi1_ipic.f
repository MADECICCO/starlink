************************************************************************

      SUBROUTINE AGI_1IPIC ( WKSLOC, PSTLOC, TOTNUM, FOUND, STATUS )

*+
*  Name:
*     AGI_1IPIC

*  Purpose:
*     Inquire the number of pictures on a workstation.

*  Language:
*     VAX Fortran

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL AGI_1IPIC ( WKSLOC, PSTLOC, TOTNUM, FOUND, STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     Inquire the number of pictures on a workstation. Return the
*     picture structure locator if it was found.

*  Algorithm:
*     Check status on entry.
*     If picture structure is present then
*        Get the locator to the picture structure.
*        Inquire how many pictures are in the picture structure.
*     Endif

*  Authors:
*     Nick Eaton  ( DUVAD::NE )
*     {enter_new_authors_here}

*  History:
*     July 1988
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*

*  Type Definitions:
      IMPLICIT NONE


*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'agi_nam'


*  Arguments Given:
*     Locator to workstation
      CHARACTER * ( DAT__SZLOC ) WKSLOC


*  Arguments Returned:
*     Locator to picture structure. Undefined if .NOT. FOUND
      CHARACTER * ( DAT__SZLOC ) PSTLOC

*     Number of pictures in array of pictures. Undefined if .NOT. FOUND
      INTEGER TOTNUM

*     Flag to indicate if picture structure has been found
      LOGICAL FOUND


*  Status:
      INTEGER STATUS

*.


      IF ( STATUS .EQ. SAI__OK ) THEN

*   Check to see if picture structure is present
         CALL DAT_THERE( WKSLOC, AGI__PCNAM, FOUND, STATUS )

*   If so get the number of current cells
         PSTLOC = ' '
         IF ( FOUND ) THEN
            CALL DAT_FIND ( WKSLOC, AGI__PCNAM, PSTLOC, STATUS )
            CALL DAT_SIZE ( PSTLOC, TOTNUM, STATUS )
         ENDIF

      ENDIF

*      print*, '+++++ AGI_1IPIC +++++'
*      call HDS_SHOW( 'FILES', status )
*      call HDS_SHOW( 'LOCATORS', status )

      END

