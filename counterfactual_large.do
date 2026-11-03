
/* 

Name : counterfactual_large.do 
Aim : Counterfactual volatility of aggregate trade flows when muting shocks

*/ 


cd $datapath 

// Volatility in the large, ALL DESTINATIONS  

use fixed_effects_hdfe$lhs_lab, clear 

drop *_
egen  med_micro_fes=sd(fes_hdfe)  
egen  med_micro_feb=sd(feb_hdfe) 
egen  med_micro_rsb=sd(rsb_hdfe) 


g div = feb_hdfe + rsb_hdfe + pricei_b 
g micro = div + fes_hdfe
egen tot=sum(export0), by(year  ) 
g w=export0/tot 

* build counterfactual volatilities

drop tot 
sort siren year 

egen tot=sum(export0), by(buyer year iso2) 
g i_sb_=export0/tot*rsb_hdfe 
g i_s_=export0/tot*fes_hdfe 
egen i_sb=sum(i_sb_), by(buyer iso2 year) 
egen i_s=sum(i_s_), by(buyer iso2 year) 
g i=i_sb + i_s 


g pond_s=i_s/i 
g pond_sb=i_sb/i 
replace pond_s=-2 if pond_s<-2 
replace pond_s=3 if pond_s>3 
replace pond_sb=-2 if pond_sb<-2 
replace pond_sb=3 if pond_sb>3 

g mute_macro = gs - gsm 
g mute_fes= gs - fes_hdfe 
g mute_fes_b= gs - fes_hdfe - pricei_b*(pond_s)
g mute_feb= gs - feb_hdfe 
g mute_feb_b= gs - feb_hdfe 
g mute_rsb= gs - rsb_hdfe 
g mute_rsb_b= gs - rsb_hdfe - pricei_b*(pond_sb)
g mute_div_b= gs - rsb_hdfe - feb_hdfe - gsm - pricei_b*(pond_sb)
g mute_div= gs - rsb_hdfe - feb_hdfe - gsm
g mute_divm_b= gs - rsb_hdfe - feb_hdfe  - pricei_b*(pond_sb)
g mute_divm= gs - rsb_hdfe - feb_hdfe 


global mute mute_macro mute_fes mute_fes_b mute_feb mute_feb_b mute_rsb mute_rsb_b mute_divm mute_divm_b mute_div mute_div_b

foreach i in gs gsm micro fes_hdfe feb_hdfe pricei_b rsb_hdfe div $mute{
	replace `i'=w*`i'
}

egen nb=count(export0), by(year iso2 ) 

foreach i in fes_hdfe feb_hdfe rsb_hdfe pricei_b{
	g `i'_nogran=`i'/nb 
}
g all_nogran= gsm + fes_hdfe_nogran+  feb_hdfe_nogran+ rsb_hdfe_nogran+  pricei_b

collapse (count) nb_buyer=gs (sum) $mute all_nogran export export0 micro pricei_b w gs* fe* rsb* div  (mean) med*, by(year ) 

g dlexport=log(export/export0)

foreach i in micro fes_hdfe rsb_hdfe feb_hdfe pricei_b gsm gs div {
	egen mean`i'=mean(`i') 
}
g cov_micro=(micro - meanmicro)*(gs - meangs)
g cov_macro=(gsm - meangsm)*(gs - meangs)

g cov_nodiv=(fes_hdfe - meanfes)*(gs - meangs)
g cov_div=(div - meandiv)*(micro - meanmicro)

g cov_feb=(div - meandiv)*(feb_hdfe - meanfeb)
g cov_rsb=(div - meandiv)*(rsb_hdfe - meanrsb)
g cov_pri=(div - meandiv)*(pricei_b - meanpricei_b)

g cov_feb_micro=(gs - meangs)*(feb_hdfe - meanfeb)
g cov_rsb_micro=(gs - meangs)*(rsb_hdfe - meanrsb)
g cov_pri_micro=(gs - meangs)*(pricei_b - meanpricei_b)


collapse (count) count=gs (sd) all_nogran gs* fe* rsb* pricei_b micro div $mute (sum)  cov* (min) miny = year (median) med*  // compute the volatility (sd) gs* fe* rsb* div 
keep if count>3
foreach i in  gs fes_hdfe div feb_hdfe  rsb_hdfe gsm micro pricei_b $mute all_nogran {
	replace `i'=`i'*`i' // compute the variance (instead of std. dev.) 
}


putexcel set "$outputpath/table_counterfactual_large.xls", sheet("volatility") replace 
putexcel E1=("Median (multilateral)")
putexcel F1=("%change (multilateral)")

rename gsm mute_micro 
local row = 2 
foreach x in gs mute_macro mute_micro mute_fes_b mute_feb mute_rsb_b all_nogran{
	local varlabel : var label `x' 
	sum `x', d 
	putexcel A`row'=("`x'") B`row'=("` varlabel'") E`row'=(r(p50)) 
	local row = `row'+1 
} 

local row = 3
foreach x in mute_macro mute_micro mute_fes_b mute_feb mute_rsb_b all_nogran{
putexcel F`row'=formula(=E`row'/E2-1) 
local row = `row'+1 
} 

// Volatility in the large, by destination 

use fixed_effects_hdfe$lhs_lab, clear 
g test="$lhs_lab"

drop *_
egen  med_micro_fes=sd(fes_hdfe)  
egen  med_micro_feb=sd(feb_hdfe) 
egen  med_micro_rsb=sd(rsb_hdfe) 


g div = feb_hdfe + rsb_hdfe + pricei_b 
g micro = div + fes_hdfe
egen tot=sum(export0), by(year  iso2) 
g w=export0/tot 

* build counterfactual volatilities

drop tot 
sort siren year 

egen tot=sum(export0), by(buyer year iso2) 
g i_sb_=export0/tot*rsb_hdfe 
g i_s_=export0/tot*fes_hdfe 
egen i_sb=sum(i_sb_), by(buyer iso2 year) 
egen i_s=sum(i_s_), by(buyer iso2 year) 
g i=i_sb + i_s 


g pond_s=i_s/i 
g pond_sb=i_sb/i 
replace pond_s=-2 if pond_s<-2 
replace pond_s=3 if pond_s>3 
replace pond_sb=-2 if pond_sb<-2 
replace pond_sb=3 if pond_sb>3 

g mute_macro = gs - gsm 
g mute_fes= gs - fes_hdfe 
g mute_fes_b= gs - fes_hdfe - pricei_b*(pond_s)
g mute_feb= gs - feb_hdfe 
g mute_feb_b= gs - feb_hdfe 
g mute_rsb= gs - rsb_hdfe 
g mute_rsb_b= gs - rsb_hdfe - pricei_b*(pond_sb)
g mute_div_b= gs - rsb_hdfe - feb_hdfe - gsm - pricei_b*(pond_sb)
g mute_div= gs - rsb_hdfe - feb_hdfe - gsm
g mute_divm_b= gs - rsb_hdfe - feb_hdfe  - pricei_b*(pond_sb)
g mute_divm= gs - rsb_hdfe - feb_hdfe 

g fes_b = fes_hdfe + pricei_b*(pond_s)
g rsb_b = rsb_hdfe + pricei_b*(pond_sb)
global mute mute_macro mute_fes mute_fes_b mute_feb mute_feb_b mute_rsb mute_rsb_b mute_divm mute_divm_b mute_div mute_div_b

foreach i in gs gsm micro fes_hdfe feb_hdfe pricei_b rsb_hdfe div fes_b rsb_b $mute{
replace `i'=w*`i'
}

egen nb=count(export0), by(year iso2 ) 

foreach i in fes_hdfe feb_hdfe rsb_hdfe pricei_b{
g `i'_nogran=`i'/nb 
}
g all_nogran= gsm + fes_hdfe_nogran+  feb_hdfe_nogran+ rsb_hdfe_nogran+  pricei_b

collapse (count) nb_buyer=gs (sum) $mute all_nogran export export0 micro pricei_b w gs* fe* rsb* div  (mean) med*, by(year iso2) 
g dlexport=log(export/export0)
*g test=gs - gsm -micro
*sum test, d 
*drop test

foreach i in micro fes_hdfe rsb_hdfe feb_hdfe pricei_b gsm gs div fes_b rsb_b {
egen mean`i'=mean(`i') 
}
g cov_micro=(micro - meanmicro)*(gs - meangs)
g cov_macro=(gsm - meangsm)*(gs - meangs)
g cov_nodiv=(fes_hdfe - meanfes_hdfe)*(gs - meangs)
g cov_div=(div - meandiv)*(micro - meanmicro)
g cov_feb=(div - meandiv)*(feb_hdfe - meanfeb)
g cov_rsb=(div - meandiv)*(rsb_hdfe - meanrsb_hdfe)
g cov_pri=(div - meandiv)*(pricei_b - meanpricei_b)
g cov_feb_micro=(gs - meangs)*(feb_hdfe - meanfeb)
g cov_rsb_micro=(gs - meangs)*(rsb_hdfe - meanrsb_hdfe)
g cov_pri_micro=(gs - meangs)*(pricei_b - meanpricei_b)
g cov_fes_b=(fes_b - meanfes_b)*(gs - meangs)
g cov_rsb_b=(gs - meangs)*(rsb_b - meanrsb_b)

collapse (count) count=gs (sd) all_nogran gs* fe* rsb* pricei_b micro div $mute (sum)  cov* (min) miny = year (median) med* , by(iso2) // compute the volatility (sd) gs* fe* rsb* div 
keep if count>3

foreach i in  gs fes_hdfe div feb_hdfe  rsb_hdfe gsm micro pricei_b $mute all_nogran {
replace `i'=`i'*`i' // compute the variance (instead of std. dev.) 
}

foreach i in feb rsb nodiv feb_micro rsb_micro pri_micro macro fes_b rsb_b{
replace cov_`i'=cov_`i'/(count -1)
}


g country="Belgium" if iso2=="BE"
replace country="Germany" if iso2=="DE"
replace country="Denmark" if iso2=="DK"
replace country="Spain" if iso2=="ES"
replace country="Finland" if iso2=="FI"
replace country="UK" if iso2=="GB"
replace country="Italy" if iso2=="IT"
replace country="Netherands" if iso2=="NL"
replace country="Portugal" if iso2=="PT"
replace country="Sweden" if iso2=="SE"
replace country="Ireland" if iso2=="IE"


foreach i in mute_macro gsm  mute_fes_b mute_feb mute_rsb_b all_nogran{
g change_`i'=`i'/gs -1 
}

// Regressions featured in Table A.4
global name $outputpath/table_heterogeneityvol_large$lab.xls 
reg cov_macro gs 
	outreg2 gs  using  "$name", label e(all) nocons bdec(2) symbol(***, **,*) replace
reg cov_fes_b gs 
	outreg2 gs  using  "$name", label e(all) nocons bdec(2) symbol(***, **,*) append
reg cov_feb gs 
	outreg2 gs  using  "$name", label e(all) nocons bdec(2) symbol(***, **,*) append 
reg cov_rsb_b gs  
	outreg2 gs  using  "$name", label e(all) nocons bdec(2) symbol(***, **,*) append


// Results featured in Table A.3
collapse (median) gs mute_macro gsm  mute_fes_b mute_feb mute_rsb_b all_nogran change_*
 
putexcel C1=("Median (bilateral)")
putexcel D1=("%change (bilateral)")

rename gsm mute_micro 
local row = 2 
foreach x in gs mute_macro mute_micro mute_fes_b mute_feb mute_rsb_b all_nogran{
sum `x', d 
putexcel C`row'=(r(p50)) 
local row = `row'+1 
} 

local row = 3
foreach x in mute_macro mute_micro mute_fes_b mute_feb mute_rsb_b all_nogran{
sum `x', d
putexcel D`row'=(r(p50))
local row = `row'+1 
} 



