## 04_clean_nvdrs_variables.R - Clean and Prepare NVDRS Variables
## IPV-Related Suicide Classifier
## Purpose: Clean and format NVDRS administrative variables for the classifier

#' Clean NVDRS variables for IPV classifier
#' @param nvdrs_data NVDRS dataframe (single suicides only)
#' @return Cleaned NVDRS dataframe with formatted variables
clean_nvdrs_variables <- function(nvdrs_data) {
  
  cat("Cleaning NVDRS administrative variables...\n")
  
  # Define census regions
  NE <- c("Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont",
          "New Jersey", "New York", "Pennsylvania")
  
  MW <- c("Illinois", "Indiana", "Michigan", "Ohio", "Wisconsin",
          "Iowa", "Kansas", "Minnesota", "Missouri", "Nebraska", "North Dakota", "South Dakota")
  
  S <- c("Delaware", "Florida", "Georgia", "Maryland", "North Carolina", "South Carolina", 
         "Virginia", "District of Columbia", "West Virginia", "Alabama", "Kentucky", 
         "Mississippi", "Tennessee", "Arkansas", "Louisiana", "Oklahoma", "Texas")
  
  W <- c("Arizona", "Colorado", "Idaho", "Montana", "Nevada", "New Mexico", "Utah", "Wyoming",
         "Alaska", "California", "Hawaii", "Oregon", "Washington")
  
  # Clean and format variables
  nvdrs_clean <- nvdrs_data %>%
    mutate(
      # Ensure ID variable exists
      id = paste(siteid, incidentyear, incidentid, personid, sep = "-"),
      state = siteid,
      
      # Narrative length
      n_narr_len = stringi::stri_width(paste(narrativecme, narrativele)),
      
      # Demographics - sex
      vdrs_demog_male = ifelse(sex == "Male", 1, 0),
      vdrs_demog_female_SUMM = ifelse(sex == "Female", 1, 0),
      vdrs_demog_gender_SUMM = ifelse(sex == "Male", "Men", "Women"),
      
      # Demographics - age
      vdrs_demog_age = suppressWarnings(as.numeric(ageyears_c)),
      vdrs_demog_age = ifelse(vdrs_demog_age > 100, 100, vdrs_demog_age),
      vdrs_demog_age_grp_SUMM = case_when(
        vdrs_demog_age < 10 ~ "<10 yrs",
        vdrs_demog_age >= 10 & vdrs_demog_age <= 24 ~ "10-24 yrs",
        vdrs_demog_age >= 25 & vdrs_demog_age <= 40 ~ "25-40 yrs",
        vdrs_demog_age >= 41 & vdrs_demog_age <= 54 ~ "41-54 yrs",
        vdrs_demog_age >= 55 & vdrs_demog_age <= 70 ~ "55-70 yrs",
        vdrs_demog_age >= 71 ~ "71+ yrs"
      ),
      
      # Demographics - race/ethnicity
      vdrs_demog_race_eth_SUMM = case_when(
        raceethnicity_c == "White, non-Hispanic" ~ "White (NH)",
        raceethnicity_c == "Black or African American, non-Hispanic" ~ "Black (NH)",
        raceethnicity_c == "American Indian/Alaska Native, non-Hispanic" ~ "AI/AN (NH)",
        raceethnicity_c == "Asian/Pacific Islander, non-Hispanic" ~ "Asian (NH)",
        raceethnicity_c == "Hispanic" ~ "Hispanic",
        raceethnicity_c %in% c("Two or more races, non-Hispanic",
                               "Unknown race, non-Hispanic",
                               "Other/Unspecified, non-Hispanic") ~ "Other/unknown (NH)"
      ),
      vdrs_demog_race_eth_white = ifelse(vdrs_demog_race_eth_SUMM == "White (NH)", 1, 0),
      vdrs_demog_race_eth_black = ifelse(vdrs_demog_race_eth_SUMM == "Black (NH)", 1, 0),
      vdrs_demog_race_eth_aian = ifelse(vdrs_demog_race_eth_SUMM == "AI/AN (NH)", 1, 0),
      vdrs_demog_race_eth_asian = ifelse(vdrs_demog_race_eth_SUMM == "Asian (NH)", 1, 0),
      vdrs_demog_race_eth_hisp = ifelse(vdrs_demog_race_eth_SUMM == "Hispanic", 1, 0),
      vdrs_demog_race_eth_other_unk = ifelse(vdrs_demog_race_eth_SUMM == "Other/unknown (NH)", 1, 0),
      
      # Demographics - marital status
      vdrs_demog_mar_SUMM = maritalstatus,
      vdrs_demog_mar_married = ifelse(maritalstatus == "Married/Civil Union/Domestic Partnership", 1, 0),
      vdrs_demog_mar_sep = ifelse(maritalstatus == "Married/Civil Union/Domestic Partnership, but separated", 1, 0),
      vdrs_demog_mar_never_or_single = ifelse(maritalstatus %in% c("Never Married", "Single, not otherwise specified"), 1, 0),
      vdrs_demog_mar_widow = ifelse(maritalstatus == "Widowed", 1, 0),
      vdrs_demog_mar_divorced = ifelse(maritalstatus == "Divorced", 1, 0),
      
      # Demographics - educational attainment
      vdrs_demog_educ_SUMM = educationlevel,
      vdrs_demog_educ_hs_less = ifelse(educationlevel %in% c("8th grade or less", "9th to 12th grade, no diploma"), 1, 0),
      vdrs_demog_educ_hs = ifelse(educationlevel == "High school graduate or GED completed", 1, 0),
      vdrs_demog_educ_bs = ifelse(educationlevel == "Bachelor's degree", 1, 0),
      vdrs_demog_educ_asc_or_somecollg = ifelse(educationlevel %in% c("Associate's degree", "Some college credit, but no degree"), 1, 0),
      vdrs_demog_educ_more = ifelse(educationlevel %in% c("Doctorate or Professional degree", "Master's degree"), 1, 0),
      
      # Demographics - other
      vdrs_demog_military = ifelse(military == "Yes", 1, 0),
      vdrs_demog_pregnant = case_when(
        pregnant %in% c("Pregnant at time of death", 
                       "Pregnant, not otherwise specified",
                       "Not pregnant but pregnant w/in 42 days of death",
                       "Not pregnant but pregnant 43 days to 1 year before death") ~ 1,
        TRUE ~ 0
      ),
      vdrs_demog_sexorent = ifelse(sexualorientation %in% c("Lesbian", "Gay", "Bisexual", "Unspecified sexual minority"), 1, 0),
      vdrs_demog_trans = ifelse(transgender == "Yes", 1, 0),
      
      # Incident year variables (for model compatibility)
      yr_2010 = ifelse(incidentyear == 2010, 1, 0),
      yr_2011 = ifelse(incidentyear == 2011, 1, 0),
      yr_2012 = ifelse(incidentyear == 2012, 1, 0),
      yr_2013 = ifelse(incidentyear == 2013, 1, 0),
      yr_2014 = ifelse(incidentyear == 2014, 1, 0),
      yr_2015 = ifelse(incidentyear == 2015, 1, 0),
      yr_2016 = ifelse(incidentyear == 2016, 1, 0),
      yr_2017 = ifelse(incidentyear == 2017, 1, 0),
      yr_2018 = ifelse(incidentyear == 2018, 1, 0),
      
      # Incident manner
      vdrs_incd_manner_SUMM = case_when(
        abstractordeathmanner_c %in% c("Suicide or intentional self-harm", "Terrorism suicide") ~ "Suicide",
        abstractordeathmanner_c %in% c("Homicide", "Terrorism homicide") ~ "Homicide",
        abstractordeathmanner_c == "Undetermined intent" ~ "Undetermined",
        str_detect(abstractordeathmanner_c, "Unintentional") == TRUE ~ "Unintentional",
        abstractordeathmanner_c == "Legal intervention (by police or other authority)" ~ "Legal intv",
        TRUE ~ "Other/missing"
      ),
      
      # Incident location
      vdrs_incd_home = ifelse(injuredatvictimhome == "Yes", 1, 0),
      
      # Weapon type
      vdrs_weap_SUMM = case_when(
        weapontype1 == "Firearm" ~ "Firearm",
        weapontype1 == "Sharp instrument" ~ "Sharp instrument",
        weapontype1 == "Hanging, strangulation, suffocation" ~ "Hanging, strangulation, suffocation",
        weapontype1 == "Fall" ~ "Fall",
        weapontype1 == "Poisoning" ~ "Poisoning",
        TRUE ~ "Other"
      ),
      vdrs_weap_firearm = ifelse(weapontype1 == "Firearm", 1, 0),
      vdrs_weap_fall = ifelse(weapontype1 == "Fall", 1, 0),
      vdrs_weap_sharp = ifelse(weapontype1 == "Sharp instrument", 1, 0),
      vdrs_weap_hang = ifelse(weapontype1 == "Hanging, strangulation, suffocation", 1, 0),
      vdrs_weap_poison = ifelse(weapontype1 == "Poisoning", 1, 0),
      
      # Life circumstances and mental/behavioral health
      vdrs_life_crisis = ifelse(anycrisis_c == "Yes", 1, 0),
      vdrs_mh_curr = ifelse(mentalhealthproblem_c == "Yes", 1, 0),
      vdrs_mh_dep = ifelse(depressedmood_c == "Yes", 1, 0),
      vdrs_mh_tx_curr = ifelse(mentalillnesstreatmentcurrnt_c == "Yes", 1, 0),
      vdrs_mh_tx_ever = ifelse(historymentalillnesstreatmnt_c == "Yes", 1, 0),
      vdrs_bh_alc = ifelse(alcoholproblem_c == "Yes", 1, 0),
      vdrs_bh_su = ifelse(substanceabuseother_c == "Yes", 1, 0),
      vdrs_bh_other = ifelse(otheraddiction_c == "Yes", 1, 0),
      vdrs_life_crime = ifelse(precipitatedbyothercrime_c == "Yes", 1, 0),
      vdrs_life_stalk = ifelse(stalking_c == "Yes", 1, 0),
      vdrs_life_argue = ifelse(argument_c == "Yes", 1, 0),
      vdrs_life_fight = ifelse(fightbetweentwopeople_c == "Yes", 1, 0),
      vdrs_viol_perp = ifelse(interpersonalviolenceperp_c == "Yes", 1, 0),
      vdrs_viol_vict = ifelse(interpersonalviolencevictim_c == "Yes", 1, 0),
      vdrs_hist_ca = ifelse(abusedaschild_c == "Yes", 1, 0),
      vdrs_relat_fam = ifelse(familyrelationship_c == "Yes", 1, 0),
      vdrs_relat_notip = ifelse(relationshipproblemother_c == "Yes", 1, 0),
      vdrs_tox = numbersubstances_c,
      
      # Suicide-specific variables
      vdrs_suic_note = ifelse(suicidenote_c == "Yes", 1, 0),
      vdrs_suic_disclose = ifelse(suicideintentdisclosed_c == "Yes", 1, 0),
      vdrs_suic_disclose_ipp = ifelse(disclosedtointimatepartner_c == "Yes", 1, 0),
      vdrs_suic_hist_attmpt = ifelse(suicideattempthistory_c == "Yes", 1, 0),
      vdrs_suic_hist_thought = ifelse(suicidethoughthistory_c == "Yes", 1, 0),
      vdrs_relat_ipp = ifelse(intimatepartnerproblem_c == "Yes", 1, 0),
      vdrs_relat_ipp_c = ifelse(crisisintimatepartnerproblem_c == "Yes", 1, 0),
      vdrs_legal_crim = ifelse(recentcriminallegalproblem_c == "Yes", 1, 0),
      vdrs_legal_other = ifelse(legalproblemother_c == "Yes", 1, 0),
      vdrs_famfrd_death = ifelse(deathfriendorfamilyother_c == "Yes", 1, 0),
      vdrs_famfrd_suic = ifelse(recentsuicidefriendfamily_c == "Yes", 1, 0),
      vdrs_hist_anniv = ifelse(traumaticanniversary_c == "Yes", 1, 0),
      vdrs_life_physhealth = ifelse(physicalhealthproblem_c == "Yes", 1, 0),
      vdrs_life_job = ifelse(jobproblem_c == "Yes", 1, 0),
      vdrs_life_financ = ifelse(financialproblem_c == "Yes", 1, 0),
      vdrs_life_evict = ifelse(evictionorlossofhome_c == "Yes", 1, 0),
      vdrs_life_school = ifelse(schoolproblem_c == "Yes", 1, 0),
      
      # IPV-related variable
      vdrs_ipv_jeal = ifelse(intimatepartnerviolence_c == "Yes" | jealousy_c == "Yes", 1, 0)
    )
  
  # Add region variables
  nvdrs_clean <- nvdrs_clean %>%
    mutate(
      vdrs_incd_region_SUMM = case_when(
        state %in% NE ~ "Northeast",
        state %in% MW ~ "Midwest",
        state %in% S ~ "South",
        state %in% W ~ "West",
        TRUE ~ "Trrty/Unk"
      ),
      vdrs_incd_reg_NE = ifelse(state %in% NE, 1, 0),
      vdrs_incd_reg_MW = ifelse(state %in% MW, 1, 0),
      vdrs_incd_reg_S = ifelse(state %in% S, 1, 0),
      vdrs_incd_reg_W = ifelse(state %in% W, 1, 0)
    )
  
  # Keep only variables of interest
  nvdrs_clean <- nvdrs_clean %>% 
    select(id, state, incidentyear, incidentid, personid, 
           narrativecme, narrativele, n_narr_len, 
           starts_with("vdrs_"), starts_with("yr_"))
  
  # Sort variables alphabetically
  nvdrs_clean <- nvdrs_clean %>% 
    select(sort(names(.)))
  
  cat("NVDRS variables cleaned successfully!\n")
  cat("Total variables:", ncol(nvdrs_clean), "\n")
  
  return(nvdrs_clean)
}

#' Get required NVDRS variables for classifier
#' @return Character vector of required variable names
get_required_nvdrs_variables <- function() {
  
  # List of NVDRS variables required for the classifier
  # These should be included in your NVDRS RAD request
  required_vars <- c(
    "siteid", "incidentyear", "incidentid", "personid",
    "narrativecme", "narrativele",
    "sex", "ageyears_c", "raceethnicity_c", "maritalstatus",
    "educationlevel", "military", "pregnant", "sexualorientation", "transgender",
    "abstractordeathmanner_c", "injuredatvictimhome", "weapontype1",
    "anycrisis_c", "mentalhealthproblem_c", "depressedmood_c",
    "mentalillnesstreatmentcurrnt_c", "historymentalillnesstreatmnt_c",
    "alcoholproblem_c", "substanceabuseother_c", "otheraddiction_c",
    "precipitatedbyothercrime_c", "stalking_c", "argument_c",
    "fightbetweentwopeople_c", "interpersonalviolenceperp_c",
    "interpersonalviolencevictim_c", "abusedaschild_c",
    "familyrelationship_c", "relationshipproblemother_c",
    "numbersubstances_c", "suicidenote_c", "suicideintentdisclosed_c",
    "disclosedtointimatepartner_c", "suicideattempthistory_c",
    "suicidethoughthistory_c", "intimatepartnerproblem_c",
    "crisisintimatepartnerproblem_c", "recentcriminallegalproblem_c",
    "legalproblemother_c", "deathfriendorfamilyother_c",
    "recentsuicidefriendfamily_c", "traumaticanniversary_c",
    "physicalhealthproblem_c", "jobproblem_c", "financialproblem_c",
    "evictionorlossofhome_c", "schoolproblem_c",
    "intimatepartnerviolence_c", "jealousy_c",
    "incidentcategory_c"  # For filtering single suicides
  )
  
  return(required_vars)
}