from datetime import datetime, timedelta
from typing import Optional
import secrets
import string

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import connection
from database.models import Usuario, Turno, Departamento  
from schemas import (
    PeticionLogin,
    TokenAcceso,
    DatosToken,
    UsuarioCrear,
    UsuarioLeer,
    TurnoLeer,          
    DepartamentoLeer,
    UsuarioActualizar   
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])

# configuracion de seguridad JWT y hashing
SECRET_KEY = "foodlink-backend-secret-key-2026"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
ADMIN_POR_DEFECTO_EMPLEADO = "admin"
ADMIN_POR_DEFECTO_CONTRASENA = "Admin1234"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/usuarios/login")

# ========== FUNCION PARA GENERAR CONTRASEÑA ==========
def generar_contrasena_temporal(longitud: int = 12) -> str:
    caracteres = string.ascii_letters + string.digits + "!@#$%^&*"
    contrasena = ''.join(secrets.choice(caracteres) for _ in range(longitud))
    return contrasena

# ========== FUNCIONES DE AUTENTICACION ==========

def verificar_contrasena(contrasena_plana: str, hash_contrasena: str) -> bool:
    return pwd_context.verify(contrasena_plana, hash_contrasena)


def obtener_hash_contrasena(contrasena: str) -> str:
    return pwd_context.hash(contrasena)


def crear_token_acceso(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def obtener_bd():
    db = connection.SesionLocal()
    try:
        yield db
    finally:
        db.close()


def obtener_usuario_por_numero_empleado(db: Session, numero_empleado: str) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.numero_empleado == numero_empleado).first()


def crear_admin_por_defecto(db: Session) -> Usuario:
    """Crea un usuario administrador por defecto si no existe."""
    administrador = obtener_usuario_por_numero_empleado(db, ADMIN_POR_DEFECTO_EMPLEADO)
    if administrador:
        return administrador
    administrador = Usuario(
        numero_empleado=ADMIN_POR_DEFECTO_EMPLEADO,
        nombre="Administrador",
        apellido="PorDefecto",
        hash_contrasena=obtener_hash_contrasena(ADMIN_POR_DEFECTO_CONTRASENA),
        rol="admin",
        estado="active",
        creado_en=datetime.utcnow(),
        actualizado_en=datetime.utcnow(),
    )
    db.add(administrador)
    db.commit()
    db.refresh(administrador)
    return administrador


def autenticar_usuario(db: Session, numero_empleado: str, contrasena: str) -> Optional[Usuario]:
    # Para el administrador por defecto, aceptamos las credenciales de forma explicita
    if numero_empleado == ADMIN_POR_DEFECTO_EMPLEADO:
        if contrasena != ADMIN_POR_DEFECTO_CONTRASENA:
            return None
        administrador = obtener_usuario_por_numero_empleado(db, numero_empleado)
        if administrador:
            return administrador
        return crear_admin_por_defecto(db)

    usuario = obtener_usuario_por_numero_empleado(db, numero_empleado)
    if not usuario:
        return None
    if not verificar_contrasena(contrasena, usuario.hash_contrasena):
        return None
    
    # Verificar que el usuario esté activo
    if usuario.estado != "active":
        return None
    
    return usuario


def obtener_usuario_actual(token: str = Depends(oauth2_scheme), db: Session = Depends(obtener_bd)) -> Usuario:
    excepcion_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        numero_empleado: str = payload.get("sub")
        if numero_empleado is None:
            raise excepcion_credenciales
        datos_token = DatosToken(numero_empleado=numero_empleado)
    except JWTError:
        raise excepcion_credenciales
    usuario = obtener_usuario_por_numero_empleado(db, datos_token.numero_empleado)
    if usuario is None:
        raise excepcion_credenciales
    return usuario


def obtener_usuario_admin_actual(usuario_actual: Usuario = Depends(obtener_usuario_actual)) -> Usuario:
    if usuario_actual.rol != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Se requiere rol de administrador",
        )
    return usuario_actual

# ---------- ENDPOINTS DE USUARIO ----------

@router.post("/login", response_model=TokenAcceso)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(obtener_bd)):
    # Primero verificar si el usuario existe
    usuario = obtener_usuario_por_numero_empleado(db, form_data.username)
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Numero de empleado o contrasena incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verificar si la cuenta está inactiva antes de validar la contraseña
    if usuario.estado != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cuenta desactivada. Contacta al administrador.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verificar contraseña
    if not verificar_contrasena(form_data.password, usuario.hash_contrasena):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Numero de empleado o contrasena incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Si todo está bien, crear token
    token_acceso = crear_token_acceso(
        data={"sub": usuario.numero_empleado},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": token_acceso, "token_type": "bearer"}


# ========== CREAR USUARIO ==========
@router.post("/", response_model=UsuarioLeer)
def crear_usuario(
    usuario_in: UsuarioCrear, 
    db: Session = Depends(obtener_bd), 
    _: Usuario = Depends(obtener_usuario_admin_actual)
):
    print("\n" + "="*50)
    print("📥 DATOS RECIBIDOS:")
    print(f"   numero_empleado: {usuario_in.numero_empleado}")
    print(f"   nombre: {usuario_in.nombre}")
    print(f"   apellido: {usuario_in.apellido}")
    print(f"   rol: {usuario_in.rol}")
    print(f"   estado: {usuario_in.estado}")
    print(f"   departamento_id: {usuario_in.departamento_id}")
    print(f"   turno_id: {usuario_in.turno_id}")
    print(f"   contrasena: {'***' if usuario_in.contrasena else 'VACIA (se generara)'}")
    print("="*50 + "\n")
    
    usuario_existente = obtener_usuario_por_numero_empleado(db, usuario_in.numero_empleado)
    if usuario_existente:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El numero de empleado ya existe")
    
    # Generar contraseña si no se proporciona
    if usuario_in.contrasena and usuario_in.contrasena.strip():
        contrasena_plana = usuario_in.contrasena
        es_temporal = True
    else:
        contrasena_plana = generar_contrasena_temporal()
        es_temporal = True
    
    usuario = Usuario(
        numero_empleado=usuario_in.numero_empleado,
        nombre=usuario_in.nombre,
        apellido=usuario_in.apellido,
        hash_contrasena=obtener_hash_contrasena(contrasena_plana),
        rol=usuario_in.rol or "user",
        departamento_id=usuario_in.departamento_id,
        turno_id=usuario_in.turno_id,
        estado=usuario_in.estado or "active",
        creado_en=datetime.utcnow(),
        actualizado_en=datetime.utcnow(),
        es_temporal=es_temporal,
        contrasena_temporal=es_temporal,
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    
    # Devolver la contraseña generada
    result = usuario.__dict__.copy()
    result["contrasena_generada"] = contrasena_plana if es_temporal else None
    return result


@router.get("/me", response_model=UsuarioLeer)
def obtener_mis_datos(usuario_actual: Usuario = Depends(obtener_usuario_actual)):
    return usuario_actual


@router.get("/", response_model=list[UsuarioLeer])
def obtener_usuarios(
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_admin_actual)
):
    """
    Obtiene la lista de todos los usuarios registrados en el sistema.
    Solo accesible para usuarios con rol de administrador.
    """
    usuarios = db.query(Usuario).all()
    return usuarios


@router.get("/turnos", response_model=list[TurnoLeer])
def obtener_turnos(db: Session = Depends(obtener_bd)):
    """
    Obtiene la lista de todos los turnos disponibles.
    """
    turnos = db.query(Turno).all()
    return turnos


@router.get("/departamentos", response_model=list[DepartamentoLeer])
def obtener_departamentos(db: Session = Depends(obtener_bd)):
    """
    Obtiene la lista de todos los departamentos disponibles.
    """
    departamentos = db.query(Departamento).all()
    return departamentos


@router.get("/{numero_empleado}", response_model=UsuarioLeer)
def obtener_usuario(numero_empleado: str, usuario_actual: Usuario = Depends(obtener_usuario_actual), db: Session = Depends(obtener_bd)):
    usuario = obtener_usuario_por_numero_empleado(db, numero_empleado)
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    if usuario_actual.rol != "admin" and usuario_actual.numero_empleado != numero_empleado:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tiene permiso para ver este usuario")
    return usuario


# ========== ACTUALIZAR USUARIO ==========
@router.put("/{numero_empleado}", response_model=UsuarioLeer)
def actualizar_usuario(
    numero_empleado: str,
    usuario_in: UsuarioActualizar,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_admin_actual)
):
    """
    Actualiza los datos de un usuario existente.
    Solo accesible para administradores.
    """
    usuario = obtener_usuario_por_numero_empleado(db, numero_empleado)
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    
    # No permitir cambiar el rol del administrador principal
    if usuario.rol == "admin" and usuario_in.rol and usuario_in.rol != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No se puede cambiar el rol del administrador principal"
        )
    
    # Actualizar solo los campos que vienen en la petición
    if usuario_in.nombre is not None:
        usuario.nombre = usuario_in.nombre
    if usuario_in.apellido is not None:
        usuario.apellido = usuario_in.apellido
    if usuario_in.departamento_id is not None:
        usuario.departamento_id = usuario_in.departamento_id
    if usuario_in.turno_id is not None:
        usuario.turno_id = usuario_in.turno_id
    if usuario_in.rol is not None:
        usuario.rol = usuario_in.rol
    if usuario_in.estado is not None:
        usuario.estado = usuario_in.estado
    
    # Si se envía una nueva contraseña, actualizarla
    if usuario_in.contrasena is not None and usuario_in.contrasena != "":
        usuario.hash_contrasena = obtener_hash_contrasena(usuario_in.contrasena)
    
    usuario.actualizado_en = datetime.utcnow()
    
    db.commit()
    db.refresh(usuario)
    return usuario


# ========== ELIMINAR USUARIO ==========
@router.delete("/{numero_empleado}")
def eliminar_usuario(
    numero_empleado: str,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_admin_actual)
):
    """
    Elimina físicamente a un usuario de la base de datos.
    Solo accesible para administradores.
    No se puede eliminar al administrador principal.
    """
    usuario = obtener_usuario_por_numero_empleado(db, numero_empleado)
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    
    if usuario.rol == "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No se puede eliminar al administrador principal"
        )
    
    db.delete(usuario)
    db.commit()
    
    return {"message": f"Usuario {usuario.nombre} {usuario.apellido} eliminado correctamente"}


# ========== CAMBIAR CONTRASEÑA ==========
@router.post("/cambiar-contrasena")
def cambiar_contrasena(
    request_data: dict,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    Permite al usuario cambiar su contraseña.
    Si es contraseña temporal, no requiere la contraseña actual.
    """
    contrasena_actual = request_data.get('contrasena_actual', '')
    nueva_contrasena = request_data.get('nueva_contrasena', '')
    
    print("\n" + "="*50)
    print("📥 CAMBIAR CONTRASEÑA:")
    print(f"   Usuario: {usuario_actual.numero_empleado}")
    print(f"   contrasena_actual: {'***' if contrasena_actual else 'VACIA'}")
    print(f"   nueva_contrasena: {'***' if nueva_contrasena else 'VACIA'}")
    print("="*50 + "\n")
    
    # Validar nueva contraseña
    if len(nueva_contrasena) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos 8 caracteres"
        )
    
    if not any(c.isupper() for c in nueva_contrasena):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos una mayuscula"
        )
    
    if not any(c.islower() for c in nueva_contrasena):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos una minuscula"
        )
    
    if not any(c.isdigit() for c in nueva_contrasena):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos un numero"
        )
    
    caracteres_especiales = "!@#$%^&*(),.?\":{}|<>"
    if not any(c in caracteres_especiales for c in nueva_contrasena):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña debe tener al menos un caracter especial"
        )
    
    # Si es contraseña temporal, no necesita verificar la actual
    if usuario_actual.contrasena_temporal:
        usuario_actual.hash_contrasena = obtener_hash_contrasena(nueva_contrasena)
        usuario_actual.contrasena_temporal = False
        usuario_actual.es_temporal = False
        usuario_actual.actualizado_en = datetime.utcnow()
        db.commit()
        db.refresh(usuario_actual)
        
        # Devolver el usuario actualizado
        return {
            "message": "Contraseña actualizada exitosamente",
            "usuario": {
                "id": usuario_actual.id,
                "numero_empleado": usuario_actual.numero_empleado,
                "nombre": usuario_actual.nombre,
                "apellido": usuario_actual.apellido,
                "rol": usuario_actual.rol,
                "estado": usuario_actual.estado,
                "departamento_id": usuario_actual.departamento_id,
                "turno_id": usuario_actual.turno_id,
                "es_temporal": usuario_actual.es_temporal,
                "contrasena_temporal": usuario_actual.contrasena_temporal
            }
        }
    
    # Si no es temporal, verificar la contraseña actual
    if not verificar_contrasena(contrasena_actual, usuario_actual.hash_contrasena):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Contraseña actual incorrecta"
        )
    
    usuario_actual.hash_contrasena = obtener_hash_contrasena(nueva_contrasena)
    usuario_actual.contrasena_temporal = False
    usuario_actual.es_temporal = False
    usuario_actual.actualizado_en = datetime.utcnow()
    db.commit()
    db.refresh(usuario_actual)
    
    # Devolver el usuario actualizado
    return {
        "message": "Contraseña actualizada exitosamente",
        "usuario": {
            "id": usuario_actual.id,
            "numero_empleado": usuario_actual.numero_empleado,
            "nombre": usuario_actual.nombre,
            "apellido": usuario_actual.apellido,
            "rol": usuario_actual.rol,
            "estado": usuario_actual.estado,
            "departamento_id": usuario_actual.departamento_id,
            "turno_id": usuario_actual.turno_id,
            "es_temporal": usuario_actual.es_temporal,
            "contrasena_temporal": usuario_actual.contrasena_temporal
        }
    }