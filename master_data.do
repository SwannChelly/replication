set scheme s1mono

/* 
Name : master_data.do 

Aim : clean the data and prepare the datasets used in the empirical analysis

*/

set more off

* Define global variables
global post  // used when playing with the time period -> leave blank 
global results W:\Bureau\kmm_jie\data\results\ // where output is saves
global datapath W:\Bureau\kmm_jie\data // where data are saved
global dopath W:\Bureau\kmm_jie\ // where do files are saved
global adopath W:\Bureau\kmm_jie\Ado // where ado files are saves (if any)
adopath + "$adopath"
cd $datapath

cd $dopath
do data_source

global list BE DE DK ES FI GB IE IT NL PT SE // list of iso2 codes for country sample
global dlog replace gs = log(gs+1)
cd $dopath
do shocks_prepdata // prepares the data used in master_results.do 

global year 2007
cd $dopath
do coverage_data // produces the stylized facts featured in Table 1

cd $dopath
do concentration // produces the stylized facts featured in Table 3

cd $dopath
do graph_diversification // produces the graphs featured in Figure 1 

global numsim 100
cd $dopath
do shocks_simulate // Simulate data to quantify the bias induced by the sparsity of the network

global pas .01
global target -0.0670
cd $dopath
do grid_search_lambda // algorithm to estimate the lambda parameter consistent with the moment conditions of the MC model 
