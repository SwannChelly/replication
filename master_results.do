set scheme s1mono

/* 
Name : master_results.do 

Aim : produce all the output tables of the paper
Inputs: 
- dta_reg.dta produced in master_data
- gridsearch_commonfe.dta produced in master_data

Outputs: 
- Tables 4-6, A1-A6 & Figures 1-3

*/

set more off
global post  // used when playing with the time period -> leave blank 
global results W:\Bureau\kmm_jie\data\results\ // where output is saves
global datapath W:\Bureau\kmm_jie\data // where data are saved
global dopath W:\Bureau\kmm_jie\ // where do files are saved
global adopath W:\Bureau\kmm_jie\Ado // where ado files are saves (if any)
adopath + "$adopath"

cd $datapath

*************************************************************************
*** BENCHMARK MODEL *****************************************************
*** Results assuming away feedbaks effects through the buyer price index

global outputpath $results/baseline // the results are sent in this folder
global lambda=0 // the algorithm to compute lambda is described in appendix A.3
global lhs_lab lambda$lambda 
global lab _baseline // no label 
global lhs gen lhs=gs + gbm*$lambda // =gs as lambda==0 in the baseline 

cd $dopath
do estimate_shocks_baseline.do // recover the shocks 
 
cd $dopath
do stat_shocks // featured in Table 4, and Table A.1, panel Benchmark model 

global restriction_connect 
global lab
cd $dopath
do counterfactual_small // results featured in Table 5, and Table A.2, column Bench; graph featured in Figure 2 

cd $dopath
do counterfactual_large // featured in Table 6 and Table A.3, lines Benchmark; and Table A.4, Benchmark 

cd $dopath
do graph_volatility_size // featured in Figure3 

global restriction_connect keep if nbseller>5 
global lab nbs5
cd $dopath
do counterfactual_small // featured in Table A.5, column 2 

global restriction_connect keep if nbbuyer>5 
global lab nbb5
cd $dopath
do counterfactual_small // featured in Table A.5, column 3

global restriction_connect keep if nbbuyer>15 
global lab nbb15
cd $dopath
do counterfactual_small // featured in Table A.5, column 2 
 
*****************************************
*** MONOPOLISTIC COMPETITION ************
*** Results (using the lambda correction)  

global outputpath $results/monop_comp/ // the results are sent in this folder

use $outputpath/gridsearch_commonfe, clear
keep if _n==1
sum lambda
global lambda=0.77 //r(mean) // the algorithm to compute lambda is described in appendix A.3
global lhs_lab lambda$lambda 
global lab // no label 
global lhs gen lhs=gs + gbm*$lambda // transformation of the LHS variable (see equation A.1) 
global restriction_connect
cd $dopath
do estimate_shocks.do // recover the shocks 

cd $dopath
do stat_shocks // featured in Table A.1, panel MC model 

cd $dopath
do counterfactual_small // featured in Table A.2, column MC 

cd $dopath
do counterfactual_large // featured in Table A.3, lines OC; and Table A.4, line Monop. comp. 

***********************************************************************
*** OLIGOPOLISTIC COMPETITION *****************************************
*** Results (using the lambda correction and assuming variable markups)  

global outputpath $results/oligo_comp/ // the results are sent in this folder
use $outputpath/gridsearch_commonfe, clear
keep if _n==1
sum lambda
global lambda=0.77 // the algorithm to compute lambda is described in appendix A.3
global lhs_lab _markup 
global lab _markup
global lhs gen lhs=gs + gbm*$lambda // transformation of the LHS variable (see equation A.3) 
global restriction_connect 
cd $dopath
do estimate_shocks_oligo // recover the shocks 

cd $dopath
do stat_shocks // featured in Table A.1, panel OC Model 

cd $dopath
do counterfactual_small // featured in Table A.2, column OC 

cd $dopath
do counterfactual_large // featured in Table A.3, lines OC; and Table A.4, line Oligop. 

