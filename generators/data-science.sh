#!/bin/bash
# Data Science component generator for Spinbox
# Creates data science environment with Jupyter, analysis tools, and visualization setup

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"

# Generate Data Science framework component
function generate_data_science_component() {
    local project_dir="$1"
    local ds_dir="$project_dir/data-science"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate Data Science framework component"
        return 0
    fi
    
    print_status "Creating Data Science framework component..."
    
    # Ensure data science directory structure exists
    safe_create_dir "$ds_dir"
    safe_create_dir "$ds_dir/notebooks"
    safe_create_dir "$ds_dir/data"
    safe_create_dir "$ds_dir/data/raw"
    safe_create_dir "$ds_dir/data/processed"
    safe_create_dir "$ds_dir/data/external"
    safe_create_dir "$ds_dir/scripts"
    safe_create_dir "$ds_dir/models"
    safe_create_dir "$ds_dir/reports"
    safe_create_dir "$ds_dir/visualization"
    safe_create_dir "$ds_dir/tests"
    
    # Generate data science files
    generate_ds_dockerfiles "$ds_dir"
    generate_ds_requirements "$ds_dir"
    generate_ds_notebooks "$ds_dir"
    generate_ds_scripts "$ds_dir"
    generate_ds_config "$ds_dir"
    generate_ds_tests "$ds_dir"
    generate_ds_env_files "$ds_dir"
    
    print_status "Data Science framework component created successfully"
}

# Generate Docker configuration for data science
function generate_ds_dockerfiles() {
    local ds_dir="$1"
    local python_version=$(get_effective_python_version)
    
    # Development Dockerfile with Jupyter and data science tools
    cat > "$ds_dir/Dockerfile.dev" << EOF
FROM python:${python_version}-slim

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    build-essential \\
    zsh \\
    graphviz \\
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \\
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Configure Zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\\/powerlevel10k"/g' ~/.zshrc \\
    && sed -i 's/plugins=(git)/plugins=(git docker python pip)/g' ~/.zshrc \\
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Set up virtual environment path
ENV PATH="/workspace/venv/bin:\$PATH"

# Add data science aliases
RUN echo '# Data Science aliases' >> ~/.zshrc \\
    && echo 'alias jlab="jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root"' >> ~/.zshrc \\
    && echo 'alias jnb="jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root"' >> ~/.zshrc \\
    && echo 'alias pytest="python -m pytest"' >> ~/.zshrc \\
    && echo 'alias uvinstall="uv pip install -r requirements.txt"' >> ~/.zshrc \\
    && echo 'alias train="python scripts/train_model.py"' >> ~/.zshrc \\
    && echo 'alias viz="python scripts/visualize_data.py"' >> ~/.zshrc

EXPOSE 8888

# Activate virtual environment on shell start
RUN echo 'if [[ -f /workspace/venv/bin/activate ]]; then source /workspace/venv/bin/activate; fi' >> ~/.zshrc

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
EOF

    # Production Dockerfile
    cat > "$ds_dir/Dockerfile" << EOF
FROM python:${python_version}-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    build-essential \\
    && rm -rf /var/lib/apt/lists/*

# Install UV for dependency management
RUN pip install --no-cache-dir uv

# Create and activate virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:\$PATH"

# Copy and install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

# Copy project files
COPY . .

# Run Jupyter Lab by default
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
EOF

    # Docker ignore file
    cat > "$ds_dir/.dockerignore" << 'EOF'
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
.env
.env.local
.pytest_cache/
.coverage
.tox/
dist/
build/
*.egg-info/
.git/
.gitignore
README.md
Dockerfile*
docker-compose*
data/raw/
data/processed/
models/
.ipynb_checkpoints/
*.log
EOF

    print_debug "Generated data science Docker configuration"
}

# Generate requirements.txt with data science dependencies
function generate_ds_requirements() {
    local ds_dir="$1"
    
    cat > "$ds_dir/requirements.txt" << 'EOF'
# Core data science stack
pandas>=2.1.0
numpy>=1.24.0
scikit-learn>=1.3.0
scipy>=1.11.0

# Jupyter and notebook tools
jupyter>=1.0.0
jupyterlab>=4.0.0
ipywidgets>=8.0.0
nbformat>=5.9.0

# Visualization
matplotlib>=3.7.0
seaborn>=0.12.0
plotly>=5.15.0

# Data processing
openpyxl>=3.1.0
xlrd>=2.0.0
beautifulsoup4>=4.12.0
lxml>=4.9.0

# Machine learning extensions
xgboost>=1.7.0
lightgbm>=4.0.0
catboost>=1.2.0

# Development tools
uv>=0.1.0
pytest>=7.4.0
black>=23.0.0
python-dotenv>=1.0.0
requests>=2.31.0

# Utilities
tqdm>=4.66.0
python-dateutil>=2.8.0
pytz>=2023.3
EOF

    # Add optional dependencies based on selected components
    if [[ "${USE_POSTGRESQL:-false}" == "true" ]]; then
        cat >> "$ds_dir/requirements.txt" << 'EOF'

# PostgreSQL dependencies
psycopg2-binary>=2.9.7
sqlalchemy>=2.0.0
EOF
    fi
    
    if [[ "${USE_MONGODB:-false}" == "true" ]]; then
        cat >> "$ds_dir/requirements.txt" << 'EOF'

# MongoDB dependencies
pymongo>=4.5.0
EOF
    fi

    print_debug "Generated data science requirements.txt"
}

# Generate Jupyter notebooks and analysis templates
function generate_ds_notebooks() {
    local ds_dir="$1"
    local notebooks_dir="$ds_dir/notebooks"
    
    # Data exploration notebook
    cat > "$notebooks_dir/01_data_exploration.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Exploration\n",
    "\n",
    "This notebook contains initial data exploration and understanding."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "from pathlib import Path\n",
    "\n",
    "# Set up plotting\n",
    "plt.style.use('seaborn-v0_8')\n",
    "sns.set_palette('husl')\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load data\n",
    "data_path = Path('../data/raw/')\n",
    "# df = pd.read_csv(data_path / 'your_data.csv')\n",
    "# df.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Basic data info\n",
    "# print(f\"Dataset shape: {df.shape}\")\n",
    "# print(f\"Columns: {df.columns.tolist()}\")\n",
    "# df.info()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Statistical summary\n",
    "# df.describe()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Check for missing values\n",
    "# missing_data = df.isnull().sum()\n",
    "# print(\"Missing values per column:\")\n",
    "# print(missing_data[missing_data > 0])"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Data cleaning notebook
    cat > "$notebooks_dir/02_data_cleaning.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Cleaning and Preprocessing\n",
    "\n",
    "This notebook handles data cleaning, preprocessing, and feature engineering."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "from sklearn.preprocessing import StandardScaler, LabelEncoder\n",
    "from sklearn.impute import SimpleImputer\n",
    "from pathlib import Path"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load raw data\n",
    "# df = pd.read_csv('../data/raw/your_data.csv')\n",
    "# print(f\"Original shape: {df.shape}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Data cleaning steps\n",
    "# 1. Handle missing values\n",
    "# 2. Remove duplicates\n",
    "# 3. Fix data types\n",
    "# 4. Handle outliers"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Feature engineering\n",
    "# Add your feature engineering code here"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Save processed data\n",
    "# df_clean.to_csv('../data/processed/cleaned_data.csv', index=False)\n",
    "# print(f\"Cleaned data saved. Final shape: {df_clean.shape}\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Model development notebook
    cat > "$notebooks_dir/03_model_development.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Model Development and Training\n",
    "\n",
    "This notebook handles model development, training, and evaluation."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV\n",
    "from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier\n",
    "from sklearn.linear_model import LogisticRegression\n",
    "from sklearn.metrics import accuracy_score, classification_report, confusion_matrix\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "import joblib\n",
    "from pathlib import Path"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load processed data\n",
    "# df = pd.read_csv('../data/processed/cleaned_data.csv')\n",
    "# print(f\"Data shape: {df.shape}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Prepare features and target\n",
    "# X = df.drop('target', axis=1)\n",
    "# y = df['target']\n",
    "# X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Model training\n",
    "# models = {\n",
    "#     'Random Forest': RandomForestClassifier(random_state=42),\n",
    "#     'Gradient Boosting': GradientBoostingClassifier(random_state=42),\n",
    "#     'Logistic Regression': LogisticRegression(random_state=42)\n",
    "# }\n",
    "\n",
    "# for name, model in models.items():\n",
    "#     model.fit(X_train, y_train)\n",
    "#     y_pred = model.predict(X_test)\n",
    "#     accuracy = accuracy_score(y_test, y_pred)\n",
    "#     print(f\"{name}: {accuracy:.4f}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Model evaluation\n",
    "# Add your model evaluation code here"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Save best model\n",
    "# joblib.dump(best_model, '../models/best_model.pkl')\n",
    "# print(\"Model saved successfully!\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    print_debug "Generated Jupyter notebooks"
}

# Generate Python scripts for automation
function generate_ds_scripts() {
    local ds_dir="$1"
    local scripts_dir="$ds_dir/scripts"
    
    # Data processing script
    cat > "$scripts_dir/data_processing.py" << 'EOF'
#!/usr/bin/env python3
"""
Data processing utilities for the data science project.
"""

import pandas as pd
import numpy as np
from pathlib import Path
from typing import Tuple, Optional
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataProcessor:
    """Class for handling data processing operations."""
    
    def __init__(self, data_dir: str = "data"):
        self.data_dir = Path(data_dir)
        self.raw_dir = self.data_dir / "raw"
        self.processed_dir = self.data_dir / "processed"
        
        # Create directories if they don't exist
        self.processed_dir.mkdir(parents=True, exist_ok=True)
    
    def load_raw_data(self, filename: str) -> pd.DataFrame:
        """Load raw data from CSV file."""
        filepath = self.raw_dir / filename
        logger.info(f"Loading data from {filepath}")
        return pd.read_csv(filepath)
    
    def clean_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Clean and preprocess the data."""
        logger.info("Starting data cleaning...")
        
        # Remove duplicates
        df_clean = df.drop_duplicates()
        logger.info(f"Removed {len(df) - len(df_clean)} duplicate rows")
        
        # Handle missing values
        missing_before = df_clean.isnull().sum().sum()
        df_clean = df_clean.dropna()  # Simple strategy - can be improved
        missing_after = df_clean.isnull().sum().sum()
        logger.info(f"Handled {missing_before - missing_after} missing values")
        
        return df_clean
    
    def save_processed_data(self, df: pd.DataFrame, filename: str) -> None:
        """Save processed data to CSV file."""
        filepath = self.processed_dir / filename
        df.to_csv(filepath, index=False)
        logger.info(f"Saved processed data to {filepath}")

def main():
    """Main processing function."""
    processor = DataProcessor()
    
    # Example usage
    # df = processor.load_raw_data("your_data.csv")
    # df_clean = processor.clean_data(df)
    # processor.save_processed_data(df_clean, "cleaned_data.csv")
    
    logger.info("Data processing complete!")

if __name__ == "__main__":
    main()
EOF

    # Model training script
    cat > "$scripts_dir/train_model.py" << 'EOF'
#!/usr/bin/env python3
"""
Model training script for the data science project.
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
import joblib
from pathlib import Path
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelTrainer:
    """Class for handling model training operations."""
    
    def __init__(self, data_dir: str = "data", models_dir: str = "models"):
        self.data_dir = Path(data_dir)
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(parents=True, exist_ok=True)
    
    def load_data(self, filename: str) -> pd.DataFrame:
        """Load processed data."""
        filepath = self.data_dir / "processed" / filename
        logger.info(f"Loading data from {filepath}")
        return pd.read_csv(filepath)
    
    def prepare_features(self, df: pd.DataFrame, target_column: str) -> Tuple[np.ndarray, np.ndarray]:
        """Prepare features and target for training."""
        X = df.drop(target_column, axis=1)
        y = df[target_column]
        logger.info(f"Features shape: {X.shape}, Target shape: {y.shape}")
        return X, y
    
    def train_model(self, X: np.ndarray, y: np.ndarray) -> RandomForestClassifier:
        """Train a Random Forest model."""
        logger.info("Training Random Forest model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Train model
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        logger.info(f"Model accuracy: {accuracy:.4f}")
        
        return model
    
    def save_model(self, model, filename: str) -> None:
        """Save trained model."""
        filepath = self.models_dir / filename
        joblib.dump(model, filepath)
        logger.info(f"Model saved to {filepath}")

def main():
    """Main training function."""
    trainer = ModelTrainer()
    
    # Example usage
    # df = trainer.load_data("cleaned_data.csv")
    # X, y = trainer.prepare_features(df, "target")
    # model = trainer.train_model(X, y)
    # trainer.save_model(model, "random_forest_model.pkl")
    
    logger.info("Model training complete!")

if __name__ == "__main__":
    main()
EOF

    # Visualization script
    cat > "$scripts_dir/visualize_data.py" << 'EOF'
#!/usr/bin/env python3
"""
Data visualization utilities for the data science project.
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataVisualizer:
    """Class for creating data visualizations."""
    
    def __init__(self, data_dir: str = "data", reports_dir: str = "reports"):
        self.data_dir = Path(data_dir)
        self.reports_dir = Path(reports_dir)
        self.reports_dir.mkdir(parents=True, exist_ok=True)
        
        # Set up plotting style
        plt.style.use('seaborn-v0_8')
        sns.set_palette('husl')
    
    def load_data(self, filename: str) -> pd.DataFrame:
        """Load data for visualization."""
        filepath = self.data_dir / "processed" / filename
        logger.info(f"Loading data from {filepath}")
        return pd.read_csv(filepath)
    
    def create_summary_plots(self, df: pd.DataFrame) -> None:
        """Create summary plots for the dataset."""
        logger.info("Creating summary plots...")
        
        # Distribution plots
        numeric_columns = df.select_dtypes(include=[np.number]).columns
        n_cols = min(len(numeric_columns), 3)
        n_rows = (len(numeric_columns) + n_cols - 1) // n_cols
        
        fig, axes = plt.subplots(n_rows, n_cols, figsize=(15, 5 * n_rows))
        axes = axes.flatten() if n_rows > 1 else [axes]
        
        for i, col in enumerate(numeric_columns):
            if i < len(axes):
                df[col].hist(ax=axes[i], bins=30)
                axes[i].set_title(f'Distribution of {col}')
                axes[i].set_xlabel(col)
                axes[i].set_ylabel('Frequency')
        
        # Hide unused subplots
        for i in range(len(numeric_columns), len(axes)):
            axes[i].set_visible(False)
        
        plt.tight_layout()
        plt.savefig(self.reports_dir / 'data_distributions.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        logger.info("Summary plots saved to reports/data_distributions.png")
    
    def create_correlation_matrix(self, df: pd.DataFrame) -> None:
        """Create correlation matrix heatmap."""
        logger.info("Creating correlation matrix...")
        
        # Calculate correlation matrix
        numeric_df = df.select_dtypes(include=[np.number])
        correlation_matrix = numeric_df.corr()
        
        # Create heatmap
        plt.figure(figsize=(12, 10))
        sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0,
                   square=True, fmt='.2f')
        plt.title('Feature Correlation Matrix')
        plt.tight_layout()
        plt.savefig(self.reports_dir / 'correlation_matrix.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        logger.info("Correlation matrix saved to reports/correlation_matrix.png")

def main():
    """Main visualization function."""
    visualizer = DataVisualizer()
    
    # Example usage
    # df = visualizer.load_data("cleaned_data.csv")
    # visualizer.create_summary_plots(df)
    # visualizer.create_correlation_matrix(df)
    
    logger.info("Data visualization complete!")

if __name__ == "__main__":
    main()
EOF

    # Make scripts executable
    chmod +x "$scripts_dir/data_processing.py"
    chmod +x "$scripts_dir/train_model.py"
    chmod +x "$scripts_dir/visualize_data.py"

    print_debug "Generated Python scripts"
}

# Generate configuration files
function generate_ds_config() {
    local ds_dir="$1"
    
    # Jupyter configuration
    cat > "$ds_dir/jupyter_config.py" << 'EOF'
"""
Jupyter configuration for the data science project.
"""

c = get_config()

# Set notebook directory
c.NotebookApp.notebook_dir = 'notebooks'

# Allow access from any IP
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.allow_origin = '*'

# Disable authentication for development
c.NotebookApp.token = ''
c.NotebookApp.password = ''

# Enable auto-reload of modules
c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2']

# Set matplotlib backend
c.InlineBackend.figure_format = 'retina'
EOF

    # Project configuration
    cat > "$ds_dir/config.py" << 'EOF'
"""
Project configuration settings.
"""

import os
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent
DATA_DIR = PROJECT_ROOT / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"
EXTERNAL_DATA_DIR = DATA_DIR / "external"
MODELS_DIR = PROJECT_ROOT / "models"
REPORTS_DIR = PROJECT_ROOT / "reports"
NOTEBOOKS_DIR = PROJECT_ROOT / "notebooks"

# Create directories if they don't exist
for dir_path in [DATA_DIR, RAW_DATA_DIR, PROCESSED_DATA_DIR, 
                 EXTERNAL_DATA_DIR, MODELS_DIR, REPORTS_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)

# Model settings
MODEL_RANDOM_STATE = 42
TEST_SIZE = 0.2
CROSS_VALIDATION_FOLDS = 5

# Plotting settings
FIGURE_SIZE = (12, 8)
DPI = 300
PLOT_STYLE = 'seaborn-v0_8'
COLOR_PALETTE = 'husl'

# Data processing settings
MISSING_VALUE_THRESHOLD = 0.5  # Drop columns with >50% missing values
OUTLIER_DETECTION_METHOD = 'iqr'  # or 'zscore'
OUTLIER_THRESHOLD = 3
EOF

    print_debug "Generated configuration files"
}

# Generate test files
function generate_ds_tests() {
    local ds_dir="$1"
    local tests_dir="$ds_dir/tests"
    
    cat > "$tests_dir/__init__.py" << 'EOF'
"""Data science tests."""
EOF

    cat > "$tests_dir/test_data_processing.py" << 'EOF'
"""
Test data processing functions.
"""

import pytest
import pandas as pd
import numpy as np
from pathlib import Path
import sys

# Add scripts directory to path
sys.path.append(str(Path(__file__).parent.parent / "scripts"))

from data_processing import DataProcessor


class TestDataProcessor:
    """Test the DataProcessor class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.processor = DataProcessor()
    
    def test_clean_data_removes_duplicates(self):
        """Test that clean_data removes duplicate rows."""
        # Create test data with duplicates
        df = pd.DataFrame({
            'A': [1, 2, 3, 1, 2],
            'B': [4, 5, 6, 4, 5]
        })
        
        result = self.processor.clean_data(df)
        
        # Should have 3 unique rows
        assert len(result) == 3
        assert not result.duplicated().any()
    
    def test_clean_data_handles_missing_values(self):
        """Test that clean_data handles missing values."""
        # Create test data with missing values
        df = pd.DataFrame({
            'A': [1, 2, np.nan, 4],
            'B': [5, np.nan, 7, 8]
        })
        
        result = self.processor.clean_data(df)
        
        # Should have no missing values
        assert not result.isnull().any().any()
    
    def test_data_processor_initialization(self):
        """Test DataProcessor initialization."""
        processor = DataProcessor("test_data")
        
        assert processor.data_dir == Path("test_data")
        assert processor.raw_dir == Path("test_data/raw")
        assert processor.processed_dir == Path("test_data/processed")
EOF

    cat > "$tests_dir/test_model_training.py" << 'EOF'
"""
Test model training functions.
"""

import pytest
import pandas as pd
import numpy as np
from pathlib import Path
import sys

# Add scripts directory to path
sys.path.append(str(Path(__file__).parent.parent / "scripts"))

from train_model import ModelTrainer


class TestModelTrainer:
    """Test the ModelTrainer class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.trainer = ModelTrainer()
    
    def test_prepare_features(self):
        """Test feature preparation."""
        # Create test data
        df = pd.DataFrame({
            'feature1': [1, 2, 3, 4],
            'feature2': [5, 6, 7, 8],
            'target': [0, 1, 0, 1]
        })
        
        X, y = self.trainer.prepare_features(df, 'target')
        
        assert X.shape == (4, 2)
        assert y.shape == (4,)
        assert list(y) == [0, 1, 0, 1]
    
    def test_model_trainer_initialization(self):
        """Test ModelTrainer initialization."""
        trainer = ModelTrainer("test_data", "test_models")
        
        assert trainer.data_dir == Path("test_data")
        assert trainer.models_dir == Path("test_models")
EOF

    print_debug "Generated data science tests"
}

# Generate environment files
function generate_ds_env_files() {
    local ds_dir="$1"
    
    # Environment template
    cat > "$ds_dir/.env.example" << 'EOF'
# Data Science Project Configuration

# Project settings
PROJECT_NAME="Data Science Project"
DEBUG=True

# Data sources
DATA_SOURCE_URL=https://example.com/data
API_KEY=your-api-key-here

# Database (if using external database)
DATABASE_URL=postgresql://user:password@localhost:5432/database

# Jupyter settings
JUPYTER_TOKEN=your-jupyter-token-here
JUPYTER_PASSWORD=your-jupyter-password-here

# Model settings
MODEL_RANDOM_STATE=42
TEST_SIZE=0.2

# Visualization settings
FIGURE_DPI=300
PLOT_STYLE=seaborn-v0_8
EOF

    # Create actual .env if it doesn't exist
    if [[ ! -f "$ds_dir/.env" ]]; then
        cp "$ds_dir/.env.example" "$ds_dir/.env"
    fi

    # Copy virtual environment setup script
    local setup_venv_template="$PROJECT_ROOT/templates/security/setup_venv.sh"
    if [[ -f "$setup_venv_template" ]]; then
        cp "$setup_venv_template" "$ds_dir/setup_venv.sh"
        chmod +x "$ds_dir/setup_venv.sh"
    fi

    # Copy Python .gitignore
    local gitignore_template="$PROJECT_ROOT/templates/security/python.gitignore"
    if [[ -f "$gitignore_template" ]]; then
        cp "$gitignore_template" "$ds_dir/.gitignore"
        # Add data science specific ignores
        cat >> "$ds_dir/.gitignore" << 'EOF'

# Data Science specific
.ipynb_checkpoints/
*.ipynb_checkpoints
data/raw/
data/processed/
models/
reports/
*.pkl
*.joblib
*.h5
*.model
*.log
EOF
    fi

    # Create README for the data science project
    cat > "$ds_dir/README.md" << 'EOF'
# Data Science Project

A comprehensive data science project structure with Jupyter notebooks, Python scripts, and automated workflows.

## Project Structure

```
data-science/
├── notebooks/          # Jupyter notebooks for analysis
├── scripts/           # Python scripts for automation
├── data/              # Data storage
│   ├── raw/           # Raw, unprocessed data
│   ├── processed/     # Cleaned and processed data
│   └── external/      # External data sources
├── models/            # Trained models
├── reports/           # Generated reports and visualizations
├── tests/             # Unit tests
└── visualization/     # Static visualizations
```

## Getting Started

1. **Set up environment:**
   ```bash
   ./setup_venv.sh
   source venv/bin/activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Start Jupyter Lab:**
   ```bash
   jupyter lab
   ```

4. **Run data processing:**
   ```bash
   python scripts/data_processing.py
   ```

5. **Train models:**
   ```bash
   python scripts/train_model.py
   ```

6. **Generate visualizations:**
   ```bash
   python scripts/visualize_data.py
   ```

## Notebooks

- `01_data_exploration.ipynb` - Initial data exploration and understanding
- `02_data_cleaning.ipynb` - Data cleaning and preprocessing
- `03_model_development.ipynb` - Model development and training

## Scripts

- `data_processing.py` - Data cleaning and preprocessing utilities
- `train_model.py` - Model training and evaluation
- `visualize_data.py` - Data visualization utilities

## Configuration

Edit `.env` file to configure project settings:
- Data source URLs
- API keys
- Database connections
- Model parameters

## Testing

Run tests with:
```bash
pytest tests/
```
EOF

    print_debug "Generated environment files and documentation"
}

# Main function to create data science component
function create_data_science_component() {
    local project_dir="$1"
    
    print_info "Creating Data Science framework component in $project_dir"
    
    generate_data_science_component "$project_dir"
    
    print_status "Data Science framework component created successfully!"
    print_info "Next steps:"
    echo "  1. cd $(basename "$project_dir")/data-science"
    echo "  2. Set up environment: cp .env.example .env"
    echo "  3. Create virtual environment: ./setup_venv.sh"
    echo "  4. Start Jupyter Lab: jupyter lab"
    echo "  5. Open notebooks/01_data_exploration.ipynb to get started"
}

# Export functions for use by project generator
export -f generate_data_science_component create_data_science_component
export -f generate_ds_dockerfiles generate_ds_requirements generate_ds_notebooks
export -f generate_ds_scripts generate_ds_config generate_ds_tests generate_ds_env_files