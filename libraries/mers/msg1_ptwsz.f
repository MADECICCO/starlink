      SUBROUTINE MSG1_PTWSZ( SIZE )
*+
*  Name:
*     MSG1_PTWSZ

*  Purpose:
*     Put the value of element MSGWSZ into the MSG_CMN common block.

*  Language:
*    Starlink Fortran 77

*  Invocation:
*     CALL MSG1_PTWSZ( SIZE )

*  Description:
*     This routine sets the value of element MSGWSZ in the MSG_CMN 
*     common block. This should be used instead of directly accessing the
*     common block since access from a different shared library may result in
*     the comm block value being uninitialised by the corresponding BLOCK DATA
*     module.

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     Copyright (C) 2004 Central Laboratory of the Research Councils.
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
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     1-JUL-2004 (DSB):
*        Original version.
*     24-JUL-2008 (TIMJ):
*        Copy from msg1_gtwsz
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

      IMPLICIT NONE                     
      INCLUDE 'MSG_CMN'                 
      INTEGER SIZE

      MSGWSZ = SIZE

      END
