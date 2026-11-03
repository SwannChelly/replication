
/*
	Name: graph_diversification.dta
	
	Program: produces graphs on the diversification of sellers in terms of buyers and destination
	
*/

global year 2007 
global destination 
global sect 
global list BE DE DK ES FI GB IE IT NL PT SE

use x_eu, clear
egen sirenpays=group(siren pays) 
keep if year==$year 
g yes=0
foreach i in $list{
replace yes=1 if iso2=="`i'"
}
drop if yes==0 
drop yes 

* number of buyers per seller-destination
global focus sirenpays
global input buyer 
global product 
global sect 
global class s_byb 
cd $dopath
do degree_distribution
label var cum2_all "Total Sales" 
label var cum2_10 "Top 10% Sales"
label var cum2_50 "Top 50% Sales"
label var cum2_90 "Top 90% Sales"
gr tw scatter cum2_all cum2_90 cum2_50 cum2_10 degree if degree<300,  xscale(log)  ytitle("Share of sellers $product with x buyers or less") xtitle("# of buyers per seller $product") mlw(medthick) msize(large medsmall medsmall medsmall)  leg(region(lcolor(white)) ring(0) pos(3)) ms(circle_hollow diamond triangle square) xlab(1 2 5 10 35 100 300) ylab(0.4(0.1)1,angle(horizontal)) 
graph export "$graphpath\degree_sellers$product$year$destination.eps", replace

* number of buyers per seller-destination
global focus siren
global input pays 
global product 
global sect 
global class s_byb 
cd $dopath
do degree_distribution
label var cum2_all "Total Sales" 
label var cum2_10 "Top 10% Sales"
label var cum2_50 "Top 50% Sales"
label var cum2_90 "Top 90% Sales"
gr tw scatter cum2_all cum2_90 cum2_50 cum2_10 degree if degree<300,  xscale(log)  ytitle("Share of sellers $product with x buyers or less") xtitle("# of buyers per seller $product") mlw(medthick) msize(large medsmall medsmall medsmall)  leg(region(lcolor(white)) ring(0) pos(3)) ms(circle_hollow diamond triangle square) xlab(1 2 5 10 35 100 300) ylab(0.4(0.1)1,angle(horizontal)) 
graph export "$graphpath\degree_sellers$product$year$destination.eps", replace
