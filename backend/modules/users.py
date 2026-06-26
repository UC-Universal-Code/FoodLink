from typing import Optional
from fastapi import APIRouter
from pydanitic import BaseModel

router = APIRouter(prefix="/users", tags=["users"])
"""creamos un modulo llamado users, este modulo contendra
el CRUD de los usuarios"""

class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
"""ejemplo de la base de un endpoint"""

"""modularizamos los endpoints para de esta forma tener
un orden estructurado sobre la 
aplicacion FastAPI, y asi poder tener un control sobre
la estructura de la aplicacion"""