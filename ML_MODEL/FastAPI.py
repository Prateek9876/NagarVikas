from fastapi import FastAPI, File, UploadFile
import uvicorn
from ML_MODEL.model_inference import classify_image
app = FastAPI()

@app.post("/validate-image/")
async def validate_image(file: UploadFile = File(...)):
    image_bytes = await file.read()
    result = classify_image(image_bytes)
    return result

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
