

/*
	Program: estimate_shocks_oligo.do
	Date: May 2018
	Aim: estimate individual shocks in the context of non-constant markups  

*/


cd $datapath 

use dta_reg , clear 
keep if group_connexe==1
keep year iso2 buyer siren  gs export export0 main_cpa gbm group_connex
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)
g const=1

egen tot=sum(export0), by(siren year) 
g mkt_s=export0/tot 
drop tot 
xtile power_s=mkt_s , n(4) 
egen tot=sum(export0), by(buyer iso2 year) 
g mkt_b=export0/tot 
xtile power_b=mkt_b , n(4) 
drop tot 
egen tot=sum(export0), by(year) 
g mkt=export0/tot 
xtile power=mkt , n(4) 
drop tot 

egen mkt_med=median(mkt_b) , by(siren year) 
egen mktb_med=median(mkt_b) , by(buyer iso2 year) 

gen large=mkt_b>mkt_med
egen max_wb=max(mkt_b), by(buyer iso2 year) 

g w_ref=mkt_b==max_wb

egen sbc=group(siren buyer iso2) 
g test_rsb=.
g test_fes=. 
g test_feb=.
quietly sum year
local min=r(min)
local max=r(max)
forvalues year=`min'/`max'{
	reghdfe gs if  year==`year' , absorb(fes=s feb=b)  tolerance(1e-6) resid
	predict rsb, res				
	replace test_rsb= rsb if   year==`year'
	replace test_fes= fes if   year==`year'
	replace test_feb= feb if   year==`year'
	drop rsb fes feb
}
		
*** genreate the LHS variable 

$lhs 
egen sect=group(main_cpa year) 
egen cty=group(iso2 year) 
	
egen macro=group(iso2 main_cpa)
g rsb_hdfe_=.
g rsb_=.
g fes_hdfe_=.
g fes_=.
g fesl_=.

g feb_=. 
g feb_hdfe_=.

g feb_size=.
g fes_size=.
g rsb_size=.
 
g rsb_hdfe_size=.
g feb_hdfe_size=.
g fes_hdfe_size=.

save base_temp$lambda, replace 

use base_temp$lambda, clear 
g coef_hs=0 

gen highshare=mkt_b>mkt_med

egen _a=max(highshare), by(siren year) 
egen _i=min(highshare), by(siren year) 
g _=_a==_i 

quietly sum year
local min=r(min)
local max=r(max)


forvalues year=`min'/`max'{
reghdfe lhs if year==`year', absorb(fes=s feb=b)  tolerance(1e-6)  
	replace fes_= fes if year==`year'
	replace feb_= feb if year==`year'
	drop fes feb 
}	

g inter=highshare*fes_
g lhs2= lhs - fes_ - feb_ 

reg lhs2 fes_ 
reg lhs2 inter 
replace coef_hs= _b[inter]*highshare
drop fes_ feb_ 

save temp, replace 

use temp, clear 
g fes=. 
g feb=. 
g fesh=.
g s_h=. 

quietly sum year
local min=r(min)
local max=r(max)
local i = 1
local j =1 
while `i'>0.0001 {

replace s_h=s*(coef_hs) 

    forvalues year=`min'/`max'{
    reghdfe lhs if year==`year', absorb(fes_=s fes_sh=s_h  feb_=b)  tolerance(1e-6)     resid
	replace fes= fes_ if year==`year'
	replace fesh= fes + fes_sh if year==`year'
	replace feb= feb_ if year==`year'
	predict rsb, res
	replace rsb_= rsb if year==`year'
	drop fes_ feb_ fes_sh rsb
	}

replace inter=highshare*fes
replace lhs2= lhs - fes - feb  
reg lhs2 inter
replace coef_hs=_b[inter]*highshare
sum coef_hs 
replace s_h=s*(coef_hs) 

g fes1=.
g feb1=.
g fesh1=.
 forvalues year=`min'/`max'{
    reghdfe lhs if year==`year', absorb(fes1_=s fes_sh1=s_h feb1_=b)  tolerance(1e-6) 
	replace fes1= fes1_  if year==`year'
	replace fesh1= fes1_ + fes_sh1 if year==`year'
	replace feb1= feb1_ if year==`year'
	drop fes1_ feb1_ fes_sh1
	}

g tests=(fesh1 - fesh)^2
g testb=(feb1 - feb)^2

replace feb = feb1 
replace fes=fes1 
drop fes1 feb1 

egen s_ =mean(tests) 
egen b_=mean(testb) 
sum s_ b_ 

local i = s_ + b_ 
dis `j' 
local j = `j'+1 
drop s_ b_ tests testb
} 

g feb_=feb 
g fes_= fes + fesh1 

g interaction=coef_hs + 1 
egen macros=group(macro)
g inter_macro=macros*coef_hs
	
quietly sum year
local min=r(min)
local max=r(max)
	foreach i in _ {
forvalues year=`min'/`max'{
	reghdfe fes   if year==`year', a(a=macros)  resid
	predict rsb, res
	replace fes_hdfe`i'= rsb if year==`year'
	drop rsb a  
	areg feb`i'    if year==`year', a(macros)  
	predict rsb, res
	replace feb_hdfe`i'= rsb if year==`year'
	drop rsb
	reghdfe rsb`i'   if year==`year', a(a=macros)  resid
	predict rsb, res
	replace rsb_hdfe`i'= rsb if year==`year'
	drop rsb a 
	}	
}	

g fes_hdfe_inter=fes_hdfe_*(1+coef_hs) 

foreach i in rsb_hdfe feb_hdfe fes_hdfe {
g `i' = `i'_
}


foreach i in rsb feb fes {
drop `i'_  `i'_hdfe_ 
drop `i'_size `i'_hdfe_size
}

keep if fes_hdfe!=. & rsb_hdfe!=. & feb_hdfe!=.
keep iso2 siren buyer year export export0 f* rsb*  gs lhs main_cpa  gb gbm  highshare
 
g gsm=(lhs - fes_hdfe_inter - feb_hdfe - rsb_hdfe)/(1+$lambda) 
drop fes_hdfe 
rename fes_hdfe_inter fes_hdfe // this is the seller component 

g test= gs +gbm*$lambda - (1+$lambda)*gsm - fes_hdfe - feb_hdfe - rsb_hdfe 
sum test 
drop test

replace feb_hdfe = feb_hdfe/(1+$lambda)
g pricei_b=(gsm + feb_hdfe - gbm)*$lambda 

g test = gs - fes_hdfe - feb_hdfe - rsb_hdfe - gsm - pricei_b 
sum test 
drop test 
egen nbb=count(gs), by(siren year) 
egen nbs=count(gs), by(buyer iso2 year)
count 
count if nbb>1 & nbs>1 
 
*corr gs gsm fes_hdfe feb_hdfe rsb_hdfe pricei_b
save fixed_effects_hdfe_markup, replace



