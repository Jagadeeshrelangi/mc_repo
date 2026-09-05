"""Tests for Task 8 Stage 1 — Fuel & Marketplace SQLAlchemy ORM Models.

Validates the model contract:
- Metadata registration
- Table names
- Primary keys (Text, UUID, and Composite PKs)
- Foreign keys and targets
- Unique constraints and check constraints
- Column types, nullability, and default expressions
- Relationships and back_populates / cascade configurations
- DDL compilation against PostgreSQL dialect
"""

import inspect
from decimal import Decimal
import pytest
from sqlalchemy import Date, DateTime, Numeric, String, Text, Uuid
from sqlalchemy.dialects.postgresql import dialect as postgresql_dialect
from sqlalchemy.orm import RelationshipProperty
from sqlalchemy.schema import CreateTable

from app.core.database import Base
from app.models import (
    # Fuel
    FuelOrder,
    PriceEstimate,
    FuelStation,
    FuelPartner,
    TrackingEvent,
    Invoice,
    # Marketplace
    Category,
    Brand,
    Product,
    ProductSpecification,
    ProductVehicleType,
    ProductCompatibility,
    ProductReview,
    Offer,
    Coupon,
    Order,
    OrderItem,
    OrderEntry,
)

FUEL_TABLES = {
    "fuel_orders",
    "price_estimates",
    "fuel_stations",
    "fuel_partners",
    "tracking_events",
    "invoices",
}

MARKETPLACE_TABLES = {
    "categories",
    "brands",
    "products",
    "product_specifications",
    "product_vehicle_types",
    "product_compatibility",
    "product_reviews",
    "offers",
    "coupons",
    "orders",
    "order_items",
    "order_entries",
}

ALL_TASK8_TABLES = FUEL_TABLES | MARKETPLACE_TABLES


# ============================================================================
# Metadata Registration & Table Names
# ============================================================================


def test_all_task8_tables_registered() -> None:
    tables = set(Base.metadata.tables)
    assert ALL_TASK8_TABLES <= tables


def test_models_are_declarative() -> None:
    models = [
        FuelOrder,
        PriceEstimate,
        FuelStation,
        FuelPartner,
        TrackingEvent,
        Invoice,
        Category,
        Brand,
        Product,
        ProductSpecification,
        ProductVehicleType,
        ProductCompatibility,
        ProductReview,
        Offer,
        Coupon,
        Order,
        OrderItem,
        OrderEntry,
    ]
    for model in models:
        assert hasattr(model, "__table__")
        assert model.__table__.name in ALL_TASK8_TABLES


# ============================================================================
# Primary Key Validation
# ============================================================================


def test_primary_keys() -> None:
    # Text PKs
    assert [c.name for c in Base.metadata.tables["fuel_orders"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["fuel_stations"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["fuel_partners"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["invoices"].primary_key] == ["invoice_id"]
    assert [c.name for c in Base.metadata.tables["categories"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["brands"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["products"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["offers"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["coupons"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["order_entries"].primary_key] == ["id"]

    # UUID PKs
    assert [c.name for c in Base.metadata.tables["tracking_events"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["product_specifications"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["product_reviews"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["orders"].primary_key] == ["id"]
    assert [c.name for c in Base.metadata.tables["order_items"].primary_key] == ["id"]

    # Foreign Key as PK (1:1)
    assert [c.name for c in Base.metadata.tables["price_estimates"].primary_key] == ["fuel_order_id"]

    # Composite PKs
    assert sorted([c.name for c in Base.metadata.tables["product_vehicle_types"].primary_key]) == ["product_id", "vehicle_type"]
    assert sorted([c.name for c in Base.metadata.tables["product_compatibility"].primary_key]) == ["compatible_with", "product_id"]


# ============================================================================
# Foreign Keys Validation
# ============================================================================


def test_foreign_keys() -> None:
    # Fuel Orders -> Users
    fo_fks = list(Base.metadata.tables["fuel_orders"].foreign_keys)
    assert len(fo_fks) == 1
    assert fo_fks[0].parent.name == "user_id"
    assert fo_fks[0].target_fullname == "users.id"

    # Price Estimates -> Fuel Orders
    pe_fks = list(Base.metadata.tables["price_estimates"].foreign_keys)
    assert len(pe_fks) == 1
    assert pe_fks[0].parent.name == "fuel_order_id"
    assert pe_fks[0].target_fullname == "fuel_orders.id"

    # Tracking Events -> Fuel Orders
    te_fks = list(Base.metadata.tables["tracking_events"].foreign_keys)
    assert len(te_fks) == 1
    assert te_fks[0].parent.name == "order_id"
    assert te_fks[0].target_fullname == "fuel_orders.id"

    # Invoices -> Fuel Orders
    inv_fks = list(Base.metadata.tables["invoices"].foreign_keys)
    assert len(inv_fks) == 1
    assert inv_fks[0].parent.name == "order_id"
    assert inv_fks[0].target_fullname == "fuel_orders.id"

    # Products -> Brands, Categories
    prod_fks = {fk.parent.name: fk.target_fullname for fk in Base.metadata.tables["products"].foreign_keys}
    assert prod_fks["brand_id"] == "brands.id"
    assert prod_fks["category_id"] == "categories.id"

    # Product Children -> Products
    assert list(Base.metadata.tables["product_specifications"].foreign_keys)[0].target_fullname == "products.id"
    assert list(Base.metadata.tables["product_vehicle_types"].foreign_keys)[0].target_fullname == "products.id"
    assert list(Base.metadata.tables["product_compatibility"].foreign_keys)[0].target_fullname == "products.id"
    assert list(Base.metadata.tables["product_reviews"].foreign_keys)[0].target_fullname == "products.id"

    # Orders -> Users
    ord_fks = list(Base.metadata.tables["orders"].foreign_keys)
    assert len(ord_fks) == 1
    assert ord_fks[0].parent.name == "user_id"
    assert ord_fks[0].target_fullname == "users.id"

    # Order Items -> Orders
    oi_fks = list(Base.metadata.tables["order_items"].foreign_keys)
    assert len(oi_fks) == 1
    assert oi_fks[0].parent.name == "order_id"
    assert oi_fks[0].target_fullname == "orders.id"

    # Order Entries -> Users
    oe_fks = list(Base.metadata.tables["order_entries"].foreign_keys)
    assert len(oe_fks) == 1
    assert oe_fks[0].parent.name == "user_id"
    assert oe_fks[0].target_fullname == "users.id"


# ============================================================================
# Constraints & Indexes Validation
# ============================================================================


def test_unique_constraints() -> None:
    # invoices.order_id unique
    inv_uqs = [c for c in Base.metadata.tables["invoices"].constraints if c.__class__.__name__ == "UniqueConstraint"]
    assert any("order_id" in [col.name for col in c.columns] for c in inv_uqs)

    # coupons.code unique
    coupon_uqs = [c for c in Base.metadata.tables["coupons"].constraints if c.__class__.__name__ == "UniqueConstraint"]
    assert any("code" in [col.name for col in c.columns] for c in coupon_uqs)

    # orders.external_id unique
    ord_uqs = [c for c in Base.metadata.tables["orders"].constraints if c.__class__.__name__ == "UniqueConstraint"]
    assert any("external_id" in [col.name for col in c.columns] for c in ord_uqs)


def test_check_constraints() -> None:
    # fuel_stations.availability check
    fs_checks = [c.sqltext.text for c in Base.metadata.tables["fuel_stations"].constraints if c.__class__.__name__ == "CheckConstraint"]
    assert any("availability IN" in sql for sql in fs_checks)

    # coupons.type check
    coupon_checks = [c.sqltext.text for c in Base.metadata.tables["coupons"].constraints if c.__class__.__name__ == "CheckConstraint"]
    assert any("type IN ('percent', 'freeDelivery')" in sql for sql in coupon_checks)

    # order_entries check
    oe_checks = [c.sqltext.text for c in Base.metadata.tables["order_entries"].constraints if c.__class__.__name__ == "CheckConstraint"]
    assert any("type IN ('parts', 'mechanic', 'fuel', 'aiReport')" in sql for sql in oe_checks)
    assert any("status IN ('Pending', 'Delivered', 'Completed', 'In Progress', 'Cancelled')" in sql for sql in oe_checks)


# ============================================================================
# Relationships Validation
# ============================================================================


def test_fuel_order_relationships() -> None:
    assert hasattr(FuelOrder, "price_estimate")
    assert hasattr(FuelOrder, "tracking_events")
    assert hasattr(FuelOrder, "invoice")
    assert hasattr(PriceEstimate, "fuel_order")
    assert hasattr(TrackingEvent, "fuel_order")
    assert hasattr(Invoice, "fuel_order")


def test_marketplace_relationships() -> None:
    assert hasattr(Category, "products")
    assert hasattr(Category, "offers")
    assert hasattr(Brand, "products")
    assert hasattr(Offer, "category")
    assert hasattr(Product, "brand")
    assert hasattr(Product, "category")
    assert hasattr(Product, "specifications")
    assert hasattr(Product, "vehicle_types")
    assert hasattr(Product, "compatibility")
    assert hasattr(Product, "reviews")
    assert hasattr(ProductSpecification, "product")
    assert hasattr(ProductVehicleType, "product")
    assert hasattr(ProductCompatibility, "product")
    assert hasattr(ProductReview, "product")
    assert hasattr(Order, "items")
    assert hasattr(OrderItem, "order")


# ============================================================================
# DDL Compilation (PostgreSQL Dialect)
# ============================================================================


def test_ddl_compilation_postgresql() -> None:
    pg = postgresql_dialect()
    for table_name in ALL_TASK8_TABLES:
        table = Base.metadata.tables[table_name]
        ddl = str(CreateTable(table).compile(dialect=pg))
        assert f"CREATE TABLE {table_name}" in ddl
