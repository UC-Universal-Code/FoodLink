from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Date, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()

class Departamento(Base):
    __tablename__ = "departamentos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(128), nullable=False, unique=True)
    descripcion = Column(String(256), nullable=True)

    usuarios = relationship("Usuario", back_populates="departamento")

class Turno(Base):
    __tablename__ = "turnos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(128), nullable=False, unique=True)
    hora_inicio = Column(String(16), nullable=False)
    hora_fin = Column(String(16), nullable=False)
    dias = Column(String(128), nullable=False)

    usuarios = relationship("Usuario", back_populates="turno")

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    numero_empleado = Column(String(64), unique=True, nullable=False, index=True)
    nombre = Column(String(128), nullable=False)
    apellido = Column(String(128), nullable=False)
    hash_contrasena = Column(String(256), nullable=False)
    rol = Column(String(32), nullable=False, default="user")
    departamento_id = Column(Integer, ForeignKey("departamentos.id"), nullable=True)
    turno_id = Column(Integer, ForeignKey("turnos.id"), nullable=True)
    creado_en = Column(DateTime, default=datetime.utcnow)
    actualizado_en = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    estado = Column(String(32), nullable=False, default="active")

    departamento = relationship("Departamento", back_populates="usuarios")
    turno = relationship("Turno", back_populates="usuarios")

class MenuSemanal(Base):
    __tablename__ = "menus_semanales"
    
    id = Column(Integer, primary_key=True, index=True)
    semana_inicio = Column(Date, nullable=False)
    semana_fin = Column(Date, nullable=False)
    turno = Column(String(20), nullable=False)
    activo = Column(Boolean, default=True)
    creado_por = Column(String(50), nullable=False)
    creado_en = Column(DateTime, default=datetime.utcnow)
    actualizado_en = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    items = relationship("MenuItem", back_populates="menu", cascade="all, delete-orphan")

class MenuItem(Base):
    __tablename__ = "menu_items"
    
    id = Column(Integer, primary_key=True, index=True)
    menu_semanal_id = Column(Integer, ForeignKey("menus_semanales.id", ondelete="CASCADE"), nullable=False)
    dia_semana = Column(String(20), nullable=False)
    tipo_comida = Column(String(20), nullable=False)
    nombre_plato = Column(String(100), nullable=False)
    descripcion = Column(Text, nullable=True)
    ingredientes = Column(Text, nullable=True)
    imagen_url = Column(String(255), nullable=True)
    limite_porciones = Column(Integer, nullable=True)
    precio = Column(Float, nullable=False)
    disponible = Column(Boolean, default=True)
    
    menu = relationship("MenuSemanal", back_populates="items")

class ReporteIncidencia(Base):
    __tablename__ = "reportes_incidencias"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    numero_empleado = Column(String(50), nullable=False)
    titulo = Column(String(100), nullable=False)
    descripcion = Column(Text, nullable=False)
    estado = Column(String(50), nullable=False)
    creado_en = Column(DateTime, default=datetime.utcnow)

    usuario = relationship("Usuario")