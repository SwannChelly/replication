cap program drop CRratio

program CRratio 

collapse (sum) `1', by(`2')

gsort - `1'
g top10_`1' = `1'*(_n<=10)
g top10p_`1' = `1'*(_n/_N<=.10)

collapse (sum) `1' top10_`1' top10p_`1'

g share_top10 = top10_`1' / `1' 
g share_top10p = top10p_`1' / `1' 

end

* Computes the contribution to aggregate variable `1' of the top 10 and top10% individuals (`2') 
* share_top10 is the contribution of the top 10 firms
* share_top10p is the contribution of the top 10% of firms
