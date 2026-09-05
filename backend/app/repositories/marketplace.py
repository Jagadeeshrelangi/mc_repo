"""Marketplace & Parts repository layer (Task 8 Stage 3A).

DATA ACCESS ONLY — no FastAPI dependencies, no HTTP logic, no business rules.
Reads never commit; writes ``flush()`` only.
Transaction boundaries are owned by the service layer.
"""

from typing import Optional, Sequence

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.brand import Brand
from app.models.category import Category
from app.models.coupon import Coupon
from app.models.offer import Offer
from app.models.order import Order
from app.models.order_entry import OrderEntry
from app.models.order_item import OrderItem
from app.models.product import Product
from app.models.product_review import ProductReview
from app.repositories.base import BaseRepository


def _product_relations():
    """Selectinload options for full Product aggregate relationships."""
    return (
        selectinload(Product.brand),
        selectinload(Product.category),
        selectinload(Product.specifications),
        selectinload(Product.vehicle_types),
        selectinload(Product.compatibility),
        selectinload(Product.reviews),
    )


class CategoryRepository(BaseRepository[Category]):
    """Data access for marketplace categories."""

    model = Category

    async def get_by_id(self, category_id: str) -> Optional[Category]:
        """Fetch category by primary key."""
        return await self.session.get(self.model, category_id)

    async def list_all(self, *, offset: int = 0, limit: int = 100) -> Sequence[Category]:
        """List categories sorted by sort_order and name."""
        stmt = (
            select(self.model)
            .order_by(self.model.sort_order.asc(), self.model.name.asc())
            .offset(offset)
            .limit(limit)
        )
        result = await self.session.scalars(stmt)
        return list(result.all())


class BrandRepository(BaseRepository[Brand]):
    """Data access for marketplace manufacturer brands."""

    model = Brand

    async def get_by_id(self, brand_id: str) -> Optional[Brand]:
        """Fetch brand by primary key."""
        return await self.session.get(self.model, brand_id)

    async def list_all(self, *, offset: int = 0, limit: int = 100) -> Sequence[Brand]:
        """List brands sorted alphabetically."""
        stmt = select(self.model).order_by(self.model.name.asc()).offset(offset).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())


class OfferRepository(BaseRepository[Offer]):
    """Data access for promotional banners."""

    model = Offer

    async def get_by_id(self, offer_id: str) -> Optional[Offer]:
        """Fetch offer by primary key."""
        return await self.session.get(self.model, offer_id)

    async def list_all(
        self, *, category_id: Optional[str] = None, limit: int = 50
    ) -> Sequence[Offer]:
        """List offers, optionally filtered by category."""
        stmt = select(self.model)
        if category_id is not None:
            stmt = stmt.where(self.model.category_id == category_id)
        stmt = stmt.order_by(self.model.id).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())


class CouponRepository(BaseRepository[Coupon]):
    """Data access for discount coupons."""

    model = Coupon

    async def get_by_id(self, coupon_id: str) -> Optional[Coupon]:
        """Fetch coupon by primary key."""
        return await self.session.get(self.model, coupon_id)

    async def get_by_code(self, code: str) -> Optional[Coupon]:
        """Fetch coupon by unique code."""
        stmt = select(self.model).where(self.model.code == code)
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def list_all(self, *, limit: int = 50) -> Sequence[Coupon]:
        """List available coupons."""
        stmt = select(self.model).order_by(self.model.id).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())


class ProductRepository(BaseRepository[Product]):
    """Data access for marketplace products and attributes."""

    model = Product

    async def get_by_id(
        self, product_id: str, *, load_relations: bool = True
    ) -> Optional[Product]:
        """Fetch a single product by primary key."""
        if not load_relations:
            return await self.session.get(self.model, product_id)
        stmt = select(self.model).where(self.model.id == product_id).options(*_product_relations())
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def list_all(
        self,
        *,
        offset: int = 0,
        limit: int = 50,
        category_id: Optional[str] = None,
        brand_id: Optional[str] = None,
        is_featured: Optional[bool] = None,
        search: Optional[str] = None,
        load_relations: bool = True,
    ) -> Sequence[Product]:
        """List products with catalog filters and optional search query."""
        stmt = select(self.model)
        if category_id is not None:
            stmt = stmt.where(self.model.category_id == category_id)
        if brand_id is not None:
            stmt = stmt.where(self.model.brand_id == brand_id)
        if is_featured is not None:
            stmt = stmt.where(self.model.is_featured == is_featured)
        if search:
            stmt = stmt.where(self.model.name.ilike(f"%{search}%"))

        stmt = stmt.order_by(self.model.id).offset(offset).limit(limit)
        if load_relations:
            stmt = stmt.options(*_product_relations())
        result = await self.session.scalars(stmt)
        return list(result.all())

    async def add_review(self, review: ProductReview) -> ProductReview:
        """Persist a new product review (flush; commit owned by caller)."""
        self.session.add(review)
        await self.session.flush()
        return review

    async def list_reviews_for_product(self, product_id: str) -> Sequence[ProductReview]:
        """List reviews for a given product."""
        stmt = (
            select(ProductReview)
            .where(ProductReview.product_id == product_id)
            .order_by(ProductReview.reviewed_at.desc())
        )
        result = await self.session.scalars(stmt)
        return list(result.all())


class OrderRepository(BaseRepository[Order]):
    """Data access for marketplace customer orders."""

    model = Order

    async def get_by_id(
        self, order_id: str, *, load_relations: bool = True
    ) -> Optional[Order]:
        """Fetch order by primary key."""
        if not load_relations:
            return await self.session.get(self.model, order_id)
        stmt = (
            select(self.model)
            .where(self.model.id == order_id)
            .options(selectinload(Order.items))
        )
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def get_owned(
        self, order_id: str, user_id: str, *, load_relations: bool = True
    ) -> Optional[Order]:
        """Fetch order with explicit user ownership check."""
        stmt = select(self.model).where(
            self.model.id == order_id, self.model.user_id == user_id
        )
        if load_relations:
            stmt = stmt.options(selectinload(Order.items))
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def list_for_user(
        self,
        user_id: str,
        *,
        offset: int = 0,
        limit: int = 50,
        load_relations: bool = True,
    ) -> Sequence[Order]:
        """List orders belonging to a user, newest first."""
        stmt = (
            select(self.model)
            .where(self.model.user_id == user_id)
            .order_by(self.model.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        if load_relations:
            stmt = stmt.options(selectinload(Order.items))
        result = await self.session.scalars(stmt)
        return list(result.all())


class OrderEntryRepository(BaseRepository[OrderEntry]):
    """Data access for unified cross-domain user activity ledger."""

    model = OrderEntry

    async def get_by_id(self, entry_id: str) -> Optional[OrderEntry]:
        """Fetch ledger entry by primary key."""
        return await self.session.get(self.model, entry_id)

    async def get_owned(self, entry_id: str, user_id: str) -> Optional[OrderEntry]:
        """Fetch ledger entry with explicit user ownership check."""
        stmt = select(self.model).where(
            self.model.id == entry_id, self.model.user_id == user_id
        )
        result = await self.session.scalars(stmt)
        return result.one_or_none()

    async def list_for_user(
        self,
        user_id: str,
        *,
        offset: int = 0,
        limit: int = 100,
        entry_type: Optional[str] = None,
    ) -> Sequence[OrderEntry]:
        """List ledger entries for a user, newest first, with optional type filter."""
        stmt = select(self.model).where(self.model.user_id == user_id)
        if entry_type is not None:
            stmt = stmt.where(self.model.type == entry_type)
        stmt = stmt.order_by(self.model.occurred_at.desc()).offset(offset).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())
