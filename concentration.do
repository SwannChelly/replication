/*
	concentration.do
	
	Date: November 2015
	
	Program: computes statistics on the concentration of trade

	Input: 
		x_eu saved in $datapath
		herf.do
		CRratio.do
		
	Output: concentration.xcls files 
	
*/

cd $dopath
do herf.do
do CRratio.do


cd $datapath 

*********************************************************

// Sheet corres.xcls: Produces the correlation table 
// Adds the mean and std dev of variables 

*********************************************************
global database temp2007
use x_eu, clear 
keep if year==2007
save $database, replace

putexcel set $outputpath/concentration , sheet("Concentration") replace

putexcel B2=("seller") C2=("buyers") D2=("seller-buyer pairs")
putexcel A4=("Herfindahl") A5=("Absolute value") A6=("Relative to symmetry")
putexcel A7=("Share in aggregate of") A8=("Top 10%") A9=("10 largest")

use $database, clear 

herf export siren

quietly sum herf
local herf=r(mean)
quietly sum relative_herf
local relherf=r(mean)

putexcel B5=(`herf') B6=(`relherf')

use $database, clear 

herf export buyer

quietly sum herf
local herf=r(mean)
quietly sum relative_herf
local relherf=r(mean)

putexcel C5=(`herf') D6=(`relherf')

use $database, clear 

herf export "siren buyer"

quietly sum herf
local herf=r(mean)
quietly sum relative_herf
local relherf=r(mean)

putexcel D5=(`herf') D6=(`relherf')

use $database, clear 

CRratio export siren

quietly sum share_top10
local top10=r(mean)
quietly sum share_top10p
local top10p=r(mean)

putexcel B8=(`top10') B9=(`top10p')

use $database, clear 

CRratio export buyer

quietly sum share_top10
local top10=r(mean)
quietly sum share_top10p
local top10p=r(mean)

putexcel C8=(`top10') C9=(`top10p')

use $database, clear 

CRratio export "siren buyer"

quietly sum share_top10
local top10=r(mean)
quietly sum share_top10p
local top10p=r(mean)

putexcel D8=(`top10') D9=(`top10p')

erase $database
