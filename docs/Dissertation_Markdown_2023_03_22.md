# Tool to detect IPV-related suicides in NVDRS

setup 3col/9col grid for toc_float and main content

# Tool to detect IPV-related suicides in
NVDRS

Tool to detect IPV-related suicides in
NVDRS

Julie M Kafka, PhD, MPH

Mar 12, 2022

# Overview

Overview

This code shows how to apply our SML tool (hereafter referred to as
“the IPV Classifier”) to suicide data in the National Violent Death
Reporting System (NVDRS). The IPV Classifier is designed to detect
whether suicide cases in NVDRS were precipitated by intimate partner
violence (IPV) or not (yes/no), using textual information from NVDRS
death narratives.

This code shows how to apply our SML tool (hereafter referred to as
“the IPV Classifier”) to suicide data in the National Violent Death
Reporting System (NVDRS). The IPV Classifier is designed to detect
whether suicide cases in NVDRS were precipitated by intimate partner
violence (IPV) or not (yes/no), using textual information from NVDRS
death narratives.

All you need to run the IPV Classifier is:

All you need to run the IPV Classifier is:

- Your copy of the NVDRS RAD file
Your copy of the NVDRS RAD file

- The Concept dataset (Rdata file)
The Concept dataset (Rdata file)

- The IPV Classifier model itself (Rdata file)
The IPV Classifier model itself (Rdata file)

The steps covered in this demo include:

The steps covered in this demo include:

- Load data

Load data

- Extract text-based variables

Use Textfeatures package for sentiment scores and grammatical
counts

Calculate concept scores


Extract text-based variables

- Use Textfeatures package for sentiment scores and grammatical
counts

Use Textfeatures package for sentiment scores and grammatical
counts

- Calculate concept scores

Calculate concept scores

- Clean existing NVDRS variables
Clean existing NVDRS variables

- Prepare the dataset

Prepare the dataset

- Apply IPV Classifier
Apply IPV Classifier

# 1. Load libraries & data

1. Load libraries & data

To start, we’ll be using a handful of different packages for data
management and text cleaning, so make sure those are loaded in.

To start, we’ll be using a handful of different packages for data
management and text cleaning, so make sure those are loaded in.

library(dplyr)
library(tidyverse)
library(stringr)
library(tidytext)

Load in your own NVDRS RAD file.

Load in your own NVDRS RAD file.

load(file = "RAD_2019_demo_010622.Rdata")

For this demo, we are just using 2019 data. You can run the IPV
Classifier using different years of data, but be aware that larger
datasets may take more time to process.

For this demo, we are just using 2019 data. You can run the IPV
Classifier using different years of data, but be aware that larger
datasets may take more time to process.

Run these quick data cleaning steps to get started. I like to set
variable names to lower case, organize the variables alphabetically, and
create a unique identifier for each row. In our case, the ID variable
will be unique for each decedent (dead person) in NVDRS.

Run these quick data cleaning steps to get started. I like to set
variable names to lower case, organize the variables alphabetically, and
create a unique identifier for each row. In our case, the ID variable
will be unique for each decedent (dead person) in NVDRS.

#set variable names to lower case
names(nvdrs) <-tolower(names(nvdrs))

#organize variables alphabetically
nvdrs <- nvdrs %>% select(sort(names(.)))

#create one identifier (ID) variable
nvdrs <- nvdrs %>% mutate(id = paste(siteid, incidentyear, incidentid, personid, sep="-"))

The IPV Classifier was designed primarily to work on single suicide
events. These are isolated suicide cases that were unconnected to other
violent deaths. In other words, the classifier should NOT be applied to
homicide-suicides (you can use the existing IPV variable in NVDRS for
those cases, here is a nice [resource] (https://onlinelibrary.wiley.com/doi/10.1111/1556-4029.12887)
on that).

The IPV Classifier was designed primarily to work on single suicide
events. These are isolated suicide cases that were unconnected to other
violent deaths. In other words, the classifier should NOT be applied to
homicide-suicides (you can use the existing IPV variable in NVDRS for
those cases, here is a nice [resource] (

https://onlinelibrary.wiley.com/doi/10.1111/1556-4029.12887

)
on that).

So let’s extract all single suicides before moving forward.

So let’s extract all single suicides before moving forward.

#pull out single suicide events 
nvdrs_ss <- nvdrs %>% filter(incidentcategory_c=="Single suicide")

It’s always helpful to confirm that we’re working with the data we
want…

It’s always helpful to confirm that we’re working with the data we
want…

#here, we're expecting only single suicides from 2019
nvdrs_ss %>% count(incidentcategory_c, incidentyear)

## # A tibble: 1 × 3
##   incidentcategory_c incidentyear     n
##   <chr>                     <dbl> <int>
## 1 Single suicide             2019 32793

#and here is a peak at the data structure
head(nvdrs_ss)

## # A tibble: 6 × 344
##   abstra…¹ abuse…² abuse…³ age   ageunit ageye…⁴ ageye…⁵ alcoh…⁶ alcoh…⁷ alcoh…⁸
##   <chr>    <chr>   <chr>   <chr> <chr>   <chr>   <chr>     <dbl> <chr>   <chr>  
## 1 Suicide… No, No… <NA>    45    Years   45      <NA>         NA Yes     <NA>   
## 2 Suicide… No, No… <NA>    62    Years   62      <NA>          0 No, No… Not pr…
## 3 Suicide… No, No… <NA>    32    Years   32      <NA>        177 Yes     Present
## 4 Suicide… No, No… <NA>    54    Years   54      <NA>         NA No, No… <NA>   
## 5 Suicide… No, No… <NA>    68    Years   68      <NA>         NA No, No… <NA>   
## 6 Suicide… No, No… <NA>    29    Years   29      <NA>         NA Yes     <NA>   
## # … with 334 more variables: alcoholtested <chr>, alcoholusesuspected <chr>,
## #   alcoholusesuspectedsuspect1 <chr>, amphetamineresult <chr>,
## #   amphetaminetested <chr>, anticonvulsantsresult <chr>,
## #   anticonvulsantstested <chr>, antidepressantresult <chr>,
## #   antidepressanttested <chr>, antipsychoticresult <chr>,
## #   antipsychotictested <chr>, anycrisis_c <chr>, argument_c <chr>,
## #   argumenttiming_c <chr>, attemptedsuicidesuspect1 <chr>, …

Great, we are working with NVDRS 2019 data, focused on single
suicides. There is one row per suicide decedent, with 32,793 rows total.
Let’s proceed.

Great, we are working with NVDRS 2019 data, focused on single
suicides. There is one row per suicide decedent, with 32,793 rows total.
Let’s proceed.

# 2. Extract text-based variables

2. Extract text-based variables

Computers cannot read or understood text in the same way that humans
can. Accordingly, the next step is to derive text-based variables using
the death narratives.

Computers cannot read or understood text in the same way that humans
can. Accordingly, the next step is to derive text-based variables using
the death narratives.

Let’s cut down the dataset so it only contains the ID variable and
the death narratives for now. That will make things more manageable.

Let’s cut down the dataset so it only contains the ID variable and
the death narratives for now. That will make things more manageable.

nvdrs_narr <- nvdrs_ss %>% select(id, narrativecme, narrativele)

Sometimes the death narratives include strange characters, symbols,
or line breaks. Take a look and see if you notice anything funny that we
need to address.

Sometimes the death narratives include strange characters, symbols,
or line breaks. Take a look and see if you notice anything funny that we
need to address.

nvdrs_narr %>% slice(1:1)

##                                 id
## 1 Massachusetts-2019-910382-883719
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        narrativecme
## 1 44 year old white, non-Hispanic male with no known past suicidal ideations and attempts. V shot himself in the head in front of his wife while they were arguing. The wife immediately called the police. The son of V, who was also home at the time, ran into the room and the tried to stop the bleeding by applying pressure. When the police department and emergency medical services arrived, V was unresponsive. According to police reports and interviews with V’s son and wife, V had been drinking all day. When the V's wife came home from work that evening, they started arguing. The V accused his wife of cheating on him, but his wife denied the accusation. V told her that he should “put a bullet in her head”. He then went into the bedroom and retrieved a 9mm pistol. He waved the gun in the air and then shot himself in the head. Both the son and wife stated that the V often got violent when he drank. Toxicology was not done. Medical examiner cause of death is a gunshot wound to the head.
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               narrativele
## 1 V was a 44-year-old white male. In the evening hours, the victim was in a verbal argument (unknown topic) with his wife at their shared residence when he reportedly said he should shoot her in the head. He then entered the bedroom of their residence, returned with a gun, and they resumed fighting. The victim then proceeded to shoot himself in the head. The wife and her son called 911, and EMS arrived but the victim was pronounced on the scene. The victim was known to abuse alcohol (with withdrawals) and methamphetamine, but was not known to have any problems with depression. He had no known suicidal ideations or attempts, and no suicide note was found on the scene. The manner of death is suicide and the cause of death is gunshot wound to the head. No other circumstances are known.

Note that we’re only showing a composite narrative here, in
accordance with CDC’s Data Use Agreement (DUA) requirements. All the
following steps, including data checking, will focus on this
fictionalized case.

Note that we’re only showing a composite narrative here, in
accordance with CDC’s Data Use Agreement (DUA) requirements. All the
following steps, including data checking, will focus on this
fictionalized case.

We’ll start by combining the narratives from the coroner/medical
examiner (CME) and from law enforcement (LE) into one text field. We’ll
use this combined narrative moving forwards.

We’ll start by combining the narratives from the coroner/medical
examiner (CME) and from law enforcement (LE) into one text field. We’ll
use this combined narrative moving forwards.

nvdrs_narr <- nvdrs_narr %>% mutate(narr = paste(narrativecme, narrativele, sep = " "))

Extracting text-based variables will come in two parts, a) running
the textfeatures package to get sentiment scores and grammatical counts,
and b) creating concept scores.

Extracting text-based variables will come in two parts, a) running
the textfeatures package to get sentiment scores and grammatical counts,
and b) creating concept scores.

## 2a.Text features (seniment, grammar)

2a.Text features (seniment, grammar)

The textfeatures
package is a user-friendly tool for extracting generic features from
text in one simple step:

The

textfeatures
package

is a user-friendly tool for extracting generic features from
text in one simple step:

library(textfeatures)

txt_feat <-textfeatures(nvdrs_narr$narr, 
         sentiment= TRUE, 
         word_dims = 0, 
         normalize= FALSE) %>%
        bind_cols(nvdrs_narr %>% select(id))

names(txt_feat)

##  [1] "id"               "n_urls"           "n_uq_urls"        "n_hashtags"      
##  [5] "n_uq_hashtags"    "n_mentions"       "n_uq_mentions"    "n_chars"         
##  [9] "n_uq_chars"       "n_commas"         "n_digits"         "n_exclaims"      
## [13] "n_extraspaces"    "n_lowers"         "n_lowersp"        "n_periods"       
## [17] "n_words"          "n_uq_words"       "n_caps"           "n_nonasciis"     
## [21] "n_puncts"         "n_capsp"          "n_charsperword"   "sent_afinn"      
## [25] "sent_bing"        "sent_syuzhet"     "sent_vader"       "n_polite"        
## [29] "n_first_person"   "n_first_personp"  "n_second_person"  "n_second_personp"
## [33] "n_third_person"   "n_tobe"           "n_prepositions"

For each case, we now have variables for a number of features
including sentiment scores, total counts of the number of first person
references, and others.

For each case, we now have variables for a number of features
including sentiment scores, total counts of the number of first person
references, and others.

For the IPV Classifier to run, we only need to keep a few of these
variables.

For the IPV Classifier to run, we only need to keep a few of these
variables.

txt_feat <- txt_feat %>% 
        select(id, sent_syuzhet, sent_vader,
        n_first_person, n_polite, 
        n_second_person, n_second_personp, n_third_person)

## 2b. Concept scores

2b. Concept scores

Next, we calculate concept scores for each case. These scores
summarize how much a concept is (or is not) mentioned in the combined
death narrative for each decedent. This step is a bit more involved and
will take some time.

Next, we calculate concept scores for each case. These scores
summarize how much a concept is (or is not) mentioned in the combined
death narrative for each decedent. This step is a bit more involved and
will take some time.

Thanks for bearing with me!

Thanks for bearing with me!

An overview of this process is depicted below.

An overview of this process is depicted below.

First, we clean and pre-process text. That includes removing numbers,
setting text to lower case, and implementing a controlled vocabulary.
Next, text is tokenized into single words (unigrams), two-word phrases
(bigrams), and three-word phrases (trigrams). Only terms that are on our
a priori Concept Term lists will be retained. These are important
keywords/phrases that we hypothesized are indicative of IPV, organized
by concept (e.g., ABUSE, DANGEROUS PERSON, PHYSICAL HARM). Finally we
create a summary score, representing how frequently each concept is
discussed per case.

First, we clean and pre-process text. That includes removing numbers,
setting text to lower case, and implementing a controlled vocabulary.
Next, text is tokenized into single words (unigrams), two-word phrases
(bigrams), and three-word phrases (trigrams). Only terms that are on our
a priori Concept Term lists will be retained. These are important
keywords/phrases that we hypothesized are indicative of IPV, organized
by concept (e.g., ABUSE, DANGEROUS PERSON, PHYSICAL HARM). Finally we
create a summary score, representing how frequently each concept is
discussed per case.

 

### 2b.i.Clean text

2b.i.Clean text

First, we’ll do some additional cleaning of the text.

First, we’ll do some additional cleaning of the text.

We need to implement a controlled vocabulary so that similar words,
like references to an INTIMATE PARTNER (e.g., “girlfriend”, “boyfriend”,
“wife) can all be rendered as the same word. That makes our text mining
task much more streamlined and simple.

We need to implement a controlled vocabulary so that similar words,
like references to an INTIMATE PARTNER (e.g., “girlfriend”, “boyfriend”,
“wife) can all be rendered as the same word. That makes our text mining
task much more streamlined and simple.

For example, a sentence that reads, “The wife called the police
because she was afraid her boyfriend would attack her” would now be
simplified to: “The iipp called the police because she was afraid her
iipp would attack her.” Using “iipp” as a special term for INTIMATE
PARTNER allows this term to be easily searchable, identifiable, and
extractable from the text.

For example, a sentence that reads, “The wife called the police
because she was afraid her boyfriend would attack her” would now be
simplified to: “The iipp called the police because she was afraid her
iipp would attack her.” Using “iipp” as a special term for INTIMATE
PARTNER allows this term to be easily searchable, identifiable, and
extractable from the text.

Do not worry about upper/lowercase versions of the text, we’ll handle
that later on.

Do not worry about upper/lowercase versions of the text, we’ll handle
that later on.

###### Intimate Partner (IP) ####

#Create a list of IP references (only put single words in this list)
iipp_list <- c("girlfriend", "boyfriend", "gf", "bf", "wife", "husband", 
     "fiance", "fiancé", "fianc", "spouse",
     #plural
     "girlfriends", "boyfriends", "wifes", "husbands", 
     "fiances", "spouses")
#Only use lower case here, keep references that were at the start of a sentence, we will address those later

#create a regex
iipp_regex <- paste0("\\b(", paste0(iipp_list, collapse="|"), ")\\b")   

#replace any word in the IP list with the special term "iipp"
nvdrs_narr$narr <- gsub(iipp_regex, "iipp", nvdrs_narr$narr)

#go through one-by-one with any phrases (2+ words) to reduce them to the special "iipp" term
nvdrs_narr$narr <- gsub("intimate partner", "iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("dating partner", "iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("significant other", "iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("romantic relationship", "iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("romantic relations", "iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("ex-iipp", "ex iipp", nvdrs_narr$narr)


###### ex ####

ex_list <- c("ex", "former", "formerly",
     "estranged", 
     "breakup", 
     "separate", "separated", "separating", 
     "divorce", "divorced", "divorcing")    

#create a list
ex_regex <- paste0("\\b(", paste0(ex_list, collapse="|"), ")\\b")   

#make replacements
nvdrs_narr$narr <- gsub(ex_regex, "ex", nvdrs_narr$narr)

#pull in borderline iipp words/phrases
nvdrs_narr$narr <- gsub("ex dating", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("ex dated", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("ex couple", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("formerly dating", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("formerly dated", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("former couple", "ex", nvdrs_narr$narr) 
nvdrs_narr$narr <- gsub("formerly married", "ex", nvdrs_narr$narr)  
nvdrs_narr$narr <- gsub("no longer dating", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("no longer married", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("previously married", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("previously dated", "ex", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("exgirlfriend", "ex iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("exboyfriend", "ex iipp", nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("exhusband", "ex iipp", nvdrs_narr$narr) 
nvdrs_narr$narr <- gsub("exwife", "ex iipp", nvdrs_narr$narr) 
nvdrs_narr$narr <- gsub("exspouse", "ex iipp", nvdrs_narr$narr) 


###### Decedent ####

#The terms "decedent" or "victim" is often used to refer to the person who died by suicide.
#We are going to REMOVE these references 
#so that we can focus on the other content of the death narratives

#decedent / victim
v <- c("victim", "decedent", "deceased", "v", "d")
#Only use lower case here, keep references that were at the start of a sentence

#create regex
v_regex <- paste0("\\b(", paste0(v, collapse="|"), ")\\b")  

#Remove
nvdrs_narr$narr <- gsub(v_regex, "", nvdrs_narr$narr)


###### Clean up ####

#quick clean of narr spacing...
#https://stackoverflow.com/questions/64492572/regex-in-r-to-add-space-after-period-if-not-present
nvdrs_narr$narr <- gsub("\\.(?=[A-Za-z])", ". ", nvdrs_narr$narr, perl = TRUE)

#remove number sign (RP#1)
nvdrs_narr$narr <- gsub("#", "", nvdrs_narr$narr, perl = TRUE)

Some states refer to subjects who were interviewed during the death
investigation as a “Concerned Party (CP)”, “Witness (W)”, “Interested
Party (IP)”, or “Reporting Party (RP).” This makes it hard to properly
identify when these people are intimate partners of the decedent, versus
other family members, friend, neighbors, etc. We designed a very
simplistic set of functions that identify and replace any of the RP, W,
IP, or CP references if they were actually referring to an intimate
partner. There are likely more eloquent, technical ways to handle this
problem, but we found that this basic approach worked sufficiently well
for our purposes.

Some states refer to subjects who were interviewed during the death
investigation as a “Concerned Party (CP)”, “Witness (W)”, “Interested
Party (IP)”, or “Reporting Party (RP).” This makes it hard to properly
identify when these people are intimate partners of the decedent, versus
other family members, friend, neighbors, etc. We designed a very
simplistic set of functions that identify and replace any of the RP, W,
IP, or CP references if they were actually referring to an intimate
partner. There are likely more eloquent, technical ways to handle this
problem, but we found that this basic approach worked sufficiently well
for our purposes.

###### CP, W, and RP #######    

#find starting position in the death narrative for any particular text string
find_start_spots = function(txt, txt_to_find){
    str_locate_all(tolower(txt), tolower(txt_to_find)) %>% 
        `[[`(1) %>% as_tibble %>% pull(start)
}

#determine whether two strings are close together (within 8 characters)
are_vectors_close = function(term1_vec, term2_vec, num_dist = 8, verbose = F){
    if((length(term1_vec) == 0) | (length(term2_vec) == 0)) {return(F)}
    distance_tbl = expand_grid(term1_vec, term2_vec) %>% 
        mutate(distance = abs(term1_vec-term2_vec)) %>% 
        mutate(is_close_enough = distance <= num_dist)
    
    if(verbose) print(distance_tbl)
    return(any(distance_tbl$is_close_enough))
}

#if the CP, W, or RP references are within 8 characters of an IP reference, then replace
sub_if_close = function(txt, find_rp_txt, remove_rp_txt, ip_txt){
    
    rp_pos <- txt %>% map(find_start_spots, find_rp_txt) 
    ip_pos <- txt %>% map(find_start_spots, ip_txt)
    
    should_replace = map2_chr(rp_pos, ip_pos, are_vectors_close)
    
    text_tbl = tibble(original_txt = txt, should_replace) %>%
        mutate(new_text = if_else(should_replace == T, 
                                                            original_txt %>% str_replace_all(remove_rp_txt,ip_txt), 
                                                            original_txt))
    return(text_tbl$new_text) #or return text_tbl to see the full ds / $new_text
}

# implement
nvdrs_narr <- nvdrs_narr %>% 
    mutate(new_text = narr %>% sub_if_close(find_rp_txt="reporting party ", remove_rp_txt = "\\b(rp|RP)\\b",   ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="the reporting party", remove_rp_txt = "\\b(rp|RP)\\b",   ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\brp\\b", remove_rp_txt= "\\b(rp|RP)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\brp1\\b", remove_rp_txt= "\\b(rp1|RP1)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\brp2\\b", remove_rp_txt= "\\b(rp2|RP2)\\b", ip_txt="iipp")) %>%  
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\brp3\\b", remove_rp_txt= "\\b(rp3|RP3)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\brp4\\b", remove_rp_txt= "\\b(rp4|RP4)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\brp5\\b", remove_rp_txt= "\\b(rp5|RP5)\\b", ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Concerned Party 1", remove_rp_txt= "\\b(cp1|CP1)\\b",   ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Concerned Party 2", remove_rp_txt= "\\b(cp2|CP2)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Concerned Party 3", remove_rp_txt= "\\b(cp3|CP3)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Concerned Party 4", remove_rp_txt= "\\b(cp4|CP4)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Concerned Party 5", remove_rp_txt= "\\b(cp5|CP5)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="concerned party 1", remove_rp_txt= "\\b(cp1|CP1)\\b",   ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="concerned party 2", remove_rp_txt= "\\b(cp2|CP2)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="concerned party 3", remove_rp_txt= "\\b(cp3|CP3)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="concerned party 4", remove_rp_txt= "\\b(cp4|CP4)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="concerned party 5", remove_rp_txt= "\\b(cp5|CP5)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="concerned party", remove_rp_txt= "\\b(cp|CP)\\b",   ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="the concerned party",remove_rp_txt = "\\b(cp|CP)\\b",   ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bcp\\b", remove_rp_txt = "\\b(cp|CP)\\b",   ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bcp1\\b", remove_rp_txt = "\\b(cp1|CP1)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bcp2\\b", remove_rp_txt = "\\b(cp2|CP2)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bcp3\\b", remove_rp_txt = "\\b(cp3|CP3)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bcp4\\b", remove_rp_txt = "\\b(cp4|CP4)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bcp5\\b", remove_rp_txt = "\\b(cp5|CP5)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="involved party 1", remove_rp_txt= "\\b(IP1|ip1)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Involved Party 1", remove_rp_txt= "\\b(IP1|ip1)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="involved party 2", remove_rp_txt= "\\b(IP2|ip2)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Involved Party 2", remove_rp_txt= "\\b(IP2|ip2)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="involved party 3", remove_rp_txt= "\\b(IP3|ip3)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Involved Party 3", remove_rp_txt= "\\b(IP3|ip3)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="involved party 4", remove_rp_txt= "\\b(IP4|ip4)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Involved Party 4", remove_rp_txt= "\\b(IP4|ip4)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="involved party 5", remove_rp_txt= "\\b(IP5|ip5)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Involved Party 5", remove_rp_txt= "\\b(IP5|ip5)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="the involved party ", remove_rp_txt= "\\b(IP|ip)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="the Involved Party ", remove_rp_txt= "\\b(IP|ip)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="involved party ", remove_rp_txt= "\\b(IP|ip)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="Involved Party ", remove_rp_txt= "\\b(IP|ip)\\b",ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bip1\\b", remove_rp_txt= "\\b(ip1|ip1)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bip2\\b", remove_rp_txt= "\\b(ip2|ip2)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bip3\\b", remove_rp_txt= "\\b(ip3|ip3)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bip4\\b", remove_rp_txt= "\\b(ip4|ip4)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bip5\\b", remove_rp_txt= "\\b(ip5|ip5)\\b", ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="witness 1", remove_rp_txt= "\\b(W1|w1)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="witness 2", remove_rp_txt= "\\b(W2|w2)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="witness 3", remove_rp_txt= "\\b(W3|w3)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="witness 4", remove_rp_txt= "\\b(W4|w4)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="witness 5", remove_rp_txt= "\\b(W5|w5)\\b",  ip_txt="iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bw1\\b",  remove_rp_txt= "\\b(W1|w1)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bw2\\b",  remove_rp_txt= "\\b(W2|w2)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bw3\\b",  remove_rp_txt= "\\b(W3|w3)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bw4\\b",  remove_rp_txt= "\\b(W4|w4)\\b",  ip_txt="iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close(find_rp_txt="\\bw5\\b",  remove_rp_txt= "\\b(W5|w5)\\b",  ip_txt="iipp"))

nvdrs_narr<- nvdrs_narr %>%
    select(-c(narr)) %>% 
    rename(narr=new_text)

Next we’ll deal with numbers and symbols. Often, you want to remove
numbers from text before analyzing it, but some numbers like “911”
signify key content that we don’t want to lose. During this step, we can
also deal with contraction words (e.g., won’t) that may get dropped or
mangled during tokenization.

Next we’ll deal with numbers and symbols. Often, you want to remove
numbers from text before analyzing it, but some numbers like “911”
signify key content that we don’t want to lose. During this step, we can
also deal with contraction words (e.g., won’t) that may get dropped or
mangled during tokenization.

####### numbers + symbols #####

#call 911
nvdrs_narr$narr <- gsub("911", "police", nvdrs_narr$narr)

#remove other numbers
nvdrs_narr$narr <- gsub('[[:digit:]]+', '', nvdrs_narr$narr)

#deal with WON'T before it gets stemmed or the apostrophe gets clipped
nvdrs_narr$narr <- gsub("won't", "should", nvdrs_narr$narr) #otherwise, this can get tokenized to "won"

#remove non english unicode characters and characters w accent marks
nvdrs_narr$narr  <- gsub("[^0-9A-Za-z\\.///' ]","" , nvdrs_narr$narr ,ignore.case = TRUE)

#remove possessive s
nvdrs_narr$narr  <- gsub("'s","" , nvdrs_narr$narr ,ignore.case = TRUE)

#Deal with other funky symbols or line breaks 
nvdrs_narr$narr <- gsub('[ÃåââãåÅâÂ]', '', nvdrs_narr$narr)
nvdrs_narr$narr <- gsub("[\n]",       " ", nvdrs_narr$narr)


#quick clean of narr spacing...
nvdrs_narr$narr <- gsub("\\.(?=[A-Za-z])", ". ", nvdrs_narr$narr, perl = TRUE)
#https://stackoverflow.com/questions/64492572/regex-in-r-to-add-space-after-period-if-not-present

#confirm that we're using sentence case
nvdrs_narr$narr <-str_to_sentence(nvdrs_narr$narr, locale = "en")

Now that we’ve somewhat simplified the text, let’s move from
case-level to sentence-level. That will make it easier to do quality
checks during text cleaning. Before performing this step, check to make
sure that your text is in sentence case (with a capital letter at the
start of each sentence and a period marking the end).

Now that we’ve somewhat simplified the text, let’s move from
case-level to sentence-level. That will make it easier to do quality
checks during text cleaning. Before performing this step, check to make
sure that your text is in sentence case (with a capital letter at the
start of each sentence and a period marking the end).

nvdrs_narr %>% slice(1:1) %>% select(narr)

##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     narr
## 1  Year old white nonhispanic male with no known past suicidal ideations and attempts. V shot himself in the head in front of his iipp while they were arguing. The iipp immediately called the police. The son of v who was also home at the time ran into the room and the tried to stop the bleeding by applying pressure. When the police department and emergency medical services arrived v was unresponsive. According to police reports and interviews with vs son and iipp v had been drinking all day. When the v iipp came home from work that evening they started arguing. The v accused his iipp of cheating on him but his iipp denied the accusation. V told her that he should put a bullet in her head. He then went into the bedroom and retrieved a mm pistol. He waved the gun in the air and then shot himself in the head. Both the son and iipp stated that the v often got violent when he drank. Toxicology was not done. Medical examiner cause of death is a gunshot wound to the head. V was a yearold white male. In the evening hours the  was in a verbal argument unknown topic with his iipp at their shared residence when he reportedly said he should shoot her in the head. He then entered the bedroom of their residence returned with a gun and they resumed fighting. The  then proceeded to shoot himself in the head. The iipp and her son called police and ems arrived but the  was pronounced on the scene. The  was known to abuse alcohol with withdrawals and methamphetamine but was not known to have any problems with depression. He had no known suicidal ideations or attempts and no suicide note was found on the scene. The manner of death is suicide and the cause of death is gunshot wound to the head. No other circumstances are known.

Use the unnest_tokens function from tidytext
to transform the data to the sentence-level.

Use the unnest_tokens function from

tidytext

to transform the data to the sentence-level.

#### Sentence-level #####
sent <- nvdrs_narr %>% 
    arrange(id) %>%
    mutate(id_doc = row_number()) %>%
    unnest_tokens(output = sentence, input=narr, token = "sentences",  drop = FALSE) %>%
    group_by(id_doc) %>% mutate(id_sent = row_number()) %>% ungroup() %>% #create sentence ID for ordering
    mutate(sentence_OG = sentence) #save original sentence

sent %>% slice(1:10) %>% select(id, sentence)

## # A tibble: 10 × 2
##    id                               sentence                                    
##    <fct>                            <chr>                                       
##  1 Massachusetts-2019-910382-883719 year old white nonhispanic male with no kno…
##  2 Massachusetts-2019-910382-883719 v shot himself in the head in front of his …
##  3 Massachusetts-2019-910382-883719 the iipp immediately called the police.     
##  4 Massachusetts-2019-910382-883719 the son of v who was also home at the time …
##  5 Massachusetts-2019-910382-883719 when the police department and emergency me…
##  6 Massachusetts-2019-910382-883719 according to police reports and interviews …
##  7 Massachusetts-2019-910382-883719 when the v iipp came home from work that ev…
##  8 Massachusetts-2019-910382-883719 the v accused his iipp of cheating on him b…
##  9 Massachusetts-2019-910382-883719 v told her that he should put a bullet in h…
## 10 Massachusetts-2019-910382-883719 he then went into the bedroom and retrieved…

Seeing everything sentence-by-sentence makes it easier to pinpoint
subsections of the narratives. For example, if we wanted to see only
sentences that contained our special term “iipp”, we could hone in on
that quickly.

Seeing everything sentence-by-sentence makes it easier to pinpoint
subsections of the narratives. For example, if we wanted to see only
sentences that contained our special term “iipp”, we could hone in on
that quickly.

sent %>% filter(str_detect(sentence, "iipp") == TRUE ) %>% slice(1:5) %>% select(sentence)

## # A tibble: 5 × 1
##   sentence                                                                      
##   <chr>                                                                         
## 1 v shot himself in the head in front of his iipp while they were arguing.      
## 2 the iipp immediately called the police.                                       
## 3 according to police reports and interviews with vs son and iipp v had been dr…
## 4 when the v iipp came home from work that evening they started arguing.        
## 5 the v accused his iipp of cheating on him but his iipp denied the accusation.

Now we can continue cleaning the text, removing non-content words,
and streamlining the vocabulary. The main motivation here is to help
clarify who is mentioned in the narratives (i.e., an
intimate partner verses another person) and in what
context (i.e., in the context of substance abuse
vs. physical abuse). We pay special attention to any words that might
signify a pattern of behavior, given that IPV often
entails chronic, repeated abuse. We also take special care to
differentiate phrases that refer to self-harm (using reflexive keywords
like himself or herself) compared to interpersonal harm (often using
personal pronouns or an IP reference). Finally, we found it was helpful
to take note of auxiliary words and conditional terms (e.g., “should”,
“won’t”) as they may express coercive or controlling
behaviors/intentions.

Now we can continue cleaning the text, removing non-content words,
and streamlining the vocabulary. The main motivation here is to help
clarify

**who**who

is mentioned in the narratives (i.e., an
intimate partner verses another person) and in what

**context**context

(i.e., in the context of substance abuse
vs. physical abuse). We pay special attention to any words that might
signify a

**pattern**pattern

of behavior, given that IPV often
entails chronic, repeated abuse. We also take special care to
differentiate phrases that refer to self-harm (using reflexive keywords
like himself or herself) compared to interpersonal harm (often using
personal pronouns or an IP reference). Finally, we found it was helpful
to take note of auxiliary words and conditional terms (e.g., “should”,
“won’t”) as they may express

**coercive or controlling**coercive or controlling

behaviors/intentions.

Overall, these text cleaning decisions have been informed by our
manual review of the death narratives, error analyses during model
building, and existing IPV research, including the Power
and Control Wheel and the Women’s
Experiences with Battering scale, among other resources.

Overall, these text cleaning decisions have been informed by our
manual review of the death narratives, error analyses during model
building, and existing IPV research, including the

Power
and Control Wheel

and the

Women’s
Experiences with Battering scale

, among other resources.

The following code block is a long one. It’s primarily a list of
word/phrase replacements and deletions.

The following code block is a long one. It’s primarily a list of
word/phrase replacements and deletions.

#strip out extra white space
sent$sentence<-str_squish(sent$sentence) 

#do these AGAIN now that we don't need to worry about caps vs. lower case...        
        
###### IP ####
#IP
sent$sentence <- gsub(iipp_regex, "iipp", sent$sentence)

#eX
sent$sentence <- gsub(ex_regex, "ex", sent$sentence)
        
sent$sentence <- gsub("intimate partner", "iipp", sent$sentence)
sent$sentence <- gsub("dating partner", "iipp", sent$sentence)
sent$sentence <- gsub("significant other", "iipp", sent$sentence)
sent$sentence <- gsub("romantic relationship", "iipp", sent$sentence)
sent$sentence <- gsub("romantic relations", "iipp", sent$sentence)
        
sent$sentence <- gsub("ex dating", "ex", sent$sentence)
sent$sentence <- gsub("ex dated", "ex", sent$sentence)
sent$sentence <- gsub("ex couple", "ex", sent$sentence)
sent$sentence <- gsub("formerly dating", "ex", sent$sentence)
sent$sentence <- gsub("formerly dated", "ex", sent$sentence)
sent$sentence <- gsub("former couple", "ex", sent$sentence) 
sent$sentence <- gsub("formerly married", "ex", sent$sentence)  
sent$sentence <- gsub("no longer dating", "ex", sent$sentence)
sent$sentence <- gsub("no longer married", "ex", sent$sentence)
sent$sentence <- gsub("previously married", "ex", sent$sentence)
sent$sentence <- gsub("previously dated", "ex", sent$sentence)
sent$sentence <- gsub("exgirlfriend", "ex iipp", sent$sentence)
sent$sentence <- gsub("exboyfriend", "ex iipp", sent$sentence)
sent$sentence <- gsub("exhusband", "ex iipp", sent$sentence) 
sent$sentence <- gsub("exwife", "ex iipp", sent$sentence) 
sent$sentence <- gsub("exspouse", "ex iipp", sent$sentence) 
sent$sentence <- gsub("ex-iipp", "ex iipp", sent$sentence)
        
        
###### exceptions ####  
#want to remove the word INTO except in these cases...
#break-ins
sent$sentence <- gsub("broken into", "trespass", sent$sentence)
sent$sentence <- gsub("breaking into", "trespass", sent$sentence)
sent$sentence <- gsub("broke into", "trespass", sent$sentence)
sent$sentence <- gsub("broken in", "trespass", sent$sentence)
sent$sentence <- gsub("breaking in", "trespass", sent$sentence)
sent$sentence <- gsub("broke in", "trespass", sent$sentence)

sent$sentence <- gsub("kick in", "trespass", sent$sentence)
sent$sentence <- gsub("kicked in", "trespass", sent$sentence)
sent$sentence <- gsub("kicking in", "trespass", sent$sentence)

sent$sentence <- gsub("busting in", "trespass", sent$sentence)
sent$sentence <- gsub("bust in", "trespass", sent$sentence)
sent$sentence <- gsub("busted in", "trespass", sent$sentence)


#convert some important phrases w/ stop words in them
#IN --> Need -in front-
sent$sentence <- gsub("in front", "infront", sent$sentence)
#IT --> Waving it [a gun/weapon]
sent$sentence <- gsub("waving it", "waving object", sent$sentence)
sent$sentence <- gsub("waved it", "waving object", sent$sentence)
sent$sentence <- gsub("wave it", "waving object", sent$sentence)
#ON --> move on
sent$sentence <- gsub("move on", "get over", sent$sentence)
sent$sentence <- gsub("moved on", "get over", sent$sentence)
sent$sentence <- gsub("moving on", "get over", sent$sentence)
#ON --> Spit on
sent$sentence <- gsub("spit on", "spiton", sent$sentence)
sent$sentence <- gsub("spitting on", "spiton", sent$sentence)
sent$sentence <- gsub("spat on", "spiton", sent$sentence)
#FROM --> threatening a person
sent$sentence <- gsub("threats from", "threat comment", sent$sentence)
sent$sentence <- gsub("threats by", "threat comment", sent$sentence)
sent$sentence <- gsub("threatened by", "threat comment", sent$sentence)
sent$sentence <- gsub("receiving threat", "threat comment", sent$sentence)
sent$sentence <- gsub("received threat", "threat comment", sent$sentence)


#OR ELSE
sent$sentence <- gsub("or else", "orelse", sent$sentence)
#BECAME / BECOME
sent$sentence <- gsub("became physical", "physical fight", sent$sentence)
sent$sentence <- gsub("become physical", "physical fight", sent$sentence)
sent$sentence <- gsub("becoming physical", "physical fight", sent$sentence)

#came", "come", "comes"
sent$sentence <- gsub("came after ", "follow you", sent$sentence)
sent$sentence <- gsub("comes after ", "follow you", sent$sentence)
sent$sentence <- gsub("coming after ", "follow you", sent$sentence) #note the space, so its not "afterwards"!

#rather
sent$sentence <- gsub("rather die ", "should die", sent$sentence)

#this
sent$sentence <- gsub("watch this", "watch me", sent$sentence)
sent$sentence <- gsub("see this", "see me", sent$sentence)

#pointing a weapon at someone
sent$sentence <- gsub("weapon at her", "weapon you", sent$sentence)
sent$sentence <- gsub("weapon at him", "weapon you", sent$sentence)
sent$sentence <- gsub("knife at her", "knife you", sent$sentence)
sent$sentence <- gsub("knife at him", "knife you", sent$sentence)

#the look
sent$sentence <- gsub("had a look", "thelook", sent$sentence)
sent$sentence <- gsub("gets a look", "thelook", sent$sentence)
sent$sentence <- gsub("got a look", "thelook", sent$sentence)
sent$sentence <- gsub("had this look", "thelook", sent$sentence)
sent$sentence <- gsub("gets this look", "thelook", sent$sentence)
sent$sentence <- gsub("got this look", "thelook", sent$sentence)
sent$sentence <- gsub("evil look", "thelook", sent$sentence)
sent$sentence <- gsub("scary look", "thelook", sent$sentence)
sent$sentence <- gsub("nasty look", "thelook", sent$sentence)

#becoming crazy
sent$sentence <- gsub("became crazy", "get crazy", sent$sentence)
sent$sentence <- gsub("become crazy", "get crazy", sent$sentence)
sent$sentence <- gsub("becomes crazy", "get crazy", sent$sentence)
sent$sentence <- gsub("becoming crazy", "get crazy", sent$sentence)

sent$sentence <- gsub("face time", "facetime", sent$sentence)
sent$sentence <- gsub("face-time", "facetime", sent$sentence)
sent$sentence <- gsub("facetimed", "facetime", sent$sentence)
sent$sentence <- gsub("facetiming", "facetime", sent$sentence)

sent$sentence <- gsub("come after", "chase", sent$sentence)
sent$sentence <- gsub("came after", "chase", sent$sentence)
sent$sentence <- gsub("coming after", "chase", sent$sentence)

sent$sentence <- gsub("each other", "eachother", sent$sentence)


###### pattern ####
#Pattern
pattern_list <- c("always","chronically", "again", 
    "continuously", "continually", "constant", "constantly", 
    "commonly", "daily", "excessively",     "exteremely", "extreme",
    "frequently", "forever", "invariably", 
    "multiple", "many", 
    "never-ending", "nonstop", "non-stop", "numerous",
    "often", "overly", 
    "intensely", 
    "perpetually", "previously", "past", 
    "regularly", "relentless", "repeated", "repeatedly", "repeating", "repetatively",
    "routinely", "twice", 
    "several", 
    "unceasingly", "unremitting", "unnecessarily",  "utterly", 
    "weekly", "whenever",
    "two", "twice", "second", "three", "third", "forth", "four", "fifth", "five", 
    "six", "seven", "eight", "nine", "ten")

#need these strong ones in here so I can easily and succinctly reference them in my concept lists
#create regex
pattern_regex <- paste0("\\b(", paste0(pattern_list, collapse="|"), ")\\b")  
#make replacements
sent$sentence <- gsub(pattern_regex, "pattern", sent$sentence)

sent$sentence <- gsub("never ending", "pattern", sent$sentence)
sent$sentence <- gsub("non stop", "pattern", sent$sentence)
sent$sentence <- gsub("non-stop", "pattern", sent$sentence)
sent$sentence <- gsub("any time", "pattern", sent$sentence)
sent$sentence <- gsub("all the time", "pattern", sent$sentence)
sent$sentence <- gsub("every time", "pattern", sent$sentence)
sent$sentence <- gsub("numerous times", "pattern", sent$sentence)
sent$sentence <- gsub("without stopping", "pattern", sent$sentence)
sent$sentence <- gsub("not stopping", "pattern", sent$sentence)
sent$sentence <- gsub("many times", "pattern", sent$sentence)
sent$sentence <- gsub("several times", "pattern", sent$sentence)
sent$sentence <- gsub("multiple times", "pattern", sent$sentence)
sent$sentence <- gsub("many times", "pattern", sent$sentence)
sent$sentence <- gsub("pattern times", "pattern", sent$sentence)
sent$sentence <- gsub("this before", "pattern", sent$sentence)
sent$sentence <- gsub("happened before", "pattern", sent$sentence)
sent$sentence <- gsub("happening before", "pattern", sent$sentence)
sent$sentence <- gsub("once before", "pattern", sent$sentence)
sent$sentence <- gsub("history of", "pattern", sent$sentence)
sent$sentence <- gsub("pattern before", "pattern", sent$sentence)
sent$sentence <- gsub("pattern pattern", "pattern", sent$sentence)


###### auxiliary and conditional terms ####

aux_list <- c("would", "wont", # already took care of "won't"
    "can", "could", "couldn't", "couldn", 
    "can't", "cannot" ,  "cant",
    "should", "shouldn't", "should", "shouldn", 
    "would", "wouldn't", "wouldn", 
    "must", "mustn", "mustn't")

#create regex
aux_regex <- paste0("\\b(", paste0(aux_list, collapse="|"), ")\\b")  
#make replacements
sent$sentence <- gsub(aux_regex, "should", sent$sentence)

###### first person ####
firtperson_list <- c("us", "me", "my", "i", 
    "ourselves", "you", "yours", "your") #may rquire updates to theory list 

firtperson_regex <- paste0("\\b(", paste0(firtperson_list, collapse="|"), ")\\b")  
#make replacements
sent$sentence <- gsub(firtperson_regex, "you", sent$sentence)


###### negation ####

no_list <- c("don't", "don", "didn't", "didn",
    "hadn't", "hadn", "hasn't", "hasn", "haven't", "haven",
    "no", "not", "non", "none", "noone", "nor", "nothing",
    "neither")

no_regex <- paste0("\\b(", paste0(no_list, collapse="|"), ")\\b")  
#make replacements
sent$sentence <- gsub(no_regex, "no", sent$sentence)

sent$sentence <- gsub("no sign", "no", sent$sentence)
sent$sentence <- gsub("no signs", "no", sent$sentence)
sent$sentence <- gsub("no evidence", "no", sent$sentence)
sent$sentence <- gsub("no history", "no", sent$sentence)


###### gun ####
#GUN#
gun_list <- c("gun","guns",
    "handgun", "handguns", 
    "firearm", "firearms",
    "shotgun", "shotguns", 
    "rifle", "rifles", 
    "revolver",     "revolvers", 
    "pistol", "pistols", 
    "bullet", "bullets",
    "gauge", "caliber",
    "semi-automatic", "ammunition", "barrell", "sniper",
    "glock", "submachine", "ak",
    "luger")
gun_regex <- paste0("\\b(", paste0(gun_list, collapse="|"), ")\\b")         
sent$sentence <- gsub(gun_regex, "gun", sent$sentence)

#gun pointing... 
sent$sentence <- gsub("gun at her", "gun you", sent$sentence)
sent$sentence <- gsub("gun at him", "gun you", sent$sentence)



###### stop ####

library(stopwords)

stop <- stopwords(source = "smart")

#edit down the stop words list
#type out the words to KEEP
words_to_keep <- c("able", "again", "against", "allow", "allows", "ask",
 "alone", "always", "away", 
 "because", "both", "cause", "causes", "better", 
 "body", "down", "ex", "even", 
 "came", "come", "comes", 
 "followed",  "following",   "follows", "former",  "formerly", 
 "get", "gets" , "getting", "go", "got", "gotten", "give", "given",
 "help", 
 "keep", "kept", "keeps", 
 "let", "look", 
 "mean", "name", "no", "non", "not", 
 "off", "out", "over",
 "placed", "please",
 "saw", "see", "seeing", "seen", "sorry", "sent", "send", "sending", 
 "take", "took", "taking", "taken", "together", "tried", "try", 
 "toward", "towards", "try", "trying", "tell", 
 "up", 
 "want", "unwanted", "unwant", "why", "where", "wish", 
 "x", "xx",
 
 ##pp and other replacement key words
 "he", "him", "his", "she", "her", "hers", "them", "their", "they",
 "he'd", "he'll", "he's",
 "she",  "she'd", "she'll", "she's",
 "theirs", "they'd", "they'll", "they're", "they've",
 
 "ever", "never", 
 
 "you",
 "self", "herself", "himself", "selves", "themselves", "yourself", "yourselves",
 "should", "unless", "if",  #these are already taken care of
 "pattern", #these are already taken care of
 "no", #these are already taken care of

 "two", "twice", "second", "three", "third", "forth", "four", "fifth", "five", "six")

stop <- tm::removeWords(stop, words_to_keep)

#add terms
new_stop_words <- c(
#TIME
"after", "ago", "again", "before", 
"began", "begin", "begun", 
"continued", "continuing", "continue", 
"last", "time", 
"previously", "previous", "prior",
"night", "morning", "evening", "earlier", 
"month", "months", "week", "weeks", "day", "days", "weekend", "year", "years",
"recent",

#SAYS                               
"state", "stated", "stating", "states", "statement", "said", "says", "say",         
"reporting", "reported", "report",

#something about injuries getting in the way about who was impacted
"sustain", "sustaining", "sustained",
"receive", "receiving", "received")

stop <- c(stop, new_stop_words)
            
#remove emtpy elements
stop<-stop[!is.na(stop) & stop != ""]
            
#build RegEx
stop_regex <- paste0("\\b(", paste0(stop, collapse="|"), ")\\b")  #using same setup as prior... 

#remove
sent$sentence <- gsub(stop_regex, "", sent$sentence)


#strip out extra white space
sent$sentence<-str_squish(sent$sentence) 

#simplify
sent$sentence <- gsub("got argument", "argument", sent$sentence)
sent$sentence <- gsub("not believe", "no", sent$sentence)
sent$sentence <- gsub("no believe", "no", sent$sentence)
sent$sentence <- gsub("no evidence", "no", sent$sentence)
sent$sentence <- gsub("not evidence", "no", sent$sentence)



###### phone ####

phone_list <- c("phone","cell",
    "calling", "calls", #not just call
     "texting", "texts", #not just text
    "messages", "messaging", #not just mesage
    "post", "posts", "posting",
    "voicemail","telephone", 
    "videos", "video", "facetime", "facetiming")
phone_regex <- paste0("\\b(", paste0(phone_list, collapse="|"), ")\\b")         
sent$sentence <- gsub(phone_regex, "phone", sent$sentence)

sent$sentence <- gsub("face timing", "phone", sent$sentence)
sent$sentence <- gsub("cellular phone", "phone", sent$sentence)
sent$sentence <- gsub("cellphone", "phone", sent$sentence)
sent$sentence <- gsub("phone phone", "phone", sent$sentence)
sent$sentence <- gsub("leaving messages", "phone", sent$sentence)
sent$sentence <- gsub("social media", "phone", sent$sentence)
sent$sentence <- gsub("phone call", "phone", sent$sentence) #singular
sent$sentence <- gsub("text message", "phone", sent$sentence) #singular



###### reflex ####
#REFLEXIVE#
reflexive <- c("\\b\\w*self\\b")
sent$sentence <- gsub(reflexive, "self", sent$sentence)

#strip out white space
sent$sentence<-str_squish(sent$sentence) 

#always replacing ING words first, so that nesting doesn't cause trouble

#OBVIOUS reflexive harm
#kill self  
sent$sentence <- gsub("killing self", "suicidality", sent$sentence)
sent$sentence <- gsub("killed self", "suicidality", sent$sentence)
sent$sentence <- gsub("kill self", "suicidality", sent$sentence)

#cut wrist
sent$sentence <- gsub("cutting wrist", "suicidality", sent$sentence)
sent$sentence <- gsub("cut wrist", "suicidality", sent$sentence)
sent$sentence <- gsub("cutting self", "suicidality", sent$sentence)
sent$sentence <- gsub("cut self", "suicidality", sent$sentence)
sent$sentence <- gsub("self cutting", "suicidality", sent$sentence)
sent$sentence <- gsub("self cut", "suicidality", sent$sentence)


#shoot self
sent$sentence <- gsub("shooting self", "suicidality", sent$sentence)
sent$sentence <- gsub("shot self", "suicidality", sent$sentence)
sent$sentence <- gsub("shoot self", "suicidality", sent$sentence)
#strangle self
sent$sentence <- gsub("strangling self", "suicidality", sent$sentence)
sent$sentence <- gsub("strangled self", "suicidality", sent$sentence)
sent$sentence <- gsub("strangle self", "suicidality", sent$sentence)
#cut
sent$sentence <- gsub("cutting self", "suicidality", sent$sentence)
sent$sentence <- gsub("cut self", "suicidality", sent$sentence)
#choke
sent$sentence <- gsub("choking self", "suicidality", sent$sentence)
sent$sentence <- gsub("choke self", "suicidality", sent$sentence)
sent$sentence <- gsub("choked self", "suicidality", sent$sentence)
#stab
sent$sentence <- gsub("stabbing self", "suicidality", sent$sentence)
sent$sentence <- gsub("stabbed self", "suicidality", sent$sentence)
sent$sentence <- gsub("stab self", "suicidality", sent$sentence)

#suicide
sent$sentence <- gsub("suicide", "suicidality", sent$sentence)
sent$sentence <- gsub("suicidal ideation", "suicidality", sent$sentence)
sent$sentence <- gsub("attempts or threats", "suicidality", sent$sentence)
sent$sentence <- gsub("threats or attempts", "suicidality", sent$sentence)
#self harm
sent$sentence <- gsub("self harm", "suicidality", sent$sentence)
sent$sentence <- gsub("self-harm", "suicidality", sent$sentence)
sent$sentence <- gsub("harming self", "suicidality", sent$sentence)
sent$sentence <- gsub("harm self", "suicidality", sent$sentence)
sent$sentence <- gsub("hurting self", "suicidality", sent$sentence)
sent$sentence <- gsub("hurt self", "suicidality", sent$sentence)
sent$sentence <- gsub("self hurt", "suicidality", sent$sentence)

#suicide threats
sent$sentence <- gsub("threatening hang", "suicthreat", sent$sentence)
sent$sentence <- gsub("threatened hang", "suicthreat", sent$sentence)
sent$sentence <- gsub("threaten hang", "suicthreat", sent$sentence)

sent$sentence <- gsub("threatening suicide", "suicthreat", sent$sentence)
sent$sentence <- gsub("threatened suicide", "suicthreat", sent$sentence)
sent$sentence <- gsub("threaten suicide", "suicthreat", sent$sentence)

sent$sentence <- gsub("suicidal threats", "suicthreat", sent$sentence)
sent$sentence <- gsub("suicidal threat", "suicthreat", sent$sentence)
sent$sentence <- gsub("suicide threats", "suicthreat", sent$sentence)
sent$sentence <- gsub("suicide threat", "suicthreat", sent$sentence)

sent$sentence <- gsub("suicidality threats", "suicthreat", sent$sentence)
sent$sentence <- gsub("suicidality threat", "suicthreat", sent$sentence)

sent$sentence <- gsub("threatening suicidality", "suicthreat", sent$sentence)
sent$sentence <- gsub("threatened suicidality", "suicthreat", sent$sentence)
sent$sentence <- gsub("threaten suicidality", "suicthreat", sent$sentence)

sent$sentence <- gsub("threatening suicide", "suicthreat", sent$sentence)
sent$sentence <- gsub("threatened suicide", "suicthreat", sent$sentence)
sent$sentence <- gsub("threaten suicide", "suicthreat", sent$sentence)

#self-inflicted
sent$sentence <- gsub("self inflicted", "suicidality", sent$sentence)
sent$sentence <- gsub("selfinflicted", "suicidality", sent$sentence)

#strip out white space
sent$sentence<-str_squish(sent$sentence) 



###### dvpo ####
dvpo_list <- c("pfa", "ppo", "po", "dvpo", "dvro", "epo", "tpo")

dvpo_regex <- paste0("\\b(", paste0(dvpo_list, collapse="|"), ")\\b")   
sent$sentence <- gsub(dvpo_regex, "dvpo", sent$sentence)

sent$sentence <- gsub("order protection", "dvpo", sent$sentence)
sent$sentence <- gsub("protection order", "dvpo", sent$sentence)
sent$sentence <- gsub("protective order", "dvpo", sent$sentence)
sent$sentence <- gsub("restraining order", "dvpo", sent$sentence)
sent$sentence <- gsub("order contact", "dvpo", sent$sentence)
sent$sentence <- gsub("contact order", "dvpo", sent$sentence)
sent$sentence <- gsub("order restraining", "dvpo", sent$sentence)
sent$sentence <- gsub("restraining order", "dvpo", sent$sentence)


###### pp ####
#kill/harm person
pp_list <- c("he", "him", "his", "she", "her", "hers", "them", "their", "they",
     "he'd", "he'll", "he's",
     "she",  "she'd", "she'll", "she's",
     "theirs", "they'd", "they'll", "they're", "they've")

pp_regex <- paste0("\\b(", paste0(pp_list, collapse="|"), ")\\b")   
sent$sentence <- gsub(pp_regex, "pppp", sent$sentence)

sent$sentence <- gsub("kill pppp", "kill you", sent$sentence)
sent$sentence <- gsub("killing pppp", "kill you", sent$sentence)
sent$sentence <- gsub("killed pppp", "kill you", sent$sentence)

sent$sentence <- gsub("cut pppp down", "lower", sent$sentence) #not IPV
sent$sentence <- gsub("cut pppp", "cut you", sent$sentence)
sent$sentence <- gsub("cutting pppp", "cut you", sent$sentence)

sent$sentence <- gsub("stab pppp", "stab you", sent$sentence)
sent$sentence <- gsub("stabbing pppp", "stab you", sent$sentence)
sent$sentence <- gsub("stabbed pppp", "stab you", sent$sentence)

#following someone
sent$sentence <- gsub("follow pppp", "follow you", sent$sentence)
sent$sentence <- gsub("following pppp", "follow you", sent$sentence)
sent$sentence <- gsub("followed pppp", "follow you", sent$sentence)

#hurt someone 
sent$sentence <- gsub("hurt pppp", "hurt you", sent$sentence)
sent$sentence <- gsub("hurting pppp", "hurt you", sent$sentence)

#shoot someone
sent$sentence <- gsub("shoot pppp", "shoot you", sent$sentence)
sent$sentence <- gsub("shooting pppp", "shoot you", sent$sentence)
sent$sentence <- gsub("shot pppp", "shoot you", sent$sentence)

#kick someone
sent$sentence <- gsub("kick pppp", "kick you", sent$sentence)
sent$sentence <- gsub("kicking pppp", "kick you", sent$sentence)
sent$sentence <- gsub("kicked pppp", "kick you", sent$sentence)

#push someone
sent$sentence <- gsub("push pppp", "push you", sent$sentence)
sent$sentence <- gsub("pushing pppp", "push you", sent$sentence)
sent$sentence <- gsub("pushed pppp", "push you", sent$sentence)

#hit someone
sent$sentence <- gsub("hit pppp", "hit you", sent$sentence)
sent$sentence <- gsub("hitting pppp", "hit you", sent$sentence)

#now we can remove personal pronouns
sent$sentence <- gsub("pppp", "", sent$sentence)

#strip out white space
sent$sentence<-str_squish(sent$sentence) 


###### drugs ####

#get rid of misleading references to ABUSE - needs SPECIFIC phrasing, not just any mention of abuse
sent$sentence <- gsub("abuse ethanol", "drugs", sent$sentence)
sent$sentence <- gsub("abuse cannabis", "drugs", sent$sentence)
sent$sentence <- gsub("abuse marijuana", "drugs", sent$sentence)
sent$sentence <- gsub("abuse cocaine", "drugs", sent$sentence)
sent$sentence <- gsub("abuse meth", "drugs", sent$sentence)
sent$sentence <- gsub("abuse alcohol", "drugs", sent$sentence)
sent$sentence <- gsub("abuse drugs", "drugs", sent$sentence)
sent$sentence <- gsub("abuse testosterone", "drugs", sent$sentence)
sent$sentence <- gsub("abuse mushrooms", "drugs", sent$sentence)
sent$sentence <- gsub("abuse heroin", "drugs", sent$sentence)
sent$sentence <- gsub("abuse etoh", "drugs", sent$sentence)
sent$sentence <- gsub("abuse methamphetamine", "drugs", sent$sentence)
sent$sentence <- gsub("abuse methamphetamines", "drugs", sent$sentence)
sent$sentence <- gsub("abuse morphine", "drugs", sent$sentence)
sent$sentence <- gsub("abuse chemical", "drugs", sent$sentence)
sent$sentence <- gsub("abuse rx", "drugs", sent$sentence)
sent$sentence <- gsub("abuse prescriptions", "drugs", sent$sentence)
sent$sentence <- gsub("abuse prescription", "drugs", sent$sentence)

sent$sentence <- gsub("abusing heroin", "drugs", sent$sentence)
sent$sentence <- gsub("abusing marijuana", "drugs", sent$sentence)
sent$sentence <- gsub("abusing cannibus", "drugs", sent$sentence)
sent$sentence <- gsub("abusing cocaine", "drugs", sent$sentence)
sent$sentence <- gsub("abusing meth", "drugs", sent$sentence)
sent$sentence <- gsub("abusing alcohol", "drugs", sent$sentence)
sent$sentence <- gsub("abusing drugs", "drugs", sent$sentence)
sent$sentence <- gsub("abusing testosterone", "drugs", sent$sentence)
sent$sentence <- gsub("abusing mushrooms", "drugs", sent$sentence)
sent$sentence <- gsub("abusing etoh", "drugs", sent$sentence)
sent$sentence <- gsub("abusing methamphetamine", "drugs", sent$sentence)
sent$sentence <- gsub("abusing methamphetamines", "drugs", sent$sentence)
sent$sentence <- gsub("abusing ethanol", "drugs", sent$sentence)
sent$sentence <- gsub("abusing morphine", "drugs", sent$sentence)
sent$sentence <- gsub("abusing chemical", "drugs", sent$sentence)
sent$sentence <- gsub("abusing rx", "drugs", sent$sentence)
sent$sentence <- gsub("abusing prescriptions", "drugs", sent$sentence)
sent$sentence <- gsub("abusing prescription", "drugs", sent$sentence)

sent$sentence <- gsub("drug abuse", "drugs", sent$sentence)
sent$sentence <- gsub("drugs abuse", "drugs", sent$sentence)
sent$sentence <- gsub("substance abuse", "drugs", sent$sentence)
sent$sentence <- gsub("substance misuse", "drugs", sent$sentence)
sent$sentence <- gsub("use/abuse", "drugs", sent$sentence)
sent$sentence <- gsub("use or abuse", "drugs", sent$sentence)
sent$sentence <- gsub("alcohol abuse", "drugs", sent$sentence)
sent$sentence <- gsub("ethanol abuse", "drugs", sent$sentence)
sent$sentence <- gsub("chemical abuse", "drugs", sent$sentence)
sent$sentence <- gsub("rx abuse", "drugs", sent$sentence)
sent$sentence <- gsub("prescriptions abuse", "drugs", sent$sentence)
sent$sentence <- gsub("prescription abuse", "drugs", sent$sentence)
sent$sentence <- gsub("methamphetamine abuse", "drugs", sent$sentence)
sent$sentence <- gsub("cannabis abuse", "drugs", sent$sentence)
sent$sentence <- gsub("etoh abuse", "drugs", sent$sentence)
sent$sentence <- gsub("marijuana abuse", "drugs", sent$sentence)
sent$sentence <- gsub("cocaine abuse", "drugs", sent$sentence)
sent$sentence <- gsub("meth abuse", "drugs", sent$sentence)
sent$sentence <- gsub("alcohol abuse", "drugs", sent$sentence)
sent$sentence <- gsub("drug abuse", "drugs", sent$sentence)
sent$sentence <- gsub("testosterone aubse", "drugs", sent$sentence)
sent$sentence <- gsub("mushrooms abuse", "drugs", sent$sentence)
sent$sentence <- gsub("heroin abuse", "drugs", sent$sentence)
sent$sentence <- gsub("morphine abuse", "drugs", sent$sentence)




###### not IPV ####

#NOT IPV
sent$sentence <- gsub("heart attack", "heart", sent$sentence)
sent$sentence <- gsub("panic attack", "panic", sent$sentence)
sent$sentence <- gsub("anxiety attack", "anxiety", sent$sentence)
sent$sentence <- gsub("struck out", "fail", sent$sentence)
sent$sentence <- gsub("cut out", "remove", sent$sentence)

sent$sentence <- gsub("break-up", "breakup", sent$sentence)
sent$sentence <- gsub("break up", "breakup", sent$sentence)
sent$sentence <- gsub("break off", "breakup", sent$sentence)
sent$sentence <- gsub("breaking up", "breakup", sent$sentence)
sent$sentence <- gsub("broke up", "breakup", sent$sentence)
sent$sentence <- gsub("broken up", "breakup", sent$sentence)
sent$sentence <- gsub("broken-up", "breakup", sent$sentence)

sent$sentence <- gsub("broken heart", "heartbreak", sent$sentence)
sent$sentence <- gsub("breaking heart", "heartbreak", sent$sentence)
sent$sentence <- gsub("broke my heart", "heartbreak", sent$sentence)

sent$sentence <- gsub("cut down", "lower", sent$sentence)
sent$sentence <- gsub("cutting down", "lower", sent$sentence)
sent$sentence <- gsub("took down", "lower", sent$sentence)

sent$sentence <- gsub("cutting rope", "lower", sent$sentence)
sent$sentence <- gsub("cut rope", "lower", sent$sentence)

sent$sentence <- gsub("cut cable", "lower", sent$sentence)
sent$sentence <- gsub("cutting cable", "lower", sent$sentence)

sent$sentence <- gsub("cut ligature", "lower", sent$sentence)
sent$sentence <- gsub("cutting ligature", "lower", sent$sentence)

sent$sentence <- gsub("cut cord", "lower", sent$sentence)
sent$sentence <- gsub("cutting cord", "lower", sent$sentence)

sent$sentence <- gsub("obsessive compulsive", "ocd", sent$sentence)



###### child ####

child_list = c("kid", "kids", "grandaughter", "grandaughters", 
     "grandchild", "grandchilds", "grandson", "grandson", 
     "daughter", "daughter",
     "son", "sons", "baby", "custody", "children",
     "child", "childs", "childrens",
     "stepson", "stepsons",
     "stepdaughter", "stepdaughters")

child_regex <- paste0("\\b(", paste0(child_list, collapse="|"), ")\\b")   
sent$sentence <- gsub(child_regex, "child", sent$sentence)



###### child abuse ####
#child abuse
sent$sentence <- gsub("assaulted child", "childbuse", sent$sentence)
sent$sentence <- gsub("assaulting child", "childbuse", sent$sentence)
sent$sentence <- gsub("assault child", "childbuse", sent$sentence)
sent$sentence <- gsub("assaulted minor", "childbuse", sent$sentence)
sent$sentence <- gsub("assaulting minor", "childbuse", sent$sentence)
sent$sentence <- gsub("assault minor", "childbuse", sent$sentence)

sent$sentence <- gsub("sex child", "childbuse", sent$sentence)
sent$sentence <- gsub("sex minor", "childbuse", sent$sentence)
sent$sentence <- gsub("child sex abuse", "childbuse", sent$sentence)
sent$sentence <- gsub("child sexual abuse", "childbuse", sent$sentence)

sent$sentence <- gsub("abuse minor", "childbuse", sent$sentence)
sent$sentence <- gsub("abused minor", "childbuse", sent$sentence)
sent$sentence <- gsub("abused child", "childbuse", sent$sentence)
sent$sentence <- gsub("abused child", "childbuse", sent$sentence)
sent$sentence <- gsub("abused kid", "childbuse", sent$sentence)
sent$sentence <- gsub("child abuse", "childbuse", sent$sentence)


###### parent/family ####

fam_list = c( "paps",
        "papa",
        "dad", "dads",
        "mom", "moms",
        "stepmom", "stepmoms",
        "stepdad", "stepdads",
        "father", "rathers", 
        "mother", "mothers",
        "parent", "parents", 
        "grandmother", "grandmothers",
        "grandfather", "grandfathers",
        "aunt", "aunts",
        "uncle", "uncles", 
        "family", 
        "sister", "sisters",
        "brother", "brothers",
        "stepsister", "stepsisters",
        "stepbrother", "stepbrothers")

fam_regex <- paste0("\\b(", paste0(fam_list, collapse="|"), ")\\b")   
sent$sentence <- gsub(fam_regex, "family", sent$sentence)



###### police ####

le_list = c( "police",
     "le", "officers", "officers", 
     "sherif", "sheriff", 
     "cop", "cops")

le_regex <- paste0("\\b(", paste0(le_list, collapse="|"), ")\\b")   
sent$sentence <- gsub(le_regex, "police", sent$sentence)

sent$sentence <- gsub("law enforcement", "police", sent$sentence)
sent$sentence <- gsub("police police", "police", sent$sentence)


#strip out white space
sent$sentence<-str_squish(sent$sentence) 


    
###### IP (again) ####
#IP

#again! just in case... 

sent$sentence <- gsub("intimate partner", "iipp", sent$sentence)
sent$sentence <- gsub("dating partner", "iipp", sent$sentence)
sent$sentence <- gsub("significant other", "iipp", sent$sentence)
sent$sentence <- gsub("romantic relationship", "iipp", sent$sentence)
sent$sentence <- gsub("romantic relations", "iipp", sent$sentence)

###### ex (again) ####

#do this again in case stop words were getting in the way before 
    
#pull in borderline iipp words
sent$sentence <- gsub("ex dating", "ex", sent$sentence)
sent$sentence <- gsub("ex dated", "ex", sent$sentence)
sent$sentence <- gsub("ex couple", "ex", sent$sentence)
sent$sentence <- gsub("formerly dating", "ex", sent$sentence)
sent$sentence <- gsub("formerly dated", "ex", sent$sentence)
sent$sentence <- gsub("former couple", "ex", sent$sentence) 
sent$sentence <- gsub("formerly married", "ex", sent$sentence)  
sent$sentence <- gsub("no longer dating", "ex", sent$sentence)
sent$sentence <- gsub("no longer married", "ex", sent$sentence)
sent$sentence <- gsub("previously married", "ex", sent$sentence)
sent$sentence <- gsub("previously dated", "ex", sent$sentence)
sent$sentence <- gsub("exgirlfriend", "ex", sent$sentence)
sent$sentence <- gsub("exboyfriend", "ex", sent$sentence)
sent$sentence <- gsub("exhusband", "ex", sent$sentence) 
sent$sentence <- gsub("exwife", "ex", sent$sentence) 
sent$sentence <- gsub("exspouse", "ex", sent$sentence) 



###### place ####

place_list = c( "place",
    "residence", "apartment", 
    "home", "house", "duplex", "trailer", 
    "shed", "barn", "garage", "studio", "porch", 
    "wall", "window",
    "door")

place_regex <- paste0("\\b(", paste0(place_list, collapse="|"), ")\\b")   
sent$sentence <- gsub(place_regex, "place", sent$sentence)

sent$sentence <- gsub("iipp place", "iippplace", sent$sentence)
sent$sentence <- gsub("place iipp", "iippplace", sent$sentence)
sent$sentence <- gsub("ex place", "iippplace", sent$sentence)
sent$sentence <- gsub("place ex iipp", "iippplace", sent$sentence)
sent$sentence <- gsub("place live iipp", "iippplace", sent$sentence)

#strip out white space
sent$sentence<-str_squish(sent$sentence)

What we have now is a simplified form of the death narratives.

What we have now is a simplified form of the death narratives.

sent %>% select(sentence) %>% slice(1:10)

## # A tibble: 10 × 1
##    sentence                                                          
##    <chr>                                                             
##  1 white nonhispanic male no pattern suicidalitys attempts.          
##  2 suicidality head infront iipp arguing.                            
##  3 iipp immediately called police.                                   
##  4 child place ran room tried stop bleeding applying pressure.       
##  5 police department emergency medical services arrived unresponsive.
##  6 police reports interviews child iipp drinking .                   
##  7 iipp came place place started arguing.                            
##  8 accused iipp cheating iipp denied accusation.                     
##  9 told should put gun head.                                         
## 10 bedroom retrieved mm gun.

### 2b.ii. Load concept term lists

2b.ii. Load concept term lists

Next, we’ll load in the concept term lists that were created a priori
by our human coders. This will help us determine what text is important
from the death narratives, and how to extract that information and
render it as different numerical variables.

Next, we’ll load in the concept term lists that were created a priori
by our human coders. This will help us determine what text is important
from the death narratives, and how to extract that information and
render it as different numerical variables.

load(file="concept_020122.Rdata")

For each concept, there are multiple terms (word or phrase). For
example, the ABUSE concept contains 309 different unique terms.

For each concept, there are multiple terms (word or phrase). For
example, the ABUSE concept contains 309 different unique terms.

concept %>% count(concept)

## # A tibble: 34 × 2
##    concept           n
##    <chr>         <int>
##  1 abuse           309
##  2 argue            96
##  3 aux_condit       32
##  4 child            10
##  5 child_abuse       5
##  6 control         724
##  7 danger_person   488
##  8 danger_weapon   674
##  9 deceipt         191
## 10 dvpo            105
## # … with 24 more rows

This dataset is structured so that each term has it’s own row.

This dataset is structured so that each term has it’s own row.

head(concept %>% select(token, concept))

## # A tibble: 6 × 2
##   token   concept
##   <chr>   <chr>  
## 1 abuse   abuse  
## 2 abused  abuse  
## 3 abusing abuse  
## 4 abusive abuse  
## 5 assalt  abuse  
## 6 assault abuse

We listed terms based on what we observed during human review of the
training set, but also based on existing IPV research literature,
measurement scales, and theory (mirroring the process briefly described
above for the controlled vocabulary). We added different variations of
each term to ensure a comprehensive approach.

We listed terms based on what we observed during human review of the
training set, but also based on existing IPV research literature,
measurement scales, and theory (mirroring the process briefly described
above for the controlled vocabulary). We added different variations of
each term to ensure a comprehensive approach.

To avoid sparsity (low cell counts), we created a “term_root” so that
synonyms or different variations of phrases can be considered together
as a single, comprehensive unit when we calculate the concept scores.
For example, the terms, “enrage”, “infuriate”, “irate”, and “rage” were
all assigned the same token_root, “enrage” so that they can be
considered together.

To avoid sparsity (low cell counts), we created a “term_root” so that
synonyms or different variations of phrases can be considered together
as a single, comprehensive unit when we calculate the concept scores.
For example, the terms, “enrage”, “infuriate”, “irate”, and “rage” were
all assigned the same token_root, “enrage” so that they can be
considered together.

#For example... 
concept %>% select(token, token_root, concept) %>% filter (token_root == "enrage")

## # A tibble: 4 × 3
##   token  token_root concept      
##   <chr>  <chr>      <chr>        
## 1 enrag  enrage     danger_person
## 2 infuri enrage     danger_person
## 3 irat   enrage     danger_person
## 4 rage   enrage     danger_person

### 2b.iii.Tokenize

2b.iii.Tokenize

We’ll use this Concept dataset to determine which terms in the
narratives to retain. Anything that is NOT on the a priori concept term
lists will be thrown away.

We’ll use this Concept dataset to determine which terms in the
narratives to retain. Anything that is NOT on the a priori concept term
lists will be thrown away.

Let’s start with unigrams (single words). We have certain unigrams
that should be stemmed while other unigram terms should not be stemmed.
Separate these out.

Let’s start with unigrams (single words). We have certain unigrams
that should be stemmed while other unigram terms should not be stemmed.
Separate these out.

concept_uni_stem <- concept %>% 
    filter(ngram == 1 & do_not_stem==0)
    
concept_uni_nostem <- concept %>% 
    filter(ngram == 1 & do_not_stem==1)

For bigrams (2-word phrases) and trigrams (3-word phrases), there are
no stemming exceptions.

For bigrams (2-word phrases) and trigrams (3-word phrases), there are
no stemming exceptions.

concept_bi <- concept %>% 
    filter(ngram == 2)

concept_tri <- concept %>% 
    filter(ngram == 3)

Now we can proceed with tokenizing.

Now we can proceed with tokenizing.

library(SnowballC)
library(textstem)

word <- sent %>%  
    unnest_tokens(output=word, input=sentence, token = "words",  drop = FALSE) %>%
    filter(str_length(word) >= 2) %>% #keep words that 2-14 letters in length.
    filter(str_length(word) <= 14)%>%
    mutate(stem = tolower(SnowballC::wordStem(word))) %>%
    #stem vs. not stem options
    left_join(concept_uni_stem %>% mutate(theor=1) %>% select(stem, theor, concept, token_root), by = "stem") %>% 
    left_join(concept_uni_nostem %>% mutate(theor=1, not_stem=1) %>% rename(word = token) %>% select(word, theor, concept, token_root, not_stem), by = "word") %>% 
    #https://stackoverflow.com/questions/35732995/avoiding-and-renaming-x-and-y-columns-when-merging-or-joining-in-r 
    mutate(token = case_when(not_stem==1 ~ word,
                                                 TRUE ~ stem),
                 concept = case_when(!(is.na(concept.x))~ concept.x, 
                                                                     !(is.na(concept.y))~ concept.y),
                 token_root = case_when(!(is.na(token_root.x))~ token_root.x, 
                                                                     !(is.na(token_root.y))~ token_root.y)) %>% 
    filter(theor.x==1 | theor.y ==1) %>% 
    select(id, sentence, sentence_OG, token, token_root, concept)


bigram <- sent %>%  
    unnest_tokens(output=ngram, input=sentence, token = "ngrams", n=2, drop = FALSE) %>%
    #use the same stemming approach as before
    mutate(stem = stem_strings(ngram)) %>%
    #don't worry about stemming exceptions
    left_join(concept_bi %>% mutate(theor=1) %>% select(stem, theor, concept, token_root), by = "stem") %>% 
    filter(theor==1) %>% 
    rename(token = stem) %>% 
    select(id, sentence, sentence_OG, token, token_root, concept)

trigram <- sent %>%  
    unnest_tokens(output=ngram, input=sentence, token = "ngrams", n=3, drop = FALSE) %>%
    #use the same stemming approach as before
    mutate(stem = stem_strings(ngram)) %>%
    #don't worry about stemming exceptions
    left_join(concept_tri %>% mutate(theor=1) %>% select(stem, theor, concept, token_root), by = "stem") %>% 
    filter(theor==1) %>% 
    rename(token = stem) %>% 
    select(id, sentence, sentence_OG, token, token_root, concept)

We’ve retained both the original sentences as well as the reduced
sentences (after replacement, simplification, and/or removal of key
vocabulary) so that it’s easy to see where each term came from.

We’ve retained both the original sentences as well as the reduced
sentences (after replacement, simplification, and/or removal of key
vocabulary) so that it’s easy to see where each term came from.

Now that we have the unigrams, bigrams, and trigrams separated out,
we can combine them all into a single dataset, and tack on one piece of
remaining information from our Concept dataset.

Now that we have the unigrams, bigrams, and trigrams separated out,
we can combine them all into a single dataset, and tack on one piece of
remaining information from our Concept dataset.

token <- rbind(word, bigram, trigram)

token <- token %>%
    left_join(concept %>% select(token_root, rf) %>% unique(), by = "token_root") %>% 
    arrange(id)

token %>% slice(1:10)

## # A tibble: 10 × 7
##    id                               sentence sente…¹ token token…² concept rf_wt
##    <fct>                            <chr>    <chr>   <chr> <chr>   <chr>   <dbl>
##  1 Massachusetts-2019-910382-883719 white n… year o… suic… suicid… self_h… -2.18
##  2 Massachusetts-2019-910382-883719 suicida… v shot… suic… suicid… self_h… -2.18
##  3 Massachusetts-2019-910382-883719 suicida… v shot… infr… infront witness  0.25
##  4 Massachusetts-2019-910382-883719 suicida… v shot… iipp  ip      iipp     0.25
##  5 Massachusetts-2019-910382-883719 suicida… v shot… argu  argue   argue    0.25
##  6 Massachusetts-2019-910382-883719 iipp im… the ii… iipp  ip      iipp     0.25
##  7 Massachusetts-2019-910382-883719 iipp im… the ii… polic police  justic…  0.25
##  8 Massachusetts-2019-910382-883719 child p… the so… child child   child   -1.85
##  9 Massachusetts-2019-910382-883719 child p… the so… ran   ran     evade    0.25
## 10 Massachusetts-2019-910382-883719 police … when t… polic police  justic…  0.25
## # … with abbreviated variable names ¹​sentence_OG, ²​token_root

### 2b.iv. Calculate concept scores

2b.iv. Calculate concept scores

What we’ve just added from the Concept dataset is a variable called
rf. This is the “relative frequency” value which will be used to
implement TF-RF weights (term frequency-relative frequency).

What we’ve just added from the Concept dataset is a variable called
rf. This is the “relative frequency” value which will be used to
implement TF-RF weights (term frequency-relative frequency).

But first, what are TF-RF weights, and why should we use them? There
are multiple terms listed for each concept, but certain terms may be
more/less informative than others. TF-RF weights help us determine how
much each term is useful for the task of distinguishing IPV=yes from
IPV=no. We used the TF-RF implementation approach proposed by Adji
(2016), which up-weights terms that have higher relevance to the target
class (IPV=yes), while down-weighting less relevant terms. Adji’s
approach is described in detail elsewhere, but the general equations
we used to calculate TF-RF weights were:

But first, what are TF-RF weights, and why should we use them? There
are multiple terms listed for each concept, but certain terms may be
more/less informative than others. TF-RF weights help us determine how
much each term is useful for the task of distinguishing IPV=yes from
IPV=no. We used the TF-RF implementation approach proposed by Adji
(2016), which up-weights terms that have higher relevance to the target
class (IPV=yes), while down-weighting less relevant terms.

Adji’s
approach

is described in detail elsewhere, but the general equations
we used to calculate TF-RF weights were:

For all terms in any IPV-related concept list (e.g., physical
violence, abuse, dangerous person…) (tf) * max(Log((A_ij + 1)/(C_ij+1)),
0.25)

For all terms in any IPV-related concept list (e.g., physical
violence, abuse, dangerous person…) (tf) * max(Log((A_ij + 1)/(C_ij+1)),
0.25)

For all terms in miscellaneous other concept lists (e.g., child,
parent/family, self-harm) (tf) * max(Log((A_ij + 1)/(C_ij+1)),
-0.25)

For all terms in miscellaneous other concept lists (e.g., child,
parent/family, self-harm) (tf) * max(Log((A_ij + 1)/(C_ij+1)),
-0.25)

Terms for these equations were defined as follows: tf_train(tj, dk):
Raw term frequency of feature in training set A_ij: Number of deaths
that mention the given term in the training set for the target class,
IPV=yes C_ij: Number of deaths that mention the given term in the
training set for the non-target class, IPV=no

Terms for these equations were defined as follows: tf_train(tj, dk):
Raw term frequency of feature in training set A_ij: Number of deaths
that mention the given term in the training set for the target class,
IPV=yes C_ij: Number of deaths that mention the given term in the
training set for the non-target class, IPV=no

We tested the utility of TF-RF weighting against TF-IDF (Term
Frequency-Inverse Document Frequency), binary representation (yes/no),
and simple frequency, but we found that ultimately, TF-RF yielded the
best performance.

We tested the utility of TF-RF weighting against TF-IDF (Term
Frequency-Inverse Document Frequency), binary representation (yes/no),
and simple frequency, but we found that ultimately, TF-RF yielded the
best performance.

As you can see below, concepts that we hypothesize to be associated
with an IPV=yes label take on positive values for the RF component,
because we assigned them a baseline RF of 0.25 (if even they were not
present in the training set). Miscellaneous concepts were permitted to
take on negative values, and if they were not present in the training
set, they were assigned a baseline of -0.25.

As you can see below, concepts that we hypothesize to be associated
with an IPV=yes label take on positive values for the RF component,
because we assigned them a baseline RF of 0.25 (if even they were not
present in the training set). Miscellaneous concepts were permitted to
take on negative values, and if they were not present in the training
set, they were assigned a baseline of -0.25.

concept %>% 
    group_by(concept) %>% 
    summarize(max_rf = max(rf),
                        min_rf = min(rf),
                        mean_rf = mean(rf))

FALSE # A tibble: 34 × 4
FALSE    concept       max_rf min_rf mean_rf
FALSE    <chr>          <dbl>  <dbl>   <dbl>
FALSE  1 abuse           3.46   0.25   1.73 
FALSE  2 argue           1.81   0.25   0.491
FALSE  3 aux_condit      0.25   0.25   0.25 
FALSE  4 child          -0.25  -3     -1.93 
FALSE  5 child_abuse    -1.34  -2.14  -1.66 
FALSE  6 control         3.17   0.25   0.436
FALSE  7 danger_person   3.46   0.25   0.595
FALSE  8 danger_weapon   2.58   0.25   0.604
FALSE  9 deceipt         1.58   0.25   0.480
FALSE 10 dvpo            3.32   0.25   1.61 
FALSE # … with 24 more rows

#note that the self-harm only has one entry, that is because we've already simplified most of these terms during the "replace all" approach already.

The Concept dataset only provides information about the RF component
of the TF-RF calculations. The TF component will be taken from the 2019
NVDRS dataset we’re working on.

The Concept dataset only provides information about the RF component
of the TF-RF calculations. The TF component will be taken from the 2019
NVDRS dataset we’re working on.

To determine how frequently each term is mentioned per case (i.e.,
TF), we need to go from the term-level (one row per term) up to the
case-level (on row per decedent). To accomplish this, we’ll summ the
TF-RF weights for all terms in each concept list, yielding a single
score for each concept per case.

To determine how frequently each term is mentioned per case (i.e.,
TF), we need to go from the term-level (one row per term) up to the
case-level (on row per decedent). To accomplish this, we’ll summ the
TF-RF weights for all terms in each concept list, yielding a single
score for each concept per case.

case_concept <- token %>% 
    #one token_root may appear multiple times within one case, so first go to the id/token_root level 
    mutate(tf=1) %>% 
    group_by(id, token_root, concept) %>%
    summarize(tf = sum(tf),
                        rf = mean(rf)) %>%  
    #calculate TF-RF
    mutate(tf_rf = tf*rf) %>% 
    #now we have tf-rf for each token/document
    #need to go up to the case-level
    #summarize at concept-level first
    group_by(id, concept) %>%
    summarize(tf_rf = sum(tf_rf)) %>% 
    #pivot so each concept becomes it's own variable
    pivot_wider(id_cols = id, 
                        names_from=concept,
                        values_from= c(tf_rf), 
                        values_fill = 0) %>%
    as_tibble()

Our dataset is now organized so that each case has a concept score,
based on the information we derived from the CME and LE death
narratives. We’ll make two quick summaries across these concepts as
bonus features. The first simply adds up all the IPV-related concept
scores (across all IPV concepts) and the other tries to summarize how
much self-harm language might be used to manipulate or intimidate
another person.

Our dataset is now organized so that each case has a concept score,
based on the information we derived from the CME and LE death
narratives. We’ll make two quick summaries across these concepts as
bonus features. The first simply adds up all the IPV-related concept
scores (across all IPV concepts) and the other tries to summarize how
much self-harm language might be used to manipulate or intimidate
another person.

case_concept <- case_concept %>% 
    mutate( wtsum_ipv_concepts = harm_other + harm_emot + harm_sex + harm_phys + 
            fear + evade +  economic + jeal + deceipt + control + rev + witness +
            pics + ip_place + property + 
            danger_person + danger_weapon + stalk + 
            threat + threat_suicide + 
            abuse + dvpo,
    wtsum_condit_pattern = aux_condit + pattern + self_harm + argue) 


#add prefix so there variables are easy to identify later
case_concept <- case_concept %>% 
    setNames(paste0('c_', names(.))) %>%
    rename(id = c_id)

case_concept %>% slice(1)

## # A tibble: 1 × 37
##   id     c_argue c_aux…¹ c_child c_con…² c_dan…³ c_dan…⁴ c_dec…⁵ c_evade c_har…⁶
##   <fct>    <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>
## 1 Massa…    1.25     0.5   -12.0    0.25    1.47    0.75    0.25    0.75   0.351
## # … with 27 more variables: c_iipp <dbl>, c_jeal <dbl>, c_justice_inv <dbl>,
## #   c_no_ipv <dbl>, c_pattern <dbl>, c_self_harm <dbl>, c_threat_suicide <dbl>,
## #   c_witness <dbl>, c_parent_fam <dbl>, c_ip_past <dbl>, c_pics <dbl>,
## #   c_rev <dbl>, c_property <dbl>, c_threat <dbl>, c_ip_place <dbl>,
## #   c_harm_other <dbl>, c_ip_injury <dbl>, c_abuse <dbl>, c_stalk <dbl>,
## #   c_harm_emot <dbl>, c_harm_sex <dbl>, c_dvpo <dbl>, c_economic <dbl>,
## #   c_fear <dbl>, c_child_abuse <dbl>, c_wtsum_ipv_concepts <dbl>, …

If you are running this code on a small dataset with limited text,
you might find that some of these concept scores did not get created,
because no keywords for the corresponding concept list was found in the
text. If that is the case, simply delete that concept variable from the
code above and try re-running this last step. Then, create an “empty”
variable for each missing concept score where all the values are set to
zero. You can do this in a simple mutate within a dplyr pipeline (e.g.,
case_concept <- case_concept %>% mutate(c_abuse = 0).

If you are running this code on a small dataset with limited text,
you might find that some of these concept scores did not get created,
because no keywords for the corresponding concept list was found in the
text. If that is the case, simply delete that concept variable from the
code above and try re-running this last step. Then, create an “empty”
variable for each missing concept score where all the values are set to
zero. You can do this in a simple mutate within a dplyr pipeline (e.g.,
case_concept <- case_concept %>% mutate(c_abuse = 0).

# 3. Clean existing NVDRS variables

3. Clean existing NVDRS variables

Before we can apply to classifier, we still need to clean the
administrative variables. It is important that you run this step (don’t
skip it!!); the IPV classifier relies on variables being named and
formatted in a particular way, otherwise it will not run.

Before we can apply to classifier, we still need to clean the
administrative variables. It is important that you run this step (don’t
skip it!!); the IPV classifier relies on variables being named and
formatted in a particular way, otherwise it will not run.

Information about which variables we are using for this project are
posted in a separate document, be sure you include those in your NVDRS
RAD request to CDC so that they will all be included when you receive
your RAD dataset.

Information about which variables we are using for this project are
posted in a separate document, be sure you include those in your NVDRS
RAD request to CDC so that they will all be included when you receive
your RAD dataset.

nvdrs_clean <- nvdrs_ss %>%
    mutate(id = paste(siteid, incidentyear, incidentid, personid, sep="-"), 
        state = siteid,
    #Narrative length   
    n_narr_len = stringi::stri_width(paste(narrativecme, narrativele)),
    #Demographics - sex 
    vdrs_demog_male = ifelse(sex=="Male", 1, 0),
    vdrs_demog_female_SUMM = ifelse(sex=="Female", 1, 0),
    vdrs_demog_gender_SUMM = ifelse(sex=="Male", "Men", "Women"),
    #Demographics - age
    vdrs_demog_age = as.numeric(ageyears_c),
    vdrs_demog_age = ifelse(vdrs_demog_age>100, 100, vdrs_demog_age),
        vdrs_demog_age_grp_SUMM = case_when(vdrs_demog_age<10 ~ "<10 yrs",
        vdrs_demog_age>=10 & vdrs_demog_age<=24 ~ "10-24 yrs", 
        vdrs_demog_age>=25 & vdrs_demog_age<=40 ~ "25-40 yrs",
        vdrs_demog_age>=41 & vdrs_demog_age<=54 ~ "41-54 yrs",
        vdrs_demog_age>=55 & vdrs_demog_age<=70 ~ "55-70 yrs",
        vdrs_demog_age>=71 ~ "71+ yrs"),
    #Demographics - race/ethnicity              
    vdrs_demog_race_eth_SUMM = case_when(raceethnicity_c=="White, non-Hispanic" ~ "White (NH)",
     raceethnicity_c== "Black or African American, non-Hispanic" ~ "Black (NH)",
     raceethnicity_c =="American Indian/Alaska Native, non-Hispanic" ~ "AI/AN (NH)",    
     raceethnicity_c == "Asian/Pacific Islander, non-Hispanic" ~ "Asian (NH)",
     raceethnicity_c == "Hispanic" ~ "Hispanic",    
     raceethnicity_c == "Two or more races, non-Hispanic" |
     raceethnicity_c == "Unknown race, non-Hispanic"      |
     raceethnicity_c == "Other/Unspecified, non-Hispanic" ~  "Other/unknown (NH)"), 
    vdrs_demog_race_eth_white = ifelse(vdrs_demog_race_eth_SUMM== "White (NH)", 1, 0),
    vdrs_demog_race_eth_black = ifelse(vdrs_demog_race_eth_SUMM== "Black (NH)", 1, 0),
    vdrs_demog_race_eth_aian = ifelse(vdrs_demog_race_eth_SUMM== "AI/AN (NH)", 1, 0),               
    vdrs_demog_race_eth_asian = ifelse(vdrs_demog_race_eth_SUMM== "Asian (NH)", 1, 0),
    vdrs_demog_race_eth_hisp = ifelse(vdrs_demog_race_eth_SUMM== "Hispanic", 1, 0),
    vdrs_demog_race_eth_other_unk = ifelse(vdrs_demog_race_eth_SUMM== "Other/unknown (NH)", 1, 0),
    #Demographics - marital status
    vdrs_demog_mar_SUMM = maritalstatus,
    vdrs_demog_mar_married = ifelse(maritalstatus== "Married/Civil Union/Domestic Partnership", 1, 0),
    vdrs_demog_mar_sep = ifelse(maritalstatus== "Married/Civil Union/Domestic Partnership, but separated", 1, 0),
    vdrs_demog_mar_never_or_single = ifelse(maritalstatus== "Never Married", 1, 0),
    vdrs_demog_mar_never_or_single = ifelse(maritalstatus== "Single, not otherwise specified", 1, 0),
    vdrs_demog_mar_widow = ifelse(maritalstatus== "Widowed", 1, 0),
    vdrs_demog_mar_divorced = ifelse(maritalstatus== "Divorced", 1, 0),
    #Demographics - educational attainment   
    vdrs_demog_educ_SUMM = educationlevel,
    vdrs_demog_educ_hs_less =ifelse(educationlevel == "8th grade or less" |
         educationlevel == "9th to 12th grade, no diploma" , 1, 0),
    vdrs_demog_educ_hs =     ifelse(educationlevel == "High school graduate or GED completed" , 1, 0),
    vdrs_demog_educ_bs =     ifelse(educationlevel == "Bachelor's degree" , 1, 0),
    vdrs_demog_educ_asc_or_somecollg = ifelse(educationlevel == "Associate's degree" |
        educationlevel == "Some college credit, but no degree", 1, 0),
    vdrs_demog_educ_more =   ifelse(educationlevel == "Doctorate or Professional degree" |
        educationlevel == "Master's degree", 1, 0),
    #Demographics - other   
    vdrs_demog_military = ifelse(military=="Yes", 1, 0),
    vdrs_demog_pregnant = case_when(pregnant=="Pregnant at time of death" ~ 1, 
        pregnant=="Pregnant, not otherwise specified" ~ 1,
        pregnant=="Not pregnant but pregnant w/in 42 days of death" ~ 1,  #RECENTLY pregnant
        pregnant=="Not pregnant but pregnant 43 days to 1 year before death" ~ 1,
        TRUE ~ 0),
     vdrs_demog_sexorent = ifelse(sexualorientation=="Lesbian" | sexualorientation=="Gay" | 
        sexualorientation=="Bisexual" | sexualorientation=="Unspecified sexual minority", 1, 0),
    vdrs_demog_trans = ifelse(transgender=="Yes", 1, 0),
    
    #Incident variables 
   yr_2010 = ifelse(incidentyear==2010, 1, 0), 
     yr_2011 = ifelse(incidentyear==2011, 1, 0),
     yr_2012 = ifelse(incidentyear==2012, 1, 0),
     yr_2013 = ifelse(incidentyear==2013, 1, 0),                                        
     yr_2014 = ifelse(incidentyear==2014, 1, 0),
     yr_2015 = ifelse(incidentyear==2015, 1, 0),
     yr_2016 = ifelse(incidentyear==2016, 1, 0),
     yr_2017 = ifelse(incidentyear==2017, 1, 0),
     yr_2018 = ifelse(incidentyear==2018, 1, 0), 
    #no 2019 cases were used for training, thus info for that year was not used as a predictor for the model
    #even if you are using data post 2019 (therefore, these dummy variables are all zeroes)
    #still create these placeholders anyway so that the model will run
    vdrs_incd_manner_SUMM = case_when(abstractordeathmanner_c== "Suicide or intentional self-harm" ~ "Suicide",
        abstractordeathmanner_c== "Terrorism suicide"                 ~ "Suicide",
        abstractordeathmanner_c== "Homicide"                          ~ "Homicide",
        abstractordeathmanner_c== "Terrorism homicide"                ~ "Homicide", 
        abstractordeathmanner_c== "Undetermined intent"               ~ "Undetermined",     
        str_detect(abstractordeathmanner_c, "Unintentional")==TRUE    ~ "Unintentional",
        abstractordeathmanner_c=="Legal intervention (by police or other authority)" ~ "Legal intv",        
        TRUE ~ "Other/missing"),
    vdrs_incd_home = ifelse(injuredatvictimhome== "Yes", 1, 0),
    vdrs_weap_SUMM = case_when(weapontype1== "Firearm" ~ "Firearm", 
      weapontype1== "Sharp instrument" ~ "Sharp instrument",
      weapontype1== "Hanging, strangulation, suffocation" ~ "Hanging, strangulation, suffocation",
      weapontype1== "Fall" ~ "Fall",
      weapontype1== "Poisoning" ~ "Poisoning",                                                   
      TRUE ~ "Other"),               
    vdrs_weap_firearm = case_when(weapontype1== "Firearm" ~ 1, TRUE ~ 0),
    vdrs_weap_fall =    case_when(weapontype1== "Fall"  ~ 1, TRUE ~ 0),
    vdrs_weap_sharp =   case_when(weapontype1== "Sharp instrument"  ~ 1, TRUE ~ 0),
    vdrs_weap_hang =    case_when(weapontype1== "Hanging, strangulation, suffocation"   ~ 1, TRUE ~ 0),
    vdrs_weap_poison =  case_when(weapontype1== "Poisoning" ~ 1, TRUE ~ 0),
    
    #Life circumstances and mental/behavioral health             
    vdrs_life_crisis = ifelse(anycrisis_c== "Yes", 1, 0),
    vdrs_mh_curr =     ifelse(mentalhealthproblem_c== "Yes", 1, 0),
    vdrs_mh_dep =      ifelse(depressedmood_c=="Yes", 1, 0),    
    vdrs_mh_tx_curr =  ifelse(mentalillnesstreatmentcurrnt_c=="Yes", 1, 0),
    vdrs_mh_tx_ever =  ifelse(historymentalillnesstreatmnt_c=="Yes", 1, 0),
    vdrs_bh_alc =      ifelse(alcoholproblem_c=="Yes", 1, 0),       
    vdrs_bh_su =       ifelse(substanceabuseother_c=="Yes", 1, 0),  
    vdrs_bh_other =    ifelse(otheraddiction_c=="Yes", 1, 0),       
    vdrs_life_crime =  ifelse(precipitatedbyothercrime_c=="Yes", 1, 0),         
    vdrs_life_stalk =  ifelse(stalking_c== "Yes", 1, 0),
    vdrs_life_argue = ifelse(argument_c== "Yes", 1, 0),
    vdrs_life_fight = ifelse(fightbetweentwopeople_c== "Yes", 1, 0),           
    vdrs_viol_perp = ifelse(interpersonalviolenceperp_c== "Yes", 1, 0),                      
    vdrs_viol_vict = ifelse(interpersonalviolencevictim_c== "Yes", 1, 0),
    vdrs_hist_ca = ifelse(abusedaschild_c=="Yes", 1, 0),            
    vdrs_relat_fam = ifelse(familyrelationship_c=="Yes", 1, 0),
    vdrs_relat_notip = ifelse(relationshipproblemother_c=="Yes", 1, 0),     
    vdrs_tox = numbersubstances_c,
    #suicide-specific
  vdrs_suic_note = ifelse(suicidenote_c=="Yes", 1, 0),                   
  vdrs_suic_disclose = ifelse(suicideintentdisclosed_c=="Yes", 1, 0),
  vdrs_suic_disclose_ipp = ifelse(disclosedtointimatepartner_c=="Yes", 1, 0),
  vdrs_suic_hist_attmpt = ifelse(suicideattempthistory_c=="Yes", 1, 0),                  
  vdrs_suic_hist_thought = ifelse(suicidethoughthistory_c=="Yes", 1, 0),
  vdrs_relat_ipp = ifelse(intimatepartnerproblem_c=="Yes", 1, 0),   
  vdrs_relat_ipp_c = ifelse(crisisintimatepartnerproblem_c=="Yes", 1, 0),
  vdrs_legal_crim = ifelse(recentcriminallegalproblem_c=="Yes", 1, 0),      
  vdrs_legal_other = ifelse(legalproblemother_c=="Yes", 1, 0),
  vdrs_famfrd_death = ifelse(deathfriendorfamilyother_c=="Yes", 1, 0),
  vdrs_famfrd_suic = ifelse(recentsuicidefriendfamily_c=="Yes", 1, 0),      
  vdrs_hist_anniv = ifelse(traumaticanniversary_c=="Yes", 1, 0),        
  vdrs_life_physhealth = ifelse(physicalhealthproblem_c=="Yes", 1, 0),
  vdrs_life_job = ifelse(jobproblem_c=="Yes", 1, 0),        
  vdrs_life_financ = ifelse(financialproblem_c=="Yes", 1, 0),   
  vdrs_life_evict = ifelse(evictionorlossofhome_c=="Yes", 1, 0),     
  vdrs_life_school = ifelse(schoolproblem_c=="Yes", 1, 0),
    #variables not consistently filled out for suicides
  vdrs_ipv_jeal = ifelse(intimatepartnerviolence_c=="Yes" | jealousy_c=="Yes", 1, 0))

## Warning in mask$eval_all_mutate(quo): NAs introduced by coercion

#Note that age was originally continuous,
#when we converted to age groups, NAs may be introduced by coercion.

Even though we won’t have data from earlier years here (e.g., 2010,
2011) , the model was built with these variables baked in, so we need to
create empty variables anyway.

Even though we won’t have data from earlier years here (e.g., 2010,
2011) , the model was built with these variables baked in, so we need to
create empty variables anyway.

We used census bureau designated regions to record where each case
came from.

We used census bureau designated regions to record where each case
came from.

#Census Bureau-designated regions -https://en.wikipedia.org/wiki/List_of_regions_of_the_United_States

NE <- c("Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont",
    "New Jersey", "New York", "Pennsylvania")

MW <- c("Illinois", "Indiana", "Michigan", "Ohio", "Wisconsin",
    "Iowa", "Kansas", "Minnesota", "Missouri", "Nebraska", "North Dakota", "South Dakota")

S<- c("Delaware", "Florida", "Georgia", "Maryland", "North Carolina", "South Carolina", 
    "Virginia", "District of Columbia", "West Virginia", "Alabama", "Kentucky", "Mississippi", "Tennessee",
    "Arkansas", "Louisiana", "Oklahoma","Texas")

W<-c("Arizona", "Colorado", "Idaho", "Montana", "Nevada", "New Mexico", "Utah", "Wyoming",
  "Alaska", "California", "Hawaii", "Oregon", "Washington")

#Puerto Rico and other US territories are not part of any census region or census division


nvdrs_clean <- nvdrs_clean %>%
    mutate(vdrs_incd_region_SUMM=case_when(state %in% NE ~ "Northeast",
            state %in% MW ~ "Midwest",
            state %in% S ~ "South",
            state %in% W ~ "West",
            TRUE ~ "Trrty/Unk"),
     vdrs_incd_reg_NE=ifelse(state %in% NE, 1, 0),
     vdrs_incd_reg_MW=ifelse(state %in% MW, 1, 0),
     vdrs_incd_reg_S=ifelse(state %in% S, 1, 0),
     vdrs_incd_reg_W=ifelse(state %in% W, 1, 0))

#Keep only variables of interest
nvdrs_clean <-  nvdrs_clean %>% 
    select(id, state, incidentyear, incidentid, personid, 
                 narrativecme, narrativele, n_narr_len, starts_with("vdrs_"), starts_with("yr_"))

#sort variables alphabetically
nvdrs_clean <- nvdrs_clean %>% 
    select(sort(names(.)))

Let’s check to see how the dataset is shaping up.

Let’s check to see how the dataset is shaping up.

#check
names(nvdrs_clean)

##  [1] "id"                               "incidentid"                      
##  [3] "incidentyear"                     "n_narr_len"                      
##  [5] "narrativecme"                     "narrativele"                     
##  [7] "personid"                         "state"                           
##  [9] "vdrs_bh_alc"                      "vdrs_bh_other"                   
## [11] "vdrs_bh_su"                       "vdrs_demog_age"                  
## [13] "vdrs_demog_age_grp_SUMM"          "vdrs_demog_educ_asc_or_somecollg"
## [15] "vdrs_demog_educ_bs"               "vdrs_demog_educ_hs"              
## [17] "vdrs_demog_educ_hs_less"          "vdrs_demog_educ_more"            
## [19] "vdrs_demog_educ_SUMM"             "vdrs_demog_female_SUMM"          
## [21] "vdrs_demog_gender_SUMM"           "vdrs_demog_male"                 
## [23] "vdrs_demog_mar_divorced"          "vdrs_demog_mar_married"          
## [25] "vdrs_demog_mar_never_or_single"   "vdrs_demog_mar_sep"              
## [27] "vdrs_demog_mar_SUMM"              "vdrs_demog_mar_widow"            
## [29] "vdrs_demog_military"              "vdrs_demog_pregnant"             
## [31] "vdrs_demog_race_eth_aian"         "vdrs_demog_race_eth_asian"       
## [33] "vdrs_demog_race_eth_black"        "vdrs_demog_race_eth_hisp"        
## [35] "vdrs_demog_race_eth_other_unk"    "vdrs_demog_race_eth_SUMM"        
## [37] "vdrs_demog_race_eth_white"        "vdrs_demog_sexorent"             
## [39] "vdrs_demog_trans"                 "vdrs_famfrd_death"               
## [41] "vdrs_famfrd_suic"                 "vdrs_hist_anniv"                 
## [43] "vdrs_hist_ca"                     "vdrs_incd_home"                  
## [45] "vdrs_incd_manner_SUMM"            "vdrs_incd_reg_MW"                
## [47] "vdrs_incd_reg_NE"                 "vdrs_incd_reg_S"                 
## [49] "vdrs_incd_reg_W"                  "vdrs_incd_region_SUMM"           
## [51] "vdrs_ipv_jeal"                    "vdrs_legal_crim"                 
## [53] "vdrs_legal_other"                 "vdrs_life_argue"                 
## [55] "vdrs_life_crime"                  "vdrs_life_crisis"                
## [57] "vdrs_life_evict"                  "vdrs_life_fight"                 
## [59] "vdrs_life_financ"                 "vdrs_life_job"                   
## [61] "vdrs_life_physhealth"             "vdrs_life_school"                
## [63] "vdrs_life_stalk"                  "vdrs_mh_curr"                    
## [65] "vdrs_mh_dep"                      "vdrs_mh_tx_curr"                 
## [67] "vdrs_mh_tx_ever"                  "vdrs_relat_fam"                  
## [69] "vdrs_relat_ipp"                   "vdrs_relat_ipp_c"                
## [71] "vdrs_relat_notip"                 "vdrs_suic_disclose"              
## [73] "vdrs_suic_disclose_ipp"           "vdrs_suic_hist_attmpt"           
## [75] "vdrs_suic_hist_thought"           "vdrs_suic_note"                  
## [77] "vdrs_tox"                         "vdrs_viol_perp"                  
## [79] "vdrs_viol_vict"                   "vdrs_weap_fall"                  
## [81] "vdrs_weap_firearm"                "vdrs_weap_hang"                  
## [83] "vdrs_weap_poison"                 "vdrs_weap_sharp"                 
## [85] "vdrs_weap_SUMM"                   "yr_2010"                         
## [87] "yr_2011"                          "yr_2012"                         
## [89] "yr_2013"                          "yr_2014"                         
## [91] "yr_2015"                          "yr_2016"                         
## [93] "yr_2017"                          "yr_2018"

Looks cleaner, doesn’t it?

Looks cleaner, doesn’t it?

# 4. Prepare dataset

4. Prepare dataset

We now have all the separate components that we need to run the
classifier. Put all the variables in a single dataset and make sure the
formatting is ready to go.

We now have all the separate components that we need to run the
classifier. Put all the variables in a single dataset and make sure the
formatting is ready to go.

ready <- left_join(nvdrs_clean, txt_feat) 
#Combine NVDRS RAD vars w/ txt features (grammar, sentiment scores)
ready <- left_join(ready, case_concept) #Combine with concept scores we just created

This model will not run if there are missing values in the dataset.
In our case, any missing values could have been generated if there were
no concepts present in the death narrative. Thus, we can set all numeric
missing values to zero at this stage.

This model will not run if there are missing values in the dataset.
In our case, any missing values could have been generated if there were
no concepts present in the death narrative. Thus, we can set all numeric
missing values to zero at this stage.

#deal with missing data
ready   <- ready %>% 
    #missing
    mutate_if(is.numeric, replace_na, 0)

If there are any NVDRS variables with missing values, you can review
them on a case-by-case to confirm that missing should be set to zero
vs. dropped from the analytic sample.

If there are any NVDRS variables with missing values, you can review
them on a case-by-case to confirm that missing should be set to zero
vs. dropped from the analytic sample.

# 5. Apply classifier

5. Apply classifier

Load in the IPV Classider. The classifier automatically normalizes
all continuous variables, otherwise, the rest of the data cleaning is
DONE. Go ahead and use the Tidymodels package to make your
predictions.

Load in the IPV Classider. The classifier automatically normalizes
all continuous variables, otherwise, the rest of the data cleaning is
DONE. Go ahead and use the Tidymodels package to make your
predictions.

load(file = "IPV_Related_Suicide_rfmodel_2022_01_28.Rdata")

library(tidymodels)
#make predictions
pred <- predict(rf_final_model, ready, type = "prob") %>% 
    bind_cols(ready %>% select(id)) %>%
  mutate(pred_class = ifelse(.pred_yes>0.5, 1, 2))

#code the predicted class correctly as a factor
pred$pred_class <- factor(pred$pred_class,
        levels = c(1,2),
        labels = c("yes", "no"))

If any variables appear to be missing (e.g., some of the rarer
concept scores may not have been created if none of the corresponding
keywords showed up in your text), then you can create an empty variable
where all values are set to zero and try re-running the predictions.

If any variables appear to be missing (e.g., some of the rarer
concept scores may not have been created if none of the corresponding
keywords showed up in your text), then you can create an empty variable
where all values are set to zero and try re-running the predictions.

Otherwise… You should now have one prediction per case. Thanks for
walking through this demo with me. Best of luck with your own research,
data science work, or applied public health practice!

Otherwise… You should now have one prediction per case. Thanks for
walking through this demo with me. Best of luck with your own research,
data science work, or applied public health practice!

pred %>% select(vdrs_demog_age, vdrs_demog_male, pred_class, .pred_yes) %>% head()

## # A tibble: 6 × 4
##   vdrs_demog_age vdrs_demog_male pred_class .pred_yes
##            <dbl>           <dbl> <fct>          <dbl>
## 1             45               1 no           0.0283 
## 2             62               1 no           0.202  
## 3             32               1 no           0.165  
## 4             54               1 yes          0.618  
## 5             68               1 no           0.00331
## 6             29               1 no           0.102

// add bootstrap table styles to pandoc tables
function bootstrapStylePandocTables() {
  $('tr.odd').parent('tbody').parent('table').addClass('table table-condensed');
}
$(document).ready(function () {
  bootstrapStylePandocTables();
});

tabsets

$(document).ready(function () {
  window.buildTabsets("TOC");
});

$(document).ready(function () {
  $('.tabset-dropdown > .nav-tabs > li').click(function () {
    $(this).parent().toggleClass('nav-tabs-open');
  });
});

code folding

$(document).ready(function ()  {

    // temporarily add toc-ignore selector to headers for the consistency with Pandoc
    $('.unlisted.unnumbered').addClass('toc-ignore')

    // move toc-ignore selectors from section div to header
    $('div.section.toc-ignore')
        .removeClass('toc-ignore')
        .children('h1,h2,h3,h4,h5').addClass('toc-ignore');

    // establish options
    var options = {
      selectors: "h1,h2,h3",
      theme: "bootstrap3",
      context: '.toc-content',
      hashGenerator: function (text) {
        return text.replace(/[.\\/?&!#<>]/g, '').replace(/\s/g, '_');
      },
      ignoreSelector: ".toc-ignore",
      scrollTo: 0
    };
    options.showAndHide = true;
    options.smoothScroll = true;

    // tocify
    var toc = $("#TOC").tocify(options).data("toc-tocify");
});

dynamically load mathjax for compatibility with self-contained

(function () {
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src  = "https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML";
    document.getElementsByTagName("head")[0].appendChild(script);
  })();