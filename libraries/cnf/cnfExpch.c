#include <string.h>
#include "f77.h"                 /* CNF macros and prototypes               */
#if HAVE_CONFIG_H
#  include <config.h>
#endif

void cnfExpch( const char *source_c, char *dest_f, int nchars )

/*
*+
*  Name:
*     cnfExpch

*  Purpose:
*     Export a C array of char to a FORTRAN string.

*  Language:
*     ANSI C

*  Invocation:
*     cnfExpch( source_c, dest_f, nchars )

*  Description:
*     Export a C array of char to a FORTRAN string, copying `nchars' characters.
      No characters, are special so this may be used to export an HDS locator
      which could contain a null character.

*  Arguments:
*     const char *source_c (Given)
*        A pointer to the array of char
*     char *dest_f (Returned via pointer)
*        A pointer to the FORTRAN output string
*     int nchars (Given)
*        The number of characters to be copied from source_c to dest_f

*  Copyright:
*     Copyright (C) 1996 Council for the Central Laboratory of the Research
*     Councils

*  Authors:
*     AJC: A.J. Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     28-JUN-1996 (AJC):
*        Original version.
*     16-Aug-1996 (AJC):
*        Correct include file
*     23-SEP-1998 (AJC):
*        Specify const char * for input strings
*     19-JUL-2004 (PWD):
*        Changed to use memmove when bcopy isn't available. Also to 
*        just do the straight copy when neither is available (very unlikely). 
*        Note that bcopy is deprecated in POSIX.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*...........................................................................*/

{
/* Local Variables:							    */

   int i;			 /* Loop counter			    */


/* Copy the characters of the input C array to the output FORTRAN string.  */

#if HAVE_BCOPY
   bcopy( (const void *)source_c, (void *)dest_f, (size_t)nchars );
#elif HAVE_MEMMOVE
   memmove( (void *)dest_f, (const void *)source_c, (size_t)nchars );
#else
/* Do this by hand, note no overlaps allowed */
   for ( i = 0; i < nchars; i++ ) {
       dest_f[i] = source_c[i];
   }
#endif
}
