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
