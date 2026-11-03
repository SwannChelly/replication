
/*
	shocks_simulate.do
	
	Date: August 2015
	
	Program: simulate a fake sample of orthogonal shocks and run the HDFE estimation 
	to quantify the bias induced by the sparsity of the network

	Input: dta_reg saved in $datapath, output of shocks_prepdata.do
		
	Output: fixed_effects_simulated_YY.dta files 
	YY is the number of the iterration
	
*/

cd $datapath 

* First estimate once to get calibrated values for the std dev of shocks
use dta_reg , clear 
keep if group_connexe==1
keep year iso2 buyer siren  gs export export0 main_cpa sample_final gb gbm
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)
g const=1

g rsb_hdfe=.
g fes_hdfe=.
g feb_hdfe=. 
quietly sum year
local min=r(min)
local max=r(max)
forvalues year=`min'/`max'{
	qui reghdfe gs if  year==`year' , absorb(fes=s feb=b)  tolerance(1e-6)
	predict rsb, res
	replace rsb_hdfe= rsb if   year==`year'
	replace fes_hdfe= fes if   year==`year'
	replace feb_hdfe= feb if   year==`year'
	drop rsb fes feb
}
save fixed_effects_hdfe, replace

* Calibrate stdev
use fixed_effects_hdfe, replace
sort iso2
collapse (sd) sd_sb=rsb_hdfe sd_b=feb_hdfe, by(iso2 )
sort iso2
save temp_cf, replace
use fixed_effects_hdfe, replace
collapse (sd) sd_s=fes_hdfe 
quietly sum sd_s
local sd_s=r(mean)

use dta_reg , clear 
keep if group_connexe==1
keep year iso2 buyer siren  gs export export0 main_cpa sample_final gb gbm
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)
g const=1

sort iso2
merge m:1 iso2 using temp_cf
drop _merge
save temp_simulate, replace

* Initiate result tables
clear
set obs 1
g sim=1
drop if sim==1
save cov_matrix_shocks_simulate_hdfe_commonfe, replace
clear
set obs 1
g sim=1
drop if sim==1
save cov_matrix_shocks_simulate_hdfe_restricted_commonfe, replace


* Simulation	
forvalues Y=1(1)$numsim{
	di "Simulation number `Y'"
	use temp_simulate , clear 

	// Simulate shocks: epsilon_st epsilon_bt epsilon_sbt
	g epsilon_st=.
	g epsilon_bt=.
	g epsilon_sbt=.
	
	local seed=339487+225*`Y'
	set seed `seed'
	bys s: g u=rnormal(0,`sd_s') if _n==1
	bys s: egen v=mean(u)	
	replace epsilon_st = v
	drop u v
	
	local j=1	 
	foreach i in $list {
		quietly sum sd_b if iso2=="`i'"
		local sd_b=r(mean)
		quietly sum sd_sb if iso2=="`i'"
		local sd_sb=r(mean)

		local seed=339487+157*`Y'+333*`j'
		set seed `seed'
		bys b iso2: g u=rnormal(0,`sd_b') if iso2=="`i'" & _n==1
		bys b iso2: egen v=mean(u)	
		replace epsilon_bt = v if iso2=="`i'"
		drop u v
		local seed=339487+62*`Y'+333*`j'
		set seed `seed'
		replace epsilon_sbt = rnormal(0,`sd_sb') if iso2=="`i'"
		local j=`j'+1
	}
	g gs_=epsilon_st+epsilon_bt+epsilon_sbt

	save dta_sim, replace

	// Method #1: HDFE 
	// Estimate seller-year and buyer-year fixed effects 
	// The method imposes that FE_bt _ FE_st is orthogonal to espilon_sbt
	use dta_sim, clear
	g rsb_hdfe=.
	g fes_hdfe=.
	g feb_hdfe=. 
	quietly sum year
	local min=r(min)
	local max=r(max)
	forvalues year=`min'/`max'{
		qui reghdfe gs_ if  year==`year', absorb(fes=s feb=b)  tolerance(1e-6)
		predict rsb, res
		replace rsb_hdfe= rsb if   year==`year'
		replace fes_hdfe= fes if   year==`year'
		replace feb_hdfe= feb if   year==`year'
		drop rsb fes feb
	}
	keep iso2 siren buyer year export export0 f* rsb* gs_ main_cpa epsilon* sample_final
	save fixed_effects_hdfe_simulated_`Y', replace 

	
	// Compute correlation between fe_s and fe_b and store result
	// Method #1: HDFE 
	// Restricted sample
	use fixed_effects_hdfe_simulated_`Y', clear
	keep if sample_final==1
	foreach var in rsb fes feb{
		egen mean_`var'=mean(`var'_hdfe)
		g d`var'_sq=(`var'_hdfe-mean_`var')*(`var'_hdfe-mean_`var')
	}
	foreach var in st bt sbt{
		egen mean_epsilon_`var'=mean(epsilon_`var')
		g depsilon_`var'_sq=(epsilon_`var'-mean_epsilon_`var')*(epsilon_`var'-mean_epsilon_`var')
	}
	* covariance between components (estimated and simulated)
	g cov_fesfeb_estimated=(fes_hdfe-mean_fes)*(feb_hdfe-mean_feb)
	g cov_fesfeb_simulated=(epsilon_st-mean_epsilon_st)*(epsilon_bt-mean_epsilon_bt)
	g cov_rsbfeb_estimated=(rsb_hdfe-mean_rsb)*(feb_hdfe-mean_feb)
	g cov_rsbfeb_simulated=(epsilon_sbt-mean_epsilon_sbt)*(epsilon_bt-mean_epsilon_bt)
	g cov_fesrsb_estimated=(fes_hdfe-mean_fes)*(rsb_hdfe-mean_rsb)
	g cov_fesrsb_simulated=(epsilon_st-mean_epsilon_st)*(epsilon_sbt-mean_epsilon_sbt)
	* covariance between estimated and simulated components
	g cov_fes_simest=(fes_hdfe-mean_fes)*(epsilon_st-mean_epsilon_st)
	g cov_feb_simest=(feb_hdfe-mean_feb)*(epsilon_bt-mean_epsilon_bt)
	g cov_rsb_simest=(rsb_hdfe-mean_rsb)*(epsilon_sbt-mean_epsilon_sbt)
	
	collapse (count) N=dfes_sq (sum) cov_* dfes_sq dfeb_sq drsb_sq depsilon*
	foreach var in cov_fesfeb_estimated cov_fesfeb_simulated cov_rsbfeb_estimated cov_rsbfeb_simulated cov_fesrsb_estimated cov_fesrsb_simulated cov_fes_simest cov_feb_simest cov_rsb_simest dfes_sq dfeb_sq drsb_sq depsilon_st_sq depsilon_bt_sq depsilon_sbt_sq{
		replace `var'=`var'/(N-1)
	}
	g corr_fesfeb_estimated=cov_fesfeb_estimated/sqrt(dfes_sq*dfeb_sq)
	g corr_fesfeb_simulated=cov_fesfeb_simulated/sqrt(depsilon_st_sq*depsilon_bt_sq)
	g corr_rsbfeb_estimated=cov_rsbfeb_estimated/sqrt(dfeb_sq*drsb_sq)
	g corr_rsbfeb_simulated=cov_rsbfeb_simulated/sqrt(depsilon_sbt_sq*depsilon_bt_sq)
	g corr_fesrsb_estimated=cov_fesrsb_estimated/sqrt(dfes_sq*drsb_sq)
	g corr_fesrsb_simulated=cov_fesrsb_simulated/sqrt(depsilon_sbt_sq*depsilon_st_sq)
	g corr_fes_simest=cov_fes_simest/sqrt(dfes_sq*depsilon_st_sq)
	g corr_feb_simest=cov_feb_simest/sqrt(dfeb_sq*depsilon_bt_sq)
	g corr_rsb_simest=cov_rsb_simest/sqrt(drsb_sq*depsilon_sbt_sq)
	
    g sim=`Y'
	keep cov* corr* dfes_sq dfeb_sq drsb_sq depsilon_st_sq depsilon_bt_sq depsilon_sbt_sq corr* sim
	append using cov_matrix_shocks_simulate_hdfe_restricted_commonfe
	save cov_matrix_shocks_simulate_hdfe_restricted_commonfe, replace
	
	// Whole sample
	use fixed_effects_hdfe_simulated_`Y', clear
	foreach var in rsb fes feb{
		egen mean_`var'=mean(`var'_hdfe)
		g d`var'_sq=(`var'_hdfe-mean_`var')*(`var'_hdfe-mean_`var')
	}
	foreach var in st bt sbt{
		egen mean_epsilon_`var'=mean(epsilon_`var')
		g depsilon_`var'_sq=(epsilon_`var'-mean_epsilon_`var')*(epsilon_`var'-mean_epsilon_`var')
	}
	* covariance between components (estimated and simulated)
	g cov_fesfeb_estimated=(fes_hdfe-mean_fes)*(feb_hdfe-mean_feb)
	g cov_fesfeb_simulated=(epsilon_st-mean_epsilon_st)*(epsilon_bt-mean_epsilon_bt)
	g cov_rsbfeb_estimated=(rsb_hdfe-mean_rsb)*(feb_hdfe-mean_feb)
	g cov_rsbfeb_simulated=(epsilon_sbt-mean_epsilon_sbt)*(epsilon_bt-mean_epsilon_bt)
	g cov_fesrsb_estimated=(fes_hdfe-mean_fes)*(rsb_hdfe-mean_rsb)
	g cov_fesrsb_simulated=(epsilon_st-mean_epsilon_st)*(epsilon_sbt-mean_epsilon_sbt)
	* covariance between estimated and simulated components
	g cov_fes_simest=(fes_hdfe-mean_fes)*(epsilon_st-mean_epsilon_st)
	g cov_feb_simest=(feb_hdfe-mean_feb)*(epsilon_bt-mean_epsilon_bt)
	g cov_rsb_simest=(rsb_hdfe-mean_rsb)*(epsilon_sbt-mean_epsilon_sbt)
	
	collapse (count) N=dfes_sq (sum) cov_* dfes_sq dfeb_sq drsb_sq depsilon*
	foreach var in cov_fesfeb_estimated cov_fesfeb_simulated cov_rsbfeb_estimated cov_rsbfeb_simulated cov_fesrsb_estimated cov_fesrsb_simulated cov_fes_simest cov_feb_simest cov_rsb_simest dfes_sq dfeb_sq drsb_sq depsilon_st_sq depsilon_bt_sq depsilon_sbt_sq{
		replace `var'=`var'/(N-1)
	}
	g corr_fesfeb_estimated=cov_fesfeb_estimated/sqrt(dfes_sq*dfeb_sq)
	g corr_fesfeb_simulated=cov_fesfeb_simulated/sqrt(depsilon_st_sq*depsilon_bt_sq)
	g corr_rsbfeb_estimated=cov_rsbfeb_estimated/sqrt(dfeb_sq*drsb_sq)
	g corr_rsbfeb_simulated=cov_rsbfeb_simulated/sqrt(depsilon_sbt_sq*depsilon_bt_sq)
	g corr_fesrsb_estimated=cov_fesrsb_estimated/sqrt(dfes_sq*drsb_sq)
	g corr_fesrsb_simulated=cov_fesrsb_simulated/sqrt(depsilon_sbt_sq*depsilon_st_sq)
	g corr_fes_simest=cov_fes_simest/sqrt(dfes_sq*depsilon_st_sq)
	g corr_feb_simest=cov_feb_simest/sqrt(dfeb_sq*depsilon_bt_sq)
	g corr_rsb_simest=cov_rsb_simest/sqrt(drsb_sq*depsilon_sbt_sq)
	
    g sim=`Y'
	keep cov* corr* dfes_sq dfeb_sq drsb_sq depsilon_st_sq depsilon_bt_sq depsilon_sbt_sq corr* sim
	append using cov_matrix_shocks_simulate_hdfe_commonfe
	save cov_matrix_shocks_simulate_hdfe_commonfe, replace
	

	erase fixed_effects_hdfe_simulated_`Y'.dta
}
use cov_matrix_shocks_simulate_hdfe_commonfe, clear
save $outputpath/cov_matrix_shocks_simulate_hdfe_commonfe, replace

erase temp_cf.dta
erase temp_simulate.dta
erase dta_sim.dta


