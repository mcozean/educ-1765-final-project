* Programmer: Maxwell Cozean
* Created: March 20th, 2024

*------------------------------------------------------------------------------*

* Defining treatment and control groups

clear all

* Define working directory
cd "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master"
// REPLACE WITH DIRECTORY WHERE SURVEY PANEL IS STORED

* Use cleaned survey panel 
use "survey_panel.dta", clear

* Generate dummy variable for born post-September 1998
gen sept = (nac_anio == 1997) & (nac_mes >= 9)

* Generate binary treatment variable
gen treat = nac_anio > 1997 | sept
// T = 1 if born post-September 1997
// 2012 - 15 = 1997, exposed to compulsory schooling until age 18
// Treatment: individuals aged 15 or younger at time of reform
drop sept // no longer need sept variable

* Generate new sept variable
gen sept = (nac_anio == 2002) & (nac_mes >= 9)
// Indicates if individual was post-September in 2002
// Identifes individuals impacted by the COVID-19 pandemic

* Drop individuals born post-September 1st, 2002
drop if nac_anio > 2002 | sept // use sept variable
drop sept // no longer need sept variable

* Tabulate eda and treatment dummy
tab eda treat

* Drop if year < 18 or year > 26
drop if eda < 18 | eda > 26
// define age range

* Tabulate anios_esc and treatment dummy
tab anios_esc
tab anios_esc treat

* Tabulate survey year and treatment dummy
tab anio treat

* Drop survey years < 2016
drop if anio < 2016
// Years where treatment and control both exist

*------------------------------------------------------------------------------*

* Decode region and create temporary variable
decode ent, gen(ent_1)
// drop ent // no longer need ent variable

* Create birth region dummy following Leon-Bravo (2012)
gen region = 1 if ent_1 == "Chiapas" | ent_1 == "Guerrero" | ent_1 == "Oaxaca"
replace region = 2 if ent_1 == "Campeche" | ent_1 == "Hidalgo" | ent_1 == "Puebla" | ///
					  ent_1 == "San Luis Potosí" | ent_1 == "Tabasco" | ent_1 == "Veracruz de Ignacio de la Llave"
replace region = 3 if ent_1 == "Durango" | ent_1 == "Guanajuato" | ent_1 == "Michoacán de Ocampo" | ///
					  ent_1 == "Tlaxcala" | ent_1 == "Zacatecas"
replace region = 4 if ent_1 == "Colima" | ent_1 == "México" | ent_1 == "Morelos" | ///
					  ent_1 == "Nayarit" | ent_1 == "Querétaro" | ent_1 == "Quintana Roo" | ///
					  ent_1 == "Sinaloa" | ent_1 == "Yucatán"
replace region = 5 if ent_1 == "Baja California" | ent_1 == "Baja California Sur" | ///
				      ent_1 == "Chihuahua" | ent_1 == "Sonora" | ent_1 == "Tamaulipas"
replace region = 6 if ent_1 == "Aguascalientes" | ent_1 == "Coahuila de Zaragoza" | ent_1 == "Jalisco" | ///
					  ent_1 == "Nuevo León"
replace region = 7 if ent_1 == "Ciudad de México"
drop ent_1 // no longer need ent_1 variable
order region, after(anio) // reorder variables

sum anio if treat // summarize survey year for treat
sum anio if !treat // summarize survey year for control
sum anio // summarize survey year for the full sample
sum anio, detail // summarize survey year in detail

* Generate survey year dummy variables
replace anio = 1 if anio == 2016
replace anio = 2 if anio == 2017
replace anio = 3 if anio == 2018
replace anio = 4 if anio == 2019
replace anio = 5 if anio == 2020
replace anio = 6 if anio == 2021
replace anio = 7 if anio == 2022
replace anio = 8 if anio == 2023

*------------------------------------------------------------------------------*

* Summary statistics

* Summary statistics for the full sample
eststo summstats: estpost summarize sex eda ur anios_esc log_ing_x_hrs

* Summary statistics for the treatment group 
eststo treatment: estpost summarize sex eda ur anios_esc log_ing_x_hrs if treat

* Summary statistics for the control group
eststo control: estpost summarize sex eda ur anios_esc log_ing_x_hrs if !treat

* Generate and export table of summary statistics
esttab summstats treatment control using ///
"/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Output/summarystatistics.rtf", ///
replace main(mean %6.2f) aux(sd) mtitle("Full sample" "Treatment" "Control")
// REPLACE WITH DIRECTORY WHERE OUTPUT IS STORED

*------------------------------------------------------------------------------*

* Treatment/control histograms for key outcome variables
* Generate histograms for anios_esc by treatment and control
twoway (histogram anios_esc if treat, start(0) width(1) color(red%30)) ///        
       (histogram anios_esc if !treat, start(0) width(1) color(blue%30)), ///   
       legend(order(1 "Treatment" 2 "Control"))
	   
* Export histogram
graph export "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Output/hist_yearsschooling.pdf", replace
// REPLACE WITH DIRECTORY WHERE OUTPUT IS STORED

* Generate histograms for log_salario by treatment and control
twoway (histogram log_ing_x_hrs if treat, start(0) width(1) color(red%30)) ///
       (histogram log_ing_x_hrs if !treat, start(0) width(1) color(blue%30)), ///
       legend(order(1 "Treatment" 2 "Control")) ///
	   
* Export histogram
graph export "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Output/hist_logwages.pdf", replace
// REPLACE WITH DIRECTORY WHERE OUTPUT IS STORED

*------------------------------------------------------------------------------*

* Running variable

* Generate running variable to measure birth (in months) relative to 1997 cutoff
gen birth_date = mdy(nac_mes, 1, nac_anio) // variable for birth date
gen cutoff_date = mdy(9, 1, 1997) // variable for cutoff date
gen months_distance = (year(birth_date) - year(cutoff_date)) * 12 + (month(birth_date) - month(cutoff_date)) // running variable
drop birth_date cutoff_date // no longer need variable for birth date and cutoff date

*------------------------------------------------------------------------------*

* Trim upper end of anios_esc variable
drop if anios_esc > 16
// Cutoff of anios_esc > 17 vs > 16 results in very
// different looking regression discontinuity plots
// anios_esc > 16 comprises < 4% of the sample

*------------------------------------------------------------------------------*

* Regressions

* (1) First stage: years of schooling
reg anios_esc treat months_distance, r // no covariates
predict years_of_schooling_hat_1, xb // predict years of schooling
reg anios_esc treat months_distance anio, r // add gender covariate
predict years_of_schooling_hat_2, xb // predict years of schooling
reg anios_esc treat months_distance anio region, r // add survey year covariate
predict years_of_schooling_hat_3, xb // predict years of schooling
reg anios_esc treat months_distance anio region ur, r // add birth region covariate
predict years_of_schooling_hat_4, xb // predict years of schooling
reg anios_esc treat months_distance anio region ur sex, r // add urban status covariate
predict years_of_schooling_hat_5, xb // predict years of schooling
//  regression of years of schooling on treatment, running variable, all covariates

* (2) Reduced-form: log of hourly wages
reg log_ing_x_hrs treat months_distance, r // no covariates
reg log_ing_x_hrs treat months_distance anio, r // add gender covariate
reg log_ing_x_hrs treat months_distance anio region, r // add survey year covariate
reg log_ing_x_hrs treat months_distance anio region ur, r // add birth region covariate
reg log_ing_x_hrs treat months_distance anio region ur sex, r // add urban status covariate
//  regression of log of hourly wages on treatment, running variable, all covariates

* (3) Second stage: log of hourly wages (years of schooling as an instrument)
reg log_ing_x_hrs years_of_schooling_hat_1 months_distance, r // no covariates
reg log_ing_x_hrs years_of_schooling_hat_2 months_distance anio, r // add gender covariate
reg log_ing_x_hrs years_of_schooling_hat_3 months_distance anio region, r // add survey year covariate
reg log_ing_x_hrs years_of_schooling_hat_4 months_distance anio region ur, r // add birth region covariate
reg log_ing_x_hrs years_of_schooling_hat_5 months_distance anio region ur sex, r // add urban status covariate

*------------------------------------------------------------------------------*

* Regression discontinuity plots

* (1) Years of schooling
rdplot anios_esc months_distance, p(2) binselect(es) graph_options(xlabel(-100(25)50) /// 
xtitle("Distance in Months from September 1st, 1997") ytitle("Years of Schooling"))

* Export graph
graph export "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Output/rdplot_yearsschooling.pdf", replace

* (2) Log of hourly wages
rdplot log_ing_x_hrs months_distance, p(2) binselect(es) graph_options(xlabel(-100(25)50) /// 
xtitle("Distance in Months from September 1st, 1997") ytitle("Log of Hourly Wages"))
// REPLACE WITH DIRECTORY WHERE OUTPUT IS STORED

* Export graph
graph export "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Output/rdplot_logwages.pdf", replace
// REPLACE WITH DIRECTORY WHERE OUTPUT IS STORED

*------------------------------------------------------------------------------*
