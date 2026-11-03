cap program drop herf

program herf 

collapse (sum) `1', by(`2')

egen tot = sum(`1')
g share2 = (`1'/tot)^2

collapse (count) N=share2 (sum) herf = share2
g relative_herf = herf * N

end

* Computes a herfindahl index of `1' based on market shares defined in dimension `2'
* herf is the herfindahl index, 
* relative_herf is the Herfindahl index in relative terms with respect to a symmetric world given N individuals
