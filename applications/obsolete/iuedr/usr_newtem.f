      SUBROUTINE USR_NEWTEM( STATUS )
*+
*  Name:
*     SUBROUTINE USR_NEWTEM

*  Description:
*     The contents of CMTEM are read from a specified file.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL USR_NEWTEM( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     JRG: Jack Giddings (UCL)
*     PCTR: Paul Rees (UCL)
*     MJC: Martin Clayton (UCL)
*     {enter_new_authors_here}

*  History:
*     01-MAY-82 (JRG):
*       IUEDR Vn. 1.0
*     05-NOV-88 (PCTR):
*       IUEDR Vn. 2.0
*     18-OCT-94 (MJC):
*       IUEDR Vn. 3.1-7
*     18-JAN-95 (MJC):
*       IUEDR Vn. 3.2
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'

*  Status:
      INTEGER STATUS     ! Global status.

*  Global Variables:
      INCLUDE 'CMHEAD'
      INCLUDE 'CMTEM'

*  Local Variables:
      BYTE FILE( 81 )    ! File name.

      INTEGER ACTVAL     ! Parameter value count.
*.

*   Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*   Get Calibration.
      CALL DASSOC( '\\', '\\', STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERROUT( 'Error: could not access dataset\\', STATUS )
         GO TO 999
      END IF

*   TEMFILE.
      CALL RDPARC( 'TEMFILE\\', .FALSE., 81, FILE, ACTVAL, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL PARFER( 'TEMFILE\\', STATUS )
         GO TO 999

      ELSE
         CALL CNPAR( 'TEMFILE\\', STATUS )
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL PCANER( 'TEMFILE\\', STATUS )
            GO TO 999
         END IF
      END IF

*   Whatever happens, update will be needed.
      CALL MODCAL

*   Read file.
      NOTEM = .TRUE.
      CALL RFTEM( FILE, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERROUT( 'Error: replacing template data\\', STATUS )
         GO TO 999
      END IF

 999  CONTINUE

      END
