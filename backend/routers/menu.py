# backend/routers/menu.py
from datetime import datetime, date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from database import connection
from database.models import MenuSemanal, MenuItem, Usuario
from schemas import (
    MenuSemanalCrear, MenuSemanalLeer, MenuSemanalActualizar,
    MenuItemCrear, MenuItemLeer, MenuItemActualizar
)

# Importar funciones de autenticación desde users.py
from routers.users import obtener_usuario_actual, obtener_usuario_admin_actual

router = APIRouter(prefix="/menu", tags=["menu"])

def obtener_bd():
    """Obtiene la sesión de la base de datos"""
    db = connection.SesionLocal()
    try:
        yield db
    finally:
        db.close()

# ========== FUNCIONES AUXILIARES ==========

def validar_semana(fecha_inicio: date, fecha_fin: date):
    """
    Valida que las fechas correspondan a una semana completa (lunes a domingo)
    """
    if fecha_inicio > fecha_fin:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La fecha de inicio debe ser menor a la fecha de fin"
        )
    
    dias_diferencia = (fecha_fin - fecha_inicio).days
    if dias_diferencia != 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El menú debe ser semanal (7 días, de lunes a domingo)"
        )
    
    # Verificar que comience en lunes (weekday() = 0 es lunes en Python)
    if fecha_inicio.weekday() != 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La semana debe comenzar en lunes"
        )

def obtener_menu_activo_por_turno(db: Session, turno: str, fecha: Optional[date] = None) -> Optional[MenuSemanal]:
    """
    Obtiene el menú activo para un turno y fecha específica
    Caso de uso: C6 - Visualizar menú semanal por turno
    """
    if fecha is None:
        fecha = date.today()
    
    return db.query(MenuSemanal).filter(
        and_(
            MenuSemanal.activo == True,
            MenuSemanal.turno == turno,
            MenuSemanal.semana_inicio <= fecha,
            MenuSemanal.semana_fin >= fecha
        )
    ).first()

# ========== ENDPOINTS PARA COCINEROS (CASOS DE USO C4 Y C5) ==========

@router.post("/semanal", response_model=MenuSemanalLeer, status_code=status.HTTP_201_CREATED)
def crear_menu_semanal(
    menu_data: MenuSemanalCrear,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    C4 - Crear menú semanal por turno
    
    El cocinero registra los platillos que estarán disponibles durante toda una semana
    en un turno específico.
    """
    # Verificar que el usuario sea cocinero o admin
    if usuario_actual.rol not in ["cocinero", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los cocineros y administradores pueden crear menús"
        )
    
    # Validar fechas
    validar_semana(menu_data.semana_inicio, menu_data.semana_fin)
    
    # Verificar que no exista un menú para esa semana y turno
    menu_existente = db.query(MenuSemanal).filter(
        and_(
            MenuSemanal.semana_inicio == menu_data.semana_inicio,
            MenuSemanal.semana_fin == menu_data.semana_fin,
            MenuSemanal.turno == menu_data.turno
        )
    ).first()
    
    if menu_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ya existe un menú para esta semana en el turno {menu_data.turno}"
        )
    
    # Verificar que no haya otro menú activo en el mismo período y turno
    menu_activo = db.query(MenuSemanal).filter(
        and_(
            MenuSemanal.activo == True,
            MenuSemanal.turno == menu_data.turno,
            MenuSemanal.semana_inicio <= menu_data.semana_fin,
            MenuSemanal.semana_fin >= menu_data.semana_inicio
        )
    ).first()
    
    if menu_activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ya hay un menú activo para el turno {menu_data.turno} en este período"
        )
    
    # Crear el menú semanal
    nuevo_menu = MenuSemanal(
        semana_inicio=menu_data.semana_inicio,
        semana_fin=menu_data.semana_fin,
        turno=menu_data.turno,
        activo=menu_data.activo,
        creado_por=usuario_actual.numero_empleado,
        creado_en=datetime.utcnow(),
        actualizado_en=datetime.utcnow()
    )
    db.add(nuevo_menu)
    db.flush()  # Para obtener el ID
    
    # Agregar los items del menú
    for item_data in menu_data.items:
        nuevo_item = MenuItem(
            menu_semanal_id=nuevo_menu.id,
            dia_semana=item_data.dia_semana.lower(),
            tipo_comida=item_data.tipo_comida.lower(),
            nombre_plato=item_data.nombre_plato,
            descripcion=item_data.descripcion,
            ingredientes=item_data.ingredientes,
            imagen_url=item_data.imagen_url,
            limite_porciones=item_data.limite_porciones,
            precio=item_data.precio,
            disponible=item_data.disponible
        )
        db.add(nuevo_item)
    
    db.commit()
    db.refresh(nuevo_menu)
    return nuevo_menu


@router.put("/semanal/{menu_id}", response_model=MenuSemanalLeer)
def editar_menu_semanal(
    menu_id: int,
    menu_data: MenuSemanalActualizar,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    C5 - Editar menú semanal por turno
    
    Permite modificar un platillo en el menú semanal publicado para un turno específico,
    ya sea para un día en particular o para toda la semana.
    """
    # Verificar que el usuario sea cocinero o admin
    if usuario_actual.rol not in ["cocinero", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los cocineros y administradores pueden editar menús"
        )
    
    # Buscar el menú
    menu = db.query(MenuSemanal).filter(MenuSemanal.id == menu_id).first()
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Menú no encontrado"
        )
    
    # Verificar que el cocinero sea el creador o admin
    if usuario_actual.rol != "admin" and menu.creado_por != usuario_actual.numero_empleado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para editar este menú"
        )
    
    # Verificar si el día ya pasó (no se puede modificar un día que ya pasó)
    hoy = date.today()
    if menu.semana_fin < hoy:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede modificar un menú de una semana que ya pasó"
        )
    
    # Actualizar campos del menú
    if menu_data.semana_inicio is not None:
        if menu_data.semana_fin is not None:
            validar_semana(menu_data.semana_inicio, menu_data.semana_fin)
        else:
            validar_semana(menu_data.semana_inicio, menu.semana_fin)
        menu.semana_inicio = menu_data.semana_inicio
    
    if menu_data.semana_fin is not None:
        if menu_data.semana_inicio is not None:
            validar_semana(menu_data.semana_inicio, menu_data.semana_fin)
        else:
            validar_semana(menu.semana_inicio, menu_data.semana_fin)
        menu.semana_fin = menu_data.semana_fin
    
    if menu_data.turno is not None:
        menu.turno = menu_data.turno
    
    if menu_data.activo is not None:
        # Si vamos a activar este menú, desactivar otros que se solapen
        if menu_data.activo and not menu.activo:
            fecha_inicio = menu_data.semana_inicio or menu.semana_inicio
            fecha_fin = menu_data.semana_fin or menu.semana_fin
            turno = menu_data.turno or menu.turno
            
            otro_activo = db.query(MenuSemanal).filter(
                and_(
                    MenuSemanal.id != menu_id,
                    MenuSemanal.activo == True,
                    MenuSemanal.turno == turno,
                    MenuSemanal.semana_inicio <= fecha_fin,
                    MenuSemanal.semana_fin >= fecha_inicio
                )
            ).first()
            
            if otro_activo:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Ya hay un menú activo para el turno {turno} en este período"
                )
        menu.activo = menu_data.activo
    
    # Actualizar items del menú si se proporcionaron
    if menu_data.items is not None:
        # Eliminar items existentes
        db.query(MenuItem).filter(MenuItem.menu_semanal_id == menu_id).delete()
        
        # Agregar nuevos items
        for item_data in menu_data.items:
            nuevo_item = MenuItem(
                menu_semanal_id=menu_id,
                dia_semana=item_data.dia_semana.lower(),
                tipo_comida=item_data.tipo_comida.lower(),
                nombre_plato=item_data.nombre_plato,
                descripcion=item_data.descripcion,
                ingredientes=item_data.ingredientes,
                imagen_url=item_data.imagen_url,
                limite_porciones=item_data.limite_porciones,
                precio=item_data.precio,
                disponible=item_data.disponible
            )
            db.add(nuevo_item)
    
    menu.actualizado_en = datetime.utcnow()
    db.commit()
    db.refresh(menu)
    return menu


@router.delete("/semanal/{menu_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_menu_semanal(
    menu_id: int,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    Elimina un menú semanal (solo el cocinero que lo creó o admin)
    """
    menu = db.query(MenuSemanal).filter(MenuSemanal.id == menu_id).first()
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Menú no encontrado"
        )
    
    # Verificar permisos: el cocinero que lo creó o admin
    if usuario_actual.rol != "admin" and menu.creado_por != usuario_actual.numero_empleado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para eliminar este menú"
        )
    
    db.delete(menu)
    db.commit()


# ========== ENDPOINTS PARA VISUALIZAR MENÚ (CASO DE USO C6) ==========

@router.get("/semanal/actual", response_model=MenuSemanalLeer)
def obtener_menu_actual(
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    C6 - Visualizar menú semanal por turno (versión automática)
    
    El trabajador consulta los platillos disponibles para toda la semana en su turno asignado.
    El sistema detecta automáticamente el turno del usuario.
    """
    if not usuario_actual.turno:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El usuario no tiene un turno asignado"
        )
    
    menu = obtener_menu_activo_por_turno(db, usuario_actual.turno)
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay menú disponible para el turno {usuario_actual.turno} en la semana actual"
        )
    return menu


@router.get("/semanal/turno/{turno}", response_model=MenuSemanalLeer)
def obtener_menu_por_turno(
    turno: str,
    fecha: Optional[date] = None,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    C6 - Visualizar menú semanal por turno (versión con parámetros)
    
    Permite consultar el menú de un turno específico en una fecha determinada.
    Solo administradores pueden ver menús de otros turnos.
    """
    if fecha is None:
        fecha = date.today()
    
    # Verificar que el usuario tenga acceso a este turno
    if usuario_actual.rol != "admin" and usuario_actual.turno != turno:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para ver el menú de otro turno"
        )
    
    menu = obtener_menu_activo_por_turno(db, turno, fecha)
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay menú disponible para el turno {turno} en la fecha {fecha}"
        )
    return menu


@router.get("/semanal/fecha", response_model=MenuSemanalLeer)
def obtener_menu_por_fecha(
    fecha: date,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    Obtiene el menú para una fecha específica en el turno del usuario
    """
    if not usuario_actual.turno:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El usuario no tiene un turno asignado"
        )
    
    menu = obtener_menu_activo_por_turno(db, usuario_actual.turno, fecha)
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay menú disponible para el turno {usuario_actual.turno} en la fecha {fecha}"
        )
    return menu


@router.get("/semanal/{menu_id}", response_model=MenuSemanalLeer)
def obtener_menu_por_id(
    menu_id: int,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    Obtiene un menú específico por su ID
    """
    menu = db.query(MenuSemanal).filter(MenuSemanal.id == menu_id).first()
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Menú no encontrado"
        )
    
    # Verificar acceso: el usuario solo puede ver menús de su turno (o admin)
    if usuario_actual.rol != "admin" and usuario_actual.turno != menu.turno:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para ver este menú"
        )
    
    return menu


@router.get("/semanal/mis-menus", response_model=List[MenuSemanalLeer])
def obtener_mis_menus(
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    """
    Obtiene todos los menús creados por el cocinero actual
    """
    if usuario_actual.rol not in ["cocinero", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los cocineros pueden ver sus menús"
        )
    
    menus = db.query(MenuSemanal).filter(
        MenuSemanal.creado_por == usuario_actual.numero_empleado
    ).order_by(MenuSemanal.semana_inicio.desc()).all()
    
    return menus


@router.get("/semanal/todos", response_model=List[MenuSemanalLeer])
def obtener_todos_menus(
    db: Session = Depends(obtener_bd),
    _: Usuario = Depends(obtener_usuario_admin_actual)
):
    """
    Obtiene todos los menús (solo administradores)
    """
    menus = db.query(MenuSemanal).order_by(MenuSemanal.semana_inicio.desc()).all()
    return menus