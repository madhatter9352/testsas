/*==============================================================================
| NAME:    fcf_wl_ofac_extract
| PRODUCT: SAS Compliance Solutions
| SYSTEM:  UNIX/WINDOWS
================================================================================

WATCH LIST PROVIDER - U.S. Treasury - Office of Foreign Assets Control
WATCH LIST NAME     - Specially Designated Nationals List (SDN List)
WATCH LIST CODE     - OFAC
WEB LINK            - http://www.treas.gov/offices/enforcement/ofac/

MODULE TYPE         - EXTRACT
MODULE PURPOSE      - Read extract file(s) and output to SAS data set(s).

MODULE NOTES
------------
This module extracts the data from csv files that have been previously 
downloaded from the OFAC download page (http://www.treasury.gov/ofac/downloads).  
This module expects three csv files (sdn.csv, add.csv, and alt.csv) in the 
location defined by the corresponding macro variables &ofac_sdn_file, 
&ofac_add_file, &ofac_alt_file;

==============================================================================*/

/*-------------------------------------------------------------------
 * Copyright (c) 2012-2016 by SAS Institute Inc., Cary, NC 27513 USA
 *  ---All Rights Reserved.
 *-------------------------------------------------------------------*/

%macro fcf_wl_ofac_extract;

  /*------------
   * Set module
   *------------*/
  %let _fcfmodule_=fcf_WL_OFAC_EXTRACT;

  /*---------------------
   * Call pre macro stub
   *---------------------*/
  %fcf_execute_macro(pre&_fcfmodule_);

  /*------------------------------------------
   * Set error code to 0 and message to blank
   *------------------------------------------*/
  %let trans_rc = 0;
  %let _fcfmsg_=;

/******************************************************************************/
/* BEGIN: GetOFACfile
/* DESCRIPTION: Copy Watch List files from the Internet to the local disk
/******************************************************************************/
%let in_ofac1=&ofac_sdn_file;
%let in_ofac2=&ofac_add_file;
%let in_ofac3=&ofac_alt_file;

%do count = 1 %to 3;

   filename in_ofac "&&in_ofac&count";

   %put NOTE: FCF: Checking for input file: &&in_ofac&count;

   %if %sysfunc(fexist(in_ofac)) = 0 %then %do;

      %fcf_rcset(16);
      %let _fcfmsg_=ERROR: FCF: Input file does not exist.;
      %put &_fcfmsg_;
      %let _fcfmsg_=ERROR: FCF: Input file location: &&in_ofac&count;
      %fcf_put_error;
      %goto MACRO_END;

   %end;
%end;


/******************************************************************************/
/* BEGIN: STG_WTCH.wl_ofac_sdn_extract                                        */
/* DESCRIPTION: Input SDN Main extact file -  csv delimited                   */
/******************************************************************************/
filename in_sdn "&ofac_sdn_file";

data STG_WTCH.wl_ofac_sdn_extract;

   attrib
      ent_num    informat=best32.
                 format=best32.
                 label="Unique Record/Listing Identifier"

      sdn_name   informat=$350.
                 format=$350.
                 label="Name of SDN"

      sdn_type   informat=$12.
                 format=$12.
                 label="Type of SDN"

      program    informat=$50.
                 format=$50.
                 label="Sanctions Program Name"

      title      informat=$200.
                 format=$200.
                 label="Title of an Individual"

      call_sign  informat=$8.
                 format=$8.
                 label="Vessel Call Sign"

      vess_type  informat=$25.
                 format=$25.
                 label="Vessel Type"

      tonnage    informat=$14.
                 format=$14.
                 label="Vessel Tonnage"

      grt        informat=$8.
                 format=$8.
                 label="Gross Registered Tonnage"

      vess_flag  informat=$40.
                 format=$40.
                 label="Vessel Flag"

      vess_owner informat=$150.
                 format=$150.
                 label="Vessel Owner"

      remarks    informat=$1000.
                 format=$1000.
                 label="Remarks On SDN"
   ;

   infile in_sdn delimiter=',' dsd truncover pad lrecl=32767 end=eof;

   /* Check for DOS EOF marker and stop reading -- needed for UNIX */
   input c $char1. @;
   if c = '1a'x then do;
      call symputx('num_recs', _N_ -1);
      stop;
   end;

   input @1 ent_num
         sdn_name
         sdn_type
         program
         title
         call_sign
         vess_type
         tonnage
         grt
         vess_flag
         vess_owner
         remarks
   ;

   if upcase("&allow_invalid") eq "N" then
      if _error_ ne 0 then do;
         call symputx('trans_rc', 999999);
         stop;
      end;

   if eof then
      call symputx('num_recs', _N_ );

run;
%put NOTE: FCF: OFAC SDN Records read from input file: &num_recs;
/******************************************************************************/
/* END: STG_WTCH.wl_ofac_sdn_extract                                          */
/******************************************************************************/

/******************************************************************************/
/* BEGIN: STG_WTCH.wl_ofac_add_extract                                        */
/* DESCRIPTION: Input Address extract file -  csv delimited                   */
/******************************************************************************/
filename in_add "&ofac_add_file";

data STG_WTCH.wl_ofac_add_extract;

   attrib
      ent_num     informat=best32.
                  format=best32.
                  label="Link To Unique Listing"

      add_num     informat=best32.
                  format=best32.
                  label="Unique Record Identifier"

      address     informat=$750.
                  format=$750.
                  label="Street Address of SDN"

      /* Current length of field as defined by OFAC is 116 */
      city        informat=$200.
                  format=$200.
                  label="City, State/Province, Zip/Postal Code"

      country     informat=$250.
                  format=$250.
                  label="Country Of Address"

      add_remarks informat=$200.
                  format=$200.
                  label="Remarks On Address"
   ;

   infile in_add delimiter=',' dsd truncover pad lrecl=32767 end=eof;

   /* Check for DOS EOF marker and stop reading -- needed for UNIX */
   input c $char1. @;
   if c = '1a'x then do;
      call symputx('num_recs', _N_ -1);
      stop;
   end;

   input @1 ent_num
         add_num     
         address
         city        
         country
         add_remarks
   ;

   if upcase("&allow_invalid") eq "N" then
      if _error_ ne 0 then do;
         call symputx('trans_rc', 999999);
         stop;
      end;

   if eof then
      call symputx('num_recs', _N_ );

run;
%put NOTE: FCF: OFAC ADD Records read from input file: &num_recs;
/******************************************************************************/
/* END: STG_WTCH.wl_ofac_add_extract                                          */
/******************************************************************************/

/******************************************************************************/
/* BEGIN: STG_WTCH.wl_ofac_alt_extract                                        */
/* DESCRIPTION: Input Alternate Identity extract file - csv delimited         */
/******************************************************************************/
filename in_alt "&ofac_alt_file";

data stg_wtch.wl_ofac_alt_extract;

attrib
   ent_num     informat=best32.
               format=best32.
               label="Link To Unique Listing"

   alt_num     informat=best32.
               format=best32.
               label="Unique Record Identifier"

   alt_type    informat=$8.
               format=$8.
               label="Type Of Alternate Identity"

   alt_name    informat=$350.
               format=$350.
               label="Alternate Identity Name"

   alt_remarks informat=$200.
               format=$200.
               label="Remarks on Alternate Idenity"
;

   infile in_alt delimiter=',' dsd truncover pad lrecl=32767 end=eof;

   /* Check for DOS EOF marker and stop reading -- needed for UNIX */
   input c $char1. @;
   if c = '1a'x then do;
      call symputx('num_recs', _N_ -1);
      stop;
   end;

   input @1 ent_num  :best32.
         alt_num     :best32.
         alt_type    :$8.
         alt_name    :$350.
         alt_remarks :$200.
   ;

   if upcase("&allow_invalid") eq "N" then
      if _error_ ne 0 then do;
         call symputx('trans_rc', 999999);
         stop;
      end;

   if eof then
      call symputx('num_recs', _N_ );

run;
%put NOTE: FCF: OFAC ALT Records read from input file: &num_recs;
/******************************************************************************/
/* END: STG_WTCH.wl_ofac_alt_extract                                          */
/******************************************************************************/


  %MACRO_END:

   %if &trans_rc eq 3 or &trans_rc ge 5 %then
      %fcf_execute_macro(fcf_error);
   %else %do;
      %fcf_execute_macro(post&_fcfmodule_);
      %fcf_execute_macro(fcf_success);
   %end;

%mend fcf_wl_ofac_extract;
