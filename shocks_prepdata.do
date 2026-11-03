

/*
	shocks_pepdata.dta
	
	Date: April 2015
	Las modified: Sept. 2015 to compute the growth of buyers
	
	Program: Prepares the data to estimate the individual shocks 
	gives statistics on the trimming procedure

	Input: x_eu9910 saved in $datapath
		
	Output: dta_reg.dta 
	
*/
set scheme s1color
global list BE DE DK ES FI GB IE IT NL PT SE 

cd $datapath  
putexcel set $datapath/sample_estimate, sheet("stat des") replace
// Prepare the excel file
#delimit ; 
putexcel B1=("Value of exports") 
C1=("# of observations")  
D1=("Firm volatility") ; 
#delimit cr 
putexcel set sample_estimate, sheet("stat des") modify
global dlog replace gs = log(gs+1)
// Prepare the data 

use x_eu, clear 
collapse (sum)  export (mean) month, by(siren buyer iso2 year main_cpa)
keep if year<2008 
g yes=0
foreach i in $list{
replace yes=1 if iso2=="`i'"
}

egen tot=sum(export)
sum tot 
putexcel A2=("All EU") B2=(r(mean)) C2=(r(N))   
drop tot 

/**/ preserve 
collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3, d
putexcel D2=(r(p50))
putexcel E2=(r(N))  
sort siren 
rename gs gs_all
save temp_all, replace
/**/ restore 

drop if yes==0 
drop yes 

egen tot=sum(export)
sum tot 
putexcel A3=("EU 11") B3=(r(mean)) C3=(r(N))   
putexcel E3=(r(mean)) 
drop tot 

/**/ preserve 
collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3 , d
putexcel D3=(r(p50)) 
putexcel E3=(r(N)) 
sort siren 
rename gs gs_11
save temp_eu11, replace 
/**/ restore 


egen id=group(buyer siren iso2) 
xtset id year 
g gs=export/L.export -1 
g export0=L.export 
g month0=L.month

g no=gs==. 

* by taking growth, we drop 16% of French exports in value
drop if no==1 
egen tot=sum(export)
sum tot 
putexcel A4=("Cannot compute the growth rate") B4=(r(mean)) C4=(r(N))   
drop tot 

sum gs , d
preserve 

collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3, d
putexcel D4=(r(p50)) 
putexcel E4=(r(N)) 
restore 

keep if gs>-0.8 & gs<4
egen tot=sum(export)
sum tot 
putexcel A5=("Drop if gs<-0.8 or gs>4 ") B5=(r(mean)) C5=(r(N))   
drop tot 

preserve 

collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3, d
putexcel D5=(r(p50)) 
putexcel E5=(r(N)) 
restore 

$dlog 

// Tag observations for which the identification of shocks cannot be performed
egen nbs=count(export), by(buyer iso2 year)  
egen nbb=count(export), by(siren iso2 year) 
count if nbs==1 & nbb==1
drop if nbs==1 & nbb==1
egen tot=sum(export)
sum tot
putexcel A6=("Exclude one-to-one relationships (nbb>1 & nbs>1) ") B6=(r(mean)) C6=(r(N))   
drop tot 
g sample_restricted=1 if nbs>1 & nbb>1

preserve 

collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3, d
putexcel D6=(r(p50))
putexcel E6=(r(N))  

restore 

// Tag observations in the main connected group
egen s=group(siren year) 
egen b=group(buyer year iso2) 
egen c=group(iso2 main_cpa year)

g group_connexe=. 
sum year 
local min=r(min)
local max=r(max)
forvalues year=`min'/`max'{
	qui reg2hdfe gs if year==`year', id1(s) id2(b) groupid(comp) 
	replace group_connexe=comp if year==`year'
	drop comp
}
egen tot=sum(export) if group_connexe==1
sum tot 
putexcel A7=("Obs in the main connected group") B7=(r(mean)) C7=(r(N))   
drop tot 

preserve 
keep if group_connexe==1
collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3, d
putexcel D7=(r(p50)) 
putexcel E7=(r(N)) 
restore 

// Tag observations with all estimated effects in the main connected group
g test_rsb=.
g test_fes=. 
g test_feb=.
quietly sum year
local min=r(min)
local max=r(max)
forvalues year=`min'/`max'{
	qui reghdfe gs if  year==`year' & group_connexe==1, absorb(fes=s feb=b)  tolerance(1e-6)
	predict rsb, res				
	replace test_rsb= rsb if   year==`year'
	replace test_fes= fes if   year==`year'
	replace test_feb= feb if   year==`year'
	drop rsb fes feb
			
}
egen tot=sum(export) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=.
sum tot 
putexcel A8=("Obs in the main connected group with all estimated effects") B8=(r(mean)) C8=(r(N))   
drop tot 

preserve 
keep if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=.
collapse (sum) export, by(siren year) 
egen id=group(siren) 
xtset id year 
g gs=log(export/L.export) 
drop if gs==. | gs<-0.8 | gs>4
collapse (sd) gs (count) nb=gs, by(siren)
sum gs if nb>3, d
putexcel D8=(r(p50)) 
putexcel E8=(r(N)) 
merge 1:1 siren using temp_all 
drop _m 
merge 1:1 siren using temp_eu11 
pwcorr gs_all gs_11 
putexcel F3=(r(rho))
pwcorr gs_all gs 
putexcel F8=(r(rho))
keep siren gs_all gs_11 gs 
rename gs_all vol_eu15 
rename gs_11 vol_eu11 
rename gs vol_for_estimation
save temp_isa, replace
restore 

*** compute the growth of each buyer's purchases 
egen _=sum(export) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=., by(buyer iso2 year) 
egen totp=max(_), by(buyer iso2 year) 
drop _
egen _=sum(export0) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=., by(buyer iso2 year) 
egen totp0=max(_), by(buyer iso2 year) 
drop _
g w0gs=export0/totp0*gs
egen gbm_=sum(w0gs) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=., by(buyer iso2 year) // new : exclude which are not in the group_connexe 
egen gbm=max(gbm_) , by(buyer iso2 year) 


drop totp totp0 w0gs
g sample_final=1 if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=.

*** compute the growth of each seller' sales 
egen _=sum(export) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=., by(siren year) 
egen totp=max(_), by(siren year) 
drop _
egen _=sum(export0) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=., by(siren year) 
egen totp0=max(_), by(siren year) 
drop _
g w0gs=export0/totp0*gs
egen gsm_=sum(w0gs) if group_connexe==1 & test_rsb!=. & test_fes!=. & test_feb!=., by(siren year) // new : exclude which are not in the group_connexe 
egen gsm=max(gsm_) , by(siren year) 


drop totp totp0 w0gs 


drop test_* s b c

save dta_reg, replace 

