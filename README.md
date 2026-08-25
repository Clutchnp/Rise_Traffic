# Plan : 
 - figure out a dataset or make a dataset for the project 
    -  traing and be test on e chalan violations 
    - traffic signal adapter 
    - generated data  -> congestion model -> congestion predictions -> traffic signal adapter 
    - Vehicle event -> Violation RF -> Violation -> show fine , violation type , junction 
    - if time permits (bus passenger demand model)
        - online dataset(bmtc gtfs only for bangalore tho) -> draw the routes -> calculate stop congestion -> calculate route congestion -> color route based on congestion level

# Changes Made : 
- ## 1st day ->
    - a script to generate a dataset with junctions , timings and randomised congestions and violations 
    - standalone ML model script for violation classifer and congestion predictor 
- ## 2nd day ->
    - changed the genrated dataset to 2 different datasets centered around Bangalore $(number\ one\ example\ of\ shitty\ traffic ) $
    - links : 
        - https://www.kaggle.com/datasets/raj713335/bangalore-police-traffic-violation-dataset-2023
        - https://www.kaggle.com/datasets/preethamgouda/banglore-city-traffic-dataset
    - made seperate ml scripts for congestion model and violation model
    - congestion model is pretty good with a R2 score of 96.5%
    - violation model is shit with a weighted avg of 60% 
    - I think it is because there are multiple violations for 1 person $(nobody\ knows\ how\ to\ drive)$
    - so the random forest reggresor only chooses the most prominent one out of them 
    - tried a simple if else statement to bag them , failed with all violations coming under parking and getting accuracy of 1
    - tried normalisation right now and getting above mentioned weighted avg
    - tried MultiLabelBinarizer and it went to like 50 I guess ?
    - I don't really remember but yeah , its a problem 
    - ### IGNORE THE generatedData.csv
