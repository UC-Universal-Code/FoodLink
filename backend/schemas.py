from datetime import datetime
from typing import Optional
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
