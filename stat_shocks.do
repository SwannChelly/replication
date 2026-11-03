
/*
	stat_shocks.do
	
	Date: November 2015
	
	Program: studies the growth and volatility of exports at the seller-buyer level

	Input: fixed_effects_$lhs_lab saved in $datapath, estimated in estimate_shocks.do
		
*/




cd $datapath 


use fixed_effects_hdfe$lhs_lab, clear 

putexcel set $outputpath/stat_shocks , sheet("corr micro shocks") replace
g lambda=$lambda

tabstat gs gsm fes_hdfe feb_hdfe rsb_hdfe pricei_b, stats(mean sd) save 
putexcel B2=matrix(r(StatTotal)' ) 
putexcel A2=("f2f growth") 
putexcel A3=("macro") 
putexcel A4=("seller") 
putexcel A5=("buyer") 
putexcel A6=("match") 
putexcel A7=("buyer cost") 

egen t1=group(iso2 year main_cpa)
egen t2=group(siren year) 
egen t3=group(buyer iso2 year) 
egen t4=group(siren buyer iso2 year)
egen t5=group(siren year) 

sum gs
putexcel D1=("Dimension") D2=(r(N))    
sum t1
putexcel D3=(r(max)) 
sum t2 
putexcel D4=(r(max)) 
sum t3
putexcel D5=(r(max))  
sum t4
putexcel D6=(r(max))   
sum t3
putexcel D7=(r(max))  
