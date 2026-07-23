from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()

class Departamento(Base):
    __tablename__ = "departamentos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(128), nullable=False, unique=True)
    descripcion = Column(String(256), nullable=True)

    # relacion con los usuarios que pertenecen a este departamento
    usuarios = relationship("Usuario", back_populates="departamento")

class Turno(Base):
    __tablename__ = "turnos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(128), nullable=False, unique=True)
    hora_inicio = Column(String(16), nullable=False)
    hora_fin = Column(String(16), nullable=False)
    dias = Column(String(128), nullable=False)

    # relacion con los usuarios que tienen este turno
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

    # relaciones con departamento y turno
    departamento = relationship("Departamento", back_populates="usuarios")
    turno = relationship("Turno", back_populates="usuarios")

#--------------------
from sqlalchemy import Column, Integer, String, Float, Date, Boolean, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from database.connection import Base
from datetime import datetime
import enum

# ========== MODELOS PARA MENÚ SEMANAL ==========

class MenuSemanal(Base):
    """
    Modelo para el menú semanal
    Casos de uso: C4 - Crear menú semanal, C5 - Editar menú semanal, C6 - Visualizar menú semanal
    """
    __tablename__ = "menus_semanales"
    
    id = Column(Integer, primary_key=True, index=True)
    semana_inicio = Column(Date, nullable=False)  # Fecha de inicio (lunes)
    semana_fin = Column(Date, nullable=False)     # Fecha de fin (domingo)
    turno = Column(String(20), nullable=False)    # "Matutino", "Vespertino", "Nocturno"
    activo = Column(Boolean, default=True)
    creado_por = Column(String(50), nullable=False)  # Número de empleado del cocinero
    creado_en = Column(DateTime, default=datetime.utcnow)
    actualizado_en = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relación con los items del menú
    items = relationship("MenuItem", back_populates="menu", cascade="all, delete-orphan")
    
    # Relación con el usuario que lo creó (opcional)
    # creador = relationship("Usuario", foreign_keys=[creado_por])


class MenuItem(Base):
    __tablename__ = "menu_items"
    
    id = Column(Integer, primary_key=True, index=True)
    menu_semanal_id = Column(Integer, ForeignKey("menus_semanales.id", ondelete="CASCADE"), nullable=False)
    dia_semana = Column(String(20), nullable=False)  # "lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"
    tipo_comida = Column(String(20), nullable=False)  # "desayuno", "almuerzo", "cena"
    nombre_plato = Column(String(100), nullable=False)
    descripcion = Column(Text, nullable=True)
    ingredientes = Column(Text, nullable=True)  # Lista de ingredientes
    imagen_url = Column(String(255), nullable=True)
    limite_porciones = Column(Integer, nullable=True)  # Límite de porciones disponibles
    precio = Column(Float, nullable=False)
    disponible = Column(Boolean, default=True)
    
    # Relación con el menú semanal
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

    # Relación opcional con el usuario
    usuario = relationship("Usuario")