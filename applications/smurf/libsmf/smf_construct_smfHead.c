/*
*+
*  Name:
*     smf_construct_smfHead

*  Purpose:
*     Populate a smfHead structure

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     pntr = smf_construct_smfHead( smfHead * tofill, sc2head * sc2head,
*              AstFrameSet * wcs, AstFitsChan * fitshdr,
*              dim_t curslice, int * status );

*  Arguments:
*     tofill = smfHead* (Given)
*        If non-NULL, this is the smfHead that is populated by the remaining
*        arguments. If NULL, the smfHead is malloced.
*     sc2head = sc2head* (Given)
*        Pointer to a struct sc2head. The contents of this structure
*        will be copied by this routine into the target structure. If NULL,
*        the struct contents are not modified.
*     wcs = AstFrameSet * (Given)
*        Frameset for the world coordinates. The pointer is copied,
*        not the contents.
*     fitshdr = AstFitsChan * (Given)
*        FITS header. The pointer is copied, not the contents.
*     curslice = dim_t (Given)
*        Current time index corresponding to the associated WCS.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:
*     smf_construct_smfHead = smfHead*
*        Pointer to newly created smfHead (NULL on error) or,
*        if "tofill" is non-NULL, the pointer to the supplied struct.

*  Description:
*     This function fills a smfHead structure. Optionally, the smfHead
*     is allocated by this routines.

*  Notes:
*     - AST objects are neither cloned not copied by this routine.
*       Use astCopy or astClone when calling if reference counts
*       should be incremented.
*     - Anomalously, the sc2head contents are copied. This is because
*       the struct is embedded in a smfHead.
*     - Free this memory using smf_close_file, via a smfData structure.
*     - Can be freed with a smf_free if header resources are freed first.

*  Authors:
*     Tim Jenness (TIMJ)
*     {enter_new_authors_here}

*  History:
*     2006-01-26 (TIMJ):
*        Initial version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* System includes */
#include <stdlib.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_construct_smfHead"

smfHead *
smf_construct_smfHead( smfHead * tofill, sc2head * sc2head,
		       AstFrameSet * wcs, AstFitsChan * fitshdr,
		       dim_t curslice, int * status ) {

  smfHead * hdr = NULL;   /* Header components */

  hdr = tofill;
  if (*status != SAI__OK) return hdr;

  if (tofill == NULL) {
    hdr = smf_create_smfHead( status );
  }

  if (*status == SAI__OK) {
    hdr->wcs = wcs;
    hdr->fitshdr = fitshdr;
    hdr->curslice = curslice;
    if ( sc2head != NULL ) {
      memcpy( &(hdr->sc2head), sc2head, sizeof(sc2head) );
    }
  }

  return hdr;
}
