# FastAPI + Data Science Integration

Complete examples for building data science APIs using FastAPI with machine learning and data analysis capabilities.

## Overview

This combination demonstrates how to create production-ready data science APIs using:
- **FastAPI**: Modern, fast web framework for building APIs
- **pandas**: Data manipulation and analysis
- **scikit-learn**: Machine learning algorithms
- **NumPy**: Numerical computing
- **matplotlib/seaborn**: Data visualization

## Prerequisites

1. **Python 3.8+**: Required for FastAPI and data science libraries
2. **Dependencies**:
   ```bash
   pip install fastapi uvicorn pandas scikit-learn numpy matplotlib seaborn python-dotenv
   ```

## Environment Setup

Create `.env` file:
```env
# FastAPI Configuration
DEBUG=True
SECRET_KEY=your-secret-key-here

# Data Science Configuration
MODEL_CACHE_SIZE=100
ENABLE_PLOTTING=True
MAX_DATASET_SIZE=10000
DEFAULT_RANDOM_STATE=42

# Performance
ENABLE_PARALLEL_PROCESSING=True
N_JOBS=-1
```

## Examples Included

### `example-data-analysis-api.py`
Data analysis and visualization API.

**Features:**
- Dataset upload and analysis
- Statistical summaries
- Data visualization
- Correlation analysis
- Missing data handling

**Endpoints:**
- `POST /data/upload` - Upload dataset
- `GET /data/analyze` - Analyze dataset
- `GET /data/visualize` - Generate plots
- `GET /data/correlations` - Correlation matrix

### `example-ml-prediction-api.py`
Machine learning prediction API.

**Features:**
- Model training and validation
- Prediction endpoints
- Model persistence
- Cross-validation
- Feature importance

**Endpoints:**
- `POST /models/train` - Train ML model
- `POST /models/predict` - Make predictions
- `GET /models/evaluate` - Model evaluation
- `GET /models/list` - List available models

### `example-time-series-api.py`
Time series analysis and forecasting API.

**Features:**
- Time series decomposition
- Trend analysis
- Seasonality detection
- Forecasting
- Anomaly detection

**Endpoints:**
- `POST /timeseries/analyze` - Analyze time series
- `POST /timeseries/forecast` - Generate forecasts
- `GET /timeseries/decompose` - Decompose time series
- `GET /timeseries/anomalies` - Detect anomalies

## Usage Examples

### 1. Upload and Analyze Dataset
```bash
curl -X POST "http://localhost:8000/data/upload" \
  -F "file=@dataset.csv" \
  -F "separator=,"
```

### 2. Train Machine Learning Model
```bash
curl -X POST "http://localhost:8000/models/train" \
  -H "Content-Type: application/json" \
  -d '{
    "dataset_id": "1",
    "target_column": "price",
    "model_type": "linear_regression",
    "test_size": 0.2
  }'
```

### 3. Make Predictions
```bash
curl -X POST "http://localhost:8000/models/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "model_id": "1",
    "features": {
      "feature1": 10.5,
      "feature2": 20.0,
      "feature3": "category_a"
    }
  }'
```

### 4. Generate Visualizations
```bash
curl "http://localhost:8000/data/visualize?dataset_id=1&plot_type=histogram&column=price"
```

### 5. Time Series Forecast
```bash
curl -X POST "http://localhost:8000/timeseries/forecast" \
  -H "Content-Type: application/json" \
  -d '{
    "data": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    "periods": 5,
    "method": "linear"
  }'
```

## Data Science Patterns

### 1. Data Preprocessing Pipeline
```python
class DataPreprocessor:
    def __init__(self):
        self.scaler = StandardScaler()
        self.encoder = LabelEncoder()
    
    def preprocess(self, df: pd.DataFrame) -> pd.DataFrame:
        # Handle missing values
        df = self.handle_missing_values(df)
        
        # Encode categorical variables
        df = self.encode_categorical(df)
        
        # Scale numerical features
        df = self.scale_features(df)
        
        return df
```

### 2. Model Management
```python
class ModelManager:
    def __init__(self):
        self.models = {}
        self.metrics = {}
    
    def train_model(self, model_type: str, X: np.ndarray, y: np.ndarray):
        if model_type == "linear_regression":
            model = LinearRegression()
        elif model_type == "random_forest":
            model = RandomForestRegressor()
        
        model.fit(X, y)
        model_id = str(uuid.uuid4())
        self.models[model_id] = model
        
        return model_id
```

### 3. Visualization Service
```python
class VisualizationService:
    def create_plot(self, data: pd.DataFrame, plot_type: str, **kwargs):
        plt.figure(figsize=(10, 6))
        
        if plot_type == "histogram":
            plt.hist(data[kwargs['column']], bins=30)
        elif plot_type == "scatter":
            plt.scatter(data[kwargs['x']], data[kwargs['y']])
        
        buffer = io.BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        
        return buffer
```

## Advanced Features

### 1. Batch Processing
```python
@app.post("/data/batch-process")
async def batch_process(
    file_paths: List[str],
    background_tasks: BackgroundTasks
):
    task_id = str(uuid.uuid4())
    background_tasks.add_task(process_files_batch, file_paths, task_id)
    return {"task_id": task_id, "status": "started"}
```

### 2. Model Versioning
```python
class ModelVersion:
    def __init__(self, model, version: str, metrics: dict):
        self.model = model
        self.version = version
        self.metrics = metrics
        self.created_at = datetime.utcnow()
    
    def compare_with(self, other_version: 'ModelVersion'):
        return {
            "current_accuracy": self.metrics.get("accuracy"),
            "other_accuracy": other_version.metrics.get("accuracy"),
            "improvement": self.metrics.get("accuracy") - other_version.metrics.get("accuracy")
        }
```

### 3. Feature Engineering
```python
class FeatureEngineer:
    def create_features(self, df: pd.DataFrame) -> pd.DataFrame:
        # Create polynomial features
        df['feature1_squared'] = df['feature1'] ** 2
        
        # Create interaction features
        df['feature1_x_feature2'] = df['feature1'] * df['feature2']
        
        # Create time-based features
        if 'timestamp' in df.columns:
            df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
            df['day_of_week'] = pd.to_datetime(df['timestamp']).dt.dayofweek
        
        return df
```

### 4. Cross-Validation
```python
def cross_validate_model(model, X, y, cv=5):
    scores = cross_val_score(model, X, y, cv=cv, scoring='accuracy')
    return {
        "mean_score": scores.mean(),
        "std_score": scores.std(),
        "individual_scores": scores.tolist()
    }
```

## Performance Optimization

### 1. Data Caching
```python
from functools import lru_cache
import pickle

@lru_cache(maxsize=128)
def load_dataset(dataset_id: str):
    with open(f"datasets/{dataset_id}.pkl", 'rb') as f:
        return pickle.load(f)
```

### 2. Parallel Processing
```python
from joblib import Parallel, delayed

def parallel_feature_engineering(df_chunks):
    processed_chunks = Parallel(n_jobs=-1)(
        delayed(process_chunk)(chunk) for chunk in df_chunks
    )
    return pd.concat(processed_chunks, ignore_index=True)
```

### 3. Memory Management
```python
def process_large_dataset(file_path: str, chunk_size: int = 10000):
    results = []
    for chunk in pd.read_csv(file_path, chunksize=chunk_size):
        processed_chunk = process_chunk(chunk)
        results.append(processed_chunk.describe())
    
    return pd.concat(results).groupby(level=0).mean()
```

## Security Considerations

### 1. File Upload Validation
```python
def validate_file(file: UploadFile):
    # Check file size
    if file.size > MAX_FILE_SIZE:
        raise HTTPException(400, "File too large")
    
    # Check file type
    allowed_types = ['text/csv', 'application/json']
    if file.content_type not in allowed_types:
        raise HTTPException(400, "Invalid file type")
    
    # Validate file content
    try:
        df = pd.read_csv(file.file)
        if len(df) > MAX_ROWS:
            raise HTTPException(400, "Too many rows")
    except Exception:
        raise HTTPException(400, "Invalid file format")
```

### 2. Input Sanitization
```python
def sanitize_column_names(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = [col.replace(' ', '_').lower() for col in df.columns]
    df.columns = [re.sub(r'[^a-zA-Z0-9_]', '', col) for col in df.columns]
    return df
```

### 3. Resource Limits
```python
import resource

def limit_memory_usage(max_memory_mb: int):
    max_memory_bytes = max_memory_mb * 1024 * 1024
    resource.setrlimit(resource.RLIMIT_AS, (max_memory_bytes, max_memory_bytes))
```

## Testing

### 1. Data Quality Tests
```python
def test_data_quality(df: pd.DataFrame):
    tests = {
        "no_empty_dataframe": len(df) > 0,
        "no_all_null_columns": not df.isnull().all().any(),
        "reasonable_size": len(df) < 1000000,
        "valid_dtypes": all(dtype in ['int64', 'float64', 'object'] for dtype in df.dtypes)
    }
    return tests
```

### 2. Model Performance Tests
```python
def test_model_performance(model, X_test, y_test):
    predictions = model.predict(X_test)
    
    return {
        "mse": mean_squared_error(y_test, predictions),
        "r2": r2_score(y_test, predictions),
        "mae": mean_absolute_error(y_test, predictions)
    }
```

### 3. API Integration Tests
```python
def test_prediction_endpoint(client):
    # Test valid prediction
    response = client.post("/models/predict", json={
        "model_id": "test_model",
        "features": {"feature1": 1.0, "feature2": 2.0}
    })
    assert response.status_code == 200
    assert "prediction" in response.json()
    
    # Test invalid model
    response = client.post("/models/predict", json={
        "model_id": "invalid_model",
        "features": {"feature1": 1.0, "feature2": 2.0}
    })
    assert response.status_code == 404
```

## Deployment

### 1. Docker Configuration
```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Create directories for data and models
RUN mkdir -p /app/data /app/models

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Environment Variables
```bash
# Production environment
DEBUG=False
SECRET_KEY=production-secret-key
MODEL_CACHE_SIZE=500
MAX_DATASET_SIZE=100000
ENABLE_PARALLEL_PROCESSING=True
N_JOBS=4
```

### 3. Model Persistence
```python
import joblib
import os

def save_model(model, model_id: str):
    os.makedirs("models", exist_ok=True)
    joblib.dump(model, f"models/{model_id}.pkl")

def load_model(model_id: str):
    return joblib.load(f"models/{model_id}.pkl")
```

## Monitoring

### 1. Performance Metrics
```python
import time
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter('api_requests_total', 'Total API requests')
REQUEST_DURATION = Histogram('api_request_duration_seconds', 'Request duration')

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.inc()
    REQUEST_DURATION.observe(duration)
    
    return response
```

### 2. Model Drift Detection
```python
def detect_model_drift(original_data: pd.DataFrame, new_data: pd.DataFrame):
    from scipy.stats import ks_2samp
    
    drift_results = {}
    for column in original_data.columns:
        if original_data[column].dtype in ['int64', 'float64']:
            statistic, p_value = ks_2samp(original_data[column], new_data[column])
            drift_results[column] = {
                "statistic": statistic,
                "p_value": p_value,
                "drift_detected": p_value < 0.05
            }
    
    return drift_results
```

## Common Issues and Solutions

### 1. Memory Issues
**Problem**: Out of memory errors with large datasets
**Solution**: Use chunked processing and streaming

### 2. Slow Predictions
**Problem**: High latency for predictions
**Solution**: Model optimization and caching

### 3. Data Quality Issues
**Problem**: Inconsistent data formats
**Solution**: Robust data validation and preprocessing

### 4. Model Overfitting
**Problem**: Poor generalization
**Solution**: Cross-validation and regularization

## Next Steps

1. **Start with data analysis**: Try `example-data-analysis-api.py`
2. **Train your first model**: Use `example-ml-prediction-api.py`
3. **Add time series**: Implement `example-time-series-api.py`
4. **Scale up**: Add model versioning and monitoring
5. **Deploy**: Use Docker and cloud services

## Resources

- **pandas Documentation**: https://pandas.pydata.org/docs/
- **scikit-learn Documentation**: https://scikit-learn.org/stable/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Data Science Best Practices**: https://github.com/drivendata/cookiecutter-data-science