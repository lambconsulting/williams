


libname ashlyn "U:\Consulting\KEL\Fox\Williams\Data";

/*data ashlyn.ashlyn_20200416(drop=age_yrs_dx); set RENAL_LSA_PFOX_20200416_KL3; age = age_yrs_dx*1; run;*/
/* Data refresh 20200710 */
/*data ashlyn.ashlyn_20200710(drop=age_yrs_dx); set williams_output_20200416_11_20200702; run;*/


/*data ashlyn ashlyn_trt; set ashlyn.ashlyn_20200416 (rename=age=age_yrs_dx); */
data ashlyn ashlyn_trt; set ashlyn.ashlyn_20200710; 
output ashlyn;
if l_s not in (" ") then output ashlyn_trt;
run;



*** KM Anlaysis with strata;
%macro surv(ds,mod_num,research_q,iv,e,dv,e_problem,series);
proc lifetest data= &ds. plots=survival censoredsymbol=none outsurv=s;
time &dv.*&e.(0);
%if &iv. ne " " %then %do;
strata &iv.;
ods output Quartiles = q HomTests = p;
%end;
run;
%if &iv. ne " " %then %do;
data p (rename=probchisq = p_value); set p (keep=test probchisq); where test = "Log-Rank"; 
mergeme = 1; run;
data q (drop=&iv.); set q (drop=transform stratum);
research_q = "&research_q."; mod_num = "&mod_num."; iv_level = left(trim(put(&iv.,5.0))); 
iv = "&iv."; dv = "&dv."; pop = "&ds."; 
mergeme = 1; 
event_problem = &e_problem.;
run;
data pq_&mod_num.; merge p q; by mergeme; run;
data all_km (drop=mergeme); length pop research_q iv dv mod_num $50.; 
retain pop research_q mod_num iv dv; set all_km pq_&mod_num.; run;
data s1 (rename = (&dv. = t)); length series research_q event mod $30.; retain series research_q event mod ; set s;
series = "&series"; mod = "&mod_num."; research_q = "&research_q."; event = "&e.";
data s_all; set s_all s1; run;
%end;
%mend;

data all_km; set _null_; data s_all; set _null_;  run;


%surv(ashlyn_trt,1,1A,l_s,e,t,0,original);
%surv(ashlyn_trt,2,2A,male,e,t,0,original);
%surv(ashlyn,2,2b,male,e,t,0,original);
%surv(ashlyn_trt,3,3A,,e,t,0,original);
%surv(ashlyn,3,3B,,e,t,0,original);
%surv(ashlyn_trt,4,4A,renal,e,t,0,original);
%surv(ashlyn,4,4B,renal,e,t,0,original);
/* Additional Data Refresh 20200711 */
%surv(ashlyn,5,5B,azo_dx,e,t,0,original);
%surv(ashlyn,6,6B,anemia_dx,e,t,0,original);





/* Does one drive the other? */
proc corr data=ashlyn;
var creat_dx hct_dx;
run;

proc freq data=ashlyn;
tables l_s * male / chisq;
run;

proc mixed data=ashlyn;
class l_s;
model age_yrs_dx = l_s;
lsmeans l_s / pdiff=all;
run;