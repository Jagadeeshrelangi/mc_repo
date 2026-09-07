"""Canonical Unified Orders API routes (Sprint 2, Architecture §4.7).

Provides the unified, cross-domain customer order feed powering the Flutter Orders tab.
All endpoints are strictly authenticated and owner-guarded via ``get_current_user()``.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.order import OrderCancelResponse, OrderDetailResponse, OrderEntryResponse
from app.services.order_service import OrderService

router = APIRouter()


@router.get(
    "",
    response_model=List[OrderEntryResponse],
    status_code=status.HTTP_200_OK,
    summary="List authenticated user's orders across all domains",
)
async def list_orders(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    order_type: Optional[str] = Query(None, alias="type"),
    order_status: Optional[str] = Query(None, alias="status"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[OrderEntryResponse]:
    """List cross-domain orders (Parts, Mechanic, Fuel, AI) for the authenticated user."""
    service = OrderService(session)
    orders = await service.list_orders(
        user_id=str(current_user.id),
        offset=offset,
        limit=limit,
        entry_type=order_type,
        status=order_status,
    )
    return [OrderEntryResponse.model_validate(o) for o in orders]


@router.get(
    "/{order_id}",
    response_model=OrderDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single order details (owner-scoped)",
)
async def get_order(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> OrderDetailResponse:
    """Fetch order details only if owned by the authenticated user."""
    service = OrderService(session)
    return await service.get_order(order_id=order_id, user_id=str(current_user.id))


@router.put(
    "/{order_id}/cancel",
    response_model=OrderCancelResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel an order (PUT, owner-scoped)",
)
async def cancel_order_put(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> OrderCancelResponse:
    """Cancel an order (owner-scoped) via PUT per Architecture §4.7."""
    service = OrderService(session)
    return await service.cancel_order(order_id=order_id, user_id=str(current_user.id))


@router.post(
    "/{order_id}/cancel",
    response_model=OrderCancelResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel an order (POST, owner-scoped)",
)
async def cancel_order_post(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> OrderCancelResponse:
    """Cancel an order (owner-scoped) via POST."""
    service = OrderService(session)
    return await service.cancel_order(order_id=order_id, user_id=str(current_user.id))
