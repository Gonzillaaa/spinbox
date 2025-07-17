"""
Items endpoints.
"""
from typing import Any, List

from fastapi import APIRouter

router = APIRouter()

@router.get("/", response_model=List[dict])
def read_items() -> Any:
    """
    Retrieve items.
    """
    return [
        {"id": 1, "name": "Item 1", "description": "First item"},
        {"id": 2, "name": "Item 2", "description": "Second item"},
    ]

@router.get("/{item_id}", response_model=dict)
def read_item(item_id: int) -> Any:
    """
    Get item by ID.
    """
    return {"id": item_id, "name": f"Item {item_id}", "description": f"Item with ID {item_id}"}
