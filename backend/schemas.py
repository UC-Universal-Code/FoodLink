from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, constr

class TokenAcceso(BaseModel):
    access_token: str
    token_type: str

class DatosToken(BaseModel):
    numero_empleado: Optional[str] = None

class PeticionLogin(BaseModel):
    numero_empleado: constr(strip_whitespace=True, min_length=1)
    contrasena: constr(strip_whitespace=True, min_length=1)

class UsuarioBase(BaseModel):
    numero_empleado: constr(strip_whitespace=True, min_length=1)
    nombre: constr(strip_whitespace=True, min_length=1)
    apellido: constr(strip_whitespace=True, min_length=1)
    departamento_id: Optional[int] = None
    turno_id: Optional[int] = None

class UsuarioCrear(UsuarioBase):
    contrasena: constr(strip_whitespace=True, min_length=6)
    rol: Optional[constr(strip_whitespace=True, min_length=1)] = "user"
    estado: Optional[constr(strip_whitespace=True, min_length=1)] = "active"

class UsuarioLeer(UsuarioBase):
    id: int
    rol: str
    estado: str
    creado_en: datetime
    actualizado_en: datetime

    class Config:
        from_attributes = True


# ========== SCHEMAS PARA MENÚ SEMANAL
from datetime import date  

class MenuItemBase(BaseModel):
    dia_semana: str
    tipo_comida: str
    nombre_plato: str
    descripcion: Optional[str] = None
    ingredientes: Optional[str] = None
    imagen_url: Optional[str] = None
    limite_porciones: Optional[int] = None
    precio: float
    disponible: bool = True

class MenuItemCrear(MenuItemBase):
    pass

class MenuItemActualizar(BaseModel):
    dia_semana: Optional[str] = None
    tipo_comida: Optional[str] = None
    nombre_plato: Optional[str] = None
    descripcion: Optional[str] = None
    ingredientes: Optional[str] = None
    imagen_url: Optional[str] = None
    limite_porciones: Optional[int] = None
    precio: Optional[float] = None
    disponible: Optional[bool] = None

class MenuItemLeer(MenuItemBase):
    id: int
    menu_semanal_id: int
    
    class Config:
        from_attributes = True

class MenuSemanalBase(BaseModel):
    semana_inicio: date
    semana_fin: date
    turno: str
    activo: bool = True

class MenuSemanalCrear(MenuSemanalBase):
    items: List[MenuItemCrear]

class MenuSemanalActualizar(BaseModel):
    semana_inicio: Optional[date] = None
    semana_fin: Optional[date] = None
    turno: Optional[str] = None
    activo: Optional[bool] = None
    items: Optional[List[MenuItemActualizar]] = None

class MenuSemanalLeer(MenuSemanalBase):
    id: int
    creado_en: datetime
    actualizado_en: datetime
    items: List[MenuItemLeer] = []
    creado_por: Optional[str] = None
    
    class Config:
        from_attributes = True

# Reconstruir modelos para resolver referencias circulares
MenuSemanalCrear.model_rebuild()
MenuSemanalActualizar.model_rebuild()
MenuSemanalLeer.model_rebuild()