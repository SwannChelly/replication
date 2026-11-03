
/* 

Name : graph_volatility_size.do 

Aim : Compute the sources of volatility by firm size

*/ 

cd $datapath

use fixed_effects_hdfe$lhs_lab, clear 
g test="$lhs_lab"
tab test 
drop test 

g div = feb_hdfe + rsb_hdfe + pricei_b + gsm
egen tot=sum(export0), by(siren year ) 
g w=export0/tot 
foreach i in gs fes_hdfe feb_hdfe pricei_b rsb_hdfe div {
replace `i'=w*`i'
}
g herf=w*w
collapse (sum) export0 pricei_b w gs* fe* rsb* div herf , by(siren year) 
bys siren: g first=_n==1
g weight=first*export0 

foreach i in  gs fes_hdfe div feb_hdfe rsb_hdfe  {
replace `i'=`i'*`i' // compute the variance (instead of std. dev.) 
}

collapse (count) count=weight (max) weight (sd) pricei_b w gs* fe* rsb* div herf , by(siren) 
keep if count>3
g contri_div= div / gs 

xtile bin_w=weight , n(10) 
collapse (count) nb=weight (median) gs fes_hdfe feb_hdfe rsb_hdfe div contri_div, by(bin_w) 
gr bar gs fes_hdfe div , over(bin)  legend(lab(1 "Volatility seller") lab(2 "Seller-driven vol.") lab(3 "Buyer-driven vol.")) b1title("Decile of size") blabel(none) scheme(s1mono)
graph export $outputpath/graph_small_volsize$lab.eps, replace

