/*
*+
*  Name:
*     smf_model_createtswcs

*  Purpose:
*     Create AstFrameSet for model data

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_model_createtswcs( smfData *model, smf_modeltype type, 
*                            AstFrameSet *refwcs, int *status );

*  Arguments:
*     model = smfData * (Given)
*        Pointer to smfData containing model information
*     type = smf_modeltype (Given)
*        Type of model
*     refwcs = AstFrameSet * (Given)
*        Pointer to time-series WCS frameset corresponding to this model
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Calculate a "time series" WCS frameset compatible with the model 
*     container, so that we can later call ndfPtwcs when we export. Requires
*     both the model smfData itself, and the tswcs from the original data.

*  Notes:

*  Authors:
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-09-29 (EC):
*        Initial Version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2008 University of British Columbia.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
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

/* Starlink includes */
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "prm_par.h"
#include "par_par.h"
#include "ast.h"

/* SMURF includes */
#include "libsmf/smf.h"

#define FUNC_NAME "smf_model_createtswcs"

void smf_model_createtswcs( smfData *model, smf_modeltype type, 
                            AstFrameSet *refwcs, int *status ) {

  /* Local Variables */
  int caxis;                    /* column axis index */
  AstMapping *cbmap=NULL;       /* Pointer to current->base mapping */
  AstFrame *cfrm=NULL;          /* 1D frame for column */
  AstCmpFrame *cfrm2=NULL;      /* 2D frame */
  AstMapping *cmap=NULL;        /* Mapping for column axis */
  AstCmpMap *cmap2=NULL;        /* 2d Mapping */
  AstFrame *ofrm=NULL;          /* 1D frame for other axis */
  AstUnitMap *omap=NULL;        /* Mapping for other axis */
  AstFrameSet *fset=NULL;       /* the returned framset */ 
  int out[NDF__MXDIM];          /* Indices outputs of mapping */
  int taxis;                    /* Index of time axis */ 
  AstFrame *tfrm=NULL;          /* 1D frame (TimeFrame) */
  AstMapping *tmap=NULL;        /* Mapping for time axis */

  /* Main routine */
  if( *status != SAI__OK ) return;

  if( !model || !refwcs ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": Null input pointers", status );
    return;
  }

  astBegin;

  /* Create frameset for each model type. Many have same dimensions as the
     raw data, so just return a copy of refwcs */

  switch( type ) {
    
  case SMF__CUM:
    fset = astCopy( refwcs );
    break;
    
  case SMF__RES:
    fset = astCopy( refwcs );
    break;
    
  case SMF__AST:
    fset = astCopy( refwcs );
    break;
    
  case SMF__COM:
    /* For 1=dimensional data, assume it is the time axis which we
       extract from the 3d WCS */
    
    /* Get a pointer to the current->base Mapping (i.e. the Mapping from
       WCS coords to GRID coords). */
    cbmap = astGetMapping( refwcs, AST__CURRENT, AST__BASE );
    
    /* Use astMapSplit to split off the Mapping for the time
       axis. This assumes that the time axis is the 3rd axis
       (i.e. index 2) */
    
    taxis = 3;
    astMapSplit( cbmap, 1, &taxis, out, &tmap );
    
    /* We now check that the Mapping was split succesfully. This should
       always be the case for the time axis since the time axis is 
       independent of the others, but it is as well to check in case of 
       bugs, etc. */
    if( !tmap ) {
      /* The "tmap" mapping will have 1 input (the WCS time value) -
         astMapSplit guarantees this. But we
         should also check that it also has only one output (the
         corresponding GRID axis). */
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME ": Couldn't extract time-axis mapping",
              status );
    } else if( astGetI( tmap, "Nout" ) != 1 ) {
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME 
              ": Time-axis mapping has incorrect number of outputs",
              status );
    } else {
      
      /* Create a new FrameSet containing a 1D GRID Frame. */
      fset = astFrameSet( astFrame( 1, "Domain=GRID" ), "" );
      
      /* Extract the 1D Frame (presumably a TimeFrame)
         describing time from the current (WCS) 3D Frame. */
      tfrm = astPickAxes( refwcs, 1, &taxis, NULL);
      
      /* Add the time frame into the 1D FrameSet, using the
         Mapping returned by astMapSplit. Note, this Mapping
         goes from time to grid, so we invert it first so that
         it goes from grid to time, as required by
         astAddFrame. */
      
      astInvert( tmap );
      astAddFrame( fset, AST__BASE, tmap, tfrm );
    }
    
    break;
    
  case SMF__NOI:
    fset = astCopy( refwcs );
    break;
    
  case SMF__EXT:
    fset = astCopy( refwcs );
    break;
    
  case SMF__LUT:
    fset = astCopy( refwcs );
    break;
    
  case SMF__QUA:
    fset = astCopy( refwcs );
    break;
    
  case SMF__DKS:
    /* For the dark squid model the only meaningful axis we can extract
       from refwcs is the column. The other axis contains both row and time
       information. */

    /* Get a pointer to the current->base Mapping (i.e. the Mapping from
       WCS coords to GRID coords). */
    cbmap = astGetMapping( refwcs, AST__CURRENT, AST__BASE );
    
    /* Use astMapSplit to split off the Mapping for the column
       axis (remember this index starts at 1) */
    
    caxis = 1+SMF__COL_INDEX;
    astMapSplit( cbmap, 1, &caxis, out, &cmap );
    
    /* We now check that the Mapping was split succesfully. This
       should always be the case for the column axis since it is
       independent of the others, but it is as well to check in case
       of bugs, etc. */
    if( !cmap ) {
      /* The "tmap" mapping will have 1 input (the WCS time value) -
         astMapSplit guarantees this. But we
         should also check that it also has only one output (the
         corresponding GRID axis). */
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME ": Couldn't extract column-axis mapping",
              status );
    } else if( astGetI( cmap, "Nout" ) != 1 ) {
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME 
              ": Column-axis mapping has incorrect number of outputs",
              status );
    } else {
      
      /* This Mapping goes from column to grid, so we invert it first so
         that it goes from grid to column, as required by
         astAddFrame. */      
      astInvert( cmap );
      
      /* Create a new FrameSet containing a 2D GRID Frame. */
      fset = astFrameSet( astFrame( 2, "Domain=GRID" ), "" );
      
      /* Extract the 1D column Frame from the reference (WCS) 3D Frame. */
      cfrm = astPickAxes( refwcs, 1, &caxis, NULL);

      /* Create a unit mapping for the other axis */
      omap = astUnitMap( 1, "" );

      /* Create another 1D frame for the oter axis */
      ofrm = astFrame( 1, "Domain=DKSQUID+COEFF" );
         
      /* Combine the frames and mappings in parallel, then add to frameset */
      cmap2 = astCmpMap( cmap, omap, 0, "" );
      cfrm2 = astCmpFrame( cfrm, ofrm, "" );                        
      astAddFrame( fset, AST__BASE, cmap2, cfrm2 );
    }
    
    break;
    
  default:
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": Invalid smf_modeltype given.", status);        
  }
  
  /* Trap additional Ast errors */
  if( (*status == SAI__OK) && !astOK ) {
    *status = SAI__ERROR;
    msgSetc("MODEL", smf_model_getname( type, status ) );
    errRep( "", FUNC_NAME ": Ast error creating frameset for ^MODEL", status );
  }
  
  if( *status==SAI__OK ) {
    /* Export the frameset before ending the ast context */
    astExport( fset );
    
    /* Create smfHead if needed */
    if( !model->hdr ) {
      model->hdr = smf_create_smfHead( status );
    }
    
    /* Annul old tswcs if one exists */
    if( (*status==SAI__OK) && model->hdr->tswcs ) {
      model->hdr->tswcs = astAnnul( model->hdr->tswcs );
    }

    /* Store the new frameset in the header */
    if( *status==SAI__OK ) model->hdr->tswcs = fset;

  }

  astEnd;

}
