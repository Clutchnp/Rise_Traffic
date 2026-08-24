# Plan : 
 - figure out a dataset or make a dataset for the project 
    -  traing and be test on e chalan violations 
    - traffic signal adapter 
    - generated data  -> congestion model -> congestion predictions -> traffic signal adapter 
    - Vehicle event -> Violation RF -> Violation -> show fine , violation type , junction 
    - if time permits (bus passenger demand model)
        - online dataset(bmtc gtfs only for bangalore tho) -> draw the routes -> calculate stop congestion -> calculate route congestion -> color route based on congestion level

# Changes Made : 
- a script to generate a dataset with junctions , timings and randomised congestions and violations 
- standalone ML model script for violation classifer and congestion predictor 
- 