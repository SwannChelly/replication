
/*
	shocks_estimate.do
	
	Date: April 2017
	
	Program: estimate individual sghocks using three different methods  

	Input: dta_reg saved in $datapath, estimated in shocks_prepdata.do
		
	Output: fixed_effects_$method.dta files 
	$method refers to te method used to estimate the shocks 
	
*/


cd $datapath 


// Estimate seller-year and buyer-year fixed effects 
// The method imposes that FE_bt + FE_st is orthogonal to espilon_sbt
use dta_reg , clear 
keep if group_connexe==1
keep year iso2 buyer siren  gs export export0 main_cpa gbm group_connex //month 
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)
g const=1

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
g rsb_hdfe=.
g rsb_=.
g fes_hdfe=.
g fes_=.
g feb_=. 
g feb_hdfe=. 

save base_temp$lambda, replace 

use base_temp$lambda, clear 

quietly sum year
local min=r(min)
local max=r(max)

forvalues year=`min'/`max'{
	reghdfe lhs if year==`year', absorb(fes=s feb=b)  tolerance(1e-6) resid
	predict rsb, res
	replace rsb_= rsb if year==`year'
	replace fes_= fes if year==`year'
	replace feb_= feb if year==`year'
	drop fes feb rsb 
}	


*we purge individual effects from macro shocks in a second step to have them orthogonal  
forvalues year=`min'/`max'{
	areg fes_ if year==`year', a(macro)
	predict rsb, res
	replace fes_hdfe= rsb if year==`year'
	drop rsb
	areg feb_ if year==`year', a(macro)
	predict rsb, res
	replace feb_hdfe= rsb if year==`year'
	drop rsb
	areg rsb_ if year==`year', a(macro)
	predict rsb, res
	replace rsb_hdfe= rsb if year==`year'
	drop rsb
		
}	


keep iso2 siren buyer year export export0 f* rsb*  gs lhs main_cpa  gb gbm   

keep if fes_hdfe!=. & rsb_hdfe!=. & feb_hdfe!=.
g gsm=(lhs - fes_hdfe - feb_hdfe - rsb_hdfe)/(1+$lambda) 

replace feb_hdfe = feb_hdfe/(1+$lambda)

g pricei_b=(gsm + feb_hdfe - gbm)*$lambda 

g test = gs - fes_hdfe - feb_hdfe - rsb_hdfe - gsm - pricei_b 
sum test 
drop test 
egen nbb=count(gs), by(siren year) 
egen nbs=count(gs), by(buyer iso2 year)

drop fes_ feb_ rsb_  
save fixed_effects_hdfe$lhs_lab, replace

