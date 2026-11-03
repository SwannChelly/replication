/*
	coverage_trade.do
	
	Date: April 2015
	
	Program: facts on the number of buyer, sellers, and transactions by country

	datafile used: x_eu.dta
	
*/
cd $datapath 
use x_eu, clear 
keep if year==$year
g yes=0
foreach i in BE DE DK ES FI GB IT NL {
replace yes=1 if iso2=="`i'"
}
keep if yes==1
local j=6
foreach i in BE DE DK ES FI GB IT NL {
egen tot=sum(export) if iso2=="`i'"
sum tot 
putexcel A`j'=("`i'") B`j'=(r(mean)) using stylized_facts , sheet("trade networks")  modify
egen s=group(siren) if iso2=="`i'"
sum s 
putexcel C`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
egen b=group(buyer) if iso2=="`i'"
sum b 
putexcel D`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
egen bs=group(siren buyer)  if iso2=="`i'"
sum bs 
putexcel E`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
drop tot s b p bs 
local j = `j'+1
}

/*
egen tot=sum(export) 
sum tot 
putexcel A`j'=("All") B`j'=(r(mean)) using stylized_facts , sheet("trade networks")  modify
egen s=group(siren) 
sum s 
putexcel C`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
egen b=group(buyer) 
sum b 
putexcel D`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
egen p=group(cpa4) 
sum p 
putexcel E`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
egen bs=group(siren buyer)  
sum bs 
putexcel F`j'=(r(max)) using stylized_facts , sheet("trade networks")  modify
drop tot s b p bs 
