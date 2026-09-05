"""Fuel Delivery API routes (Task 8 Stage 4).

THIN HTTP LAYER over ``FuelService`` — handles parameter parsing, request/response validation,
HTTP status codes, and user identity injection via ``get_current_user``.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.fuel import (
    FuelOrderCreate,
    FuelOrderResponse,
    FuelOrderUpdate,
    FuelStationResponse,
    InvoiceResponse,
    PriceEstimateCalculateIn,
    PriceEstimateResponse,
    TrackingEventResponse,
)
from app.services.fuel_service import FuelService

router = APIRouter()


# ---------------------------------------------------------------------------
# PUBLIC CATALOG & ESTIMATION
# ---------------------------------------------------------------------------


@router.get(
    "/stations",
    response_model=List[FuelStationResponse],
    status_code=status.HTTP_200_OK,
    summary="List partner fuel stations",
)
async def list_fuel_stations(
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    is_open: Optional[bool] = Query(None),
    session: AsyncSession = Depends(get_db),
) -> List[FuelStationResponse]:
    """Fetch partner fuel stations catalog with optional filtering."""
    service = FuelService(session)
    stations = await service.list_stations(offset=offset, limit=limit, is_open=is_open)
    return [FuelStationResponse.model_validate(s) for s in stations]


@router.get(
    "/stations/{station_id}",
    response_model=FuelStationResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single fuel station details",
)
async def get_fuel_station(
    station_id: str,
    session: AsyncSession = Depends(get_db),
) -> FuelStationResponse:
    """Fetch details of a single fuel station."""
    service = FuelService(session)
    station = await service.get_station(station_id)
    return FuelStationResponse.model_validate(station)


@router.post(
    "/estimate",
    response_model=PriceEstimateResponse,
    status_code=status.HTTP_200_OK,
    summary="Calculate fuel delivery price estimate",
)
async def calculate_price_estimate(
    payload: PriceEstimateCalculateIn,
    session: AsyncSession = Depends(get_db),
) -> PriceEstimateResponse:
    """Calculate upfront price estimate breakdown using authoritative domain rules."""
    service = FuelService(session)
    return await service.calculate_price(
        fuel_type=payload.fuel_type,
        quantity=payload.quantity,
        station_id=payload.station_id,
    )


# ---------------------------------------------------------------------------
# PROTECTED FUEL ORDERS (Authenticated User)
# ---------------------------------------------------------------------------


@router.post(
    "/orders",
    response_model=FuelOrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Place a new fuel delivery order",
)
async def create_fuel_order(
    payload: FuelOrderCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> FuelOrderResponse:
    """Place a new fuel order. Identity is strictly derived from the authenticated JWT."""
    service = FuelService(session)
    order = await service.create_order(user_id=str(current_user.id), payload=payload)
    return FuelOrderResponse.model_validate(order)


@router.get(
    "/orders",
    response_model=List[FuelOrderResponse],
    status_code=status.HTTP_200_OK,
    summary="List authenticated user's fuel orders",
)
async def list_user_fuel_orders(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[FuelOrderResponse]:
    """List authenticated user's fuel orders (newest first)."""
    service = FuelService(session)
    orders = await service.list_user_orders(user_id=str(current_user.id), offset=offset, limit=limit)
    return [FuelOrderResponse.model_validate(o) for o in orders]


@router.get(
    "/orders/{order_id}",
    response_model=FuelOrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single fuel order (owner-scoped)",
)
async def get_user_fuel_order(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> FuelOrderResponse:
    """Fetch order details only if owned by the authenticated user."""
    service = FuelService(session)
    order = await service.get_order(order_id=order_id, user_id=str(current_user.id))
    return FuelOrderResponse.model_validate(order)


@router.patch(
    "/orders/{order_id}/status",
    response_model=FuelOrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Update fuel order status",
)
async def update_fuel_order_status(
    order_id: str,
    payload: FuelOrderUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> FuelOrderResponse:
    """Update order status and log tracking milestone within an atomic transaction."""
    service = FuelService(session)
    order = await service.update_order_status(
        order_id=order_id,
        new_status=payload.status,
        user_id=str(current_user.id),
        partner_id=payload.partner_id,
    )
    return FuelOrderResponse.model_validate(order)


@router.get(
    "/orders/{order_id}/tracking",
    response_model=List[TrackingEventResponse],
    status_code=status.HTTP_200_OK,
    summary="Get tracking history for a fuel order",
)
async def get_fuel_order_tracking(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[TrackingEventResponse]:
    """Fetch chronological tracking event progression for the user's order."""
    service = FuelService(session)
    events = await service.get_tracking_events(order_id=order_id, user_id=str(current_user.id))
    return [TrackingEventResponse.model_validate(e) for e in events]


@router.get(
    "/orders/{order_id}/invoice",
    response_model=InvoiceResponse,
    status_code=status.HTTP_200_OK,
    summary="Get invoice for a completed fuel order",
)
async def get_fuel_order_invoice(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> InvoiceResponse:
    """Fetch invoice for a completed fuel order."""
    service = FuelService(session)
    invoice = await service.get_invoice(order_id=order_id, user_id=str(current_user.id))
    return InvoiceResponse.model_validate(invoice)
