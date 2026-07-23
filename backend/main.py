from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pakwheels
import uvicorn

app = FastAPI(title="PakWheels AI Predictor")

# Allow CORS for all origins, so Flutter web/mobile can connect easily
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class PredictionRequest(BaseModel):
    car_name: str
    model_year: int
    mileage: float
    engine_type: str
    engine_capacity: float
    transmission: str
    registered_in: str
    body_type: str

@app.get("/options")
def get_options():
    return pakwheels.get_options()

@app.post("/predict")
def predict_price(request: PredictionRequest):
    # Call the model function from pakwheels.py
    # predict_car_price(year, mileage, engine_type, transmission, registered_in, capacity, body_type, title)
    predicted_value = pakwheels.predict_car_price(
        year=request.model_year,
        mileage=request.mileage,
        engine_type=request.engine_type,
        transmission=request.transmission,
        registered_in=request.registered_in,
        capacity=request.engine_capacity,
        body_type=request.body_type,
        title=request.car_name
    )
    
    return {"predicted_price": predicted_value}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
