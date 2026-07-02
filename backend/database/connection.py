from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError

# URL de conexion a PostgreSQL
DATABASE_URL = "postgresql://postgres:Asiel1234@localhost:5432/foodlink"

# motor de SQLAlchemy para conectar con la base de datos
engine = create_engine(DATABASE_URL, echo=False, future=True)

# factory de sesiones para crear conexiones con la base de datos
SesionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# funcion para verificar la conexion a la base de datos
def verificar_conexion() -> bool:
    try:
        with engine.connect() as conexion:
            conexion.execute(text("SELECT 1"))
        return True
    except OperationalError:
        return False
