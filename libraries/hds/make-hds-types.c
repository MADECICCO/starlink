/*
 *+
 *  Name:
 *     make-hds-types

 *  Type of module:
 *     C source

 *  Purpose:
 *     Generate HDS type header file

 *  Description:
 *     We need to have some types made available to the public
 *     interface that are only derivable by looking at private
 *     config.h. Therefore this program reads config.h and creates
 *     a public include file defining the standard types. It also
 *     creates an internal types header file for types that are related
 *     to the public type but are most easily defined by a program rather
 *     than by CPP. Creates hds_types.h and hds1_types.h

 *  Usage:
 *     ./make-hds-types

 *  Authors:
 *     TIMJ: Tim Jenness (JAC, Hawaii)
 *     {enter_new_authors_here}

 *  History:
 *     2005-Oct-21 (TIMJ):
 *        Original version

 *  Copyright:
 *     Copyright (C) 2005 Particle Physics and Astronomy Research Council.
 *     All Rights Reserved.

 *  License:
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program (see SLA_CONDITIONS); if not, write to the 
 *    Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
 *    Boston, MA  02111-1307  USA

 *-
 */

#if HAVE_CONFIG_H
# include <config.h>
#endif

#if HAVE_TIME_H
# include <time.h>
#endif

#include <limits.h>

#include <stdlib.h>
#include <stdio.h>
#include "f77.h"

#define INCLUDE_FILE "hds_types.h"
#define PINCLUDE_FILE "hds1_types.h"

/* Work everything out here */

/* Define a "normal integer". Typically use the "int" type, but ensure it */
/* has at least 4 bytes of precision.                                     */

#if ( ( INT_MIN <= -2147483647L ) && ( INT_MAX >= 2147483647L ) )
# define  STD_INT "int"
#else
# define  STD_INT "long int"
#endif

/* Definitions for 64-bits integers                                        */ 
/* Use the standard int64_t if available                                   */
/* Use 'long' if it is 8 bytes, else use 'long long'                       */

#if SIZEOF_LONG == 8
#define INT_BIG "long int"
#define UINT_BIG "unsigned long int"
#define INT_BIG_S "ld"
#define INT_BIG_U "lu"
#elif SIZEOF_LONG_LONG == 8
#define INT_BIG  "long long int"
#define UINT_BIG "unsigned long long int"
#define INT_BIG_S "lld"
#define INT_BIG_U "llu"
#else
error unable to find an 8 byte integer type
#endif

/* The internal size of array dimensions within HDS can be either 32 or 64 */
/* bits. Note that 64 bits is untested and WILL change the file format!!!  */

/* Can not derive the dim size so we just set it */
/* We also state whether this is unsigned so that we can compare with
   the fortran type */
#define DIM_TYPE "int"
#define DIM_FORMAT "d"
#define DIM_IS_UNSIGNED 0

/* Good grief. All I want to do is put quotes around the CNF type
   for printing */
#define myxstr(s) mystr(s)
#define mystr(s) #s

/* Simply state the Fortran type. We could choose a 64bit type here
   if we suddenly switched to INTEGER*8. Fortran will normally always
   be signed */
#define FORTRAN_HDS_INDEX_TYPE  myxstr(F77_INTEGER_TYPE)
#define FORTRAN_DIM_IS_UNSIGNED 0

/* Internal prototypes */
const char* todaysdate(void);

/* Main routine */
int main (int argc, char ** argv ) {
  char * progname = argv[0];
  FILE * OutputFile;
  FILE * POutputFile;
  int copydims;

  /* Open the public output file */
  OutputFile = fopen( INCLUDE_FILE, "w" );
  if (!OutputFile) {
    fprintf(stderr, "%s: can't open file %s for output\n",
	    progname, INCLUDE_FILE );
    return EXIT_FAILURE;
  }

  /* Open the public output file */
  POutputFile = fopen( PINCLUDE_FILE, "w" );
  if (!POutputFile) {
    fprintf(stderr, "%s: can't open file %s for output\n",
	    progname, PINCLUDE_FILE );
    return EXIT_FAILURE;
  }

  /* Start writing the include file. Begin with the header */
  fprintf(OutputFile,
"#if !defined( HDS_TYPES_INCLUDED ) /* %s already included? */\n"
"#define HDS_TYPES_INCLUDED 1\n"
"/*\n"
"*+\n"
"*  Name:\n"
"*     %s\n"
"\n"
"*  Type of Module:\n"
"*     C include file.\n"
"\n"
"*  Purpose:\n"
"*     Define public HDS-specific data types.\n"
"\n"
"*  Description:\n"
"*     This file defines the public types that are used in the HDS\n"
"*     public API.\n"
"\n"
"*  Authors:\n"
"*     TIMJ: Tim Jenness (JAC, Hawaii)\n"
"*     %s program\n"
"\n"
"*  History:\n"
"*     21-Oct-2005 (TIMJ):\n"
"*        Original version of C program (via auto-generation).\n"
"*     %s (%s):\n"
"*        Generated\n"
"*     No further changes -- do not edit this file\n"
"\n"
"*-\n"
"*/"
"\n\n",
	  INCLUDE_FILE, INCLUDE_FILE, progname, todaysdate(), progname);

  /* Start writing the private include file. Begin with the header */
  fprintf(POutputFile,
"#if !defined( HDS1_TYPES_INCLUDED ) /* %s already included? */\n"
"#define HDS1_TYPES_INCLUDED 1\n"
"/*\n"
"*+\n"
"*  Name:\n"
"*     %s\n"
"\n"
"*  Type of Module:\n"
"*     C include file.\n"
"\n"
"*  Purpose:\n"
"*     Define private but derived HDS-specific data types.\n"
"\n"
"*  Description:\n"
"*     This file defines the private types that are used in the HDS\n"
"*     build but have no reason to be public.\n"
"\n"
"*  Authors:\n"
"*     TIMJ: Tim Jenness (JAC, Hawaii)\n"
"*     %s program\n"
"\n"
"*  History:\n"
"*     21-Oct-2005 (TIMJ):\n"
"*        Original version of C program (via auto-generation).\n"
"*     %s (%s):\n"
"*        Generated\n"
"*     No further changes -- do not edit this file\n"
"\n"
"*-\n"
"*/"
"\n\n",
	  PINCLUDE_FILE, PINCLUDE_FILE, progname, todaysdate(), progname);


  /* We first need to decide what we are using for a normal hdsint */

  fprintf(POutputFile, "/* Standard HDS integer type. Only used internally */\n");
  fprintf(POutputFile, "typedef %s hds_int32;\n\n", STD_INT );

  /* 64 bit integer type. Also internal for now */
  fprintf(POutputFile, "/* Standard HDS 64 bit integer (internal) */\n");

  fprintf(POutputFile,
	  "typedef %s hds_int64;\n"
	  "typedef %s hds_uint64;\n"
	  "#define HDS_INT_BIG_S \"%s\"\n"
	  "#define HDS_INT_BIG_U \"%s\"\n\n",
	  INT_BIG, UINT_BIG, INT_BIG_S, INT_BIG_U);

  /* Dimensions */
  fprintf( OutputFile,
	   "/* Public type for specifying HDS dimensions */\n"
	   "typedef %s hdsdim;\n"
	   "#define HDS_DIM_FORMAT \"%s\"\n\n",
	   DIM_TYPE, DIM_FORMAT);

  fprintf( POutputFile,
	   "/* Private types and sizes relating to dimensions */\n"
	   "typedef %s FORTRAN_INDEX_TYPE;\n"
	   "#define SIZEOF_HDSDIM %ld\n\n",
	   FORTRAN_HDS_INDEX_TYPE,
	   (long)sizeof(DIM_TYPE));


  /* Need to decide whether fortran dims need to be copied to
     C dims. This is required if either the size of signedness
     differ */

  if ( (sizeof(DIM_TYPE) == sizeof(FORTRAN_HDS_INDEX_TYPE)) &&
      (FORTRAN_DIM_IS_UNSIGNED == DIM_IS_UNSIGNED)) {
    copydims = 0;
  } else {
    copydims = 1;
  }
  fprintf(POutputFile,
	  "/* Decide whether Fortran dims should be copied element by element */\n"
	  "#define HDS_COPY_FORTRAN_DIMS %d\n\n",
	  copydims);


  fprintf(OutputFile,
	  "#endif /* _INCLUDED */\n\n");
  fprintf(POutputFile,
	  "#endif /* _INCLUDED */\n\n");

  fclose( OutputFile );
  fclose( POutputFile );

  return EXIT_SUCCESS;
}



/* Stolen from make-prm-par.c */
const char *todaysdate(void)
{
#if HAVE_TIME_H
    static char s[12];
    time_t t = time(0);

    strftime(s, sizeof(s), "%d-%b-%Y", localtime(&t));
    return s;
#else
    return "TODAY";
#endif
}
