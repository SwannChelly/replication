
/*
	grid_search.do
	
	Date: November 2015
	
	Program: estimate individual shocks using reghdfe with different LHS variable
	         select the lambda coefficient which is the most consistent with the theoretical OG condition

	Input: dta_reg saved in $datapath, produced in shocks_prepdata.do
		
	Output: $resultpath/gridsearch_commonfe
	
*/


cd $datapath 
use dta_reg , clear 
keep year iso2 buyer siren  gs export export0 main_cpa  gbm group_connex
keep if group_connex==1
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)

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


save temp_cf, replace

clear
set obs 1
g lambda=0
drop if lambda==0
save $resultpath/gridsearch_commonfe, replace
	
local dcorr=0.5
local lambda=0 // this should be at 0
while `dcorr'>0.001{
	di "`lambda'"
	use temp_cf, clear
	gen lhs=gs + gbm*`lambda'
	egen macro=group(iso2 main_cpa)
	g fes_hdfe=.
	g fes_purged=.
	g feb_purged=. 
	g feb_hdfe=. 
	quietly sum year
	local min=r(min)
	local max=r(max)
		forvalues year=`min'/`max'{
		reghdfe lhs if year==`year', absorb(fes=s feb=b)  tolerance(1e-6)
		replace fes_hdfe= fes if year==`year'
		replace feb_hdfe= feb if year==`year'
		drop fes feb
		}	
 
		forvalues year=`min'/`max'{
		areg fes_hdfe if year==`year', a(macro)
		predict rsb, res
		replace fes_purged= rsb if year==`year'
		drop rsb
		areg feb_hdfe if year==`year', a(macro)
		predict rsb, res
		replace feb_purged= rsb if year==`year'
		drop rsb
		}	
	
	corr fes_purged feb_purged
	local corr=r(rho)
	di `corr'
	local dcorr=abs(`corr'-$target)
	di `dcorr'
	clear
	set obs 1
	g lambda=`lambda'
	g corr_fesfeb=`corr'
	append using $resultpath/gridsearch_commonfe
	save $resultpath/gridsearch_commonfe, replace
	local lambda=`lambda'+$pas
}
erase temp_cf.dta


