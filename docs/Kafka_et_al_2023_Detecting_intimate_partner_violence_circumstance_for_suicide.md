# Detecting intimate partner violence circumstance for suicide: development and validation of a tool using natural language processing and supervised machine learning in the National Violent Death Reporting System

Julie M Kafka, Mike D Fliss, Pamela J Trangenstein, Luz McNaughton Reyes, Brian W Pence, Kathryn E Moracco

*Injury Prevention* 2023;29:134–141. doi:10.1136/ip-2022-044662

## Abstract

### Background
Intimate partner violence (IPV) victims and perpetrators often report suicidal ideation, yet there is no comprehensive national dataset that allows for an assessment of the connection between IPV and suicide. The National Violent Death Reporting System (NVDRS) captures IPV circumstances for homicide-suicides (<2% of suicides), but not single suicides (suicide unconnected to other violent deaths; >98% of suicides).

### Objective
To facilitate a more comprehensive understanding of the co-occurrence of IPV and suicide, we developed and validated a tool that detects mentions of IPV circumstances (yes/no) for single suicides in NVDRS death narratives.

### Methods
We used 10,000 hand-labelled single suicide cases from NVDRS (2010–2018) to train (n=8500) and validate (n=1500) a classification model using supervised machine learning. We used natural language processing to extract relevant information from the death narratives within a concept normalisation framework. We tested numerous models and present performance metrics for the best approach.

### Results
Our final model had robust sensitivity (0.70), specificity (0.98), precision (0.72) and kappa values (0.69). False positives mostly described other family violence. False negatives used vague and heterogeneous language to describe IPV, and often included abusive suicide threats.

### Implications
It is possible to detect IPV circumstances among singles suicides in NVDRS, although vague language in death narratives limited our tool's sensitivity. More attention to the role of IPV in suicide is merited both during the initial death investigation processes and subsequent NVDRS reporting. This tool can support future research to inform targeted prevention.

## Introduction

Suicide is a leading cause of death in the USA, and age-adjusted suicide rates have risen more than 30% in the past two decades (1999–2019). Despite these trends, researchers have made limited progress predicting and preventing suicide. Extant research tends to focus on underlying psychopathology as the cause for suicide, but precipitating factors (ie, the reasons or circumstances that led a person to make a suicide attempt) may help to identify people who are acutely suicidal and allow preventive intervention.

Intimate partner violence (IPV; physical, psychological or sexual abuse by a current or former intimate partner, IP) may be an important precipitating factor for suicide. Both IPV victims and perpetrators report high rates of suicidal thoughts and non-fatal suicidal behaviours, and research suggests that crises in romantic relationships can prompt suicidality. However, there is not yet evidence establishing whether IPV contributes to suicide mortality.

### Suicide data in the USA
In the USA, detailed suicide data are compiled through the National Violent Death Reporting System (NVDRS), which is administered by the Centers for Disease Control and Prevention (CDC). CDC funds states to record information about each violent death based on reports from coroners or medical examiners (CME), law enforcement (LE) and death certificates.

NVDRS systematically captures IPV circumstances for homicide-suicides (<2% of suicides), but not single suicides (suicides unconnected to other violent deaths; >98% of suicides). While IPV circumstances are not recorded for single suicides in any close-ended data fields, NVDRS does provide written summaries about known circumstances for each death, which may contain valuable textual information about IPV.

Researchers have conducted studies in Kentucky, North Carolina and for youth suicides across multiple states by manually reviewing NVDRS death narratives. Collectively, they identified IPV circumstances in 6.1%–11.4% of suicides. Comprehensively understanding the prevalence of IPV as a precipitating factor for suicide, however, requires nationally representative data—a task that would be challenging to accomplish using manual case review.

### The current study
We used supervised machine learning (SML) and natural language processing (NLP) to develop and validate a tool that detects mention of IPV circumstances for single suicides in NVDRS. This tool could save time and resources for researchers while enhancing available data to help expedite development and evaluation of integrated suicide and IPV prevention strategies.

## Methods

We used NVDRS data from 40 states, Washington DC, and Puerto Rico from 2010 to 2018. We focused exclusively on single suicides—other methods already exist for ascertaining IPV circumstances for homicide-suicides. Neither patients nor the public were involved in this research, which used deidentified data.

### SML approach
SML entails mapping complex associations between input variables (X) and a human-labelled outcome (Y). SML occurs across two phases: training and validation. During training, the computer adjusts parameters to fit a model to optimally predict labels for Y (IPV circumstances=yes/no). We trained our model using 8500 labelled cases. We used 10-fold cross-validation and made iterative changes to the input variables to maximise performance in the training data. Once we saw diminishing returns from further changes, we finalised the model.

For validation, we used a random sample of n=1500 NVDRS cases (not included in training) to assess model performance. During validation, the human-coded IPV label was hidden from the computer to allow comparison of model predictions for Y against the 'true' human assessment.

### Sampling and labeling
We established gold standard labels (Y) by having human coders read the death narratives for each case and record whether they mentioned IPV as a precipitating factor in the death (yes/no). Our codebook used CDC's definition for IPV circumstances (used in NVDRS to code homicide cases) to guide this labelling process. On average, it took 2–3 min to read the narratives and label each case.

During hand-coding, we followed the NVDRS convention to code a case as 'yes' only when there was sufficient evidence that the circumstance (eg, IPV) was truly present. A 'no' suggests that IPV was either not present or unknown. In other words, 'no' was applied both when IPV was definitively absent and in situations when information about IPV was unclear or missing.

Most (>80%) training data were obtained from Kafka et al and Graham et al, where cases were sampled purposively from NVDRS to identify as many IPV-related suicides (ie, suicides with IPV circumstances) as possible. Kafka et al and Graham et al had robust inter-rater reliability denoted by a Kappa of 0.71–0.73, similar to previous research. Ten per cent of cases were coded by two humans. All other cases were reviewed by one person.

We augmented available hand-coded cases with additional suicides from NVDRS (2013–2018) using stratified random sampling. This helped ensure we had enough IPV=yes and IPV=no cases from across different races, ethnicities, regions and age groups to train a model that would perform stably among underrepresented groups. To validate the model with representative data, we took a simple random sample of cases from NVDRS (2013–2018).

### Input variables
We expected that the linguistic heterogeneity of IPV language in the death narratives might pose challenges for this endeavor. Thus, we provided any/all available input variables (117 variables in total after data cleaning) that might be helpful for the classification task. We used existing NVDRS variables, including demographics (eg, age, gender), incident characteristics (eg, suicide means, year) and circumstances information (eg, recent job problems).

We also used NLP to extract information from text and render it in a numeric format as an input for the SML model. Using a dictionary approach, we created novel concept scores that represent how frequently the death narratives mentioned a relevant concept (eg, physical abuse) for each case. Drawing on the extant IPV literature and our human labelling experience in the training dataset, we identified over 25 IPV-related concepts, including physical abuse, sexual abuse, stalking, deceit, jealousy and others. We also included miscellaneous helper concepts like negated mentions of IPV.

For each concept, we drafted keyword/phrase (ie, term) lists. For example, the physical abuse concept included terms like 'hit' and 'beat'. To measure the presence/absence of each concept, CME and LE death narratives were concatenated into a single text and cleaned following common NLP preprocessing steps. We retained words or phrases only if they appeared on our a priori term lists. We then counted the terms present within each concept and summed their term frequency-relative frequency (TF-RF) weights to establish weighted concept scores. This process is depicted in Figure 1.

In addition, we used off-the-shelf NLP approaches to create supplemental text-derived variables. Grammatical characteristics may signal mood, social context or action/inaction. Accordingly, we created variables such as counts of first-person pronouns (eg, 'I', 'me'). We also calculated sentiment scores, which represent trends in language or emotion. Valence Aware Dictionary for Sentiment Reasoning scores summarise polarity of emotional language, and Syuzhet sentiment scores extract emotional plot arcs from text.

### Performance evaluation
Several metrics assessed performance, including accuracy, sensitivity (aka recall), specificity, precision (aka positive predictive value), F1 score and Kappa. We prioritised F1 score and Kappa because they are best equipped to handle outcome imbalance. Kappa inter-rater reliability from the human coding process (0.71–0.73) established a ceiling for the SML model's performance; if death narratives contained ambiguous language that caused two human coders to disagree, it is unlikely that an SML model could improve on the gold standard (human) label on which it was trained.

We compared performance of our final model against two alternatives to confirm the best approach, as there are no universal standards for 'acceptable' performance in SML. Comparison model #1 used SML with only existing NVDRS variables. Model #2 employed a 'bag-of-terms' approach that only retained terms from the text that had the highest log odds of coinciding with an IPV=yes label or an IPV=no label.

To assess whether each model over/under-counted IPV circumstances in the validation dataset, we compared the percentage of cases predicted as IPV=yes with the 'true' prevalence of IPV-related suicide, according to human coders.

To gain insight into how the model worked, we calculated Gini variable importance. This is computed based on the observed change in prediction accuracy when each input variable is removed from the model one-by-one.

Finally, the first author hand-reviewed cases that the SML tool had misclassified (according to the gold standard) in the validation dataset to qualitatively describe model errors.

### Statistical approach
Variables with multiple response categories were converted to binary (0/1) indicators. Continuous variables were normalised using z-scores. We applied SMOTE (Synthetic minority oversampling technique) to balance outcome labels for training. When using all input variables for our final model, a random forest approach yielded the best performance compared with XG Boost, LASSO Logistic Regression, and Support Vector Machines. Accordingly, a random forest approach was selected as the machine learning method for the final model.

## Results

In the training dataset, 17% of single suicide cases were labelled by humans as IPV=yes (n=1519). These data were purposively sampled from NVDRS to maximise the number of IPV-related suicides that we might encounter so that the training process could sufficiently hone in on the defining characteristics of IPV-related suicide.

The validation dataset, on other hand, was a simple random sample of single suicides so that we could understand how the SML model would perform in a generalisable sample from NVDRS. In the validation dataset, 6.8% of cases were labelled by humans as IPV=yes (n=102).

### Performance
In the validation dataset (n=1500), the final model classified 99 cases (6.6%) as IPV=yes and 1401 cases (93.4%) as IPV=no. Among the 99 cases predicted as IPV=yes, there were 28 false positives. Among the 1401 cases predicted as IPV=no, there were 31 false negatives. This corresponds with an F1 Score of 0.71 and Kappa of 0.69, suggesting substantial/robust agreement between the model's classification and the gold standard human labels.

Our final model outperformed the two comparison models on the prioritised metrics of Kappa and F1 Score. It also had the closest predicted prevalence of IPV circumstances (6.7%) to the 'true' underlying prevalence in the validation dataset (6.8%).

### Variable importance
Gini variable importance is shown in Figure 3. Input variables on the X axis are grouped based on how they were derived. The Y axis shows a continuous measure of Gini variable importance, with higher values suggesting greater importance for model success. Seven of the top 10 most important variables were concept scores. On average, concept scores had the highest overall importance (mean: 111, range: 3–1037). Incident characteristics (mean: 16, range: 2–83) and demographics (mean: 12, range: 1–48) were least important.

### Error analysis
After rereviewing death narratives for cases that were misclassified by the model (according to the human gold standard), we determined two false positives and one false negative had been mislabeled by the human coders.

Of the remaining 26 false positives, most described a 'domestic incident' between IPs but lacked sufficient detail to substantiate the incident as violent. Others mentioned 'domestic violence' without clarifying the parties involved (ie, IPs vs other family members). Remaining false positives described other interpersonal violence (n=11), often family violence.

Of the 30 false negatives, most narratives described coercive suicide threats (n=15). For example, one case reported that the decedent (ie, person who died by suicide), had threatened to kill himself if his girlfriend broke up with him. Other cases described the decedent using suicidal acts to punish their IP. Some false negatives mentioned abuse and the IP context in separate sentences or used metaphorical language to describe abuse. For example, one decedent wrote in her suicide note that her IP 'used' her and that his anger was, 'like a snowball rolling down a mountain…after it gets going there is no way to stop it.' While a human could infer that this text described IPV, the model was unsuccessful in doing so.

## Discussion

To the best of our knowledge, this is the first scalable method to accurately detect whether IPV was a precipitating factor for single suicides in NVDRS. Our SML tool could be applied to the full NVDRS dataset in the future to facilitate further research examining the who, what, when, where and why of IPV-related suicides.

The SML tool was trained using 8500 hand-reviewed cases and validated using 1500 cases. Results suggest the tool has substantial precision and sensitivity. Performance was similar to other text-based SML projects, and Kappa was comparable to the inter-rater reliability achieved by our human coders. In some cases, the SML tool even identified previous human labelling errors. Together, these findings may indicate the model reached the upper limit of performance given inherent ambiguity in NVDRS death narrative language.

The use of NLP and SML did not replace the need for human content area expertise to guide model development. The human-curated concept scores were the most important variables used to detect IPV circumstances (according to Gini importance). While mainstream NLP increasingly relies on 'off-the-shelf' approaches to extract key information from text, human subject matter expertise may be critical for rendering SML input variables for certain public health research contexts.

### Limitations
There are some limitations to using NVDRS data. Multiple layers of data underreporting will cause our model to underestimate the true prevalence of IPV-related suicide. First, IPV is underreported in the general population. Second, stigma, shame or guilt may deter surviving family members or friends from sharing information about the decedent's IPV involvement, if they even knew about it. Third, CME and LE do not routinely probe about IPV circumstances during suicide death investigations, nor are NVDRS abstractors instructed to document them. Finally, we only recorded IPV circumstances = 'yes' when IPV was clearly described in the narratives for that death. This was consistent with existing NVDRS coding conventions, although as a result, the SML tool will underestimate the role of IPV in suicide.

Death narratives usually report IPV only if a violent incident occurred within 2 weeks of the suicide. Thus, our SML tool does not necessarily capture the cumulative impact of IPV history on suicide outcomes.

We used keyword/phrase lists (ie, concept lists) drafted by the first author who had familiarity with the training data. She was later involved in hand-coding cases in the validation dataset. This may have introduced bias if drafting the concept lists influenced her heuristics for hand-coding.

We chose to use a dictionary approach primarily so the model would be interpretable and accessible, but also given documented challenges applying word embeddings to death narrative text. New IPV-related language used in future years may not be captured in the concept lists, although the lists could be updated or expanded. Future work could also consider building from our approach using different methods, such as convolutional neural networks.

The SML tool identified some false positives. These were often instances of IPV-adjacent behaviours (eg, other family violence) that may require similarly targeted prevention and intervention strategies. Our SML tool also missed some IPV-related suicide cases. Many false negatives described coercive suicide-related threats. More advanced NLP may be needed linguistically to parse out when self-harm is weaponised to abuse others. Still, this tool provides an essential first step towards facilitating more comprehensive research and surveillance on the role of IPV in suicide.

### Implications for data collection and data entry
The content, language and detail in the death narratives limited our model's ability to distinguish suicides with IPV circumstances. Amending NVDRS coding guidelines to require systematic assessment of IPV circumstances for suicide in a close-ended data field may help to improve data quality in the future. This change may require only a modest training burden, as NVDRS abstractors already record IPV circumstances for homicides. Based on what we learnt from our human coding process, we believe that applying the same IPV case definition to single suicides is challenging but feasible.

Relatedly, CME and LE should strive to clearly document IPV circumstances during suicide death investigations. For example, rather than only mention a 'domestic incident' or 'fight' that preceded a suicide, CME and LE might also describe the parties involved and any allegations of physical violence, sexual violence or coercive controlling behaviour (if known). Updating suicide death investigation protocols to encourage documentation of IPV may result in substantial gains in data quality, but may also require additional training, resources and reporting structures to support CME and LE.

Until changes are made to data collection, our tool can provide a stopgap measure to leverage existing NVDRS textual data and facilitate research on IPV-related suicide. Applying this tool could save time and create efficiencies for both CDC and researchers. For example, the model could help prompt NVDRS abstractors to verify IPV circumstances for certain suicide cases. If deployed post hoc, the model could also save researchers over 1450 hours of additional human coding time per year of suicide data.

## Conclusion

We developed a tool for identifying IPV circumstances in single suicides that could enable future research and monitoring efforts. Overall, more attention to the role of IPV in suicide is merited both during the initial death investigation processes, subsequent reporting in NVDRS, for ongoing research, and to inform applied prevention practice.