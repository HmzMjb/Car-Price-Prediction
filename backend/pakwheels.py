import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.preprocessing import LabelEncoder
import os

# Get absolute paths to the data and model files
base_dir = os.path.dirname(__file__)
csv_path = os.path.join(base_dir, 'pakwheels_cleaned.csv')
model_path = os.path.join(base_dir, 'xgb_model.pkl')

# Load cleaned data to recreate encoders
# Notice we drop 'name', 'brand' and other unnecessary columns as per the updated notebook
data = pd.read_csv(csv_path)

# Apply the same logic from your notebook to clean the titles (removing the year)
if 'title' in data.columns:
    data['title'] = data['title'].apply(lambda x: ' '.join(str(x).split()[:-1]))
model_data = data.drop(columns=['ad_url', 'location', 'color', 'ad_last_updated', 
                                'description', 'car_features', 'assembly', 'name', 'brand', 'Unnamed: 0'], 
                       errors='ignore')
model_data = model_data.dropna().drop_duplicates()

encoders = {}
cat_cols = model_data.select_dtypes(include=['object']).columns

for col in cat_cols:
    le_col = LabelEncoder()
    # Fit the encoder to ensure it matches the trained model's transformations
    model_data[col] = le_col.fit_transform(model_data[col])
    encoders[col] = le_col

# Load the saved XGBoost model
model = xgb.XGBRegressor()
model.load_model(model_path)

def get_options():
    """
    Returns valid unique options for the frontend dropdowns.
    This eliminates the need for hardcoding options in the app.
    """
    return {
        'title': sorted(encoders['title'].classes_.tolist()),
        'engine_type': sorted(encoders['engine_type'].classes_.tolist()),
        'transmission': sorted(encoders['transmission'].classes_.tolist()),
        'registered_in': sorted(encoders['registered_in'].classes_.tolist()),
        'body_type': sorted(encoders['body_type'].classes_.tolist()),
        'model_year': sorted([int(x) for x in data['model_year'].dropna().unique()], reverse=True)
    }

def predict_car_price(year, mileage, engine_type, transmission, registered_in, capacity, body_type, title):
    # Translate words to numbers using our saved encoders
    input_data = {
        'title': [encoders['title'].transform([title])[0]],
        'model_year': [year],
        'mileage': [mileage],
        'engine_type': [encoders['engine_type'].transform([engine_type])[0]],
        'transmission': [encoders['transmission'].transform([transmission])[0]],
        'registered_in': [encoders['registered_in'].transform([registered_in])[0]],
        'engine_capacity': [capacity],
        'body_type': [encoders['body_type'].transform([body_type])[0]],
    }

    # Ensure the columns match the order used during training (all features minus 'price')
    feature_cols = [col for col in model_data.columns if col != 'price']
    sample_df = pd.DataFrame(input_data)[feature_cols]
    
    price = model.predict(sample_df)[0]

    print(f"--- Market Estimate ---")
    print(f"The estimated price for a {year} {title} {body_type} is: {price:,.0f} PKR")
    return float(price)

