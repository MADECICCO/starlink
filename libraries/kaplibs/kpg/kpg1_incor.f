      SUBROUTINE KPG1_INCOR( PNAME, NDIM, NPOINT, IPCO, STATUS )
*+
*  Name:
*     KPG1_INCOx
 
*  Purpose:
*     Obtains a list of co-ordinates from the environment.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_INCOx( PNAME, NDIM, NPOINT, IPCO, STATUS )
 
*  Description:
*     The supplied parameter is used to get a list of co-ordinates from
*     the environment.  These co-ordinates are stored in dynamic
*     workspace which is expanded as necessary so that any number of
*     points can be given.  The user indicates the end of the list of
*     points by a null value.  Pointers to the workspace arrays holding
*     the co-ordinates are returned, and should be annulled when no
*     longer needed by calling PSX_FREE.
 
*  Arguments:
*     PNAME = CHARACTER * ( * ) (Given)
*        Name of the parameter with which to associate the co-ordinates.
*     NDIM = INTEGER (Returned)
*        The number of co-ordinate dimensions.  It must be positive and
*        no more than DAT__MXDIM.
*     NPOINT = INTEGER (Returned)
*        The number of points specified.
*     IPCO = INTEGER (Returned)
*        A pointer to workspace of type _REAL and size NDIM by NPOINT
*        holding the co-ordinates of each point.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for real or double-precision numeric data
*     types: replace "x" in the routine name by D or R as appropriate.
*     The returned co-ordinate array will have the specified data type.
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}
 
*  History:
*     11-NOV-1993 (DSB):
*        Original version.
*     1995 April 11 (MJC):
*        Made generic, n-dimensional and more general.  Some tidying of
*        the prologue.  Called renamed retrieval routine.  Corrected
*        typo's and made minor stylistic changes.  Used linear increment
*        to enlarge workspace.
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
      INCLUDE 'DAT_PAR'          ! DAT_ constants
      INCLUDE 'PRM_PAR'          ! VAL_ constants
      INCLUDE 'PAR_ERR'          ! PAR_ error constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
 
*  Arguments Given:
      CHARACTER * ( * ) PNAME
      INTEGER NDIM
 
*  Arguments Returned:
      INTEGER NPOINT
      INTEGER IPCO
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Constants:
      INTEGER INITSZ             ! Initial workspace size
      PARAMETER ( INITSZ = 20 )
 
*  Local Variables:
      REAL COORD( DAT__MXDIM )   ! Co-ordinates of a point
      INTEGER I                  ! Loop counter
      INTEGER WSIZE              ! Current size of workspace in bytes
      INTEGER WSTEP              ! Increment size of workspace in bytes
 
*.
 
*  Initialise the number of points in the polygon to indicate that no
*  polygon has yet been supplied.
      NPOINT = 0
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Get the first pair of co-ordinates using the supplied parameter.
      CALL PAR_EXACR( PNAME, NDIM, COORD, STATUS )
 
*  Allocate workspace to hold a reasonable number of points.  This
*  will be expanded if necessary.
      WSTEP = INITSZ * NDIM * VAL__NBR
      WSIZE = WSTEP
      CALL PSX_MALLOC( WSIZE, IPCO, STATUS )
 
*  Loop round obtaining new points until an error occurs.
      DO WHILE ( STATUS .EQ. SAI__OK )
 
*  Increment the number of points supplied so far.
         NPOINT = NPOINT + 1
 
*  If there is no room for any more points in the workspace, double
*  the size of the workspace.
         IF ( NPOINT .GT. WSIZE ) THEN
            WSIZE = WSIZE + WSTEP
            CALL PSX_REALLOC( WSIZE, IPCO, STATUS )
         END IF
 
*  Store the supplied co-ordinates in the workspace.
         DO I = 1, NDIM
            CALL KPG1_STORR( WSIZE, ( NPOINT - 1 ) * NDIM + I,
     :                         COORD( I ), %VAL( CNF_PVAL( IPCO ) ), 
     :                       STATUS )
         END DO
 
*  Cancel the current value of the parameter.
         CALL PAR_CANCL( PNAME, STATUS )
 
*  Get the next pair of co-ordinates using the supplied parameter.
         CALL PAR_EXACR( PNAME, NDIM, COORD, STATUS )
 
      END DO
 
*  If a null parameter value has been supplied, annul the error.
      IF ( STATUS .EQ. PAR__NULL ) CALL ERR_ANNUL( STATUS )
 
*  Cancel the current value of the parameter.
      CALL PAR_CANCL( PNAME, STATUS )
 
*  If any other error has occurred, set the number of points in the
*  polyline to zero, and release the workspace.  This is done within a
*  new error reporting environment because PSX_FREE does nothing if an
*  error status exists on entry (in contrast to most other `tidying up'
*  routines).
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_BEGIN( STATUS )
         NPOINT = 0
         CALL PSX_FREE( IPCO, STATUS )
         CALL ERR_END( STATUS )
      END IF
 
      END
