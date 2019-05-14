      SUBROUTINE NDF1_SETC( VALUE, TOKEN )
*+
*  Name:
*     NDF1_SETC

*  Purpose:
*     Assign a character value to a message token.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_SETC( VALUE, TOKEN )

*  Description:
*     The routine assigns a character value to a message token by
*     calling the routine MSG_SETC. It exists solely to reverse the
*     argument order of MSG_SETC so that mapped character strings may
*     be passed as the VALUE argument on UNIX systems.

*  Arguments:
*     VALUE = CHARACTER * ( * ) (Given)
*        Character value to me assigned.
*     TOKEN = CHARACTER * ( * ) (Given)
*        Message token name.

*  Algorithm:
*     -  Assign the token value.

*  Copyright:
*     Copyright (C) 1992 Science & Engineering Research Council.
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
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     20-JAN-1992 (RFWS):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Arguments Given:
      CHARACTER * ( * ) VALUE
      CHARACTER * ( * ) TOKEN

*.

*  Assign the token value.
      CALL MSG_SETC( TOKEN, VALUE )

      END
