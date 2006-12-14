/*
*+
*  Name:
*     sc2sim_heatrun

*  Purpose:
*     Generate a heater flat-field measurement

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SC2SIM subroutine

*  Invocation:
*     sc2sim_heatrun ( struct sc2sim_obs_struct *inx, 
*                      struct sc2sim_sim_struct *sinx, 
*                      double coeffs[], double digcurrent, double digmean, 
*                      double digscale, char filter[], double *heater, int nbol,
*                      double *pzero, double samptime, int *status);

*  Arguments:
*     inx = sc2sim_obs_struct* (Given)
*        Structure for values from XML
*     sinx = sc2sim_sim_struct* (Given)
*        Structure for sim values from XML
*     coeffs = double[] (Given)
*        Bolometer response coeffs
*     digcurrent - double (Given)
*        Digitisation mean current
*     digmean = double (Given)
*        Digitisation mean value
*     digscale = double (Given)
*        Digitisation scale factor
*     filter = char[] (Given)
*        String to hold filter name
*     heater - double* (Given)
*        Bolometer heater ratios
*     nbol = int (Given)
*        Total number of bolometers
*     pzero = double* (Given)
*        Bolometer power offsets
*     samptime = double (Given)
*        Sample time in sec
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     The heatrun method generates a heater flat-field measurement
*     from simulated data for each of a range of heater settings.

*  Notes:

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     Andy Gibb (UBC)
*     Edward Chapin (UBC)
*     David Berry (JAC, UCLan)
*     B.D.Kelly (ROE)
*     Jen Balfour (UBC)
*     {enter_new_authors_here}

*  History:
*     2005-02-16 (BDK):  
*        Original
*     2005-05-18 (BDK):  
*        Get xbc, ybc from instrinit
*     2005-05-20 (BDK):  
*        Add flatcal 
*     2005-06-17 (BDK):  
*        Allocate workspace dynamically
*     2005-08-19 (BDK):  
*        Do calibration fit, remove flux2cur flag check 
*     2005-10-04 (BDK):  
*        Change to new data interface
*     2006-01-13 (ELC):  
*        Write subarray name 
*     2006-01-24 (ELC):  
*        Write filter/atstart/atend 
*     2006-06-09 (JB):  
*        Added to smurf_sim 
*     2006-07-26 (JB):  
*        Moved into sc2sim_heatrun 
*     2006-07-28 (JB):
*        Changed sc2head to JCMTState
*     2006-08-08 (EC):
*        Removed slaDjcl prototype and instead include star/slalib.h
*     2006-09-22 (JB):
*        Replaced dxml_structs with sc2sim_structs and removed
*        DREAM-specific code.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
*     University of British Columbia. All Rights Reserved.

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

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

/* STARLINK includes */
#include "ast.h"
#include "fitsio.h"
#include "mers.h"
#include "par.h"
#include "par_par.h"
#include "prm_par.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/hds.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "star/slalib.h"

#include "sc2da/Dits_Err.h"
#include "sc2da/Ers.h"
#include "sc2da/sc2store_par.h"
#include "sc2da/sc2math.h"
#include "sc2da/sc2ast.h"

#include "sc2sim.h"

/* SMURF includes */
#include "smurf_par.h"
#include "libsmurf/smurflib.h"
#include "libsmf/smf.h"

#include "f77.h"

#define FUNC_NAME "sc2sim_heatrun"
#define LEN__METHOD 20

void sc2sim_heatrun ( struct sc2sim_obs_struct *inx, 
                      struct sc2sim_sim_struct *sinx, 
                      double coeffs[], double digcurrent, double digmean, 
                      double digscale, char filter[], double *heater, int nbol,
                      double *pzero, double samptime, int *status)
{

   int bol;                        /* counter for indexing bolometers */
   double corner;                  /* corner frequency in Hz */
   double current;                 /* bolometer current in amps */
   int date_da;                    /* day corresponding to MJD */
   double date_df;                 /* day fraction corresponding to MJD */
   int date_mo;                    /* month corresponding to MJD */
   int date_yr;                    /* year corresponding to MJD */
   int date_status;                /* status of mjd->calendar date conversion */
   double *dbuf=NULL;              /* simulated data buffer */
   int *digits=NULL;               /* output data buffer */
   int *dksquid=NULL;              /* dark squid values */
   char filename[SC2SIM__FLEN];    /* name of output file */
   double *flatcal=NULL;           /* flatfield calibration */
   char flatname[SC2STORE_FLATLEN];/* flatfield algorithm name */
   double *flatpar=NULL;           /* flatfield parameters */
   double flux;                    /* flux at bolometer in pW */
   static double fnoise[SC2SIM__MXSIM];    /* instr. noise for 1 bolometer */
   JCMTState *head;                /* per-frame headers */
   double *heatptr;                /* pointer to list of heater settings */ 
   int j;                          /* loop counter */
   int nflat;                      /* number of flat coeffs per bol */
   int numsamples;                 /* Number of samples in output. */
   double *output;                 /* series of output values */
   int sample;                     /* sample counter */
   double sigma;                   /* instrumental white noise */

   if ( *status != SAI__OK) return;

   /* Do a heatrun */

   /* Calculate year/month/day corresponding to MJD at start */
   slaDjcl( inx->mjdaystart, &date_yr, &date_mo, &date_da, &date_df, 
	    &date_status );

   numsamples = inx->heatnum;

   /* allocate workspace */

   output = smf_malloc ( numsamples, sizeof(*output), 1, status );
   heatptr = smf_malloc ( numsamples, sizeof(*heatptr), 1, status );
   dbuf = smf_malloc ( numsamples*nbol, sizeof(*dbuf), 1, status );
   digits = smf_malloc ( numsamples*nbol, sizeof(*digits), 1, status );
   dksquid = smf_malloc ( numsamples*inx->nboly, sizeof(*dksquid), 1, status );
   head = smf_malloc ( numsamples, sizeof(*head), 1, status );

   /* Generate the list of heater settings */

   for ( sample=0; sample<numsamples; sample++ ) {
      heatptr[sample] = inx->heatstart + (double)sample * inx->heatstep;
   }

   /*  Generate a full time sequence for one bolometer at a time */

   for ( bol=0; bol<nbol; bol++ ) {

      /* Create an instrumental 1/f noise sequence.
	 Simulate a 1/f noise sequence by generating white noise sequence, 
 	 Fourier transforming it, applying a 1/f law, then transforming back
	 again. Generate and add a new white noise sequence.
	 The buffer fnoise contains the noise pattern. */

      if ( sinx->add_fnoise == 1 ) {
	 sigma = 1.0e-9;
	 corner = 0.01;
	 sc2sim_invf ( sigma, corner, samptime, SC2SIM__MXSIM, fnoise, status );
      }

      /* Generate a measurement sequence for each bolometer. */

      for ( sample=0; sample<numsamples; sample++ ) {

         if ( sinx->add_hnoise == 1 ) {
	    flux = heatptr[sample] * heater[bol];
	 } else {
	    flux = heatptr[sample];
	 }

	 /* Convert to current with bolometer power offset.
	    The bolometer offset in PZERO(BOL) is added to the FLUX, and then
	    the power in FLUX is converted to a current in scalar CURRENT with 
	    help of the polynomial expression with coefficients in COEFFS(*) */

	 sc2sim_ptoi ( flux, SC2SIM__NCOEFFS, coeffs, pzero[bol], 
	               &current, status);

	 /* Store the value. */

	 output[sample] = current;

      }

      /* Now output[] contains the values current for all samples in 
	 the cycles for this bolometer. */

      if ( sinx->add_fnoise == 1 ) {

	 /* Add instrumental 1/f noise data in output */

	 for ( sample=0; sample<numsamples; sample++ ) {
	    output[sample] += fnoise[sample];
	 }

      }

      for ( sample=0; sample<numsamples; sample++ ) {
	 dbuf[sample*nbol+bol] = output[sample];
      }

   }

   /* Digitise the numbers */

   sc2sim_digitise ( nbol*numsamples, dbuf, digmean, digscale, digcurrent,
                     digits, status );

   /* Overwrite the original simulation with the digitised version */

   for ( sample=0; sample<numsamples*nbol; sample++ ) {
      dbuf[sample] = (double)digits[sample];
   }

   /* Perform the fit */

   if ( strcmp ( inx->flatname, "POLYNOMIAL" ) == 0 ) {

      nflat = 6;
      flatcal = smf_malloc ( nbol*nflat, sizeof(*flatcal), 1, status );
      flatpar = smf_malloc ( nflat, sizeof(*flatpar), 1, status );
      strcpy ( flatname, "POLYNOMIAL" );
      sc2sim_fitheat ( nbol, numsamples, heatptr, dbuf, flatcal, status );
      
      for ( j=0; j<nflat; j++ ) {
	 flatpar[j] = j - 2;
      }

   } else {

      nflat = numsamples;
      flatcal = smf_malloc ( nbol*nflat, sizeof(*flatcal), 1, status );
      flatpar = smf_malloc ( nflat, sizeof(*flatpar), 1, status );
      strcpy ( flatname, "TABLE" );

      for ( j=0; j<nflat; j++ ) {
	 flatpar[j] = heatptr[j];
      }

      for ( j=0; j<nflat*nbol; j++ ) {
	 flatcal[j] = dbuf[j];
      }

   }

   /* Get the name of this flatfield solution */
   sprintf ( filename, "%sheat%04i%02i%02i_00001", sinx->subname, date_yr, 
             date_mo, date_da );

   msgSetc( "FILENAME", filename );
   msgOut(" ", "Writing ^FILENAME", status ); 

   /* Store the data in output file file_name */
   /*   sc2sim_ndfwrheat ( sinx->add_atm, sinx->add_fnoise, sinx->add_pns,
                      inx->heatstart, inx->heatstep, filename, inx->nbolx, 
                      inx->nboly, inx->sample_t, sinx->subname, numsamples, 
                      nflat, flatname, head, digits, dksquid, flatcal, 
                      flatpar, filter, sinx->atstart, sinx->atend, status );*/

   sc2sim_ndfwrheat( inx, sinx, filename, numsamples, nflat, flatname, head, 
		     digits, dksquid, flatcal, flatpar, filter, status );

   msgSetc( "FILENAME", filename );
   msgOut(" ", "Done ^FILENAME", status ); 

   msgOutif(MSG__VERB," ", "Heatrun successful.", status ); 

} 
