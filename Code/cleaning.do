* Programmer: Maxwell Cozean
* Created: March 20th, 2024

*------------------------------------------------------------------------------*

clear all

* Define working directory
cd "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Raw/SDEMT" 
// REPLACE WITH DIRECTORY WHERE RAW FILES ARE STORED

* Create local macro for all .dta files in SDEMT folder
local files : dir . files "*.dta"

* Initiate loop through annual surveys
foreach file of local files {
	
	clear all
	
	* Define working directory
	cd "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Raw/SDEMT"
	
	* Use file
	use "`file'", clear
	
	* Define scalar representing year of survey from file name
	scalar year = substr("`file'", strpos("`file'", "2"), 4)
	
	* Create local macro for basename of file (without .dta extension)
	local basename: di substr("`file'", 1, strpos("`file'", ".dta") - 1)
	
	* Generate and label variable for year
	gen anio = year
	label var anio "Anio"
	
	* Destring year variable and replace
	destring(anio), replace
	
	* Keep select variables for analysis
	keep ent sex eda nac_dia nac_mes nac_anio ur anios_esc hrsocup ing_x_hrs anio
	
	* Keep full-time workers (30 <= weekly hours <= 90)
	drop if hrsocup >= 30 & hrsocup <= 90
	drop hrsocup // no longer need weekly hours variable
	
	* Generate variable for log(ing_x_hrs)
	gen log_ing_x_hrs = log(ing_x_hrs + 1) 
	label var log_ing_x_hrs "Log of Hourly Wages"
	
	* Label years of schooling variable
	label var anios_esc "Years of Schooling"
	
	* Reorder variables
	order anio ent sex eda nac_dia nac_mes nac_anio ur anios_esc
	
	* Change directory
	cd "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Cleaned Surveys"
	// REPLACE WITH DIRECTORY WHERE CLEANED SURVEYS ARE TO BE STORED
	
	* Save cleaned survey
	save "`basename'_cleaned.dta", replace
}

*------------------------------------------------------------------------------*

* Set working directory
cd "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master/Cleaned Surveys"
// REPLACE WITH DIRECTORY WHERE CLEANED SURVEYS ARE STORED

* Create local macro for all .dta files in cleaned surveys folder
local files : dir . files "*.dta"

* Create an empty dataset to start fresh
clear

* Loop through the list of surveys and append them one by one
foreach file in `files' {
    append using "`file'"
}

* Change directory
cd "/Users/maxwellcozean/Desktop/EDUC 1765 Final Project/Master"
// REPLACE WITH DIRECTORY WHERE SURVEY PANELS IS TO BE STORED

* Sort by year
sort anio

* Drop missing observations
drop if missing(ent) | missing(sex) | missing(eda) | missing(ur) | missing(anios_esc)
		
* Summarize and tabulate anios_esc variable
sum anios_esc, detail

* Drop if anios_esc == 99 (missing)
drop if anios_esc == 99 | nac_anio == 9999

* Drop missing birth year, month, and day observations
drop if nac_anio == 99 | nac_mes == 99 | nac_dia == 99

rename sex sex_1 // rename gender indicator
gen sex = sex_1 == 2 // generate new indicator	
label var sex "Sexo" // label variable
// sex = 1 if hombre and 2 if mujer
drop sex_1 // no longer need sex_1

rename ur ur_1 // rename urban/rural indicator
gen ur = ur_1 == 2 // generate new indicator
label var ur "Urbano/Rural" // label variable
// ur = 1 if urbano and 2 if rural
drop ur_1 // no longer need ur_1

* Reorder variables
order anio ent sex eda nac_dia nac_mes nac_anio ur anios_esc

* Save master file
save "survey_panel.dta", replace

*------------------------------------------------------------------------------*
