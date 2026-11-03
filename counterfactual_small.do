
/* 
Name : counterfactual_small.do 
Aim : Computes counterfactual volatility when muting shocks
*/ 


cd $datapath 

// Build the data

use fixed_effects_hdfe$lhs_lab, clear 
egen nbseller=count(export), by(buyer iso2 year)
egen nbbuyer=count(export), by(siren year)
$restriction_connect       // restrictions on the number of buyer per sellers (sensitivity Table A.5)
drop if gs==.
egen tot=sum(export0), by(siren year ) 
g w=export0/tot 
drop tot 
sort siren year 
egen tot=sum(export0), by(buyer year iso2) 
g i_sb_=export0/tot*rsb_hdfe 
g i_s_=export0/tot*fes_hdfe 
egen i_sb=sum(i_sb_), by(buyer iso2 year) 
egen i_s=sum(i_s_), by(buyer iso2 year) 
g i=i_sb + i_s 
 
// build counterfactual volatilities
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

global mute mute_macro mute_fes mute_fes_b mute_feb mute_feb_b mute_rsb mute_rsb_b mute_div mute_div_b mute_divm mute_divm_b

g div = feb_hdfe + rsb_hdfe + pricei_b + gsm
g divm=rsb_hdfe + feb_hdfe +  pricei_b
g micro = div + fes_hdfe
foreach i in gs gsm micro fes_hdfe feb_hdfe pricei_b rsb_hdfe div $mute divm {
replace `i'=w*`i'
}
g herf=w*w
g testnb=1

collapse (count) nb_buyer=gs (sum) $mute testnb export export0  micro pricei_b w gs* fe* rsb* div herf divm  (min) nbseller nbbuyer, by(siren year) 

g dlexport=log(export/export0)

g test=gs - divm - fes_hdfe - gsm
sum test, d 
drop test
cap g rsb= rsb_hdfe 
 
foreach i in micro fes rsb feb pricei_b gsm gs div divm{
	egen mean`i'=mean(`i'), by(siren )
}
g cov_micro=(micro - meanmicro)*(gs - meangs)
g cov_fes_gs=(fes - meanfes)*(gs - meangs)
g cov_gs_gs=(gs - meangs)*(gs - meangs)

g cov_divm_gs=(divm - meandivm)*(gs - meangs)

g cov_macro_gs=(gsm - meangsm)*(gs - meangs)

g cov_nodiv=(fes_hdfe - meanfes)*(micro - meanmicro)
g cov_div=(div - meandiv)*(micro - meanmicro)

g cov_feb=(div - meandiv)*(feb_hdfe - meanfeb)
g cov_rsb=(div - meandiv)*(rsb_hdfe - meanrsb)
g cov_pri=(div - meandiv)*(pricei_b - meanpricei_b)

g cov_feb_micro=(micro - meanmicro)*(feb_hdfe - meanfeb)
g cov_rsb_micro=(micro - meanmicro)*(rsb_hdfe - meanrsb)
g cov_pri_micro=(micro - meanmicro)*(pricei_b - meanpricei_b)

g cov_pri_fes=(fes - meanfes)*(pricei_b - meanpricei_b)

sort siren  year
by siren: g herf0=herf if _n==1
by siren: g nb_buyer0=nb_buyer if _n==1
by siren: g export00=export0 if _n==1

egen sum=sum(export), by( year) 
g weight=export/sum

collapse (mean)  export00 export0 herf0 nb_buyer0 herf nb_buyer weight nbseller nbbuyer (count) count=gs (sd) $mute gs* fe* rsb* pricei_b micro div (sum) cov* (min) miny = year, by(siren  ) // compute the volatility (sd) gs* fe* rsb* div 
keep if count>3 // volatility computed from firms present at least 4 years

foreach i in  gs fes_hdfe div feb_hdfe gsm rsb_hdfe gsm micro pricei_b $mute {
	replace `i'=`i'*`i' // compute the variance (instead of std. dev.) 
}

foreach i in feb rsb pri micro macro_gs divm_gs gs_gs fes_gs div nodiv feb_micro rsb_micro pri_micro pri_fes {
	replace cov_`i'=cov_`i'/(count -1)
}

label var mute_feb "Mute buyer shocks"
label var mute_fes "Mute seller shocks"
label var mute_fes_b "Mute seller shocks (inc. indirect effect)"
label var mute_rsb "Mute match shocks"
label var mute_rsb_b "Mute match shocks (inc. indirect effect)"
label var mute_macro "Mute macro shocks"
label var mute_div_b "Mute div micro and macro shocks"
label var mute_divm_b "Mute div. micro shocks"

putexcel set "$outputpath/table_small_mute$lab.xls", sheet("seller all destinations") modify
putexcel C1=("Mean") D1=("Median")
local row = 2 
foreach x in gs mute_macro mute_fes_b mute_divm_b mute_feb mute_rsb_b {
	local varlabel : var label `x' 
	sum `x' , d 
	putexcel A`row'=("`x'") B`row'=("` varlabel'") C`row'=(r(mean)) D`row'=(r(p50)) 
	local row = `row'+1 	
} 

egen decile_diver=xtile(herf), n(10) 
collapse (mean) div mute_fes  herf , by(decile_diver) 

keep div decile_diver mute_fes
sort decile 
gr bar div, over(decile_diver) b1title("Decile of sales concentration") ytitle("Buyer-driven volatility")  blabel(none) scheme(s1mono)  
*graph export $outputpath/bar_voldiver_herf_$lhs_lab.pdf, replace // Figure 2
