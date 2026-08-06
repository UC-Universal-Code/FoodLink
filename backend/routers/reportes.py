from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from database.models import ReporteIncidencia, Usuario
from routers.users import obtener_usuario_actual
from database.connection import SesionLocal 
from pydantic import BaseModel

router = APIRouter(
    prefix="", 
    tags=["Reportes"]
)

# Función generadora de sesión que FastAPI necesita para los endpoints
def obtener_bd():
    db = SesionLocal()
    try:
        yield db
    finally:
        db.close()

class ReporteCreateSchema(BaseModel):
    titulo: str
    descripcion: str
    estado: str = "Pendiente"

class ReporteUpdateSchema(BaseModel):
    estado: str

@router.post("/", status_code=status.HTTP_201_CREATED)
def crear_reporte(
    reporte_data: ReporteCreateSchema,
    db: Session = Depends(obtener_bd), # <--- Usamos nuestra función local que abre la sesión
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    nuevo_reporte = ReporteIncidencia(
        usuario_id=usuario_actual.id,
        numero_empleado=usuario_actual.numero_empleado,
        titulo=reporte_data.titulo,
        descripcion=reporte_data.descripcion,
        estado=reporte_data.estado
    )
    db.add(nuevo_reporte)
    db.commit()
    db.refresh(nuevo_reporte)
    return {"mensaje": "Reporte creado con éxito", "id": nuevo_reporte.id}

@router.get("/", status_code=status.HTTP_200_OK)
def obtener_reportes(
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    # Opcional: Puedes validar si el usuario es admin o cocinero si lo deseas, 
    # o devolver todos los reportes de la base de datos:
    reportes = db.query(ReporteIncidencia).all()
    return reportes

@router.put("/{reporte_id}", status_code=status.HTTP_200_OK)
def actualizar_estado_reporte(
    reporte_id: int,
    reporte_data: ReporteUpdateSchema,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    reporte = db.query(ReporteIncidencia).filter(ReporteIncidencia.id == reporte_id).first()
    if not reporte:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    
    reporte.estado = reporte_data.estado
    db.commit()
    db.refresh(reporte)
    return {"mensaje": "Estado actualizado con éxito", "estado": reporte.estado}

# <--- NUEVO: Endpoint para eliminar un reporte por su ID --->
@router.delete("/{reporte_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_reporte(
    reporte_id: int,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    reporte = db.query(ReporteIncidencia).filter(ReporteIncidencia.id == reporte_id).first()
    if not reporte:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    
    db.delete(reporte)
    db.commit()
    return None