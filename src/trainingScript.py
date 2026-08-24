import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor,RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error,r2_score,accuracy_score,classification_report

df = pd.read_csv('generatedData.csv')
df.info()

#random forest regressor for predicting the congestion 
df['future_congestion'] = df.groupby("junction_id")['congestion_index'].shift(-1)
congestion_df = df.dropna(subset=['future_congestion']).copy()
congestion_df['timestamp'] = pd.to_datetime(congestion_df['timestamp'])
congestion_df['hour'] = congestion_df['timestamp'].dt.hour
congestion_df['minute'] = congestion_df['timestamp'].dt.minute

rfr_target = congestion_df['future_congestion']

cat_features = ['zone_type','city']
num_features = ["hour","minute","is_weekend","road_capacity","vehicle_count","avg_speed_kmh"]
rfr_input = congestion_df[num_features + cat_features]
rfr_input_new = pd.get_dummies(rfr_input,columns=cat_features,dtype=int)

congestion_model = RandomForestRegressor(n_estimators=100,random_state=42,n_jobs=-1)
x_train,x_test,y_train,y_test = train_test_split(rfr_input_new,rfr_target,test_size=0.2,random_state=42)

congestion_model.fit(x_train,y_train)
pred = congestion_model.predict(x_test)
print(f"Mean Absolute Error : {mean_absolute_error(y_test,pred)}")
print(f"R2 score : {r2_score(y_test,pred)}")

#random forest classifier for the e challan verifier 
viol_features = ['captured_vehicle_type','event_vehicle_speed_kmh',"event_signal_is_red","event_dist_past_line_m","has_helmet","has_seatbelt"]
rfc_input = df[viol_features]
rfc_target = df['is_true_violation']

cat_features = ['captured_vehicle_type']
num_features = ["event_vehicle_speed_kmh","event_signal_is_red","event_dist_past_line_m","has_helmet","has_seatbelt"]
rfc_input_new = pd.get_dummies(rfc_input,columns=cat_features,dtype=int)

violation_model = RandomForestClassifier(n_estimators=100,random_state=42,class_weight="balanced",n_jobs=-1)
x_train,x_test,y_train,y_test = train_test_split(rfc_input_new,rfc_target,test_size=0.2,random_state=42,stratify=rfc_target)
violation_model.fit(x_train,y_train)
viol_pred = violation_model.predict(x_test)
print(f"Accuracy : {accuracy_score(y_test,viol_pred)}")
print(f"{classification_report(y_test,viol_pred)}")


#

