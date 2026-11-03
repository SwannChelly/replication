

/*
	data_source
	
	Date: January 2015
	
	Program: this program insheets the raw transaction data and cleans the dataset

	Input: P1306POLYANONYM_`year'_12.txt saved in $datapath
		
	Output:  x_eu.dta , a multilateral dataset which variables are:
		export value of exports
		main_cpa main product exported by the firm to the importer
		month first month 
		siren exporter's identifier
		buyer importer's identifier
		year year
		iso2 iso2 code of the destination 
	
*/

global dataset data_custom 
// the raw data have the form XXXXcustom_data where XXXX is the year
global datapath W:\data\TradeNetworks
cd $datapath 
clear 
g year=1995 
save x_all, replace 

forvalue i=1995(1)2010{
insheet using `i'$dataset.txt, delimiter(";") clear
append using x_all
save x_all, replace 
}

use x_all, clear

drop year 
rename v1 year
rename v2 month
rename v3 siren
rename v4 importer
rename v5 nc8
rename v6 cpa4
rename v7 iso2
rename v8 value
rename v9 indic_masse_nulle
rename v10 masse
rename v11 usup
rename v12 transport_mode

* drop observations that do not correspond to identified French firms
tostring siren, replace

replace siren="0"+siren if length(siren)==8 
replace siren="00"+siren if length(siren)==7
drop if length(siren)<=5

#delimit ;

drop if siren=="000000000"|siren=="111111111"|siren=="222222222"
|siren=="777777777"|siren=="888888888"|siren=="999999999";

#delimit cr


* "000000000" Societe en cours d'immatriculation
* "111111111" Societe monegasque (non soumis au systeme d'identification des entreprises SIRENE)
* "777777777" En groupage
* "888888888" Societe etrangere ne disposant pas de representant fiscal en France
* "999999999"  Occasionnel pour les operateurs non soumis au systeme d'identification SIRENE
* "222222222" Declaration en dessous du seuil statistique 
* integre dans ASTRINET depuis le 1er janvier 2010*

* Drop importers that do not correspond to firms identified by the customs
g _=length(importer)

* _==8: flows in regime 29
* _ > 9: destination is FR 

replace _ = 10 if _>9 
egen tot=sum(value)
egen tot_=sum(value),by(_) 
g sh=tot_/tot 
tab sh 
drop tot tot_ sh _
g iso2_tva=substr(importer,1,2) 
g confiance_tva=substr(importer,3,1)
g buyer=substr(importer,4,6) 

tab confiance_tva
egen tot=sum(value)
egen tot_=sum(value),by(confiance_tva) 
g sh=tot_/tot 
tab sh 
drop tot tot_ sh

* Adjust iso2 country codes
* Before 1999: XU for BEL and LUX - but info on the actual country based on iso2_tva number
* below a threshold, iso2 is not reported ("00") but iso2_tva can be
* in VAT number, Greece is refered to as EL
replace iso2=iso2_tva if iso2=="XU" & (iso2_tva=="BE"|iso2_tva=="LU")
replace iso2=iso2_tva if iso2=="00"
replace iso2_tva="GR" if iso2_tva=="EL"
replace iso2="GR" if iso2=="EL"
g dif=iso2!=iso2_tva 
tab dif 
rename value export
egen tot=sum(export) 
egen tot_=sum(export), by(dif) 
g sh=tot_/tot 
tab sh 
drop tot_ tot sh
drop if iso2!=iso2_tva
drop dif
* When iso2!=iso2_tva their is a third party involved in the bilateral flow => dropped

egen tot=sum(export) 
sum tot 
drop tot 

egen tot=sum(export) 
sum tot 
drop tot 
drop if iso2!=iso2_tva 
drop if confiance_tva=="9"|confiance_tva=="8"|confiance_tva=="7"|confiance_tva=="4"|confiance_tva=="3"
drop if buyer=="00000"

* Collapse data at the firm-to-firm times month-year times product level
collapse (sum) export masse usup, by(cpa4 siren buyer nc8 year iso2 month) 
save x_eu_bync8, replace
use x_eu_bync8,clear 

* Determine main product by firm-to-firm times year 
drop if nc8==0 // drop 2% of obs and 2% in value 
tostring cpa4, replace
replace cpa4="0"+cpa4 if length(cpa4)==3 
replace cpa4=substr(cpa4,1,2) 
egen tot=sum(export), by(siren year iso2 buyer)
egen totsb=sum(export), by(siren buyer year iso2 cpa4)
g sh=totsb/tot 
egen max=max(sh), by(siren buyer year iso2)
destring cpa4, replace
g main_cpa_=(max==sh)*(cpa4)
egen main_cpa=max(main_cpa_), by(buyer siren iso2 year) 

* Collapse by firm-to-firm times month-year
collapse (sum) export (max) main_cpa, by(siren buyer month year iso2) 
// combine small cpa2 
tostring main_cpa, replace 
replace main_cpa="8" if main_cpa=="5" // Mining products together
replace main_cpa="8" if main_cpa=="6" //  Mining products together
replace main_cpa="8" if main_cpa=="7" //  Mining products together
replace main_cpa="38" if main_cpa=="37" //  Water supply
drop if main_cpa=="96"
cap destring main_cpa, replace

* Collapse by firm-to-firm times year 
collapse (sum) export (max) main_cpa (min) month, by(siren buyer year iso2) 
tostring main_cpa, replace 
save x_eu, replace 


