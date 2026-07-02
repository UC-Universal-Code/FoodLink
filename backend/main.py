from fastapi import FastAPI

from database import connection
from database.connection import engine, verificar_conexion
from database.models import Base
from routers.users import crear_admin_por_defecto, router as usuarios_router

app = FastAPI(
    title="FoodLink Backend",
    description="API backend con FastAPI y documentacion Swagger UI.",
    version="0.1.0",
)

@app.on_event("startup")
def inicio_aplicacion():
    """Verifica la conexion a la base de datos y crea las tablas si no existen."""
    if not verificar_conexion():
        raise RuntimeError("No se pudo conectar a la base de datos foodlink")
    Base.metadata.create_all(bind=engine)
    db = connection.SesionLocal()
    try:
        crear_admin_por_defecto(db)
    finally:
        db.close()

@app.get("/", summary="bienvenida")
def raiz():
    """
    Devuelve un mensaje de bienvenida
    Esta funcin se expone en GET / y se documenta 
    automaaticamente en Swagger UI
    """
    return {"message": "Bienvenido a FoodLink backend con FastAPI"}
"""este es un ejemplo base de la funcion de requiesta GET, que 
se expone en la ruta / y que devuelve un mensaje de bienvenida"""

app.include_router(usuarios_router)
"""esta linea de codigo nos permite importar el modulo de users
y exponer sus endpoints en la aplicacion FastAPI"""