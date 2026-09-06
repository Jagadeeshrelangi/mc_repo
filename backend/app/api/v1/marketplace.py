"""Marketplace & Auto Parts API routes (Task 8 Stage 4).

THIN HTTP LAYER over ``MarketplaceService`` — handles catalog browsing, coupon validation,
checkout order placement, and cross-domain activity ledger retrieval.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.marketplace import (
    BrandResponse,
    CategoryResponse,
    CouponResponse,
    CouponValidateIn,
    CouponValidationResult,
    OfferResponse,
    OrderCreate,
    OrderEntryResponse,
    OrderResponse,
    ProductResponse,
    ProductReviewCreate,
    ProductReviewResponse,
)
from app.services.marketplace_service import MarketplaceService

router = APIRouter()


# ---------------------------------------------------------------------------
# PUBLIC CATALOG BROWSING
# ---------------------------------------------------------------------------


@router.get(
    "/categories",
    response_model=List[CategoryResponse],
    status_code=status.HTTP_200_OK,
    summary="List marketplace product categories",
)
async def list_categories(
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    session: AsyncSession = Depends(get_db),
) -> List[CategoryResponse]:
    """List catalog categories."""
    service = MarketplaceService(session)
    categories = await service.list_categories(offset=offset, limit=limit)
    return [CategoryResponse.model_validate(c) for c in categories]


@router.get(
    "/brands",
    response_model=List[BrandResponse],
    status_code=status.HTTP_200_OK,
    summary="List marketplace manufacturer brands",
)
async def list_brands(
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    session: AsyncSession = Depends(get_db),
) -> List[BrandResponse]:
    """List manufacturer brands."""
    service = MarketplaceService(session)
    brands = await service.list_brands(offset=offset, limit=limit)
    return [BrandResponse.model_validate(b) for b in brands]


@router.get(
    "/offers",
    response_model=List[OfferResponse],
    status_code=status.HTTP_200_OK,
    summary="List promotional offers and banners",
)
async def list_offers(
    category_id: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_db),
) -> List[OfferResponse]:
    """List promotional banner offers."""
    service = MarketplaceService(session)
    offers = await service.list_offers(category_id=category_id, limit=limit)
    return [OfferResponse.model_validate(o) for o in offers]


@router.get(
    "/products",
    response_model=List[ProductResponse],
    status_code=status.HTTP_200_OK,
    summary="List and filter marketplace products",
)
async def list_products(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    category_id: Optional[str] = Query(None),
    brand_id: Optional[str] = Query(None),
    is_featured: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    session: AsyncSession = Depends(get_db),
) -> List[ProductResponse]:
    """List products with catalog filters and search."""
    service = MarketplaceService(session)
    products = await service.list_products(
        offset=offset,
        limit=limit,
        category_id=category_id,
        brand_id=brand_id,
        is_featured=is_featured,
        search=search,
    )
    return [ProductResponse.model_validate(p) for p in products]


@router.get(
    "/products/{product_id}",
    response_model=ProductResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single product details with specifications and reviews",
)
async def get_product_detail(
    product_id: str,
    session: AsyncSession = Depends(get_db),
) -> ProductResponse:
    """Fetch complete product aggregate details."""
    service = MarketplaceService(session)
    product = await service.get_product(product_id)
    return ProductResponse.model_validate(product)


@router.post(
    "/products/{product_id}/reviews",
    response_model=ProductReviewResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a verified customer review for a product",
)
async def add_product_review(
    product_id: str,
    payload: ProductReviewCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> ProductReviewResponse:
    """Add a verified product review."""
    service = MarketplaceService(session)
    # Ensure author is derived from authenticated user name if not provided
    if not payload.author and current_user.name:
        payload.author = current_user.name
    review = await service.add_product_review(product_id=product_id, payload=payload)
    return ProductReviewResponse.model_validate(review)


@router.get(
    "/coupons",
    response_model=List[CouponResponse],
    status_code=status.HTTP_200_OK,
    summary="List available discount coupons",
)
async def list_coupons(
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_db),
) -> List[CouponResponse]:
    """Fetch available promotional discount coupons."""
    service = MarketplaceService(session)
    coupons = await service.list_coupons(limit=limit)
    return [CouponResponse.model_validate(c) for c in coupons]


@router.post(
    "/coupons/validate",
    response_model=CouponValidationResult,
    status_code=status.HTTP_200_OK,
    summary="Validate a coupon code against an order amount",
)
async def validate_coupon(
    payload: CouponValidateIn,
    session: AsyncSession = Depends(get_db),
) -> CouponValidationResult:
    """Validate coupon code and return calculated discount."""
    service = MarketplaceService(session)
    return await service.validate_coupon(code=payload.code, order_amount=payload.order_amount)


# ---------------------------------------------------------------------------
# PROTECTED ORDERS & ACTIVITY (Authenticated User)
# ---------------------------------------------------------------------------


@router.post(
    "/orders",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Place a new marketplace order",
)
async def create_marketplace_order(
    payload: OrderCreate,
    coupon_code: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> OrderResponse:
    """Place a marketplace order within an atomic database transaction."""
    service = MarketplaceService(session)
    order = await service.create_order(
        user_id=str(current_user.id),
        payload=payload,
        coupon_code=coupon_code,
    )
    return OrderResponse.model_validate(order)


@router.get(
    "/orders",
    response_model=List[OrderResponse],
    status_code=status.HTTP_200_OK,
    summary="List authenticated user's marketplace orders",
)
async def list_user_marketplace_orders(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[OrderResponse]:
    """List orders belonging to the authenticated user (newest first)."""
    service = MarketplaceService(session)
    orders = await service.list_user_orders(user_id=str(current_user.id), offset=offset, limit=limit)
    return [OrderResponse.model_validate(o) for o in orders]


@router.get(
    "/orders/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single marketplace order (owner-scoped)",
)
async def get_user_marketplace_order(
    order_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> OrderResponse:
    """Fetch order details only if owned by the authenticated user."""
    service = MarketplaceService(session)
    order = await service.get_order(order_id=order_id, user_id=str(current_user.id))
    return OrderResponse.model_validate(order)


@router.get(
    "/activity",
    response_model=List[OrderEntryResponse],
    status_code=status.HTTP_200_OK,
    summary="List authenticated user's cross-domain activity ledger entries",
)
async def list_user_activity_ledger(
    entry_type: Optional[str] = Query(None, alias="type"),
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> List[OrderEntryResponse]:
    """List unified activity ledger entries (parts, fuel, mechanic, aiReport)."""
    service = MarketplaceService(session)
    entries = await service.list_user_activity(
        user_id=str(current_user.id), offset=offset, limit=limit, entry_type=entry_type
    )
    return [OrderEntryResponse.model_validate(e) for e in entries]
