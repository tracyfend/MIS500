/*****************************************************************************/
/* Prescribed drugs, 2016
/*
/* Purchases and expenditures by Multum therapeutic class name
/*
/* Example SAS code to replicate the following estimates in the MEPS-HC summary
/*  tables by Multum therapeutic class:
/*  - Number of people with purchase
/*  - Total purchases
/*  - Total expenditures
/*
/* Input file: C:\MEPS\h188a.ssp (2016 RX event file)
/*****************************************************************************/

ods graphics off;																/* ods = output delivery system, turning graphics off with keep statistical procedures from producing graphs */

/* Load datasets ************************************************************/
/* For 1996-2013, need to merge RX event file with Multum Lexicon Addendum  */
/*  file to get therapeutic class categories and generic drug names         */

/* Load RX file */
FILENAME h188a "/folders/myfolders/MEPS/data/h188a.ssp";						/* Associates a SAS fileref with an external file */
proc xcopy in = h188a out = WORK IMPORT;										/* XCOPY will read a SAS transport file and convert the data to regular SAS format */
run;

/* Aggregate to person-level ***********************************************/

/* Remove missing drug names */
data RX;																		/* The DATA statement starts a SAS data set and names the data set, RX */
	set h188a;																	/* reads all variables and all observations from h188a */ 
	where RXNDC ne "-9" and RXDRGNAM ne "-9";									/* excludes the lines where RXNDC(National drug code) or RXDRGNAM = -9, -9 = NOT ASCERTAINED, did not record the data */
run;

proc sort data = RX;															/* sort the data, RX, created in the previous step */
	by DUPERSID VARSTR VARPSU PERWT16F RXDRGNAM;								/* first sorts by DUPERSID, then by VARSTR, then by VARPSU, then by PERWT16F, then by RXDRGNAM */
run;

proc means data = RX noprint;													/* Computes descriptive statistics for variables, noprint suppresses the output */
	by DUPERSID VARSTR VARPSU PERWT16F RXDRGNAM;								/* Produces separate statistics for each BY group */
	var RXXP16X;																/* identifies the analysis variables and specifies their order in the results */
	output out = RX_pers sum = pers_RXXP n = n_purchases;						/* Names the new output data set */
run;

data RX_pers;																	/* The DATA statement starts a SAS data set and names the data set, RX_pers */
	set RX_pers;																/* reads all variables and all observations from RX_pers, from the previous proc step */ 
	person = 1;																	/* adds a new variable to the dataset */
run;

/* Calculate estimates using survey procedures *******************************/

ods output Domain = out;														/* output-object-name=data-set-name */
proc surveymeans data = RX_pers sum;											/* This procedure estimates statistics from a survey sample */
	stratum VARSTR;																/* This specifies the stratum variable (this is listed in the h188a doc) */
	cluster VARPSU;																/* This specifies the cluster variable */ 
	weight PERWT16F;															/* Names the variable containing the sampling weights */
	var person n_purchases pers_RXXP;											/* These are the variables to analyze */
	domain RXDRGNAM;															/* This requests an analysis of the subdomain RXDRGNAM(prescription drug name) */
run;

/* Number of people with purchase */
proc print data = out noobs label;												/* Print statement, data=SAS-data-set, noobs removes the column with the observation number, label = use the variable as column header */
	label Sum = "Number of people with purchase" ;								/* Replace the sum column with this label */
	where VarName = "person";													/* Only selects observations where VarName = "person" */
	var RXDRGNAM Sum StdDev;													/* Selects the columns to print */
run;

/* Number of purchases */
proc print data = out noobs label;												/* Print statement, data=SAS-data-set, noobs removes the column with the observation number, label = use the variable as column header */
	label Sum = "Number of purchases" ;											/* Replace the sum column with this label */
	where VarName = "n_purchases";												/* Only selects observations where VarName = "n_purchases" */
	var RXDRGNAM Sum StdDev;													/* Selects the columns to print */
run;

/* Total expenditures */
proc print data = out noobs label;												/* Print statement, data=SAS-data-set, noobs removes the column with the observation number, label = use the variable as column header */
	label Sum = "Total expenditures" ;											/* Replace the sum column with this label */
	where VarName = "pers_RXXP";												/* Only selects observations where VarName = "pers_RXXP" */
	var RXDRGNAM Sum StdDev;													/* Selects the columns to print */
run;

/* Add code to generate SAS summary statistics */
proc summary data = RX_pers sum;												/* This procedure estimates statistics from a survey sample */
	weight PERWT16F;															/* Names the variable containing the sampling weights */
	var person n_purchases pers_RXXP;											/* These are the variables to analyze */
	output out = summary_out;
run;

/* Add code to generate Hypotheses for a two-sample t test */
data DRUGS;																		/* The DATA statement starts a SAS data set and names the data set, RX_pers */
	set RX;																		/* Uses the RX data struct */
	where RXMR16X > 0 or RXMD16X > 0;											/* only chooses entries that have a medicaid or medicare price */
run;

proc sort data = DRUGS;															/* sort the data, RX, created in the previous step */
	by RXDRGNAM;																/* sorts by RXDRGNAM */
run;



