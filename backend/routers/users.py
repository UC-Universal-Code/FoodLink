from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import connection
from database.models import Usuario
from schemas import PeticionLogin, TokenAcceso, DatosToken, UsuarioCrear, UsuarioLeer

router = APIRouter(prefix="/usuarios", tags=["usuarios"])

# configuracion de seguridad JWT y hashing
SECRET_KEY = "foodlink-backend-secret-key-2026"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
ADMIN_POR_DEFECTO_EMPLEADO = "admin"
ADMIN_POR_DEFECTO_CONTRASENA = "Admin1234"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/usuarios/login")

# funciones para trabajar con contrasenas y tokens

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

# endpoints de usuario

@router.post("/login", response_model=TokenAcceso)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(obtener_bd)):
    usuario = autenticar_usuario(db, form_data.username, form_data.password)
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Numero de empleado o contrasena incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token_acceso = crear_token_acceso(
        data={"sub": usuario.numero_empleado},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": token_acceso, "token_type": "bearer"}


@router.post("/", response_model=UsuarioLeer)
def crear_usuario(usuario_in: UsuarioCrear, db: Session = Depends(obtener_bd), _: Usuario = Depends(obtener_usuario_admin_actual)):
    usuario_existente = obtener_usuario_por_numero_empleado(db, usuario_in.numero_empleado)
    if usuario_existente:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El numero de empleado ya existe")
    usuario = Usuario(
        numero_empleado=usuario_in.numero_empleado,
        nombre=usuario_in.nombre,
        apellido=usuario_in.apellido,
        hash_contrasena=obtener_hash_contrasena(usuario_in.contrasena),
        rol=usuario_in.rol or "user",
        departamento_id=usuario_in.departamento_id,
        turno_id=usuario_in.turno_id,
        estado=usuario_in.estado or "active",
        creado_en=datetime.utcnow(),
        actualizado_en=datetime.utcnow(),
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario


@router.get("/me", response_model=UsuarioLeer)
def obtener_mis_datos(usuario_actual: Usuario = Depends(obtener_usuario_actual)):
    return usuario_actual


@router.get("/{numero_empleado}", response_model=UsuarioLeer)
def obtener_usuario(numero_empleado: str, usuario_actual: Usuario = Depends(obtener_usuario_actual), db: Session = Depends(obtener_bd)):
    usuario = obtener_usuario_por_numero_empleado(db, numero_empleado)
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    if usuario_actual.rol != "admin" and usuario_actual.numero_empleado != numero_empleado:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tiene permiso para ver este usuario")
    return usuario
