

cd $datapath


use $base, clear 

collapse (sum) export, by($focus $input $product)
egen nb_s_byb=count(export), by($input $product) 
egen nb_b_bys=count(export), by($focus $product) 
g class_$class=1 if nb_$class==1
replace class_$class=2 if nb_$class==2
replace class_$class=3 if 2<nb_$class & nb_$class  <5
replace class_$class=4 if 4<nb_$class & nb_$class  <9
replace class_$class=5 if 8<nb_$class & nb_$class  <17
replace class_$class=6 if 16<nb_$class & nb_$class  <33
replace class_$class=7 if 32<nb_$class & nb_$class  <65
replace class_$class=8 if 64<nb_$class & nb_$class  <129
replace class_$class=9 if 129<nb_$class
* "1" 2 "2" 3 "3-4" 4 "5-8" 5 "9-16" 6 "17-32" 7 "33-64" 8 "65-128" 9 "+128"
save temp$destination$sect, replace  

use temp$destination$sect, clear
collapse (count) degree=export, by($focus $product) 
g nb=1
collapse (sum) nb, by(degree) 
egen tot=sum(nb)
g nb_all=nb/tot
gsort - degree 
g cum_all=sum(nb_all) 
keep degree cum_all nb_all
sort degree
save temp_all$destination$sect, replace 

foreach i in 10 50 90{

use temp$destination$sect, clear
egen tot=sum(export), by($focus $product) 
g share=100*export/tot
gsort  $focus $product - share
bys $focus $product : g sum=sum(share)
g one=1 
bys $focus $product : g num=sum(one) 
keep if num==1 | sum<`i'
collapse (count) degree=export, by($focus $product) 
g nb=1
collapse (sum) nb, by(degree) 
egen tot=sum(nb)
g nb_`i'=nb/tot
gsort - degree 
g cum_`i'=sum(nb_`i') 
keep degree cum_`i' nb_`i'
sort degree
save temp_`i'$destination$sect, replace 
}

use temp_all$destination$sect, clear 
sort degree 
merge 1:1 degree using temp_10$destination$sect 
drop _m 
sort degree 
merge 1:1 degree using temp_50$destination$sect
drop _m 
sort degree 
merge 1:1 degree using temp_90$destination$sect 
drop _m
foreach i in all 90 50 10{
sort degree
g cum2_`i'=sum(nb_`i')
}


 
erase temp$destination.dta
