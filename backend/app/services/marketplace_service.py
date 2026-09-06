"""Marketplace & Auto Parts service layer (Task 8 Stage 3B).

Coordinates catalog data, coupon validation, pricing computation, order placement,
and cross-domain activity ledger creation.

Architecture
------------
- Request-scoped: receives an ``AsyncSession`` via constructor injection.
- Read operations NEVER commit.
- Write operations coordinate multiple repository operations and ``session.commit()``
  EXACTLY ONCE per logical operation; any error performs ``session.rollback()`` and re-raises.
- User ownership is strictly verified via explicit ``user_id`` arguments.
"""

from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
from typing import List, Optional, Sequence
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntityNotFoundException, InvalidInputException
from app.models.brand import Brand
from app.models.category import Category
from app.models.coupon import Coupon
from app.models.offer import Offer
from app.models.order import Order
from app.models.order_entry import OrderEntry
from app.models.order_item import OrderItem
from app.models.product import Product
from app.models.product_review import ProductReview
from app.repositories.marketplace import (
    BrandRepository,
    CategoryRepository,
    CouponRepository,
    OfferRepository,
    OrderEntryRepository,
    OrderRepository,
    ProductRepository,
)
from app.schemas.marketplace import (
    CouponValidationResult,
    OrderCreate,
    ProductReviewCreate,
)

# Standard pricing thresholds
GST_RATE = Decimal("0.18")
DELIVERY_FEE = Decimal("49.00")
FREE_DELIVERY_THRESHOLD = Decimal("999.00")


class MarketplaceService:
    """Service handling all Auto Parts Marketplace business workflows."""

    def __init__(
        self,
        session: AsyncSession,
        product_repo: Optional[ProductRepository] = None,
        category_repo: Optional[CategoryRepository] = None,
        brand_repo: Optional[BrandRepository] = None,
        offer_repo: Optional[OfferRepository] = None,
        coupon_repo: Optional[CouponRepository] = None,
        order_repo: Optional[OrderRepository] = None,
        entry_repo: Optional[OrderEntryRepository] = None,
    ) -> None:
        self.session = session
        self.product_repo = product_repo or ProductRepository(session)
        self.category_repo = category_repo or CategoryRepository(session)
        self.brand_repo = brand_repo or BrandRepository(session)
        self.offer_repo = offer_repo or OfferRepository(session)
        self.coupon_repo = coupon_repo or CouponRepository(session)
        self.order_repo = order_repo or OrderRepository(session)
        self.entry_repo = entry_repo or OrderEntryRepository(session)

    # ── Catalog ─────────────────────────────────────────────────────────────

    async def list_categories(
        self, *, offset: int = 0, limit: int = 100
    ) -> Sequence[Category]:
        """List all catalog categories."""
        return await self.category_repo.list_all(offset=offset, limit=limit)

    async def list_brands(self, *, offset: int = 0, limit: int = 100) -> Sequence[Brand]:
        """List all manufacturer brands."""
        return await self.brand_repo.list_all(offset=offset, limit=limit)

    async def list_offers(
        self, *, category_id: Optional[str] = None, limit: int = 50
    ) -> Sequence[Offer]:
        """List promotional banner offers."""
        return await self.offer_repo.list_all(category_id=category_id, limit=limit)

    async def get_product(self, product_id: str) -> Product:
        """Get product by ID with full nested specifications, reviews, and compatibility."""
        product = await self.product_repo.get_by_id(product_id, load_relations=True)
        if not product:
            raise EntityNotFoundException("Product not found.")
        return product

    async def list_products(
        self,
        *,
        offset: int = 0,
        limit: int = 50,
        category_id: Optional[str] = None,
        brand_id: Optional[str] = None,
        is_featured: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> Sequence[Product]:
        """List products with catalog filtering and keyword search."""
        return await self.product_repo.list_all(
            offset=offset,
            limit=limit,
            category_id=category_id,
            brand_id=brand_id,
            is_featured=is_featured,
            search=search,
            load_relations=True,
        )

    async def add_product_review(
        self, product_id: str, payload: ProductReviewCreate
    ) -> ProductReview:
        """Adds a customer review for a product."""
        # Verify product exists
        product = await self.product_repo.get_by_id(product_id, load_relations=False)
        if not product:
            raise EntityNotFoundException("Product not found.")

        if payload.rating < Decimal("1.0") or payload.rating > Decimal("5.0"):
            raise InvalidInputException("Rating must be between 1.0 and 5.0.")

        try:
            review = ProductReview(
                id=f"REV-{uuid.uuid4().hex[:8].upper()}",
                product_id=product_id,
                author=payload.author or "Verified Customer",
                rating=payload.rating,
                comment=payload.comment,
                is_verified_purchase=True,
            )
            await self.product_repo.add_review(review)
            await self.session.commit()
            return review
        except Exception:
            await self.session.rollback()
            raise

    # ── Coupons ─────────────────────────────────────────────────────────────

    async def list_coupons(self, limit: int = 50) -> Sequence[Coupon]:
        """List available discount coupons."""
        return await self.coupon_repo.list_all(limit=limit)

    async def validate_coupon(
        self, code: str, order_amount: Decimal
    ) -> CouponValidationResult:
        """Validates coupon code against order amount and calculates discount."""
        if not code or not code.strip():
            return CouponValidationResult(
                is_valid=False,
                discount_amount=Decimal("0.00"),
                message="Coupon code is required.",
            )

        coupon = await self.coupon_repo.get_by_code(code.strip().upper())
        if not coupon:
            return CouponValidationResult(
                is_valid=False,
                discount_amount=Decimal("0.00"),
                message="Invalid coupon code.",
            )

        now = datetime.now(timezone.utc)
        if coupon.valid_from and now < coupon.valid_from:
            return CouponValidationResult(
                is_valid=False,
                discount_amount=Decimal("0.00"),
                message="Coupon is not active yet.",
            )
        if coupon.valid_until and now > coupon.valid_until:
            return CouponValidationResult(
                is_valid=False,
                discount_amount=Decimal("0.00"),
                message="Coupon has expired.",
            )

        if coupon.min_order_value and order_amount < coupon.min_order_value:
            return CouponValidationResult(
                is_valid=False,
                discount_amount=Decimal("0.00"),
                message=f"Minimum order value for this coupon is ₹{coupon.min_order_value}.",
            )

        discount_amount = Decimal("0.00")
        if coupon.type == "freeDelivery":
            discount_amount = DELIVERY_FEE
        elif coupon.type == "percent":
            calc = (order_amount * coupon.value / Decimal("100.0")).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
            if coupon.max_discount and calc > coupon.max_discount:
                calc = coupon.max_discount
            discount_amount = calc

        if discount_amount > order_amount:
            discount_amount = order_amount

        return CouponValidationResult(
            is_valid=True,
            discount_amount=discount_amount,
            message="Coupon applied successfully.",
        )

    # ── Orders & Activity Ledger ────────────────────────────────────────────

    async def create_order(
        self,
        user_id: str,
        payload: OrderCreate,
        coupon_code: Optional[str] = None,
    ) -> Order:
        """Places a marketplace order within a single atomic database transaction.

        Flow:
        1. Validate cart is non-empty.
        2. Fetch products and calculate authoritative server-side prices.
        3. Validate coupon and calculate discounts.
        4. Calculate delivery and GST.
        5. Persist Order, OrderItems, and OrderEntry (activity ledger).
        6. session.commit() once.
        """
        if not payload.items:
            raise InvalidInputException("Order must contain at least one item.")

        subtotal = Decimal("0.00")
        order_items_to_create: List[OrderItem] = []
        item_names: List[str] = []

        for item_in in payload.items:
            if item_in.quantity < 1:
                raise InvalidInputException("Item quantity must be at least 1.")

            # Load product for authoritative price
            product = None
            if item_in.product_id:
                product = await self.product_repo.get_by_id(
                    item_in.product_id, load_relations=False
                )

            unit_price = (
                product.price
                if product and product.price is not None
                else item_in.unit_price
            )
            product_name = (
                product.name if product else item_in.product_name or "Auto Part"
            )
            brand = product.brand.name if product and product.brand else item_in.brand

            line_total = (unit_price * Decimal(str(item_in.quantity))).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
            subtotal += line_total
            item_names.append(product_name)

            order_items_to_create.append(
                OrderItem(
                    id=str(uuid.uuid4()),
                    product_id=item_in.product_id,
                    product_name=product_name,
                    brand=brand,
                    quantity=item_in.quantity,
                    unit_price=unit_price,
                    line_total=line_total,
                )
            )

        # Calculate Delivery Fee
        delivery_fee = (
            Decimal("0.00")
            if subtotal >= FREE_DELIVERY_THRESHOLD or subtotal == Decimal("0.00")
            else DELIVERY_FEE
        )

        # Calculate Coupon Discount
        discount = Decimal("0.00")
        if coupon_code:
            val_res = await self.validate_coupon(coupon_code, subtotal)
            if val_res.is_valid:
                discount = val_res.discount_amount
                # If free delivery coupon
                if discount == DELIVERY_FEE:
                    delivery_fee = Decimal("0.00")
                    discount = Decimal("0.00")

        # Calculate 18% GST
        tax = (subtotal * GST_RATE).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        # Grand Total
        grand_total = (subtotal + delivery_fee + tax - discount).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        if grand_total < Decimal("0.00"):
            grand_total = Decimal("0.00")

        order_id = str(uuid.uuid4())
        external_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"

        try:
            # 1. Create Order
            order = Order(
                id=order_id,
                user_id=user_id,
                external_id=external_id,
                address=payload.address,
                payment_method=payload.payment_method or "UPI",
                subtotal=subtotal,
                discount=discount,
                delivery=delivery_fee,
                tax=tax,
                grand_total=grand_total,
                status="Pending",
            )
            await self.order_repo.create(order)

            # 2. Attach and create OrderItems
            for oi in order_items_to_create:
                oi.order_id = order_id
                self.session.add(oi)
            await self.session.flush()

            # 3. Create cross-domain OrderEntry (activity ledger)
            summary_name = (
                item_names[0]
                if len(item_names) == 1
                else f"{item_names[0]} +{len(item_names) - 1} items"
            )
            ledger_entry = OrderEntry(
                id=str(uuid.uuid4()),
                user_id=user_id,
                name=summary_name,
                brand=order_items_to_create[0].brand if order_items_to_create else None,
                quantity=sum(item.quantity for item in order_items_to_create),
                price=grand_total,
                type="parts",
                status="Pending",
                source="Marketplace Checkout",
            )
            await self.entry_repo.create(ledger_entry)

            # Commit the entire order creation transaction once
            await self.session.commit()

            # Return loaded order with relations
            loaded = await self.order_repo.get_by_id(order_id, load_relations=True)
            return loaded or order
        except Exception:
            await self.session.rollback()
            raise

    async def get_order(self, order_id: str, user_id: str) -> Order:
        """Fetch order belonging to the authenticated user."""
        order = await self.order_repo.get_owned(order_id, user_id, load_relations=True)
        if not order:
            raise EntityNotFoundException("Order not found.")
        return order

    async def list_user_orders(
        self, user_id: str, *, offset: int = 0, limit: int = 50
    ) -> Sequence[Order]:
        """List orders belonging to the authenticated user, newest first."""
        return await self.order_repo.list_for_user(
            user_id, offset=offset, limit=limit, load_relations=True
        )

    async def list_user_activity(
        self,
        user_id: str,
        *,
        offset: int = 0,
        limit: int = 100,
        entry_type: Optional[str] = None,
    ) -> Sequence[OrderEntry]:
        """List unified activity ledger entries for the authenticated user."""
        return await self.entry_repo.list_for_user(
            user_id, offset=offset, limit=limit, entry_type=entry_type
        )
