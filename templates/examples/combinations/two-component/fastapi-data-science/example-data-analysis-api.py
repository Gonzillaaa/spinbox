"""
FastAPI + Data Science Analysis API Example
Data analysis and visualization API using FastAPI with pandas, numpy, and matplotlib.

Features:
- Dataset upload and storage
- Statistical analysis
- Data visualization
- Correlation analysis
- Missing data handling
- Data profiling

Setup:
1. pip install fastapi uvicorn pandas numpy matplotlib seaborn plotly python-dotenv
2. uvicorn example-data-analysis-api:app --reload

Environment variables:
- MAX_DATASET_SIZE: Maximum dataset size (default: 10000)
- ENABLE_PLOTTING: Enable plotting features (default: True)
- DEBUG: Enable debug mode (default: True)
"""

from fastapi import FastAPI, HTTPException, UploadFile, File, Query, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Union
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go
from plotly.utils import PlotlyJSONEncoder
import io
import json
import os
import uuid
from datetime import datetime
from dotenv import load_dotenv
import logging
from scipy import stats
import warnings

# Suppress warnings
warnings.filterwarnings('ignore')

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
MAX_DATASET_SIZE = int(os.getenv("MAX_DATASET_SIZE", "10000"))
ENABLE_PLOTTING = os.getenv("ENABLE_PLOTTING", "True").lower() == "true"
DEBUG = os.getenv("DEBUG", "True").lower() == "true"

# FastAPI app
app = FastAPI(
    title="Data Analysis API",
    description="Data analysis and visualization API with FastAPI",
    version="1.0.0"
)

# In-memory storage (use database in production)
datasets: Dict[str, pd.DataFrame] = {}
dataset_metadata: Dict[str, Dict[str, Any]] = {}
analysis_cache: Dict[str, Any] = {}

# Pydantic models
class DatasetInfo(BaseModel):
    dataset_id: str
    name: str
    shape: tuple
    columns: List[str]
    dtypes: Dict[str, str]
    uploaded_at: datetime
    size_mb: float

class AnalysisRequest(BaseModel):
    dataset_id: str
    columns: Optional[List[str]] = None
    analysis_type: str = Field(..., description="Type of analysis: 'summary', 'distribution', 'correlation'")

class VisualizationRequest(BaseModel):
    dataset_id: str
    plot_type: str = Field(..., description="Type of plot: 'histogram', 'scatter', 'boxplot', 'heatmap'")
    x_column: Optional[str] = None
    y_column: Optional[str] = None
    color_column: Optional[str] = None
    title: Optional[str] = None

class StatisticalTestRequest(BaseModel):
    dataset_id: str
    test_type: str = Field(..., description="Type of test: 't_test', 'chi_square', 'anova'")
    column1: str
    column2: Optional[str] = None
    alpha: float = Field(0.05, description="Significance level")

class DataCleaningRequest(BaseModel):
    dataset_id: str
    operations: List[str] = Field(..., description="Cleaning operations: 'drop_duplicates', 'fill_missing', 'remove_outliers'")
    fill_method: Optional[str] = Field("mean", description="Method for filling missing values")
    outlier_method: Optional[str] = Field("iqr", description="Method for outlier detection")

# Utility functions
def validate_dataset_id(dataset_id: str) -> pd.DataFrame:
    """Validate dataset exists and return it"""
    if dataset_id not in datasets:
        raise HTTPException(status_code=404, detail="Dataset not found")
    return datasets[dataset_id]

def calculate_dataset_size(df: pd.DataFrame) -> float:
    """Calculate dataset size in MB"""
    return df.memory_usage(deep=True).sum() / 1024 / 1024

def detect_column_types(df: pd.DataFrame) -> Dict[str, str]:
    """Detect semantic types of columns"""
    column_types = {}
    for col in df.columns:
        if df[col].dtype in ['int64', 'float64']:
            column_types[col] = 'numeric'
        elif df[col].dtype == 'object':
            if df[col].nunique() < 10:
                column_types[col] = 'categorical'
            else:
                column_types[col] = 'text'
        elif df[col].dtype == 'datetime64[ns]':
            column_types[col] = 'datetime'
        else:
            column_types[col] = 'other'
    return column_types

def perform_statistical_analysis(df: pd.DataFrame, columns: List[str] = None) -> Dict[str, Any]:
    """Perform comprehensive statistical analysis"""
    if columns is None:
        columns = df.select_dtypes(include=[np.number]).columns.tolist()
    
    analysis = {}
    
    for col in columns:
        if col in df.columns and df[col].dtype in ['int64', 'float64']:
            col_data = df[col].dropna()
            
            analysis[col] = {
                'count': len(col_data),
                'mean': col_data.mean(),
                'median': col_data.median(),
                'std': col_data.std(),
                'min': col_data.min(),
                'max': col_data.max(),
                'q25': col_data.quantile(0.25),
                'q75': col_data.quantile(0.75),
                'skewness': stats.skew(col_data),
                'kurtosis': stats.kurtosis(col_data),
                'missing_count': df[col].isna().sum(),
                'missing_percentage': (df[col].isna().sum() / len(df)) * 100
            }
    
    return analysis

def detect_outliers(df: pd.DataFrame, column: str, method: str = 'iqr') -> Dict[str, Any]:
    """Detect outliers using different methods"""
    if column not in df.columns:
        raise ValueError(f"Column '{column}' not found")
    
    data = df[column].dropna()
    
    if method == 'iqr':
        Q1 = data.quantile(0.25)
        Q3 = data.quantile(0.75)
        IQR = Q3 - Q1
        lower_bound = Q1 - 1.5 * IQR
        upper_bound = Q3 + 1.5 * IQR
        outliers = data[(data < lower_bound) | (data > upper_bound)]
    
    elif method == 'zscore':
        z_scores = np.abs(stats.zscore(data))
        outliers = data[z_scores > 3]
    
    else:
        raise ValueError(f"Unknown outlier detection method: {method}")
    
    return {
        'outlier_count': len(outliers),
        'outlier_percentage': (len(outliers) / len(data)) * 100,
        'outlier_values': outliers.tolist()[:10],  # First 10 outliers
        'bounds': {
            'lower': lower_bound if method == 'iqr' else None,
            'upper': upper_bound if method == 'iqr' else None
        }
    }

def create_visualization(df: pd.DataFrame, plot_type: str, **kwargs) -> str:
    """Create visualization and return as JSON (Plotly) or base64 (Matplotlib)"""
    if not ENABLE_PLOTTING:
        raise HTTPException(status_code=400, detail="Plotting is disabled")
    
    if plot_type == 'histogram':
        if not kwargs.get('x_column'):
            raise ValueError("x_column is required for histogram")
        
        fig = px.histogram(df, x=kwargs['x_column'], title=kwargs.get('title', 'Histogram'))
        return json.dumps(fig, cls=PlotlyJSONEncoder)
    
    elif plot_type == 'scatter':
        if not kwargs.get('x_column') or not kwargs.get('y_column'):
            raise ValueError("x_column and y_column are required for scatter plot")
        
        fig = px.scatter(
            df, 
            x=kwargs['x_column'], 
            y=kwargs['y_column'],
            color=kwargs.get('color_column'),
            title=kwargs.get('title', 'Scatter Plot')
        )
        return json.dumps(fig, cls=PlotlyJSONEncoder)
    
    elif plot_type == 'boxplot':
        if not kwargs.get('x_column'):
            raise ValueError("x_column is required for boxplot")
        
        fig = px.box(df, y=kwargs['x_column'], title=kwargs.get('title', 'Box Plot'))
        return json.dumps(fig, cls=PlotlyJSONEncoder)
    
    elif plot_type == 'heatmap':
        # Create correlation heatmap
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        corr_matrix = df[numeric_cols].corr()
        
        fig = px.imshow(
            corr_matrix,
            text_auto=True,
            aspect="auto",
            title=kwargs.get('title', 'Correlation Heatmap')
        )
        return json.dumps(fig, cls=PlotlyJSONEncoder)
    
    else:
        raise ValueError(f"Unknown plot type: {plot_type}")

# Routes
@app.get("/", tags=["root"])
def root():
    """API health check"""
    return {
        "message": "Data Analysis API is running",
        "version": "1.0.0",
        "features": {
            "plotting_enabled": ENABLE_PLOTTING,
            "max_dataset_size": MAX_DATASET_SIZE
        },
        "endpoints": {
            "upload": "/datasets/upload",
            "analyze": "/datasets/analyze",
            "visualize": "/datasets/visualize",
            "clean": "/datasets/clean"
        }
    }

@app.post("/datasets/upload", response_model=DatasetInfo, tags=["datasets"])
async def upload_dataset(
    file: UploadFile = File(...),
    name: Optional[str] = Query(None),
    separator: str = Query(",", description="CSV separator"),
    encoding: str = Query("utf-8", description="File encoding")
):
    """Upload a dataset for analysis"""
    # Validate file type
    if not file.filename.endswith(('.csv', '.xlsx', '.json')):
        raise HTTPException(status_code=400, detail="Supported formats: CSV, Excel, JSON")
    
    try:
        # Read file content
        content = await file.read()
        
        # Parse file based on extension
        if file.filename.endswith('.csv'):
            df = pd.read_csv(io.StringIO(content.decode(encoding)), sep=separator)
        elif file.filename.endswith('.xlsx'):
            df = pd.read_excel(io.BytesIO(content))
        elif file.filename.endswith('.json'):
            df = pd.read_json(io.StringIO(content.decode(encoding)))
        
        # Validate dataset size
        if len(df) > MAX_DATASET_SIZE:
            raise HTTPException(
                status_code=400, 
                detail=f"Dataset too large. Maximum {MAX_DATASET_SIZE} rows allowed"
            )
        
        # Generate dataset ID
        dataset_id = str(uuid.uuid4())
        dataset_name = name or file.filename
        
        # Store dataset
        datasets[dataset_id] = df
        dataset_metadata[dataset_id] = {
            "name": dataset_name,
            "uploaded_at": datetime.utcnow(),
            "original_filename": file.filename,
            "size_mb": calculate_dataset_size(df),
            "column_types": detect_column_types(df)
        }
        
        logger.info(f"Dataset uploaded: {dataset_id}, shape: {df.shape}")
        
        return DatasetInfo(
            dataset_id=dataset_id,
            name=dataset_name,
            shape=df.shape,
            columns=df.columns.tolist(),
            dtypes={col: str(dtype) for col, dtype in df.dtypes.items()},
            uploaded_at=dataset_metadata[dataset_id]["uploaded_at"],
            size_mb=dataset_metadata[dataset_id]["size_mb"]
        )
        
    except Exception as e:
        logger.error(f"Error uploading dataset: {e}")
        raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")

@app.get("/datasets/", response_model=List[DatasetInfo], tags=["datasets"])
def list_datasets():
    """List all uploaded datasets"""
    dataset_list = []
    for dataset_id, df in datasets.items():
        metadata = dataset_metadata[dataset_id]
        dataset_list.append(DatasetInfo(
            dataset_id=dataset_id,
            name=metadata["name"],
            shape=df.shape,
            columns=df.columns.tolist(),
            dtypes={col: str(dtype) for col, dtype in df.dtypes.items()},
            uploaded_at=metadata["uploaded_at"],
            size_mb=metadata["size_mb"]
        ))
    return dataset_list

@app.get("/datasets/{dataset_id}", tags=["datasets"])
def get_dataset_info(dataset_id: str):
    """Get detailed information about a dataset"""
    df = validate_dataset_id(dataset_id)
    metadata = dataset_metadata[dataset_id]
    
    # Basic info
    info = {
        "dataset_id": dataset_id,
        "name": metadata["name"],
        "shape": df.shape,
        "size_mb": metadata["size_mb"],
        "uploaded_at": metadata["uploaded_at"]
    }
    
    # Column information
    columns_info = []
    for col in df.columns:
        col_info = {
            "name": col,
            "dtype": str(df[col].dtype),
            "semantic_type": metadata["column_types"][col],
            "non_null_count": df[col].count(),
            "null_count": df[col].isna().sum(),
            "unique_count": df[col].nunique()
        }
        
        if df[col].dtype in ['int64', 'float64']:
            col_info.update({
                "min": df[col].min(),
                "max": df[col].max(),
                "mean": df[col].mean(),
                "std": df[col].std()
            })
        
        columns_info.append(col_info)
    
    info["columns"] = columns_info
    return info

@app.post("/datasets/analyze", tags=["analysis"])
def analyze_dataset(analysis_request: AnalysisRequest):
    """Perform statistical analysis on dataset"""
    df = validate_dataset_id(analysis_request.dataset_id)
    
    # Check cache
    cache_key = f"{analysis_request.dataset_id}_{analysis_request.analysis_type}"
    if cache_key in analysis_cache:
        return analysis_cache[cache_key]
    
    try:
        if analysis_request.analysis_type == "summary":
            # Statistical summary
            result = perform_statistical_analysis(df, analysis_request.columns)
        
        elif analysis_request.analysis_type == "distribution":
            # Distribution analysis
            result = {}
            columns = analysis_request.columns or df.select_dtypes(include=[np.number]).columns.tolist()
            
            for col in columns:
                if col in df.columns:
                    col_data = df[col].dropna()
                    result[col] = {
                        "normality_test": stats.normaltest(col_data)._asdict(),
                        "outliers": detect_outliers(df, col),
                        "histogram_bins": np.histogram(col_data, bins=10)[0].tolist(),
                        "histogram_edges": np.histogram(col_data, bins=10)[1].tolist()
                    }
        
        elif analysis_request.analysis_type == "correlation":
            # Correlation analysis
            numeric_cols = df.select_dtypes(include=[np.number]).columns
            corr_matrix = df[numeric_cols].corr()
            
            result = {
                "correlation_matrix": corr_matrix.to_dict(),
                "strong_correlations": []
            }
            
            # Find strong correlations
            for i in range(len(corr_matrix.columns)):
                for j in range(i + 1, len(corr_matrix.columns)):
                    corr_val = corr_matrix.iloc[i, j]
                    if abs(corr_val) > 0.7:  # Strong correlation threshold
                        result["strong_correlations"].append({
                            "variable1": corr_matrix.columns[i],
                            "variable2": corr_matrix.columns[j],
                            "correlation": corr_val
                        })
        
        else:
            raise HTTPException(status_code=400, detail="Invalid analysis type")
        
        # Cache result
        analysis_cache[cache_key] = result
        return result
        
    except Exception as e:
        logger.error(f"Error in analysis: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis error: {str(e)}")

@app.post("/datasets/visualize", tags=["visualization"])
def create_visualization_endpoint(viz_request: VisualizationRequest):
    """Create data visualization"""
    df = validate_dataset_id(viz_request.dataset_id)
    
    try:
        plot_json = create_visualization(
            df,
            viz_request.plot_type,
            x_column=viz_request.x_column,
            y_column=viz_request.y_column,
            color_column=viz_request.color_column,
            title=viz_request.title
        )
        
        return {
            "plot_json": plot_json,
            "plot_type": viz_request.plot_type,
            "dataset_id": viz_request.dataset_id
        }
        
    except Exception as e:
        logger.error(f"Error creating visualization: {e}")
        raise HTTPException(status_code=500, detail=f"Visualization error: {str(e)}")

@app.post("/datasets/test", tags=["statistics"])
def perform_statistical_test(test_request: StatisticalTestRequest):
    """Perform statistical tests"""
    df = validate_dataset_id(test_request.dataset_id)
    
    try:
        if test_request.test_type == "t_test":
            # T-test
            if not test_request.column2:
                # One-sample t-test
                data = df[test_request.column1].dropna()
                statistic, p_value = stats.ttest_1samp(data, 0)
                test_name = "One-sample t-test"
            else:
                # Two-sample t-test
                data1 = df[test_request.column1].dropna()
                data2 = df[test_request.column2].dropna()
                statistic, p_value = stats.ttest_ind(data1, data2)
                test_name = "Two-sample t-test"
        
        elif test_request.test_type == "chi_square":
            # Chi-square test
            if not test_request.column2:
                raise HTTPException(status_code=400, detail="Chi-square test requires two columns")
            
            contingency_table = pd.crosstab(df[test_request.column1], df[test_request.column2])
            statistic, p_value, dof, expected = stats.chi2_contingency(contingency_table)
            test_name = "Chi-square test"
        
        elif test_request.test_type == "anova":
            # ANOVA test
            if not test_request.column2:
                raise HTTPException(status_code=400, detail="ANOVA requires grouping column")
            
            groups = [group[test_request.column1].dropna() for name, group in df.groupby(test_request.column2)]
            statistic, p_value = stats.f_oneway(*groups)
            test_name = "One-way ANOVA"
        
        else:
            raise HTTPException(status_code=400, detail="Invalid test type")
        
        return {
            "test_name": test_name,
            "statistic": statistic,
            "p_value": p_value,
            "alpha": test_request.alpha,
            "significant": p_value < test_request.alpha,
            "interpretation": f"{'Reject' if p_value < test_request.alpha else 'Fail to reject'} null hypothesis"
        }
        
    except Exception as e:
        logger.error(f"Error in statistical test: {e}")
        raise HTTPException(status_code=500, detail=f"Statistical test error: {str(e)}")

@app.post("/datasets/clean", tags=["cleaning"])
def clean_dataset(cleaning_request: DataCleaningRequest):
    """Clean dataset with specified operations"""
    df = validate_dataset_id(cleaning_request.dataset_id)
    
    try:
        original_shape = df.shape
        cleaning_report = {"original_shape": original_shape}
        
        for operation in cleaning_request.operations:
            if operation == "drop_duplicates":
                before_count = len(df)
                df = df.drop_duplicates()
                cleaning_report["duplicates_removed"] = before_count - len(df)
            
            elif operation == "fill_missing":
                missing_before = df.isna().sum().sum()
                
                if cleaning_request.fill_method == "mean":
                    df = df.fillna(df.mean())
                elif cleaning_request.fill_method == "median":
                    df = df.fillna(df.median())
                elif cleaning_request.fill_method == "mode":
                    df = df.fillna(df.mode().iloc[0])
                elif cleaning_request.fill_method == "forward":
                    df = df.fillna(method='ffill')
                elif cleaning_request.fill_method == "backward":
                    df = df.fillna(method='bfill')
                
                missing_after = df.isna().sum().sum()
                cleaning_report["missing_values_filled"] = missing_before - missing_after
            
            elif operation == "remove_outliers":
                before_count = len(df)
                
                for col in df.select_dtypes(include=[np.number]).columns:
                    outlier_info = detect_outliers(df, col, cleaning_request.outlier_method)
                    
                    if cleaning_request.outlier_method == "iqr":
                        Q1 = df[col].quantile(0.25)
                        Q3 = df[col].quantile(0.75)
                        IQR = Q3 - Q1
                        lower_bound = Q1 - 1.5 * IQR
                        upper_bound = Q3 + 1.5 * IQR
                        df = df[(df[col] >= lower_bound) & (df[col] <= upper_bound)]
                    
                    elif cleaning_request.outlier_method == "zscore":
                        z_scores = np.abs(stats.zscore(df[col]))
                        df = df[z_scores < 3]
                
                cleaning_report["outliers_removed"] = before_count - len(df)
        
        # Update dataset
        new_dataset_id = str(uuid.uuid4())
        datasets[new_dataset_id] = df
        dataset_metadata[new_dataset_id] = {
            **dataset_metadata[cleaning_request.dataset_id],
            "name": dataset_metadata[cleaning_request.dataset_id]["name"] + "_cleaned",
            "uploaded_at": datetime.utcnow(),
            "size_mb": calculate_dataset_size(df),
            "column_types": detect_column_types(df)
        }
        
        cleaning_report.update({
            "new_dataset_id": new_dataset_id,
            "final_shape": df.shape,
            "operations_performed": cleaning_request.operations
        })
        
        return cleaning_report
        
    except Exception as e:
        logger.error(f"Error cleaning dataset: {e}")
        raise HTTPException(status_code=500, detail=f"Cleaning error: {str(e)}")

@app.delete("/datasets/{dataset_id}", tags=["datasets"])
def delete_dataset(dataset_id: str):
    """Delete a dataset"""
    if dataset_id not in datasets:
        raise HTTPException(status_code=404, detail="Dataset not found")
    
    del datasets[dataset_id]
    del dataset_metadata[dataset_id]
    
    # Clear related cache entries
    cache_keys_to_remove = [key for key in analysis_cache.keys() if key.startswith(dataset_id)]
    for key in cache_keys_to_remove:
        del analysis_cache[key]
    
    return {"message": "Dataset deleted successfully"}

@app.get("/health", tags=["health"])
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "datasets_count": len(datasets),
        "cache_size": len(analysis_cache),
        "features": {
            "plotting_enabled": ENABLE_PLOTTING,
            "max_dataset_size": MAX_DATASET_SIZE
        }
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    logger.error(f"HTTP error {exc.status_code}: {exc.detail}")
    return {"error": exc.detail, "status_code": exc.status_code}

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unexpected error: {exc}")
    return {"error": "Internal server error", "status_code": 500}

# Run with: uvicorn example-data-analysis-api:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")