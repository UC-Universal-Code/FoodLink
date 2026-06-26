from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel

from modules.users import router as users_router
"""Creamos una forma de importar los modulos/endpoints
que creemos, para de esta forma tener todo separa, ordenado
y modularizado"""

app = FastAPI(
    title="FoodLink Backend",
    description="API backend con FastAPI y documentación Swagger UI.",
    version="0.1.0",
)

@app.get("/", summary="bienvenida")
def read_root():
    """
    Devuelve un mensaje de bienvenida
    Esta funcin se expone en GET / y se documenta 
    automaaticamente en Swagger UI
    """
    return {"message": "Bienvenido a FoodLink backend con FastAPI"}
"""este es un ejemplo base de la funcion de requiesta GET, que 
se expone en la ruta / y que devuelve un mensaje de bienvenida"""

app.include_router(users_router)
"""esta linea de codigo nos permite importar el modulo de users
y exponer sus endpoints en la aplicacion FastAPI"""