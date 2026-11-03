
/*
	shocks_estimate.do
	
	Date: April 2017
	
	Program: estimate individual sghocks using three different methods  

	Input: dta_reg saved in $datapath, estimated in shocks_prepdata.do
		
	Output: fixed_effects_$method.dta files 
	$method refers to te method used to estimate the shocks 
	
*/


cd $datapath 

// Method #1: HDFE 
// Estimate seller-year and buyer-year fixed effects 
// The method imposes that FE_bt + FE_st is orthogonal to espilon_sbt
use dta_reg , clear 
keep if group_connexe==1
keep year iso2 buyer siren  gs export export0 main_cpa gbm group_connex //month 
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)
g const=1
//qui tab month , g(month_) 
//gen firsty=min(year), by(siren buyer iso2)
//tab month if firsty==year
//reg gs month_* if firsty==year 
 

egen sbc=group(siren buyer iso2) 
g test_rsb=.
g test_fes=. 
g test_feb=.
quietly sum year
local min=r(min)
local max=r(max)
forvalues year=`min'/`max'{
	reghdfe gs if  year==`year' , absorb(fes=s feb=b)  tolerance(1e-6)
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
*egen lhsm_=mean(lhs) if test_rsb!=. , by(iso2 main_cpa year) // main cpa 
*egen lhsm=mean(lhsm_), by(iso2 main_cpa year) // main_cpa 
*g lhs_=lhs - lhsm


quietly sum year
local min=r(min)
local max=r(max)
/*forvalues year=`min'/`max'{
	reghdfe lhs if year==`year', absorb(fes=s feb=b a=macro)  tolerance(1e-6)
	predict rsb, res
	replace rsb_hdfe= rsb if year==`year'
	replace fes_hdfe= fes if year==`year'
	replace feb_hdfe= feb if year==`year'
	drop fes feb rsb a
}	
*/

forvalues year=`min'/`max'{
	reghdfe lhs if year==`year', absorb(fes=s feb=b)  tolerance(1e-6)
	predict rsb, res
	replace rsb_= rsb if year==`year'
	replace fes_= fes if year==`year'
	replace feb_= feb if year==`year'
	drop fes feb rsb 
}	


	* NEW: we purge individual effects from macro shocks in a second step to have them orthogonal  
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
*drop gsm 
*That was wrong: g gsm = (gs +gbm*$lambda - fes_hdfe - feb_hdfe - rsb_hdfe)/(1+$lambda) // indeed g_sbt + lambda g_bt = (lambda+1) fe_Ct + f_st + (lambda+1) \tilda{f}_bt v_sbt  
g gsm=(lhs - fes_hdfe - feb_hdfe - rsb_hdfe)/(1+$lambda) 

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
 
corr gs gsm fes_hdfe feb_hdfe rsb_hdfe pricei_b 

g test=fes_hdfe + feb_hdfe + rsb_hdfe 
corr gs test 
drop test 

save fixed_effects_hdfe$lhs_lab, replace

/*
 

// Method #2: 2step_seller 
// Estimate seller-year and buyer-year fixed effects 
// The method imposes that FE_st is orthogonal to FE_bt + espilon_sbt
use dta_reg , clear 
keep if sample==1
keep year iso2 buyer siren gs_ gs gsm export export0 main_cpa sample_restricted gb gbm
egen s=group(siren year) 
egen b=group(buyer year) 
g const=1

$lhs 

g rsb_hdfe=.
g fes_hdfe=.
g feb_hdfe=. 

foreach i in $list{
xtreg lhs const if iso2=="`i'", fe i(s)
predict res, e
predict fes, u
xtreg res const if iso2=="`i'", fe i(b)
predict rsb, e 
predict feb, u
replace rsb_hdfe= rsb if iso2=="`i'"
replace fes_hdfe= fes if iso2=="`i'" 
replace feb_hdfe= feb if iso2=="`i'" 
drop rsb fes feb res
}

/*
xtreg gs_ const, fe i(s)
predict res, e
predict fes, u
xtreg res const, fe i(b)
predict rsb, e 
predict feb, u
replace rsb_hdfe= rsb  
replace fes_hdfe= fes 
replace feb_hdfe= feb  
drop rsb fes feb res
*/
keep iso2 siren buyer year export export0 f* rsb* gs_ gs gsm main_cpa sample_restricted lhs gb gbm
save fixed_effects_2stepseller$lhs_lab, replace 

// Method #3: 2step_buyer 
// Estimate seller-year and buyer-year fixed effects 
// The method imposes that FE_bt is orthogonal to FE_st + espilon_sbt
use dta_reg , clear 
keep if sample==1
keep year iso2 buyer siren gs_ gs gsm export export0 main_cpa sample_restricted gb gbm
egen s=group(siren year) 
egen b=group(buyer year) 
g const=1

$lhs 

g rsb_hdfe=.
g fes_hdfe=.
g feb_hdfe=. 

foreach i in $list{
xtreg lhs const if iso2=="`i'", fe i(b)
predict res, e
predict feb, u
xtreg res const if iso2=="`i'", fe i(s)
predict rsb, e 
predict fes, u
replace rsb_hdfe= rsb if iso2=="`i'"
replace fes_hdfe= fes if iso2=="`i'" 
replace feb_hdfe= feb if iso2=="`i'" 
drop rsb fes feb res
}

keep iso2 siren buyer year export export0 f* rsb* gs_ gs gsm main_cpa  sample_restricted lhs gb gbm
save fixed_effects_2stepbuyer$lhs_lab, replace 

/*
* Integrate back observations which shocks are not used for identification
foreach method in hdfe 2stepseller 2stepbuyer{
	use dta_reg, clear
	keep iso2 siren buyer year main_cpa gs export 
	sort iso2 siren buyer year main_cpa
	save temp, replace
	use fixed_effects_`method', clear
	sort iso2 siren buyer year main_cpa
	merge iso2 siren buyer year main_cpa using temp
	bys iso2 main_cpa year: egen mean=mean(gsm)
	replace gsm=mean if _merge==2
	replace gs_=gs - gsm  if _merge==2
	drop mean
	* FE seller for observations related to firms with several buyers (but buyer has one seller)
	* FE buyer and residual cannot be recover=> allocate the residual between both components based on the allocation for the median firm in the identified sample
	bys iso2 year siren: egen mean=mean(fes_hdfe)
	g fes_post=0
	replace fes_post=1 if _merge==2 & mean!=.
	replace fes_hdfe=mean if _merge==2
	drop mean
	gen cont=rsb_hdfe/(rsb_hdfe+feb_hdfe)
	sum cont, d
	local median=r(p50)
	replace rsb_hdfe=`median'*(gs-gsm-fes_hdfe) if fes_post==1
	replace feb_hdfe=(1-`median')*(gs-gsm-fes_hdfe) if fes_post==1
	drop cont
	* FE buyer for observations related to buyers with several sellers (but seller has just one buyer)
	* FE seller and residual cannot be recover=> allocate the residual between both components based on the allocation for the median firm in the identified sample
	bys iso2 year buyer: egen mean=mean(feb_hdfe)
	g feb_post=0
	replace feb_post=1 if _merge==2 & mean!=.
	replace feb_hdfe=mean if _merge==2
	drop mean
	gen cont=rsb_hdfe/(rsb_hdfe+fes_hdfe)
	sum cont, d
	local median=r(p50)
	replace rsb_hdfe=`median'*(gs-gsm-feb_hdfe) if feb_post==1
	replace fes_hdfe=(1-`median')*(gs-gsm-feb_hdfe) if feb_post==1
	drop cont
	drop if _merge==2 & feb_post!=1 & fes_post!=1
	drop _merge
	save fixed_effects_`method', replace
}
*/
cap erase temp.dta


egen tot=sum(export0), by(siren year) 
g mkt_s=export0/tot 
drop tot 
xtile power_s=mkt_s , n(4) 
egen tot=sum(export0), by(buyer year) 
g mkt_b=export0/tot 
xtile power_b=mkt_b , n(4) 
drop tot 

g fes_power_b = fes_hdfe*(power_b-1) 
g fes_power_s = fes_hdfe*(power_s-1)
g fes_mkt_b = fes_hdfe*(mkt_b) 
g fes_mkt_s = fes_hdfe*(mkt_s)

qui tab power_b, g(pwb_) 
foreach i in 1 2 3 4 {
g fes_pwb_`i'=fes_hdfe*pwb_`i'
}
   areg rsb_hdfe fes_hdfe , a(siren)
   areg rsb_hdfe fes_hdfe fes_pwb_4 pwb_4  , a(siren)
   areg rsb_hdfe fes_hdfe fes_mkt_b mkt_b , a(siren)
   
   egen test=sd(mkt_b), by(siren year) 

