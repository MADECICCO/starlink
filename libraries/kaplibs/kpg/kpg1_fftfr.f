      SUBROUTINE KPG1_FFTFR( M, N, IN, WORK, OUT, STATUS )
*+
*  Name:
*     KPG1_FFTFR

*  Purpose:
*     Takes the forward FFT of a real image.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_FFTFR( M, N, IN, WORK, OUT, STATUS )

*  Description:
*     The Fourier transform of the input (purely real) image is taken
*     and returned in OUT.  The returned FT is stored in Hermitian
*     format, in which the real and imaginary parts of the FT are
*     combined into a single array.  The FT can be inverted using
*     KPG1_FFTBR, and two Hermitian FTs can be multipled together using
*     routine KPG1_HMLTR.

*  Arguments:
*     M = INTEGER (Given)
*        Number of columns in the input image.
*     N = INTEGER (Given)
*        Number of rows in the input image.
*     IN( M, N ) = REAL (Given)
*        The input image.
*     WORK( * ) = REAL (Given)
*        Work space. This must be at least ( 3*MAX( M, N ) + 15 )
*        elements long.
*     OUT( M, N ) = REAL (Returned)
*        The FFT in Hermitian form.  Note, the same array can be used
*        for both input and output, in which case the supplied values
*        will be over-written.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     14-FEB-1995 (DSB):
*        Original version.  Written to replace KPG1_RLFFT which
*        used NAG routines.
*     1995 March 27 (MJC):
*        Removed long lines and minor documentation revisions.  Used
*        modern-style variable declarations.
*     1995 September 7 (MJC):
*        Used PDA_ prefix for FFTPACK routines.
*     13-DEC-2003 (DSB):
*        Use KPG1_R2NAG in stead of PDA_R2NAG. KPG1_R2NAG uses workspace
*        to achieve greater speed.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-


*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Arguments Given:
      INTEGER M
      INTEGER N
      REAL IN( M, N )
      REAL WORK( * )

*  Arguments Returned:
      REAL OUT( M, N )

*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Column counter
      INTEGER IW                 ! Index into work array
      INTEGER IPW                ! Pointer to work space
      INTEGER J                  ! Row counter

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Allocate work space for use in KPG1_R2NAG. Abort if failure.
      CALL PSX_CALLOC( MAX( M, N ), '_REAL', IPW, STATUS )
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Copy the input array to the output array.
      DO J = 1, N
         DO I = 1, M
            OUT( I, J ) = IN( I, J )
         END DO
      END DO

*  Initialise an array holding trig. functions used to form the FFT
*  of the input image rows.
      CALL PDA_RFFTI( M, WORK )

*  Transform each row of the output array, and convert each array into
*  the equivalent NAG format.
      DO J = 1, N
         CALL PDA_RFFTF( M, OUT( 1, J ), WORK )
         CALL KPG1_R2NAG( M, OUT( 1, J ), %VAL( CNF_PVAL( IPW ) ) )
      END DO

*  Re-initialise the work array to hold trig. functions used to form
*  the FFT of the image columns.
      CALL PDA_RFFTI( N, WORK )

*  Store the index of the last-used element in the work array.
      IW = 2 * N + 15

*  Transform each column of the current output array.
      DO I = 1, M

*  Copy this column to the end of the work array, beyond the part used
*  to store trig. functions.
         DO  J = 1, N
            WORK( IW + J ) = OUT( I, J )
         END DO

*  Transform the copy of this column.
         CALL PDA_RFFTF( N, WORK( IW + 1 ), WORK )
         CALL KPG1_R2NAG( N, WORK( IW + 1 ), %VAL( CNF_PVAL( IPW ) ) )

*  Copy the transformed column back to the output array.
         DO  J = 1, N
            OUT( I, J ) = WORK( IW + J ) 
         END DO

      END DO

*  Free work space 
      CALL PSX_FREE( IPW, STATUS )

      END
