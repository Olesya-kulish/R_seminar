// Replication package for Public Goods Under Financial Distress (JFE)
// by Pawel Janas
// Fall 2025

// This file generates all tables and figures that use city-level data.

clear all
use replication-data-city
bysort id_: egen counter = count(year)


////////////////////////////////////////////////////////////////////////////
//////////  TABLES //////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
///Table I////////////////
/////////////////////////////////////////////////////////////////////////////

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables"

eststo clear
#delimit ;
eststo: estpost sum 
pop_i_k
real_pc_rev_total
real_pc_rev_tax
real_pc_rev_nontax
real_pc_rev_debt
real_pc_rev_nontax_nondebt
real_pc_maint_dep_total
real_pc_maint_dep_gen
real_pc_maint_dep_health
real_pc_maint_dep_road
real_pc_maint_dep_pp
real_pc_maint_dep_charity
real_pc_maint_dep_rec
real_pc_maint_dep_school
real_pc_maint_dep_other
real_pc_pse
real_pc_interest
real_pc_outlay
real_pc_pay_other 
real_pc_debt_total
real_pc_debt_bond
real_pc_assess_total
default
default_city
bonds_to_assess
int_to_rev
debt_to_rev
if ~missing(real_pc_rev_total)
,
d
;
#delimit cr

#delimit ;
esttab using summary_stats_final.tex,
label cells("count(fmt(%12.3gc) label(N)) mean(fmt(2) label(Mean)) sd(fmt(2) label(SD)) p50(fmt(2) label(Median)) p25(fmt(2) label(25 pct)) p75(fmt(2) label(75 pct))")  mtitle("`i'") nonumbers 
noobs
replace 
;
#delimit cr


///////////////////////////////////////
/// Table I ////////////////
//////////////////////////////////////


eststo clear
#delimit ;
eststo: estpost sum 
bank_shock
delta_loan_31_29_tr
years_since_w
share_1925_1929_t
pop_20_30
city_age
outlay_24_29
WPA_pc
RFC_pc
murder1_pc
rape_pc
robbery_pc
aggasu_pc
burglary_pc
autothft_pc
death_rate_31
pop_30_40
if year==1930
,
d
;
#delimit cr

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables"
#delimit ;
esttab using summary_stats_static.tex,
label cells("count(fmt(%12.3gc) label(N)) mean(fmt(2) label(Mean)) sd(fmt(2) label(SD)) p50(fmt(2) label(Median)) p25(fmt(2) label(25 pct)) p75(fmt(2) label(75 pct))")  mtitle("`i'") nonumbers 
noobs
replace 
;
#delimit cr



///////////////////////////////////////////////////////////////////////////////////////////
//////////  Table II /////////
/////////////////////////////////////////////////////////////////////////////////////////


xtset id_ year
set matsize 11000
eststo clear

reghdfe bonds_to_assess29_lev_std pop_i_std if year==1929, absorb(state_) vce(cluster id_)
estadd scalar R2 = e(r2)
estadd local fe "\checkmark"
eststo

reghdfe bonds_to_assess29_lev_std  pop_i_std pc_outlay_24_29_std if year==1929, absorb(state_) vce(cluster id_)
estadd scalar R2 = e(r2)
estadd local fe "\checkmark"
eststo

reghdfe bonds_to_assess29_lev_std  pop_i_std bonds_to_assess24_lev_std pc_outlay_24_29_std if year==1929, absorb(state_) vce(cluster id_)
estadd scalar R2 = e(r2)
estadd local fe "\checkmark"
eststo

reghdfe int_to_rev29_lev_std pop_i_std int_to_rev24_lev_std pc_outlay_24_29_std if year==1929, absorb(state_) vce(cluster id_)
estadd scalar R2 = e(r2)
estadd local fe "\checkmark"
eststo

reghdfe debt_to_rev29_lev_std  pop_i_std debt_to_rev24_lev_std pc_outlay_24_29_std if year==1929, absorb(state_) vce(cluster id_)
estadd scalar R2 = e(r2)
estadd local fe "\checkmark"
eststo

reghdfe debt_total29_lev_std pop_i_std debt_total24_lev_std pc_outlay_24_29_std if year==1929, absorb(state_) vce(cluster id_)
estadd scalar R2 = e(r2)
estadd local fe "\checkmark"
eststo


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"
#delimit ;
esttab using debt_explain.tex,
s(fe R2 N,label("State FE" "R-sq" "N")
fmt("%16s" "%3.2f" "%15.0gc"))
star(* 0.10 ** 0.05 *** 0.01)
b(2)
se(2)
label
replace
nomtitle
noconstant
mgroups("Bonds/Assess" "Int/Rev" "Debt/Rev" "Debt/Capita", pattern(1 0 0 1 1 1)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
coeflabels(
pop_i_std "Population (1929)"
debt_total24_lev_std  "Debt/Capita (1924)"
debt_to_rev24_lev_std  "Debt/Rev (1924)"
int_to_rev24_lev_std "Int/Rev (1924)"
bonds_to_assess24_lev_std "Bonds/Assess (1924)"
)
;
#delimit cr



////////////////////////////////////////////////////////////////
//////////  Table III, A////////
//////////////////////////////////////////////////////////////

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"

eststo clear

xtset id_ year
foreach a in bonds_to_assess29_lev_std{
	quietly sum `a' if year==1930
	gen test = `a'
	
	foreach v of varlist real_pc_maint_dep_total_log{
		
	// No controls
		xtreg  `v' ib2.post_detail##c.test ib1928.year, fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		eststo

	
	// Population control
	
		xtreg  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year, fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		eststo 
		
	// Population group control
	
		xtreg  `v' ib2.post_detail##c.test ib1928.year i.pop_cat##i.year c.pop_20_30##i.year, fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local pop3 "\checkmark"
		eststo 
		
	
	// Revenue Control

		xtreg  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log , fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		eststo 
		

	
	//  + Region x year FE
		xtreg  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_, fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		eststo 
	
	
	
	
	}
	
	
		//  Debt revenue
		xtreg  real_pc_rev_debt_log ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_, fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		eststo 
		
	drop test
	
	
}


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"

#delimit ;
esttab using did_service.tex,
s(fe cohort pop pop2 pop3 rev regyear R2 N  ymean_ ysd_,label("City FE" "Year FE" "1930 Pop x Year" "$\Delta$1920-30 Pop x Year" "Pop Group x Year"  "Revenue" "Region x Year" "R-sq (within)" "N" "Mean(y)" "SD(y)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s"  "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
keep(1.post_detail#c.test 3.post_detail#c.test  4.post_detail#c.test  5.post_detail#c.test )
nomtitle
mgroups("Outcome: Log(Service Payments/Capita)" "Log(Debt Receipts/Capita)", pattern(1 0 0 0 0 1)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
label
replace
se(2)
b(2)
coeflabels(
1.post_detail#c.test "leverage x 1924-1926"
3.post_detail#c.test "leverage x 1929-1933"
4.post_detail#c.test "leverage x 1934-1938"
5.post_detail#c.test "leverage x 1941-1943"
)
;
#delimit cr

	
	



	
////////////////////////////////////////////////////////////////
//////////  Table III, B////////
//////////////////////////////////////////////////////////////

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"

eststo clear

xtset id_ year
foreach a in bonds_to_assess29_lev_std{
	quietly sum `a' if year==1930
	gen test = `a'
	
	foreach v of varlist real_pc_outlay{
		
	// No controls
	    ppmlhdfe `v' ib2.post_detail##c.test, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		eststo

	
	// Population control
	
		ppmlhdfe  `v' ib2.post_detail##c.test c.pop_30##i.year c.pop_20_30##i.year, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		eststo 
		
	
	// Population group control
	
		ppmlhdfe  `v' ib2.post_detail##c.test i.pop_cat##i.year c.pop_20_30##i.year, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop3 "\checkmark"
		estadd local pop2 "\checkmark"
		eststo 
		
		
	
	// Revenue Control

		ppmlhdfe  `v' ib2.post_detail##c.test c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		eststo 
		

	
	//  + Region x year FE
		ppmlhdfe  `v' ib2.post_detail##c.test c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		eststo 
		

	}
	
	
	drop test
}


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"



#delimit ;
esttab using did_outlay.tex,
s(fe cohort pop pop2 pop3 rev regyear R2 N  ymean_ ysd_ ,label("City FE" "Year FE" "1930 Pop x Year" "$\Delta$1920-30 Pop x Year" "Pop Group x Year"  "Revenue" "Region x Year"  "R-sq (pseudo)" "N" "Mean(y)" "SD(y)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s"  "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
keep(1.post_detail#c.test 3.post_detail#c.test  4.post_detail#c.test 5.post_detail#c.test )
nomtitle
mgroups("Outcome: Outlay/Capita", pattern(1 0 0 0 0 )
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
label
replace
se(2)
b(2)
coeflabels(
1.post_detail#c.test "leverage x 1924-1926"
3.post_detail#c.test "leverage x 1929-1933"
4.post_detail#c.test "leverage x 1934-1938"
5.post_detail#c.test "leverage x 1941-1943"
)
;
#delimit cr





////////////////////////////////////////////////////////////////
//////////  Table IV, A ///////////////////
//////////////////////////////////////////////////////////////

xtset id_ year
eststo clear
foreach a in bonds_to_assess29_lev int_to_rev29_lev debt_to_rev29_lev debt_total29_lev{
	gen test_moody = `a'_moody_std
	foreach v of varlist real_pc_outlay{
		
		ppmlhdfe  `v' ib2.post_detail##c.test_moody  ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_  if check<0.2 & check>-0.2, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		eststo 
		
	
	}
	
	drop test_moody test

}


	
cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"
local numbers " &(1) & (2) & (3) & (4)\\ \hline"

#delimit ;
esttab using did_moody_outlay.tex,
s(fe cohort pop pop2 rev regyear R2 N  ymean_ ysd_,label("City FE" "Year FE" "1930 Pop x Year" "$\Delta$1920-30 Pop x Year" "Revenue" "Region x Year" "R-sq (pseudo)" "N" "Mean(y)" "SD(y)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
keep(
 1.post_detail#c.test_moody 3.post_detail#c.test_moody  4.post_detail#c.test_moody
 5.post_detail#c.test_moody
 
 )
nomtitle
mgroups("Bonds / Assessed Value" "Int/Rev" "Debt/Rev" "Debt/Capita", pattern(1 1 1 1)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
mlabels(none) nonumbers posthead("`numbers'")
label
replace
se(2)
b(2)
coeflabels(
1.post_detail#c.test_moody "moodyleverage x 1924-1926"
3.post_detail#c.test_moody "moodyleverage x 1929-1933"
4.post_detail#c.test_moody "moodyleverage x 1934-1938"
5.post_detail#c.test_moody "moodyleverage x 1941-1943"
)
;
#delimit cr





////////////////////////////////////////////////////////////////
//////////  Table IV, B////////////////////
//////////////////////////////////////////////////////////////

xtset id_ year
eststo clear
foreach a in bonds_to_assess29_lev int_to_rev29_lev debt_to_rev29_lev debt_total29_lev{
	gen test_moody = `a'_moody_std

	foreach v of varlist real_pc_maint_dep_total_log{
	
				
		xtreg  `v' ib2.post_detail##c.test_moody ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_  if check<0.2 & check>-0.2, fe c(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		eststo 
		
	
	}
	
	drop test_moody

}

	
cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"
local numbers " &(1) & (2) & (3) & (4) \\ \hline"

#delimit ;
esttab using did_moody_service.tex,
s(fe cohort pop pop2 rev regyear R2 N  ymean_ ysd_,label("City FE" "Year FE" "1930 Pop x Year" "$\Delta$1920-30 Pop x Year" "Revenue" "Region x Year" "R-sq (within)" "N" "Mean(y)" "SD(y)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
keep(
 1.post_detail#c.test_moody 3.post_detail#c.test_moody  4.post_detail#c.test_moody
 5.post_detail#c.test_moody
 )
nomtitle
mgroups("Bonds / Assessed Value" "Int/Rev" "Debt/Rev" "Debt/Capita", pattern(1 1 1 1)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
mlabels(none) nonumbers posthead("`numbers'")
label
replace
se(2)
b(2)
coeflabels(
1.post_detail#c.test_moody "moodyleverage x 1924-1926"
3.post_detail#c.test_moody "moodyleverage x 1929-1933"
4.post_detail#c.test_moody "moodyleverage x 1934-1938"
5.post_detail#c.test_moody "moodyleverage x 1941-1943"
)
;
#delimit cr





////////////////////////////////////////////////////////////////
////////// Table V///////////
//////////////////////////////////////////////////////////////



eststo clear
xtset id_ year

foreach a in bonds_to_assess29_lev_std{
	quietly sum `a' if year==1930
	local xmean_ = r(mean)
	local xsd_ = r(sd)
	gen test = `a'
	
		
		ppmlhdfe  real_pc_outlay ib2.post_detail##c.test##c.bank_shock c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ , absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd scalar xmean_ = `xmean_'
		estadd scalar xsd_ = `xsd_'
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		estadd local levyear "\checkmark"
		estadd local bankyear1 "\checkmark"
		eststo 
		
		
		
				ppmlhdfe  real_pc_outlay ib2.post_detail##c.test##c.delta_loan_31_29 c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ , absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_p)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd scalar xmean_ = `xmean_'
		estadd scalar xsd_ = `xsd_'
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local regyear "\checkmark"
		estadd local levyear "\checkmark"
		estadd local bankyear2 "\checkmark"
		eststo 

	
		drop test
}
	

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"

local numbers " &(1) & (2) \\ \hline"
#delimit ;
esttab using did_banking.tex,
s(fe cohort pop pop2 rev regyear levyear bankyear1 bankyear2 R2 N  ymean_ ysd_ xmean_ xsd_,label("City FE" "Year FE" "1930 Pop x Year" "$\Delta$1920-30 Pop x Year" "Revenue" "Region x Year" "Leverage x Period" "Suspended Bank Deposits x Period" "$\Delta$ loan growth x Period" "R-sq (within)" "N" "Mean(y)" "SD(y)" "Mean(x)" "SD(x)") 
fmt("%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f" "%3.2f" "%5.3f" "%5.3f"))
star(* 0.10 ** 0.05 *** 0.01)
keep(
1.post_detail#*c.test*.bank_shock
3.post_detail#*c.test*.bank_shock
4.post_detail#*c.test*.bank_shock
5.post_detail#*c.test*.bank_shock
1.post_detail#*c.test*.delta_loan_31_29
3.post_detail#*c.test*.delta_loan_31_29
4.post_detail#*c.test*.delta_loan_31_29
5.post_detail#*c.test*.delta_loan_31_29
)
nomtitle
mgroups("Outcome: Outlay/Capita", pattern(1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
mlabels(none) nonumbers posthead("`numbers'")
label
replace
se(2)
b(2)
coeflabels(
1.post_detail#c.test#c.bank_shock "leverage x 1924-1926 x suspended bank deposits"
3.post_detail#c.test#c.bank_shock "leverage x 1929-1933 x suspended bank deposits"
4.post_detail#c.test#c.bank_shock "leverage x 1934-1938 x suspended bank deposits"
5.post_detail#c.test#c.bank_shock "leverage x 1941-1943 x suspended bank deposits"

1.post_detail#c.test#c.delta_loan_31_29 "leverage x 1924-1926 x $\Delta$ bank loan growth"
3.post_detail#c.test#c.delta_loan_31_29 "leverage x 1929-1933 x $\Delta$ bank loan growth"
4.post_detail#c.test#c.delta_loan_31_29 "leverage x 1934-1938 x $\Delta$ bank loan growth"
5.post_detail#c.test#c.delta_loan_31_29 "leverage x 1941-1943 x $\Delta$ bank loan growth"
)
;
#delimit cr



////////////////////////////////////////////////////////////////
////////// Table VI ///////////
//////////////////////////////////////////////////////////////

eststo clear	
	
// Column 1
quietly sum pop_30_40 if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  pop_30_40_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 

// Column 2
quietly sum pop_30_50 if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  pop_30_50_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 


// Column 3
quietly sum death_rate_delta if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  death_rate_delta_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 



// Column 4
quietly sum prop_crime_30_32 if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  prop_crime_30_32_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 


// Column 5
quietly sum human_crime_30_32 if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  human_crime_30_32_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 



// Column 6
quietly sum prop_crime_30_36 if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  prop_crime_30_36_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 


// Column 7
quietly sum human_crime_30_36 if year==1930
local ymean = r(mean)
local ysd = r(sd)

reg  human_crime_30_36_std debt_total29_lev_moody_std RLDF*std real_pc_rev_total_log_std pop_30_log_std  pop_20_30_std if year==1930, vce(robust)
estadd scalar R2 = e(r2)
estadd local retail "\checkmark"
estadd local pop "\checkmark"
estadd local rev "\checkmark"
estadd scalar ymean_ = `ymean'
estadd scalar ysd_ = `ysd'
eststo 

cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Tables/"

#delimit ;
esttab using did_popgrowth.tex,
s(retail pop rev R2 N ysd_,label("Retail Sales" "Population" "Revenue (1930)" "R-sq" "N" "Std[Y]") 
fmt( "%16s" "%16s" "%16s" "%3.2f" "%15.0gc" "%3.2f"))
star(* 0.10 ** 0.05 *** 0.01)
keep(debt_total29_lev_moody_std )
label
replace
se(2)
b(2)
coeflabels(
debt_total29_lev_moody_std "Moody Leverage"
)
mgroups("1930 - 1940" "1930 - 1950" "1928 - 1934" "1930 - 1933" "1930 - 1937", pattern(1 1 1 1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span
erepeat(\cmidrule(lr){@span}))
nonumbers
;
#delimit cr



////////////////////////////////////////////////////////////////////////////
//////////  Figure II
//////////////////////////////////////////////////////////////////////////


sort pop_cat year
foreach v of varlist real_pc_maint_dep_total real_pc_outlay real_pc_maint_dep_charity real_pc_maint_dep_pp{
	local x : variable label `v'
	bysort pop_cat year: egen `v'_m = mean(`v')
	label var `v'_m "`x'"
}


sort pop_cat year
foreach v of varlist *_m {
	local x : variable label `v'
	bysort pop_cat year: gen `v'_test =`v' if year==1930
	bysort pop_cat (`v'_test): replace `v'_test =`v'_test[1]
	replace `v' = `v'/`v'_test
	label var `v' "`x'"
	
}	

drop *_test
label var real_pc_maint_dep_total_m "Total Service Payments"
label var real_pc_outlay_m "Capital Outlays"
label var real_pc_maint_dep_charity_m "Total Charity and Welfare"
label var real_pc_maint_dep_pp_m "Police and Protection"

preserve

keep year pop_cat *_m year
duplicates drop

sort pop_cat year

foreach a of varlist *_m{
	local x : variable label `a'
	#delimit ;
	twoway
	(line `a' year if year<1939 & pop_cat==3,xline(1930) lcolor(black) lpattern(solid) xsc(range(1924(2)1938)) xlab(1924(2)1938))
	(line `a'  year if year<1939 & pop_cat==2,lcolor(black) lpattern(longdash) xsc(range(1924(2)1938)) xlab(1924(2)1938))
	(line `a' year if year<1939 & pop_cat==1,lcolor(black) lpattern(shortdash) xsc(range(1924(2)1938)) xlab(1924(2)1938))
	,
	title(`x', size(large))
	legend(
	label(1 "100k+")
	label(2 "10-100k")
	label(3 "1-10k")
	cols(3))
	xt("")
	yt("Index", height(5))
	xsc(range(1924(1)1938)) xlab(1924(1)1938, angle(45))
	name(`a'_time, replace)
	graphregion(color(white))
	legend(size(small) pos(6))
	yt("Index", height(5))
	;
	#delimit cr
	cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
	graph export `a'_time.png, replace
}

restore


////////////////////////////////////////////////////////////////////////////
//////////  Figure III/////////
//////////////////////////////////////////////////////////////////////////


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
hist  bonds_to_assess29_lev if year==1929 & bonds_to_assess29_lev>0, bcolor(black%40) graphregion(color(white)) xtitle("") title("Bonds / Assessed Value (1929)")
graph export bonds_to_assess.png, replace

hist  debt_to_rev29_lev if year==1929 & debt_to_rev29_lev>0, bcolor(black%40) graphregion(color(white)) xtitle("") title("Debt / Total Revenue (1929)")
graph export debt_to_rev.png, replace


hist  int_to_rev29_lev if year==1929 & int_to_rev29_lev>0, bcolor(black%40) graphregion(color(white)) xtitle("") title("Interest / Tax Revenue (1929)")
graph export int_to_rev.png, replace

hist  debt_total29_lev if year==1929 & debt_total29_lev>0, bcolor(black%40) graphregion(color(white)) xtitle("") title("Debt / Capita (1929)")
graph export debt_per_capita.png, replace





////////////////////////////////////////////////////////////////////////////
//////////  Figure IV
/////////////////////////////////////////////////////////////////////////



xtset id_ year

// outlay
xtile bonds_to_assess29_t = bonds_to_assess29_lev, n(3)
bysort bonds_to_assess29_t year: egen out_dov = mean(real_pc_outlay) if counter==18
bysort bonds_to_assess29_t year: egen out_dov_nom = mean(pc_outlay) if counter==18

xtset id_ year
gen out_smooth = (out_dov + L1.out_dov + F1.out_dov)/3
gen out_smooth_nom = (out_dov_nom + L1.out_dov_nom + F1.out_dov_nom)/3
gen test = out_smooth if year==1929
gen test_nom = out_smooth_nom if year==1929
sort id test
bysort id: replace test = test[1]
sort id test_nom
bysort id: replace test_nom = test_nom[1]


replace out_smooth = out_smooth/test
replace out_smooth_nom = out_smooth_nom/test_nom

drop test*


// non-outlay, non-interest
xtset id_ year
bysort bonds_to_assess29_t  year: egen maint_dov = mean(real_pc_maint_dep_total) if counter==18
bysort bonds_to_assess29_t  year: egen maint_dov_nom = mean(pc_maint_dep_total) if counter==18

xtset id_ year
gen maint_smooth = (maint_dov + L1.maint_dov + F1.maint_dov)/3
gen maint_smooth_nom = (maint_dov_nom + L1.maint_dov_nom + F1.maint_dov_nom)/3
gen test = maint_smooth if year==1929
gen test_nom = maint_smooth_nom if year==1929
sort id test
bysort id: replace test = test[1]
sort id test_nom
bysort id: replace test_nom = test_nom[1]
replace maint_smooth = maint_smooth/test
replace maint_smooth_nom = maint_smooth_nom/test_nom
drop test



// police officers
xtset id_ year
bysort bonds_to_assess29_t  year: egen pol_dov = mean(n_emp_pol) if counter==18

xtset id_ year
gen pol_smooth = pol_dov
gen test = pol_smooth if year==1931
sort id test
bysort id: replace test = test[1]
replace pol_smooth = pol_smooth/test

	

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////  Figure V /////////
////////////////////////////////////////////////////////////////////////////////////////////////////


#delimit ;
local vars
real_pc_maint_*log
real_pc_rev_debt_log
;
#delimit cr


xtset id_ year

foreach a in bonds_to_assess29_lev_std{
	gen test = `a'
	
	foreach v of varlist `vars'{
		
	// Revenue + Regin x year FE
		local labs: variable label `v'
		xtreg  `v' ib1928.year##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if counter==18, fe c(id_)
		#delimit ;
		coefplot, vertical yline(0)
		keep(*#c.test)
		levels(90)
		recast(connected)
		ciopts(recast(rcap) lp(dash) lc(black))
		coeflabels(
		1925.year#c.* ="1925"
		1926.year#c.* ="1926"
		1927.year#c.* ="1927"
		1928.year#c.* ="1928"
		1929.year#c.* ="1929"
		1930.year#c.* ="1930"
		1931.year#c.* ="1931"
		1932.year#c.*="1932"
		1933.year#c.*="1933"
		1934.year#c.* ="1934"
		1935.year#c.*="1935"
		1936.year#c.* ="1936"
		1937.year#c.* ="1937"
		1938.year#c.*="1938"
		1942.year#c.*="1942"
		1943.year#c.*="1943"
		,
		angle(45)
		)
		xline (5.5, lpattern(solid) lcolor(red))
		graphregion(color(white))
		title("`labs'", size(medium))
		omitted baselevels
		ylab(, labsize(medium))
		name(`v', replace)
		;
		#delimit cr
		cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
		graph export `v'_event_study_`a'.png, replace
	}
	
	drop test

		
}




#delimit ;
local vars
real_pc_outlay
;
#delimit cr

xtset id_ year

foreach a in bonds_to_assess29_lev_std{
	gen test = `a'
	eststo clear
	
	foreach v of varlist `vars'{
		
		eststo clear
		local labs: variable label `v'
		ppmlhdfe  `v' ib1928.year##c.test c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if counter==18, absorb(id_ year) cl(id_)
		#delimit ;
		coefplot, vertical yline(0)
		keep(*#c.test)
		levels(90)
		recast(connected)
		ciopts(recast(rcap) lp(dash) lc(black))
		coeflabels(
		1924.year#c.* ="1924"
		1925.year#c.* ="1925"
		1926.year#c.* ="1926"
		1927.year#c.* ="1927"
		1928.year#c.* ="1928"
		1929.year#c.* ="1929"
		1930.year#c.* ="1930"
		1931.year#c.* ="1931"
		1932.year#c.*="1932"
		1933.year#c.*="1933"
		1934.year#c.* ="1934"
		1935.year#c.*="1935"
		1936.year#c.* ="1936"
		1937.year#c.* ="1937"
		1938.year#c.*="1938"
		1942.year#c.*="1942"
		1943.year#c.*="1943",
		angle(45)
		)
		xline (5.5, lpattern(solid) lcolor(red))
		graphregion(color(white))
		title("`labs'", size(medium))
		omitted baselevels
		ylab(, labsize(medium))
		;
		#delimit cr
		cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
		graph export `v'_event_study_`a'.png, replace
			

	}
	
	drop test

		
}


	

////////////////////////////////////////////////////////////////
////////// Figure VI/////////
//////////////////////////////////////////////////////////////

xtile bonds_to_assess29_t = bonds_to_assess29_lev, n(3)
bysort year bonds_to_assess29_t: egen rating_mean = mean(rating_int)
bysort year bonds_to_assess29_t: egen rating_mean2 = mean(rating_int2)


sort year
#delimit ;
twoway(connected rating_mean2 year if year>1928 & bonds_to_assess29_t==1 & year<1940 , lw(thin) color(green))
(connected rating_mean2 year if year>1928 & bonds_to_assess29_t==3 & year<1940, lw(thin) color(red) lp(dash) msym(T) mcol(red)), 
ysc(range(6(1)10)) ylab(6(1)10) 
xsc(range(1929(1)1939)) xlab(1929(1)1939, angle(45))
xt("")
yt("")
graphregion(color(white))
legend(order(1 "Low Leverage (1929)" 2 "High Leverage (1929)"))
title("Average Moody's Bond Ratings (10 = AAA) using Debt/Revenue", size(medium))
;
#delimit cr

drop bonds_to_assess29_t


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
graph export moody_ratings.png, replace


////////////////////////////////////////////////////////////////
////////// Figure VIII, A/////////
//////////////////////////////////////////////////////////////

xtset id_ year
sum share_1925_1929_t if year==1930,d
return list
local val = r(p50)

gen test1 = .
replace test1 = 1 if share_1925_1929_t > `val' & ~missing(share_1925_1929_t)
replace test1= 0 if share_1925_1929_t < `val'


sum years_since_w if year==1930, d
return list
local val2 = r(p50)

gen test2 = .
replace test2 = 1 if years_since_w > `val2' & ~missing(years_since_w)
replace test2= 0 if years_since_w < `val2'


eststo clear
foreach a in bonds_to_assess29_lev_std{
	quietly sum `a' if year==1930 & ~missing(test1)
	local xmean_ = r(mean)
	local xsd_ = r(sd)

	quietly sum `a' if year==1930 & test1==0
	local xmean_2 = r(mean)
	local xsd_2 = r(sd)
	
	quietly sum `a' if year==1930 & test2==1
	local xmean_3 = r(mean)
	local xsd_3 = r(sd)
	
	
	gen test = `a'
	
	foreach v of varlist real_pc_outlay{
	
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if ~missing(test1), absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd scalar xmean_ = `xmean_'
		estadd scalar xsd_ = `xsd_'
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local sourceyear "\checkmark"
		eststo 
		
		
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if test1==1, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd scalar xmean_ = `xmean_2'
		estadd scalar xsd_ = `xsd_2'
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local sourceyear "\checkmark"
		eststo 
		
		
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if test2==0, absorb(id_ year) cl(id_)
		estadd scalar R2 = e(r2_w)
		estadd scalar Observations = e(_n)
		estadd ysumm
		estadd scalar ymean_ = e(ymean)
		estadd scalar ysd_ = e(ysd)
		estadd scalar xmean_ = `xmean_3'
		estadd scalar xsd_ = `xsd_3'
		estadd local fe "\checkmark"
		estadd local cohort "\checkmark"
		estadd local pop "\checkmark"
		estadd local pop2 "\checkmark"
		estadd local rev "\checkmark"
		estadd local sourceyear "\checkmark"
		eststo 
		
	
	}
	
	drop test*
}
	

#delimit ;
coefplot (est1, aseq(1) bcolor(black) ciopts(lcolor(black) recast(rcap)))
(est2, aseq(2) bcolor(green) ciopts(lcolor(green) recast(rcap))) 
(est3, aseq(3) bcolor(red) ciopts(lcolor(red) recast(rcap)))
, 
vertical recast(bar)
keep(*3.post*#c.test*
*4.post*#c.test*
*5.post*#c.test*
)
graphregion(color(white))
omitted baselevels
yline(0)
xline(4, lp(solid))
xline(8, lp(solid))
aseq swapnames
ciopts(recast(rcap))
levels(90)
barwidth(0.25) finten(30)
citop
ylab(,angle(45))
legend(order (1 "Base" 3 "Cities with above median 1925-1929 issuance" 5 "Cities with below median average bond age"))
legend(rows(3) size(small))
legend(position(6))
ysc(range(-0.6(0.06)0.06))
ylab(-0.6(0.06)0.06,angle(0))
nooffsets
xlab("")
eqlabels("1929-1933" "1934-1938" "1941-1943")
title("Outcome: capital outlay", size(medium))
;
#delimit cr


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
graph export did_demand_bonds.png, replace




////////////////////////////////////////////////////////////////
////////// Figure VIII, B/////////
//////////////////////////////////////////////////////////////



xtset id_ year
eststo clear
foreach a in bonds_to_assess29_lev_std{
	quietly sum `a' if year==1930
	local xmean_ = r(mean)
	local xsd_ = r(sd)

	quietly sum `a' if year==1930 & (outlay_24_29_q==1 | outlay_24_29_q==2)
	local xmean_2 = r(mean)
	local xsd_2 = r(sd)
	
	gen test = `a'
	
	foreach v of varlist real_pc_outlay{
	
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if ~missing(outlay_24_29_q), absorb(id_ year) cl(id_)
		eststo 
		
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if outlay_24_29_q<=2 & ~missing(outlay_24_29_q), absorb(id_ year) cl(id_)
		eststo 
		

				ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if outlay_24_29_q>=3 & ~missing(outlay_24_29_q), absorb(id_ year) cl(id_)
		eststo 
		
		
		
	
	}
	
	drop test
}
	

	
	
#delimit ;
coefplot (est1, aseq(1) bcolor(black) ciopts(lcolor(black) recast(rcap)))
(est2, aseq(2) bcolor(green) ciopts(lcolor(green) recast(rcap))) 
(est3, aseq(3) bcolor(red) ciopts(lcolor(red) recast(rcap))) 
, 
vertical recast(bar)
keep(*3.post*#c.test*
*4.post*#c.test*
*5.post*#c.test*
)
graphregion(color(white))
omitted baselevels
yline(0)
xline(4, lp(dash))
xline(8, lp(dash))
aseq swapnames
ciopts(recast(rcap))
levels(90)
barwidth(0.25) finten(30)
citop
ylab(,angle(45))
legend(order (1 "Base" 3 "Cities with below median 1924-1929 capital outlay" 5 "Cities with above median 1924-1929 capital outlay"))
legend(rows(3) size(small))
legend(position(6))
ysc(range(-0.5(0.04)0.2))
ylab(-0.5(0.04)0.2,angle(0))
xlab("")
groups(4.post_detail#c.test="sds")
eqlabels("1929-1933" "1934-1938" "1941-1943")
nolabels
title("Outcome: capital outlay", size(medium))
;
#delimit cr


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
graph export did_demand_outlay.png, replace


	
////////////////////////////////////////////////////////////////
////////// Figure VIII: Excluding low-demand cities/////////
////////// Panel B. City Age /////////
//////////////////////////////////////////////////////////////



eststo clear
foreach a in bonds_to_assess29_lev_std{

	quietly sum city_age if year==1930, d
	local med_city_age = r(p50)	
	
	gen test = `a'
	
	foreach v of varlist real_pc_outlay{
	
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if ~missing(city_age), absorb(id_ year) cl(id_)
		eststo 
		
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if city_age>`med_city_age' & ~missing(city_age), absorb(id_ year) cl(id_)
		eststo 
		
		
			ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if city_age<=`med_city_age' & ~missing(city_age), absorb(id_ year) cl(id_)
		eststo 
		
		
	
	}
	
	drop test
}
	

#delimit ;
coefplot (est1, aseq(1) bcolor(black) ciopts(lcolor(black) recast(rcap)))
(est2, aseq(2) bcolor(green) ciopts(lcolor(green) recast(rcap))) 
(est3, aseq(3) bcolor(red) ciopts(lcolor(red) recast(rcap))) 
, 
vertical recast(bar)
keep(*3.post*#c.test*
*4.post*#c.test*
*5.post*#c.test*
)
graphregion(color(white))
omitted baselevels
yline(0)
xline(4, lp(dash))
xline(8, lp(dash))
aseq swapnames
ciopts(recast(rcap))
levels(90)
barwidth(0.25) finten(30)
citop
ylab(,angle(45))
legend(order (1 "Base" 3 "Cites of below median age" 5 "Cities of above median age"))
legend(rows(3) size(small))
legend(position(6))
ysc(range(-0.5(0.04)0.06))
ylab(-0.5(0.04)0.06,angle(0))
xlab("")
eqlabels("1929-1933" "1934-1938" "1941-1943")
nolabels
title("Outcome: capital outlay", size(medium))
;
#delimit cr



cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
graph export did_demand_age.png, replace



	
////////////////////////////////////////////////////////////////
////////// Figure VIII, C /////////
//////////////////////////////////////////////////////////////


eststo clear
xtset id_ year
foreach a in bonds_to_assess29_lev_std{

	quietly sum WPA_pc if year==1930, d
	local med_wpa = r(p50)	
	
	quietly sum RFC_pc if year==1930, d
	local med_rfc = r(p50)	
	
	gen test = `a'
	
	foreach v of varlist real_pc_outlay{
	
		ppmlhdfe  `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if ~missing(WPA_pc), absorb(id_ year) cl(id_)
		eststo 
		
		
		ppmlhdfe `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if WPA_pc <= `med_wpa', absorb(id_ year) cl(id_)
		eststo 
		
		
		ppmlhdfe `v' ib2.post_detail##c.test ib1928.year c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log i.year#i.region_ if RFC_pc <= `med_rfc', absorb(id_ year) cl(id_)
		eststo 
		
	
	}
	
	drop test
}
	

#delimit ;
coefplot (est1, aseq(1) bcolor(black) ciopts(lcolor(black) recast(rcap)))
(est2, aseq(2) bcolor(green) ciopts(lcolor(green) recast(rcap))) 
(est3, aseq(3) bcolor(red) ciopts(lcolor(red) recast(rcap)))
, 
vertical recast(bar)
keep(*3.post*#c.test*
*4.post*#c.test*
*5.post*#c.test*
)
graphregion(color(white))
omitted baselevels
yline(0)
xline(4, lp(solid))
xline(8, lp(solid))
aseq swapnames
ciopts(recast(rcap))
levels(90)
barwidth(0.25) finten(30)
citop
ylab(,angle(45))
legend(order (1 "Base" 3 "Cites with below median WPA" 5 "Cities with below median RFC"))
legend(rows(3) size(small))
legend(position(6))
ysc(range(-0.5(0.04)0.06))
ylab(-0.5(0.04)0.06,angle(0))
nooffsets
xlab("")
groups(4.post_detail#c.test="sds")
eqlabels("1929-1933" "1934-1938" "1941-1943")
title("Outcome: capital outlay", size(medium))
;
#delimit cr


cd "~/Dropbox/Public Goods Under Financial Distress/Paper/Figures/"
graph export did_demand_newdeal.png, replace


