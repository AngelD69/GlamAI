from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.service import Service
from app.models.user import User
from app.schemas.service import ServiceCreate, ServiceResponse
from app.utils.dependencies import get_admin_user, get_current_user, get_db
from app.utils.logger import get_logger

router = APIRouter(prefix="/services", tags=["Services"])
logger = get_logger("service")


@router.post("/", response_model=ServiceResponse, status_code=201)
def create_service(
    service: ServiceCreate,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    logger.info("User id=%d creating service name=%s", current_user.id, service.name)
    existing = db.query(Service).filter(Service.name == service.name).first()
    if existing:
        logger.warning("Service already exists: %s", service.name)
        raise HTTPException(status_code=400, detail="Service with this name already exists")

    new_service = Service(
        name=service.name,
        description=service.description,
        price=service.price,
    )
    db.add(new_service)
    db.commit()
    db.refresh(new_service)
    logger.info("Service created: id=%d name=%s", new_service.id, new_service.name)
    return new_service


@router.get("/", response_model=list[ServiceResponse])
def get_all_services(db: Session = Depends(get_db)):
    services = db.query(Service).all()
    logger.debug("Fetched %d services", len(services))
    return services


@router.delete("/{service_id}", status_code=204)
def delete_service(
    service_id: int,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    logger.info("User id=%d deleting service id=%d", current_user.id, service_id)
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        logger.warning("Service not found: id=%d", service_id)
        raise HTTPException(status_code=404, detail="Service not found")
    db.delete(service)
    db.commit()
    logger.info("Service deleted: id=%d", service_id)
