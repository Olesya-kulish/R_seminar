// Replication package for Public Goods Under Financial Distress (JFE)
// by Pawel Janas
// Fall 2025

// This file generates all tables and figures that use micro-level census data.

clear all
use replcation-data-micro


////////////////////////////////
//Table VII, A
////////////////////////////////////////


gen lev = dt_moody_std
eststo clea

// Regression 1
qui: reg left_public lev RLDF*std pop_30_std i.region1930 age1930 age2 age3 age4 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 [pw = probit_w], cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 



// Regression 2
qui: reg left_public lev RLDF*std pop_30_std i.region1930 age1930 age2 age3 age4 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 [pw = probit_w] if sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 
	
	
	
// Regression 3
qui: reg left_public lev RLDF*std pop_30_std i.region1930 age1930 age2 age3 age4 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 [pw = probit_w] if sex1930==2, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


// Regression 4
qui: reg log_occscore_change left_public RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


// Regression 5
qui: reg log_occscore_change c.left_public##c.lev  RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)

estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


// Regression 6
qui: reg xtile_change left_public RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


// Regression 7
qui: reg xtile_change c.left_public##c.lev  RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)

estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"
local titles " & All & Males & Females & Males & Males &  Males &  Males \\"
local numbers " &(1) &(2) &(3)  &(4)  &(5) &(6)  &(7) \\ \hline"

#delimit ;
esttab using micro_main.tex,
s(retail pop region age rev household R2 N  ymean_ ysd_ ,label("Retail Sales" "Population"
"Revenue (1930)" "Region FE" "Age" "Household"  "R-sq" "N" "Mean(y)" "SD(y)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
nomtitle
mgroups("Outcome: I(Left Public)" "$\Delta$ Log(Occscore)" "$\Delta$ Rank(Occscore)", pattern(1 0  0 1 0 1 0 )
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
mlabels(none) nonumbers posthead( "`titles'" "`numbers'")
label
replace
se(3)
b(3)
keep(
lev
*left_public*)
coeflabels(
lev "Moody Leverage"
c.left_public#c.lev "Moody Leverage x I(Left Public)"
left_public "I(Left Public)"
)
;
#delimit cr



////////////////////////////////
//Table VII, B
////////////////////////////////////////

eststo clear

qui: reg age1930  left_public RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 [pw = probit_w] if ~missing(dt_moody_std) & sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg age1930  c.left_public##c.lev  RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 [pw = probit_w] if sex1930==1, cluster(city_1930)

estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg educ_cont left_public RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if ~missing(dt_moody_std) & sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg educ_cont c.left_public##c.lev  RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)

estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg log_wage left_public RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if ~missing(dt_moody_std) & sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg log_wage c.left_public##c.lev RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)

estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg move left_public RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if ~missing(dt_moody_std) & sex1930==1, cluster(city_1930)
estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 


qui: reg move c.left_public##c.lev RLDF*std pop_30_std i.region1930 real_pc_rev_total_log i.nchild1930 i.marst1930 i.sex1930 i.race1930 age1930 age2 age3 age4 [pw = probit_w] if sex1930==1, cluster(city_1930)

estadd scalar R2 = e(r2)
estadd scalar Observations = e(_n)
estadd ysumm
estadd scalar ymean_ = e(ymean)
estadd scalar ysd_ = e(ysd)
estadd local retail  "\checkmark"
estadd local pop "\checkmark"
estadd local region "\checkmark"
estadd local age "\checkmark"
estadd local rev "\checkmark"
estadd local household "\checkmark"
eststo 





cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"
local titles " & Males & Males & Males & Males & Males & Males  & Males  & Males \\"
local numbers " &(1) &(2) &(3)  &(4)  &(5) &(6) &(7) &(8)  \\ \hline"

#delimit ;
esttab using micro_main_comp.tex,
s(retail pop region age rev household R2 N  ymean_ ysd_ ,label("Retail Sales" "Population"
"Revenue (1930)" "Region FE" "Age" "Household"  "R-sq" "N" "Mean(y)" "SD(y)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
nomtitle
mgroups("Age (1940)" "Years of Schooling (1940)" "Log(Weekly Wages) (1940)" "I(Moved Out of City) (1940)", pattern(1 0 1 0 1 0 1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
mlabels(none) nonumbers posthead( "`titles'" "`numbers'")
label
replace
se(3)
b(3)
keep(
lev
*left_public*)
coeflabels(
lev "Moody Leverage"
c.left_public#c.lev "Moody Leverage x I(Left Public)"
left_public "I(Left Public)"
)
;
#delimit cr

