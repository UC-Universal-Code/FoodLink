from datetime import datetime, date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from database import connection
from database.models import MenuSemanal, MenuItem, Usuario, Turno
from schemas import (
    MenuSemanalCrear, MenuSemanalLeer, MenuSemanalActualizar,
    MenuItemCrear, MenuItemLeer, MenuItemActualizar
)

from routers.users import obtener_usuario_actual, obtener_usuario_admin_actual

router = APIRouter(
    prefix="/menu", 
    tags=["menu"], 
    redirect_slashes=False
)

def obtener_bd():
    db = connection.SesionLocal()
    try:
        yield db
    finally:
        db.close()

# ========== FUNCIONES AUXILIARES ==========

def validar_semana(fecha_inicio: date, fecha_fin: date):
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
    if fecha_inicio.weekday() != 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La semana debe comenzar en lunes"
        )

def obtener_menu_activo_por_turno_y_fecha(db: Session, turno: str, fecha: date) -> Optional[MenuSemanal]:
    return db.query(MenuSemanal).filter(
        and_(
            MenuSemanal.activo == True,
            MenuSemanal.turno == turno,
            MenuSemanal.semana_inicio <= fecha,
            MenuSemanal.semana_fin >= fecha
        )
    ).first()

# ========== ENDPOINTS ==========

@router.post("/semanal", response_model=MenuSemanalLeer, status_code=status.HTTP_201_CREATED)
def crear_menu_semanal(
    menu_data: MenuSemanalCrear,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    if usuario_actual.rol not in ["cocinero", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los cocineros y administradores pueden crear menús"
        )
    
    validar_semana(menu_data.semana_inicio, menu_data.semana_fin)
    
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
    db.flush()
    
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


@router.get("/semanal/actual/", response_model=Optional[MenuSemanalLeer])
def obtener_menu_actual(
    fecha: Optional[str] = None,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    print("\n" + "="*60)
    print(" DEBUG: OBTENER MENU ACTUAL")
    print("="*60)
    
    if usuario_actual.turno_id is None:
        print("El usuario no tiene turno asignado")
        return None
    
    turno_obj = db.query(Turno).filter(Turno.id == usuario_actual.turno_id).first()
    if not turno_obj:
        print(f"Turno con ID {usuario_actual.turno_id} no encontrado")
        return None
    
    turno_nombre = turno_obj.nombre
    print(f" Turno del usuario: '{turno_nombre}'")
    
    if fecha:
        try:
            fecha_buscar = datetime.strptime(fecha, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    else:
        fecha_buscar = date.today()
    
    # 🔧 CORRECCIÓN: Buscar por turno_id en lugar de turno (string)
    # Primero obtenemos el menú
    menu = db.query(MenuSemanal).filter(
        and_(
            MenuSemanal.activo == True,
            MenuSemanal.turno == str(usuario_actual.turno_id),  # Convertir a string porque la BD guarda '1', '2', '3'
            MenuSemanal.semana_inicio <= fecha_buscar,
            MenuSemanal.semana_fin >= fecha_buscar
        )
    ).first()
    
    if menu:
        print(f"MENÚ ENCONTRADO! ID: {menu.id}")
        return menu
    
    # Si no se encontró, buscar por el nombre del turno
    print(f"Buscando por nombre de turno: '{turno_nombre}'")
    menu_alt = db.query(MenuSemanal).filter(
        and_(
            MenuSemanal.activo == True,
            MenuSemanal.turno == turno_nombre,
            MenuSemanal.semana_inicio <= fecha_buscar,
            MenuSemanal.semana_fin >= fecha_buscar
        )
    ).first()
    
    if menu_alt:
        print(f"MENÚ ENCONTRADO por nombre! ID: {menu_alt.id}")
        return menu_alt
    
    print(" No se encontró ningún menú")
    return None


@router.get("/semanal/turno/{turno}", response_model=Optional[MenuSemanalLeer])
def obtener_menu_por_turno_y_fecha(
    turno: str,
    fecha: Optional[str] = None,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    if fecha:
        try:
            fecha_buscar = datetime.strptime(fecha, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    else:
        fecha_buscar = date.today()
    
    if usuario_actual.rol != "admin" and usuario_actual.turno != turno:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para ver el menú de otro turno"
        )
    
    menu = obtener_menu_activo_por_turno_y_fecha(db, turno, fecha_buscar)
    return menu


@router.get("/semanal/mis-menus", response_model=List[MenuSemanalLeer])
def obtener_mis_menus(
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
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
    usuario_actual: Usuario = Depends(obtener_usuario_admin_actual)
):
    menus = db.query(MenuSemanal).order_by(MenuSemanal.semana_inicio.desc()).all()
    return menus


@router.get("/semanal/{menu_id}", response_model=MenuSemanalLeer)
def obtener_menu_por_id(
    menu_id: int,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    menu = db.query(MenuSemanal).filter(MenuSemanal.id == menu_id).first()
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Menú no encontrado"
        )
    return menu


@router.put("/semanal/{menu_id}", response_model=MenuSemanalLeer)
def editar_menu_semanal(
    menu_id: int,
    menu_data: MenuSemanalActualizar,
    db: Session = Depends(obtener_bd),
    usuario_actual: Usuario = Depends(obtener_usuario_actual)
):
    if usuario_actual.rol not in ["cocinero", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los cocineros y administradores pueden editar menús"
        )
    
    menu = db.query(MenuSemanal).filter(MenuSemanal.id == menu_id).first()
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Menú no encontrado"
        )
    
    if usuario_actual.rol != "admin" and menu.creado_por != usuario_actual.numero_empleado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para editar este menú"
        )
    
    hoy = date.today()
    if menu.semana_fin < hoy:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede modificar un menú de una semana que ya pasó"
        )
    
    if menu_data.semana_inicio is not None or menu_data.semana_fin is not None:
        nueva_inicio = menu_data.semana_inicio or menu.semana_inicio
        nueva_fin = menu_data.semana_fin or menu.semana_fin
        validar_semana(nueva_inicio, nueva_fin)
        menu.semana_inicio = nueva_inicio
        menu.semana_fin = nueva_fin
    
    if menu_data.turno is not None:
        menu.turno = menu_data.turno
    
    if menu_data.activo is not None:
        menu.activo = menu_data.activo
    
    if menu_data.items is not None:
        db.query(MenuItem).filter(MenuItem.menu_semanal_id == menu_id).delete()
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
                disponible=item_data.disponible if item_data.disponible is not None else True
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
    menu = db.query(MenuSemanal).filter(MenuSemanal.id == menu_id).first()
    if not menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Menú no encontrado"
        )
    
    if usuario_actual.rol != "admin" and menu.creado_por != usuario_actual.numero_empleado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para eliminar este menú"
        )
    
    db.delete(menu)
    db.commit()