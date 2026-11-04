$setLocal X %system.dirSep%
$if not set g4mcsv $abort "Set --g4mcsv to the pooled G4M country feedback CSV"
$if not set base1 $abort "Set --base1 to the baseline SSP"
$if not set base2 $abort "Set --base2 to the baseline SCEN2"
$if not set base3 $abort "Set --base3 to the baseline RCP"

$include sets_g4m.gms

$offlisting
TABLE
G4MSCENOUTPUT_DATA_ORG(*,*,*,*)
$ondelim
$include "%g4mcsv%"
$offdelim
;

$onlisting
$include g4m_scen_map.gms

PARAMETER G4M_SCENOUTPUT_DATA_RAW(*,*,*,*,*,*) Original G4M results;

LOOP(G4M_SCEN_MAP(G4MSCEN2,SCEN1,SCEN2,SCEN3),
LOOP(G4MCOUNTRY_MAP(COUNTRY,G4MCOUNTRY),
G4M_SCENOUTPUT_DATA_RAW(COUNTRY,SCEN1,SCEN2,SCEN3,G4MOUTPUT,ALLYEAR)
 $G4MSCENOUTPUT_DATA_ORG(G4MCOUNTRY,G4MSCEN2,G4MOUTPUT,ALLYEAR)
= G4MSCENOUTPUT_DATA_ORG(G4MCOUNTRY,G4MSCEN2,G4MOUTPUT,ALLYEAR);
););

PARAMETER G4M_SCENOUTPUT_DATA(*,*,*,*,*,*) G4M results at regional level;

G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,cumG4MOUTPUT,ScenYear)
 = SUM(REGION_MAP(REGION,COUNTRY),
   G4M_SCENOUTPUT_DATA_RAW(COUNTRY,SCEN1,SCEN2,SCEN3,cumG4MOUTPUT,ScenYear));

* averaging to 10 years
G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,annG4MOUTPUT,g4mYear)
 $ SUM(ALLYear $g4mYEAR_average_map(g4mYear,ALLYEAR),1)
 = SUM((REGION_MAP(REGION,COUNTRY),g4mYEAR_average_map(g4mYear,ALLYEAR)),
        G4M_SCENOUTPUT_DATA_RAW(COUNTRY,SCEN1,SCEN2,SCEN3,annG4MOUTPUT,ALLYear))
  /SUM(ALLYear $g4mYEAR_average_map(g4mYear,ALLYEAR),1);

* #### LAND COVER
Output4_SSP(REGION,"Land Cover|Forest|Forest old","million ha",SCEN1,SCEN2,SCEN3,ScenYear) = 0;
Output4_SSP(REGION,"Land Cover|Forest|Forest old","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_old_tot_ha",ScenYear) * 0.000001;

Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear) = 0;
Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_used_ha",ScenYear) * 0.000001;

Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear) =0;
Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 $ Output4_SSP(REGION,"Land Cover|Forest|Forest old","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Forest|Forest old","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 - Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 $(Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 = Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 + Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 $(Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 = 0;

Output4_SSP(REGION,"Land Cover|Forest|Managed","million ha",SCEN1,SCEN2,SCEN3,ScenYear) = 0;
Output4_SSP(REGION,"Land Cover|Forest|Managed","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Forest|Afforestation and Reforestation","million ha",SCEN1,SCEN2,SCEN3,ScenYear) = 0;
Output4_SSP(REGION,"Land Cover|Forest|Afforestation and Reforestation","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_new_ha",ScenYear) * 0.000001;

Output4_SSP(REGION,"Land Cover|Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear) =0;
Output4_SSP(REGION,"Land Cover|Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Forest|Managed","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 + Output4_SSP(REGION,"Land Cover|Forest|Natural Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 + Output4_SSP(REGION,"Land Cover|Forest|Afforestation and Reforestation","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Forest|Deforestation rate","million ha/yr",SCEN1,SCEN2,SCEN3,ScenYear) = 0;
Output4_SSP(REGION,"Land Cover|Forest|Deforestation rate","million ha/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_df_hayear",ScenYear) * 0.000001;
 
* currently other land as residual
Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)=0;
Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 - Output4_SSP(REGION,"Land Cover|Cropland","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 - Output4_SSP(REGION,"Land Cover|Pasture","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 - Output4_SSP(REGION,"Land Cover|Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

* if negative adjust grassland area
Output4_SSP(REGION,"Land Cover|Pasture","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 $(Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)lt 0 )
 = Output4_SSP(REGION,"Land Cover|Pasture","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 + Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 $(Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)lt 0 )
 = 0;

* DL - Bending The Curve (BTC) biodiversity scenario - Result reporting - add restoration land
Output4_SSP(REGION,"Land Cover|Other Land|Other Natural Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = (OUTPUT("LAND","1000 ha",REGION,"NatLnd",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("LAND","1000 ha",REGION,"AbnLnd",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("LAND","1000 ha",REGION,"WetLnd",SCEN1,SCEN2,SCEN3,ScenYear)
 - OUTPUT("LAND2","1000 ha",REGION,'2.2.OtherGrass',SCEN1,SCEN2,SCEN3,"2000"))*0.001;

Output4_SSP(REGION,"Land Cover|Other Land|Other Natural Land|Other","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Other Land|Other Natural Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

$ontext
Output4_SSP(REGION,"Land Cover|Other Land|Other Natural Land|Restoration Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = OUTPUT('LAND','1000 Ha',REGION,'RstLnd',SCEN1,SCEN2,SCEN3,ScenYear)
  *0.001;
Output4_SSP(REGION,"Land Cover|Other Land|Other Natural Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Other Natural Land|Other","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
   + Output4_SSP(REGION,"Land Cover|Other Natural Land|Restoration Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
;
$offtext
* END DL - Bending The Curve (BTC) biodiversity scenario




* #### EMISSIONS
* YW SSPupdate 20250616: don't include peatland emission from deforestation in the V5 SSP lookup table, because (i) current parameters used in G4M probably overestimate peatland emissions from deforestation in IDN and (ii) many other IAMs don't report peatland deforestation emissions

Output4_SSP(REGION,"Emissions|CO2|AFOLU","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)=0;
Output4_SSP(REGION,"Emissions|CO2|AFOLU","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)

 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_bm_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_dom_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_sl_mtco2year",ScenYear)
* + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_peat_mtco2year",ScenYear)

 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear)
         $G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)

 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)

 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
;


Output4_SSP(REGION,"Emissions|CO2|AFOLU|Positive","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)=0;
Output4_SSP(REGION,"Emissions|CO2|AFOLU|Positive","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)gt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)gt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)gt 0)

 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_bm_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_bm_mtco2year",ScenYear)gt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_dom_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_dom_mtco2year",ScenYear)gt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_sl_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_sl_mtco2year",ScenYear)gt 0)
* + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_peat_mtco2year",ScenYear)
*         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_peat_mtco2year",ScenYear)gt 0)

 +(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear))
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)AND
          (G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
          - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear))gt 0)

 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)gt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)gt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)gt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)gt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) gt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) gt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
         $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) gt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
         $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) gt 0)
 ;

Output4_SSP(REGION,"Emissions|CO2|AFOLU|Negative","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)=0;
Output4_SSP(REGION,"Emissions|CO2|AFOLU|Negative","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)lt 0)

 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_bm_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_bm_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_dom_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_dom_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_sl_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_sl_mtco2year",ScenYear)lt 0)
* + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_peat_mtco2year",ScenYear)
*         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_peat_mtco2year",ScenYear)lt 0)

 +(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear))
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)AND
          (G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
          - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear))lt 0)

 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
         $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
         $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
;

Output4_SSP(REGION,"Emissions|CO2|AFOLU|Afforestation","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear);

Output4_SSP(REGION,"Emissions|CO2|AFOLU|Deforestation","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)=0;
Output4_SSP(REGION,"Emissions|CO2|AFOLU|Deforestation","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_bm_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_dom_mtco2year",ScenYear)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_sl_mtco2year",ScenYear)
* + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_df_peat_mtco2year",ScenYear)
 ;

Output4_SSP(REGION,"Emissions|CO2|AFOLU|Forest Management","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 $ G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear);

Output4_SSP(REGION,"Emissions|CO2|AFOLU|Other LUC","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)=0;
Output4_SSP(REGION,"Emissions|CO2|AFOLU|Other LUC","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear);


* YW 20241111: Update to new IAMC template

Output4_SSP(REGION,"Carbon Removal|Land Use","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(
   Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCF",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCF",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)
         $(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)lt 0)
 +(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear))
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)AND
          (G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_fm_bm_mtco2year",ScenYear)
          - G4M_SCENOUTPUT_DATA(REGION,"%base1%","%base2%","%base3%","em_fm_bm_mtco2year",ScenYear))lt 0)
 );

* YW: Update to new IAMC template
Output4_SSP(REGION,"Activity for GAINS|FOREST","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear);


* YW 20241205: Update to new IAMC template
Output4_SSP(REGION,"Carbon Removal|Land Use|Agroforestry","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
         $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Silvopasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0));

Output4_SSP(REGION,"Carbon Removal|Land Use|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
         $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Biochar","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0));

Output4_SSP(REGION,"Carbon Removal|Land Use|Forest Management","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Forest Management","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)$(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Forest Management","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0));

Output4_SSP(REGION,"Carbon Removal|Land Use|Re/Afforestation","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_bm_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_dom_mtco2year",ScenYear)lt 0)
 + G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)
         $(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"em_af_sl_mtco2year",ScenYear)lt 0));

*Output4_SSP(REGION,"Carbon Removal|Land Use|Re/Afforestation|Natural Forest","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
* = ;
*Output4_SSP(REGION,"Carbon Removal|Land Use|Re/Afforestation|Plantation","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
* = ;

*Output4_SSP(REGION,"Carbon Removal|Land Use|Other LUC","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
* = -(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Other LUC","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)$(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Other LUC","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0));
Output4_SSP(REGION,"Carbon Removal|Land Use|Other LUC","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -( OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear)$(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCC",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear)$(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCG",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear)$(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCE",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
 + OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear)$(OUTPUT("ECO2","Mt CO2eq/yr",REGION,"LUCR",SCEN1,SCEN2,SCEN3,ScenYear) lt 0) );

Output4_SSP(REGION,"Carbon Removal|Land Use|Soil Carbon Management","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(
    Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)
  + Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
        $(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0));

Output4_SSP(REGION,"Carbon Removal|Land Use|Soil Carbon Management|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)$(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Cropland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0)) ;

Output4_SSP(REGION,"Carbon Removal|Land Use|Soil Carbon Management|Grassland","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = -(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)$(Output4_SSP(REGION,"Emissions|CO2|AFOLU|Agriculture|Soil Carbon|Pasture","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear) lt 0));

*Output4_SSP(REGION,"Carbon Removal|Long-Lived Materials|Plastics","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
* = ;
*Output4_SSP(REGION,"Carbon Removal|Long-Lived Materials|Timber","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
* = ;

Output4_SSP(REGION,"Gross Removals|CO2|AFOLU","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
= - Output4_SSP(REGION,"Carbon Removal|Land Use","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Gross Removals|CO2|AFOLU|Intentional","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
= - Output4_SSP(REGION,"Carbon Removal|Land Use","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Gross Emissions|CO2|AFOLU","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Emissions|CO2|AFOLU|Positive","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Emissions|GHG|AFOLU","Mt CO2eq/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Emissions|CO2|AFOLU","Mt CO2/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 + Output4_SSP(REGION,"Emissions|N2O|AFOLU","kt N2O/yr",SCEN1,SCEN2,SCEN3,ScenYear)*0.298
 + Output4_SSP(REGION,"Emissions|CH4|AFOLU","Mt CH4/yr",SCEN1,SCEN2,SCEN3,ScenYear)*25;
 
Output4_SSP(REGION,"Harvested Area|Forestry","million ha/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear);


Output4_SSP(REGION,"Yield|Forestry|Timber Production","m3/ha",SCEN1,SCEN2,SCEN3,ScenYear)
  $(Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear))
 = Output4_SSP(REGION,"Forestry Production|Roundwood","million m3/yr",SCEN1,SCEN2,SCEN3,ScenYear)
 / Output4_SSP(REGION,"Land Cover|Forest|Forestry","million ha",SCEN1,SCEN2,SCEN3,ScenYear);


*===Formulas for reporting forest areas (instructed by MG)===
*Land Cover|Forest|Planted       area_forest_tot_ha - area_forest_natural_ha
*Land Cover|Forest|Planted|Natural|Re/Afforestation                  area_forest_new_ha - area_forest_new_used_ha
*Land Cover|Forest|Planted|Plantation                 area_forest_used_ha 
*Land Cover|Forest|Planted|Plantation|Re/Afforestation            area_forest_new_used_ha
*Land Cover|Forest|Planted|Plantation|Timber                area_forest_old_used_ha
* ===========================================================

Output4_SSP(REGION,"Land Cover|Forest|Planted","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 =(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_tot_ha",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_natural_ha",ScenYear))* 0.000001;

Output4_SSP(REGION,"Land Cover|Forest|Natural","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_natural_ha",ScenYear) * 0.000001;
 
Output4_SSP(REGION,"Land Cover|Forest|Primary","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_primary_ha",ScenYear) * 0.000001;

Output4_SSP(REGION,"Land Cover|Forest|Secondary","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Forest|Natural","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 - Output4_SSP(REGION,"Land Cover|Forest|Primary","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Forest|Planted|Natural|Re/Afforestation","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 =(G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_new_ha",ScenYear)
 - G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_new_used_ha",ScenYear))* 0.000001;

Output4_SSP(REGION,"Land Cover|Forest|Planted|Plantation","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_used_ha",ScenYear) * 0.000001;
 
Output4_SSP(REGION,"Land Cover|Forest|Planted|Plantation|Re/Afforestation","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_new_used_ha",ScenYear) * 0.000001;
 
Output4_SSP(REGION,"Land Cover|Forest|Planted|Plantation|Timber","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = G4M_SCENOUTPUT_DATA(REGION,SCEN1,SCEN2,SCEN3,"area_forest_old_used_ha",ScenYear) * 0.000001;



Output4_SSP(REGION,"Land Cover|Other Natural","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

Output4_SSP(REGION,"Land Cover|Other Natural|Primary Non-Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Other Natural","million ha",SCEN1,SCEN2,SCEN3,ScenYear);


Output4_SSP(REGION,"Land Cover|Other Natural|Primary Non-Forest","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 = Output4_SSP(REGION,"Land Cover|Other Natural","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 - Output4_SSP(REGION,"Land Cover|Other Natural|Restored","million ha",SCEN1,SCEN2,SCEN3,ScenYear);

*"Land Cover|Other Natural|Recovered"    million ha

* Setting "Land Cover|Other Land" to zero for now, in line with new IAMC template. (should be updated to "urban" area, or maybe "NotRel" in the future. Worth checking.)
Output4_SSP(REGION,"Land Cover|Other Land","million ha",SCEN1,SCEN2,SCEN3,ScenYear)
 $(Obj_Compare(SCEN1,SCEN2,SCEN3,ScenYear))
 = 0.00001;




