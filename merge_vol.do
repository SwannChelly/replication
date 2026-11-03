/****************************************************************************
	Date: August 2017
	
	Program: merge_vol
	
	This file:
	- Computes various measures of volatility at the level of firms from BRN/RSI
	- Merge with volatility of exports as computed in EU trade-2-trade data
	- Correlate volatility of overall activity and volatility of exports
	
	Inputs: 
	- brnrsi95-08 constructed in import_brnrsi.dta
	- list_siren.dta constructed in ???
	
	Output:	
	- various correlation coefficients
****************************************************************************/


cd $datapath
use brn95-08, clear
drop if substr(ape,1,2)=="65"|substr(ape,1,2)=="66"|substr(ape,1,2)=="67"
sort siren year
merge 1:1 siren year using export95-07
*drop if _merge==2
drop _merge

egen id_f=group(siren)
xtset id_f year
foreach var in catotal caexpor cafranc effec vabcf tot_export eu28_export eu15_export{
	g gr_`var'=log(`var')-log(l.`var')
	g outlier_`var'=0
	replace outlier_`var'=1 if gr_`var'!=. & (gr_`var'<-0.8|gr_`var'>4)
}
save temp, replace

* Summary statistics on coverage
use temp, clear
g export=1 if caexpor!=0 & caexpor!=1
g total=1 if catotal!=0 & catotal!=1
g export_=1 if tot_export!=0 & tot_export!=.
g eu28=1 if eu28_export!=0 & eu28_export!=.
g eu15=1 if eu15_export!=0 & eu15_export!=.
collapse (sum)   total export  export_ eu28 eu15 catotal caexpor tot_export eu28_export eu15_export

* Summary statistics on export intensities
use temp, clear
gen export_ratio = caexpor / catotal if catotal!=. & cafranc!=. 
summarize export_ratio if year==2007, detail
summarize export_ratio, detail
summarize export_ratio if year==2007 & caexpor!=0 & caexpor!=., detail
summarize export_ratio if caexpor!=0 & caexpor!=., detail
egen tot_caexpor = sum(caexpor)
egen tot_catotal = sum(catotal)
gen tot_export_ratio = tot_caexpor / tot_catotal
summarize tot_export_ratio 

* Compute volatility at the firm-level
foreach var in catotal caexpor cafranc tot_export eu28_export eu15_export{
	use temp, clear
	drop if outlier_`var'==1|gr_`var'==.
	sort siren id_f
	collapse (sd) sd_`var'=gr_`var' (count) count_`var'=gr_`var', by(siren id_f)
	g var_`var'=sd_`var'*sd_`var'
	save temp_`var', replace
}
use temp_catotal, clear
sort siren id_f
merge siren id_f using temp_caexpor
drop _merge
sort siren id_f
merge siren id_f using temp_cafranc
drop _merge
sort siren id_f
merge siren id_f using temp_tot_export
drop _merge
sort siren id_f
merge siren id_f using temp_eu28_export
drop _merge
sort siren id_f
merge siren id_f using temp_eu15_export
drop _merge
save temp_outlier, replace
reg var_caexpor var_cafranc if count_cafranc>=4 & count_caexpo>=4
foreach var in caexpor cafranc{
	g lvar_`var'=log(var_`var')
}
scatter lvar_caexpor lvar_cafranc if count_cafranc>=4 & count_caexpo>=4
sum lvar_caexpor, d
sum lvar_cafranc, d
scatter lvar_caexpor lvar_cafranc if count_cafranc>=4 & count_caexpo>=4 & lvar_caexpor>-7.57 & lvar_cafranc<.85 & lvar_cafranc>-8.62 & lvar_caexpor<1.49


foreach var in catotal caexpor  tot_export eu28_export eu15_export cafranc{
	di "`var'"
	gen _=sqrt(var_`var') if count_`var'>=4
	sum _, d
	drop _
	pwcorr sd_catotal sd_`var' if count_catotal>=4 & count_`var'>=4, sig
}




erase temp_typimpo.dta
erase temp_catotal.dta
erase temp_caexpor.dta
erase temp_cafranc.dta
erase temp_effec.dta
erase temp_vabcf.dta
erase temp.dta
erase temp_all.dta
erase brn95-08.dta
erase rsi95-08.dta
