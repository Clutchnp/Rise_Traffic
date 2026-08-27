import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error,mean_squared_error,r2_score
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder


df = pd.read_csv('Banglore_traffic_Dataset.csv')
df.info()

df['Date'] = pd.to_datetime(df['Date'],errors="coerce")
df = df.dropna(subset=['Date'])
df["hour"] = df["Date"].dt.hour
df["day_of_week"] = df["Date"].dt.dayofweek
df["day_name"] = df["Date"].dt.day_name()
df["month"] = df["Date"].dt.month
df['is_weekend'] = (df["day_of_week"] >=5).astype(int)
df['peak_hour'] = (df['hour'].between(7,10) | df['hour'].between(17,22)).astype(int)

x = df.drop(columns=['Congestion Level'])
y = df['Congestion Level']

#didn't use environmental impact , road utilization and travel time as they are not required or calculated from congestion level
num_features = ["Traffic Volume","Average Speed","Incident Reports","Public Transport Usage", "Traffic Signal Compliance","Parking Usage","Pedestrian and Cyclist Count","hour","day_of_week","month","is_weekend","peak_hour"]
cat_features = ["Area Name","Road/Intersection Name","Weather Conditions","Roadwork and Construction Activity"]
features = num_features + cat_features
x = x[features]

x_train,x_test,y_train,y_test = train_test_split(x,y,test_size=0.2,random_state=42)

preprocessor = ColumnTransformer(
    transformers=[
        ("categorical",OneHotEncoder(handle_unknown="ignore"),cat_features),
        ("numeric","passthrough",num_features)
    ]
)
model = RandomForestRegressor(n_estimators=200,max_depth=None,min_samples_split=2,min_samples_leaf=1,random_state=42,n_jobs=-1)

pipeline = Pipeline(
    steps=[
        ("preprocessor",preprocessor),
        ("model",model)
    ]
)

pipeline.fit(x_train,y_train)
y_pred = pipeline.predict(x_test)
print(f"Mean Absolute Error : {mean_absolute_error(y_test,y_pred)}\nRMSE : {np.sqrt(mean_squared_error(y_test,y_pred))}\nR2 : {r2_score(y_test,y_pred)}")



