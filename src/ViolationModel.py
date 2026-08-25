import pandas as pd
import numpy as np
import ast
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score,classification_report
from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder,MultiLabelBinarizer

df = pd.read_csv('Datasets/bangalore-police-traffic-violation-dataset-2023.csv')
df.info()

df['created_datetime'] = pd.to_datetime(df['created_datetime'],errors='coerce')
df = df.dropna(subset=['created_datetime','violation_type'])
df["hour"] = df['created_datetime'].dt.hour
df["day_of_week"] = df['created_datetime'].dt.dayofweek
df['month'] = df['created_datetime'].dt.month
df['is_weekend'] = (df['day_of_week'] >=5).astype(int)
df['peak_hour'] = (df['hour'].between(7,10) | df['hour'].between(17,22)).astype(int)


#the problem -> from line 24 to 33
def normalise_violations(x):
    v = ast.literal_eval(x)
    return str(sorted(v))

df["violation_type"] = df["violation_type"].apply(normalise_violations)
df['violation_list'] = df['violation_type'].apply(ast.literal_eval)
mlb = MultiLabelBinarizer()
y = mlb.fit_transform(df['violation_list'])
print(mlb.classes_)

num_features = ["latitude","longitude","center_code","hour","day_of_week","month","is_weekend","peak_hour"]
cat_features = ["location","vehicle_type","police_station","junction_name"]
features = (num_features + cat_features)

x = df[features].copy()

for c in num_features:
    x[c] = x[c].fillna(x[c].median())

for c in cat_features:
    x[c] = x[c].fillna("Unknown")

x_train,x_test,y_train,y_test = train_test_split(x,y,test_size=0.2,random_state=42)

preprocessor = ColumnTransformer(
    transformers=[
        ("categorical",OneHotEncoder(handle_unknown="ignore"),cat_features),
        ("numeric","passthrough",num_features)
    ]
)

model = RandomForestClassifier(n_estimators=50,max_depth=20,min_samples_leaf=5,random_state=42,n_jobs=-1)

pipeline = Pipeline(
    steps=[
        ("preprocessor",preprocessor),
        ("model",model)
    ]
)

pipeline.fit(x_train,y_train)
y_pred = pipeline.predict(x_test)

print(f"violation results :\nAccuracy : {accuracy_score(y_test,y_pred)}\nClassification Report:\n{classification_report(y_test,y_pred,zero_division=0)}")