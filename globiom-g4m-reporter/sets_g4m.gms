SETS
G4MOUTPUT
/
 area_af_hayear
 area_df_hayear
 area_forest_new_ha
 area_forest_old_ha
 area_forest_old_tot_ha
 area_forest_used_ha
 area_forest_old_used_ha
 area_forest_new_used_ha
 area_forest_natural_ha
 area_forest_primary_ha
 area_forest_tot_ha
 biom_af_tc
 biom_fm_tc
 cai_m3ha
 em_af_bm_mtco2year
 em_af_dom_mtco2year
 em_af_sl_mtco2year
 em_df_bm_mtco2year
 em_df_dom_mtco2year
 em_df_sl_mtco2year
 em_df_peat_mtco2year
 em_fm_ab_mtco2year
 em_fm_bm_mtco2year
 harvest_df_m3hayear
 harvest_fm_m3hayear
 harvest_total_m3year
 rotation_avg_year
/

sumG4MOUTPUT(G4MOUTPUT)
/
 area_af_hayear
 area_df_hayear
 area_forest_new_ha
 area_forest_old_ha
 area_forest_old_tot_ha
 area_forest_used_ha
 area_forest_old_used_ha
 area_forest_new_used_ha
 area_forest_natural_ha
 area_forest_primary_ha
 area_forest_tot_ha
 biom_af_tc
 biom_fm_tc
 em_af_bm_mtco2year
 em_af_dom_mtco2year
 em_af_sl_mtco2year
 em_df_bm_mtco2year
 em_df_dom_mtco2year
 em_df_sl_mtco2year
 em_df_peat_mtco2year
 em_fm_ab_mtco2year
 em_fm_bm_mtco2year
 harvest_df_m3hayear
 harvest_fm_m3hayear
 harvest_total_m3year
/

annG4MOUTPUT(G4MOUTPUT)
/
* area_af_hayear
* area_df_hayear
 em_af_bm_mtco2year
 em_af_dom_mtco2year
 em_af_sl_mtco2year
 em_df_bm_mtco2year
 em_df_dom_mtco2year
 em_df_sl_mtco2year
 em_df_peat_mtco2year
* em_fm_ab_mtco2year
 em_fm_bm_mtco2year
* harvest_df_m3hayear
* harvest_fm_m3hayear
* harvest_total_m3year
/

cumG4MOUTPUT(G4MOUTPUT)
/
 area_forest_new_ha
* area_forest_old_ha
 area_forest_old_tot_ha
 area_forest_used_ha
 
 area_forest_tot_ha
 area_forest_old_used_ha
 area_forest_new_used_ha
 area_forest_natural_ha
 area_forest_primary_ha
 
 area_df_hayear
/

OutputMsgItem_G4M_MAP(*,G4MOUTPUT)
/
 Aff_CO2_G4M .(
               em_af_bm_mtco2year
               em_af_dom_mtco2year
               em_af_sl_mtco2year
               )
 Def_CO2_G4M .(
               em_df_bm_mtco2year
               em_df_dom_mtco2year
               em_df_sl_mtco2year
               em_df_peat_mtco2year
               )
 Fmg_CO2_G4M .( em_fm_bm_mtco2year
               )
 Tot_CO2_G4M .(
               em_af_bm_mtco2year
               em_af_dom_mtco2year
               em_af_sl_mtco2year
               em_df_bm_mtco2year
               em_df_dom_mtco2year
               em_df_sl_mtco2year
               em_df_peat_mtco2year
               em_fm_bm_mtco2year
               )
/


g4mYEAR(ALLYEAR) /2000, 2010, 2020, 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100/

g4mYEAR_average_map(ALLYEAR,ALLYEAR)
/
2000 . (1995,2000)
2010 . (2005,2010)
2020 . (2015,2020)
2030 . (2025,2030)
2040 . (2035,2040)
2050 . (2045,2050)
2060 . (2055,2060)
2070 . (2065,2070)
2080 . (2075,2080)
2090 . (2085,2090)
2100 . (2095,2100)
/

G4MCOUNTRY
/
Afghanistan
Albania
Algeria
Andorra
Angola
Antigua_and_Barbuda
Argentina
Armenia
Australia
Austria
Azerbaijan
Bahamas
Bahrain
Bangladesh
Barbados
Belarus
Belgium
Belize
Benin
Bhutan
Bolivia
Bosnia_and_Herzegovina
Botswana
Brazil
Brunei_Darussalam
Bulgaria
Burkina_Faso
Burundi
Cambodia
Cameroon
Canada
Central_African_Republic
Chad
Chile
China
Colombia
Comoros
Congo
Costa_Rica
Cote_d_Ivoire
Croatia
Cuba
Cyprus
Czech_Republic
Democratic_Peoples_Republic_of_Korea
Democratic_Republic_of_the_Congo
Denmark
Djibouti
Dominica
Dominican_Republic
Ecuador
Egypt
El_Salvador
Equatorial_Guinea
Eritrea
Estonia
Ethiopia
Faeroe_Islands
Falkland_Islands
Fiji
Finland
France
French_Guiana
Gabon
Gambia
Georgia
Germany
Ghana
Greece
Greenland
Grenada
Guadeloupe
Guatemala
Guinea
Guinea_Bissau
Guyana
Haiti
Honduras
Hungary
Iceland
India
Indonesia
Iran_Islamic_Republic_of
Iraq
Ireland
Israel
Italy
Jamaica
Japan
Jordan
Kazakhstan
Kenya
Kuwait
Kyrgyzstan
Lao_Peoples_Democratic_Republic
Latvia
Lebanon
Lesotho
Liberia
Libyan_Arab_Jamahiriya
Liechtenstein
Lithuania
Luxembourg
Madagascar
Malawi
Malaysia
Mali
Malta
Martinique
Mauritania
Mauritius
Mexico
Monaco
Mongolia
Morocco
Mozambique
Myanmar
Namibia
Nepal
Netherlands
New_Caledonia
New_Zealand
Nicaragua
Nigeria
Northern_Mariana_Islands
Norway
Oman
Pakistan
Palestinian_Territories
Panama
Papua_New_Guinea
Paraguay
Peru
Philippines
Poland
Portugal
Puerto_Rico
Qatar
Republic_of_Korea
Republic_of_Moldova
Republic_of_Serbia
Reunion
Romania
Russian_Federation
Rwanda
Saint_Kitts_and_Nevis
Saint_Lucia
Saint_Vincent_and_the_Grenadines
San_Marino
Sao_Tome_and_Principe
Saudi_Arabia
Senegal
Sierra_Leone
Singapore
Slovakia
Slovenia
Solomon_Islands
Somalia
South_Africa
Spain
Sri_Lanka
Sudan
Suriname
Svalbard_and_Jan_Mayen
Swaziland
Sweden
Switzerland
Syrian_Arab_Republic
Tajikistan
Thailand
The_former_Yugoslav_Republic_of_Macedonia
Togo
Trinidad_and_Tobago
Tunisia
Turkey
Turkmenistan
Turks_and_Caicos_Islands
Uganda
Ukraine
United_Arab_Emirates
United_Kingdom
United_Republic_of_Tanzania
United_States_of_America
Uruguay
Uzbekistan
Vanuatu
Venezuela
Viet_Nam
Western_Sahara
Yemen
Zambia
Zimbabwe
/

G4MCOUNTRY_MAP(ALLCOUNTRY,G4MCOUNTRY)
/
Afghanistan     .       Afghanistan
Albania .       Albania
Algeria .       Algeria
Angola  .       Angola
Argentina       .       Argentina
Armenia .       Armenia
Australia       .       Australia
Austria .       Austria
Azerbaijan      .       Azerbaijan
Bahamas .       Bahamas
Bahrain .       Bahrain
Bangladesh      .       Bangladesh
Belarus .       Belarus
Belgium .       Belgium
Belize  .       Belize
Benin   .       Benin
Bhutan  .       Bhutan
Bolivia .       Bolivia
BosniaHerzg     .       Bosnia_and_Herzegovina
Botswana        .       Botswana
Brazil  .       Brazil
BruneiDarsm     .       Brunei_Darussalam
Bulgaria        .       Bulgaria
BurkinaFaso     .       Burkina_Faso
Burundi .       Burundi
Cambodia        .       Cambodia
Cameroon        .       Cameroon
Canada  .       Canada
CentAfrRep      .       Central_African_Republic
Chad    .       Chad
Chile   .       Chile
China   .       China
Colombia        .       Colombia
Comoros .       Comoros
CongoDemR       .       Democratic_Republic_of_the_Congo
CongoRep        .       Congo
CostaRica       .       Costa_Rica
CotedIvoire     .       Cote_d_Ivoire
Croatia .       Croatia
Cuba    .       Cuba
Cyprus  .       Cyprus
CzechRep        .       Czech_Republic
Denmark .       Denmark
Djibouti        .       Djibouti
DominicanRp     .       Dominican_Republic
Ecuador .       Ecuador
Egypt   .       Egypt
ElSalvador      .       El_Salvador
EqGuinea        .       Equatorial_Guinea
Eritrea .       Eritrea
Estonia .       Estonia
Ethiopia        .       Ethiopia
FalklandIs      .       Falkland_Islands
FijiIslands     .       Fiji
Finland .       Finland
France  .       France
FrGuiana        .       French_Guiana
Gabon   .       Gabon
Gambia  .       Gambia
Georgia .       Georgia
Germany .       Germany
Ghana   .       Ghana
Greece  .       Greece
Greenland       .       Greenland
Guadeloupe      .       Guadeloupe
Guatemala       .       Guatemala
Guinea  .       Guinea
GuineaBissau    .       Guinea_Bissau
Guyana  .       Guyana
Haiti   .       Haiti
Honduras        .       Honduras
Hungary .       Hungary
Iceland .       Iceland
India   .       India
Indonesia       .       Indonesia
Iran    .       Iran_Islamic_Republic_of
Iraq    .       Iraq
Ireland .       Ireland
Israel  .       Israel
Italy   .       Italy
Jamaica .       Jamaica
Japan   .       Japan
Jordan  .       Jordan
Kazakhstan      .       Kazakhstan
Kenya   .       Kenya
KoreaDPRp       .       Democratic_Peoples_Republic_of_Korea
KoreaRep        .       Republic_of_Korea
Kuwait  .       Kuwait
Kyrgyzstan      .       Kyrgyzstan
Laos    .       Lao_Peoples_Democratic_Republic
Latvia  .       Latvia
Lebanon .       Lebanon
Lesotho .       Lesotho
Liberia .       Liberia
Libya   .       Libyan_Arab_Jamahiriya
Lithuania       .       Lithuania
Luxembourg      .       Luxembourg
Macedonia       .       The_former_Yugoslav_Republic_of_Macedonia
Madagascar      .       Madagascar
Malawi  .       Malawi
Malaysia        .       Malaysia
Mali    .       Mali
Malta   .       Malta
Mauritania      .       Mauritania
Mauritius       .       Mauritius
Mexico  .       Mexico
MoldovaRep      .       Republic_of_Moldova
Mongolia        .       Mongolia
Morocco .       Morocco
Mozambique      .       Mozambique
Myanmar .       Myanmar
Namibia .       Namibia
Nepal   .       Nepal
Netherlands     .       Netherlands
NewCaledonia    .       New_Caledonia
NewZealand      .       New_Zealand
Nicaragua       .       Nicaragua
Nigeria .       Nigeria
Norway  .       Norway
Oman    .       Oman
Pakistan        .       Pakistan
Palestin        .       Palestinian_Territories
Panama  .       Panama
PapuaNGuin      .       Papua_New_Guinea
Paraguay        .       Paraguay
Peru    .       Peru
Philippines     .       Philippines
Poland  .       Poland
Portugal        .       Portugal
PuertoRico      .       Puerto_Rico
Qatar   .       Qatar
Reunion .       Reunion
Romania .       Romania
RussianFed      .       Russian_Federation
Rwanda  .       Rwanda
SaudiArabia     .       Saudi_Arabia
Senegal .       Senegal
Serbia-Monte    .       Republic_of_Serbia
SierraLeone     .       Sierra_Leone
Singapore       .       Singapore
Slovakia        .       Slovakia
Slovenia        .       Slovenia
SolomonIs       .       Solomon_Islands
Somalia .       Somalia
SouthAfrica     .       South_Africa
Spain   .       Spain
SriLanka        .       Sri_Lanka
Sudan   .       Sudan
Suriname        .       Suriname
Swaziland       .       Swaziland
Sweden  .       Sweden
Switzerland     .       Switzerland
Syria   .       Syrian_Arab_Republic
Tajikistan      .       Tajikistan
Tanzania        .       United_Republic_of_Tanzania
Thailand        .       Thailand
Togo    .       Togo
TrinidadTob     .       Trinidad_and_Tobago
Tunisia .       Tunisia
Turkey  .       Turkey
Turkmenistan    .       Turkmenistan
Uganda  .       Uganda
UK      .       United_Kingdom
Ukraine .       Ukraine
UntdArabEm      .       United_Arab_Emirates
Uruguay .       Uruguay
USA     .       United_States_of_America
Uzbekistan      .       Uzbekistan
Vanuatu .       Vanuatu
Venezuela       .       Venezuela
VietNam .       Viet_Nam
WestSahara      .       Western_Sahara
Yemen   .       Yemen
Zambia  .       Zambia
Zimbabwe        .       Zimbabwe
NotAccounted    .       Andorra
NotAccounted    .       Antigua_and_Barbuda
NotAccounted    .       Barbados
NotAccounted    .       Dominica
NotAccounted    .       Faeroe_Islands
NotAccounted    .       Grenada
NotAccounted    .       Liechtenstein
NotAccounted    .       Martinique
NotAccounted    .       Monaco
NotAccounted    .       Northern_Mariana_Islands
NotAccounted    .       Saint_Kitts_and_Nevis
NotAccounted    .       Saint_Lucia
NotAccounted    .       Saint_Vincent_and_the_Grenadines
NotAccounted    .       San_Marino
NotAccounted    .       Sao_Tome_and_Principe
NotAccounted    .       Svalbard_and_Jan_Mayen
NotAccounted    .       Turks_and_Caicos_Islands
/
;
