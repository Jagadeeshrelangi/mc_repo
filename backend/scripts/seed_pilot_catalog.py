"""Mecha Connect Production Pilot Catalog Seeder.

Seeds realistic pilot catalog data for Bengaluru, Karnataka:
1. Mechanics (categories, services, mechanics, skills, languages, hours, reviews)
2. Fuel Delivery (partners, stations)
3. Marketplace (categories, brands, offers, coupons, products, specs, vehicle types, compatibility, reviews)

Features:
- Purely additive & idempotent (PostgreSQL ON CONFLICT upsert)
- Zero modification of user, vehicle, address, order, or wallet data
- Single atomic transaction with automatic rollback on error
- Detailed CLI observability without leaking secrets
"""

from datetime import date, datetime, timezone
from decimal import Decimal
import os
import sys
import uuid

# Ensure backend/ root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import configure_database, dispose_engine
import app.core.database as db_module
from app.models.brand import Brand
from app.models.category import Category
from app.models.coupon import Coupon
from app.models.fuel_partner import FuelPartner
from app.models.fuel_station import FuelStation
from app.models.mechanic import (
    Mechanic,
    MechanicLanguage,
    MechanicSkill,
    MechanicWorkingHour,
)
from app.models.mechanic_category import MechanicCategory
from app.models.mechanic_review import MechanicReview
from app.models.mechanic_service import MechanicService, MechanicServiceOffered
from app.models.offer import Offer
from app.models.product import Product
from app.models.product_compatibility import ProductCompatibility
from app.models.product_review import ProductReview
from app.models.product_specification import ProductSpecification
from app.models.product_vehicle_type import ProductVehicleType

# Namespace for deterministic child UUIDs
SEED_NAMESPACE = uuid.UUID("a7e5898d-8a21-4f6e-953e-2bfa119934cd")

# ---------------------------------------------------------------------------
# 1. MECHANICS DOMAIN DATA
# ---------------------------------------------------------------------------

MECHANIC_CATEGORIES = [
    {"id": "cat_general", "name": "General Service", "icon": "build_rounded", "color": "0xFFF15A22", "bg_color": "0xFFFFF3ED", "description": "Regular maintenance & checkup", "sort_order": 0},
    {"id": "cat_breakdown", "name": "Breakdown", "icon": "warning_amber_rounded", "color": "0xFFEF4444", "bg_color": "0xFFFEE2E2", "description": "Emergency breakdown help", "sort_order": 1},
    {"id": "cat_battery", "name": "Battery", "icon": "battery_charging_full_rounded", "color": "0xFFF59E0B", "bg_color": "0xFFFEF3C7", "description": "Battery jumpstart & replacement", "sort_order": 2},
    {"id": "cat_tyre", "name": "Flat Tyre", "icon": "tire_repair_rounded", "color": "0xFF3B82F6", "bg_color": "0xFFEEF2FF", "description": "Puncture repair & tyre change", "sort_order": 3},
    {"id": "cat_engine", "name": "Engine", "icon": "precision_manufacturing_rounded", "color": "0xFF8B5CF6", "bg_color": "0xFFF3EEFF", "description": "Engine diagnostics & repair", "sort_order": 4},
    {"id": "cat_brake", "name": "Brake", "icon": "stop_circle_rounded", "color": "0xFF10B981", "bg_color": "0xFFD1FAE5", "description": "Brake pad replacement & service", "sort_order": 5},
    {"id": "cat_electrical", "name": "Electrical", "icon": "bolt_rounded", "color": "0xFFEC4899", "bg_color": "0xFFFDF2F8", "description": "Wiring & electrical fixes", "sort_order": 6},
    {"id": "cat_towing", "name": "Towing", "icon": "local_shipping_rounded", "color": "0xFF6B7280", "bg_color": "0xFFF3F4F6", "description": "Vehicle towing service", "sort_order": 7},
]

MECHANIC_SERVICES = [
    {"id": "svc_1", "name": "General Service", "icon": "build_rounded", "price": Decimal("499.00"), "estimated_minutes": 60, "description": "Oil change, filter check, comprehensive vehicle inspection"},
    {"id": "svc_2", "name": "Battery Service", "icon": "battery_charging_full_rounded", "price": Decimal("299.00"), "estimated_minutes": 30, "description": "Battery health check, terminal cleaning, jumpstart"},
    {"id": "svc_3", "name": "Flat Tyre Repair", "icon": "tire_repair_rounded", "price": Decimal("199.00"), "estimated_minutes": 25, "description": "Puncture repair, tyre inflation, wheel alignment check"},
    {"id": "svc_4", "name": "Engine Diagnostics", "icon": "precision_manufacturing_rounded", "price": Decimal("699.00"), "estimated_minutes": 90, "description": "OBD-II computer scan, sensor analysis, fault code reading"},
    {"id": "svc_5", "name": "Brake Service", "icon": "stop_circle_rounded", "price": Decimal("399.00"), "estimated_minutes": 45, "description": "Brake pad inspection, disc cleaning, fluid top-up"},
    {"id": "svc_6", "name": "Electrical Repair", "icon": "bolt_rounded", "price": Decimal("349.00"), "estimated_minutes": 40, "description": "Wiring, headlight, horn, fuse, and switch troubleshooting"},
    {"id": "svc_7", "name": "Clutch Service", "icon": "settings_rounded", "price": Decimal("549.00"), "estimated_minutes": 75, "description": "Clutch cable adjustment, lever lubrication, friction plate check"},
    {"id": "svc_8", "name": "Oil Change", "icon": "oil_barrel_rounded", "price": Decimal("249.00"), "estimated_minutes": 20, "description": "Engine oil drain, flush, and refill with premium lubricant"},
]

MECHANICS = [
    {
        "id": "m1",
        "name": "Rajesh Auto Garage",
        "rating": Decimal("4.80"),
        "review_count": 126,
        "experience_years": 12,
        "distance_km": Decimal("1.20"),
        "eta_minutes": 8,
        "is_available": True,
        "price_starting": Decimal("199.00"),
        "phone": "+91 98765 43210",
        "about": "Rajesh Auto Garage has served vehicle owners in Indiranagar for over 12 years. Specializing in two-wheeler and four-wheeler repairs, we provide rapid roadside assistance with OEM-grade spare parts.",
        "is_verified": True,
        "skills": ["Engine", "Brake", "Electrical", "Battery"],
        "languages": ["English", "Hindi", "Kannada", "Telugu"],
        "working_hours": [
            {"day": "Mon-Fri", "open": "8:00 AM", "close": "8:00 PM"},
            {"day": "Sat", "open": "9:00 AM", "close": "6:00 PM"},
            {"day": "Sun", "open": "10:00 AM", "close": "4:00 PM"},
        ],
        "services": ["svc_1", "svc_2", "svc_3", "svc_4", "svc_5", "svc_6", "svc_7", "svc_8"],
    },
    {
        "id": "m2",
        "name": "Sai Mechanical Works",
        "rating": Decimal("4.60"),
        "review_count": 89,
        "experience_years": 8,
        "distance_km": Decimal("0.80"),
        "eta_minutes": 5,
        "is_available": True,
        "price_starting": Decimal("149.00"),
        "phone": "+91 98765 43211",
        "about": "Sai Mechanical Works offers prompt, affordable roadside assistance across Koramangala. Equipped with mobile diagnostic tools for fast on-the-spot fixes.",
        "is_verified": True,
        "skills": ["Battery", "Flat Tyre", "General Service", "Oil Change"],
        "languages": ["English", "Hindi", "Tamil", "Kannada"],
        "working_hours": [
            {"day": "Mon-Sat", "open": "7:00 AM", "close": "9:00 PM"},
            {"day": "Sun", "open": "9:00 AM", "close": "5:00 PM"},
        ],
        "services": ["svc_1", "svc_2", "svc_3", "svc_8"],
    },
    {
        "id": "m3",
        "name": "QuickFix Two-Wheeler Care",
        "rating": Decimal("4.30"),
        "review_count": 54,
        "experience_years": 5,
        "distance_km": Decimal("2.50"),
        "eta_minutes": 12,
        "is_available": True,
        "price_starting": Decimal("179.00"),
        "phone": "+91 98765 43212",
        "about": "QuickFix Garage provides fast and efficient repair services in HSR Layout. Modern diagnostic tools help troubleshoot electrical and engine faults accurately.",
        "is_verified": False,
        "skills": ["Engine", "Electrical", "General Service"],
        "languages": ["English", "Hindi", "Kannada"],
        "working_hours": [
            {"day": "Mon-Sat", "open": "8:00 AM", "close": "7:00 PM"},
            {"day": "Sun", "open": "Closed", "close": "Closed"},
        ],
        "services": ["svc_1", "svc_4", "svc_6"],
    },
    {
        "id": "m4",
        "name": "Sharma Auto Care",
        "rating": Decimal("4.90"),
        "review_count": 203,
        "experience_years": 15,
        "distance_km": Decimal("3.80"),
        "eta_minutes": 18,
        "is_available": False,
        "price_starting": Decimal("249.00"),
        "phone": "+91 98765 43213",
        "about": "Sharma Auto Care is a premium vehicle service center in Whitefield with 15 years of certified technician experience. We specialize in complex engine overhauls.",
        "is_verified": True,
        "skills": ["Engine", "Brake", "Clutch", "Electrical", "Towing"],
        "languages": ["English", "Hindi", "Punjabi", "Kannada"],
        "working_hours": [
            {"day": "Mon-Fri", "open": "9:00 AM", "close": "7:00 PM"},
            {"day": "Sat", "open": "9:00 AM", "close": "5:00 PM"},
            {"day": "Sun", "open": "Closed", "close": "Closed"},
        ],
        "services": ["svc_1", "svc_2", "svc_4", "svc_5", "svc_6", "svc_7"],
    },
    {
        "id": "m5",
        "name": "Apex Motors & Diagnostics",
        "rating": Decimal("4.70"),
        "review_count": 110,
        "experience_years": 10,
        "distance_km": Decimal("4.20"),
        "eta_minutes": 16,
        "is_available": True,
        "price_starting": Decimal("299.00"),
        "phone": "+91 98765 43214",
        "about": "Apex Motors brings specialized electronic diagnostics and computerized brake testing right to Bellandur and Outer Ring Road tech hubs.",
        "is_verified": True,
        "skills": ["Engine", "Electrical", "Brake", "Battery"],
        "languages": ["English", "Hindi", "Telugu", "Kannada"],
        "working_hours": [
            {"day": "Mon-Sat", "open": "8:30 AM", "close": "8:30 PM"},
            {"day": "Sun", "open": "10:00 AM", "close": "3:00 PM"},
        ],
        "services": ["svc_1", "svc_2", "svc_4", "svc_5"],
    },
    {
        "id": "m6",
        "name": "South City Garage",
        "rating": Decimal("4.50"),
        "review_count": 75,
        "experience_years": 7,
        "distance_km": Decimal("3.10"),
        "eta_minutes": 14,
        "is_available": True,
        "price_starting": Decimal("199.00"),
        "phone": "+91 98765 43215",
        "about": "Trusted neighborhood workshop in Jayanagar providing quick oil changes, tyre punctures, and clutch tuning for all common commuter vehicles.",
        "is_verified": True,
        "skills": ["General Service", "Oil Change", "Flat Tyre", "Clutch"],
        "languages": ["Kannada", "Tamil", "English"],
        "working_hours": [
            {"day": "Mon-Sat", "open": "9:00 AM", "close": "8:00 PM"},
            {"day": "Sun", "open": "9:00 AM", "close": "1:00 PM"},
        ],
        "services": ["svc_1", "svc_3", "svc_7", "svc_8"],
    },
    {
        "id": "m7",
        "name": "Express Roadside Assistance",
        "rating": Decimal("4.60"),
        "review_count": 92,
        "experience_years": 9,
        "distance_km": Decimal("1.50"),
        "eta_minutes": 10,
        "is_available": True,
        "price_starting": Decimal("199.00"),
        "phone": "+91 98765 43216",
        "about": "Central Bengaluru emergency rescue unit on MG Road. 24/7 battery jumpstarts, tyre repairs, and breakdown dispatch with rapid arrival times.",
        "is_verified": True,
        "skills": ["Battery", "Flat Tyre", "Breakdown", "Towing"],
        "languages": ["English", "Hindi", "Kannada", "Malayalam"],
        "working_hours": [
            {"day": "Mon-Sun", "open": "12:00 AM", "close": "11:59 PM"},
        ],
        "services": ["svc_2", "svc_3", "svc_6"],
    },
    {
        "id": "m8",
        "name": "Nandi Hill Rescue & Garage",
        "rating": Decimal("4.40"),
        "review_count": 48,
        "experience_years": 6,
        "distance_km": Decimal("5.00"),
        "eta_minutes": 20,
        "is_available": True,
        "price_starting": Decimal("229.00"),
        "phone": "+91 98765 43217",
        "about": "Hebbal and North Bangalore auto service specialists with flatbed recovery support, brake overhauls, and routine highway safety checks.",
        "is_verified": True,
        "skills": ["Brake", "Engine", "Towing", "General Service"],
        "languages": ["Kannada", "Telugu", "English", "Hindi"],
        "working_hours": [
            {"day": "Mon-Sat", "open": "8:00 AM", "close": "8:00 PM"},
            {"day": "Sun", "open": "10:00 AM", "close": "4:00 PM"},
        ],
        "services": ["svc_1", "svc_4", "svc_5"],
    },
]

MECHANIC_REVIEWS = [
    {"id": "r1", "mechanic_id": "m1", "reviewer_name": "Ravi Kumar", "rating": Decimal("5.00"), "comment": "Excellent service! Fixed my bike's engine overheating issue within an hour.", "reviewed_at": date(2026, 9, 6), "vehicle": "Honda Activa 6G"},
    {"id": "r2", "mechanic_id": "m1", "reviewer_name": "Priya Sharma", "rating": Decimal("5.00"), "comment": "Very professional and punctual. Arrived in 10 mins for battery replacement.", "reviewed_at": date(2026, 9, 2), "vehicle": "TVS Jupiter"},
    {"id": "r3", "mechanic_id": "m1", "reviewer_name": "Anil Reddy", "rating": Decimal("4.00"), "comment": "Good work, reasonable pricing. The technician explained what parts needed replacement.", "reviewed_at": date(2026, 8, 25), "vehicle": "Hero Splendor Plus"},
    {"id": "r4", "mechanic_id": "m2", "reviewer_name": "Suresh Patil", "rating": Decimal("5.00"), "comment": "Quick battery jumpstart at night in Koramangala. Absolute lifesaver!", "reviewed_at": date(2026, 9, 5), "vehicle": "Maruti Suzuki Alto"},
    {"id": "r5", "mechanic_id": "m2", "reviewer_name": "Kavita Nair", "rating": Decimal("4.00"), "comment": "Affordable and fast tyre puncture repair on the spot. Great courtesy.", "reviewed_at": date(2026, 9, 1), "vehicle": "Yamaha FZ-S"},
    {"id": "r6", "mechanic_id": "m3", "reviewer_name": "Mohit Verma", "rating": Decimal("4.00"), "comment": "Diagnosed the electrical fuse issue fast. Clean workmanship.", "reviewed_at": date(2026, 9, 3), "vehicle": "Honda City i-VTEC"},
    {"id": "r7", "mechanic_id": "m4", "reviewer_name": "Deepak Jain", "rating": Decimal("5.00"), "comment": "Best workshop in Whitefield. OEM parts and transparent billing.", "reviewed_at": date(2026, 9, 7), "vehicle": "Royal Enfield Classic 350"},
    {"id": "r8", "mechanic_id": "m4", "reviewer_name": "Sunita Rao", "rating": Decimal("5.00"), "comment": "Clutch replacement done perfectly. Gear shifting is butter smooth now.", "reviewed_at": date(2026, 9, 4), "vehicle": "Hyundai i20"},
    {"id": "r9", "mechanic_id": "m5", "reviewer_name": "Gautam Das", "rating": Decimal("5.00"), "comment": "Computerized scanner pinpointed the sensor error right away. Very modern setup.", "reviewed_at": date(2026, 8, 28), "vehicle": "Kia Seltos"},
    {"id": "r10", "mechanic_id": "m6", "reviewer_name": "Chethan Gowda", "rating": Decimal("4.00"), "comment": "Routine 10,000 km service done in Jayanagar. Prompt and reliable.", "reviewed_at": date(2026, 8, 30), "vehicle": "Maruti Swift Dzire"},
    {"id": "r11", "mechanic_id": "m7", "reviewer_name": "Farhan Ahmed", "rating": Decimal("5.00"), "comment": "Towing and jumpstart on MG Road in 15 minutes flat. High quality response.", "reviewed_at": date(2026, 9, 7), "vehicle": "Volkswagen Polo"},
    {"id": "r12", "mechanic_id": "m8", "reviewer_name": "Naveen Babu", "rating": Decimal("4.00"), "comment": "Reliable brake overhaul before long highway drive. Firm and responsive pedal feel.", "reviewed_at": date(2026, 9, 4), "vehicle": "Tata Nexon"},
]

# ---------------------------------------------------------------------------
# 2. FUEL DELIVERY DOMAIN DATA
# ---------------------------------------------------------------------------

FUEL_PARTNERS = [
    {
        "id": "partner_1",
        "name": "Manjunath Swamy",
        "phone": "+91 98450 11223",
        "rating": Decimal("4.80"),
        "rating_count": 142,
        "distance_km": Decimal("1.40"),
        "eta_minutes": 12,
        "is_available": True,
        "vehicle_number": "KA-01-EA-1001",
        "vehicle_model": "Tata Ace Mobile Bowser (500L)",
    },
    {
        "id": "partner_2",
        "name": "Siddharth Hegde",
        "phone": "+91 98450 22334",
        "rating": Decimal("4.70"),
        "rating_count": 98,
        "distance_km": Decimal("2.10"),
        "eta_minutes": 15,
        "is_available": True,
        "vehicle_number": "KA-03-FA-2002",
        "vehicle_model": "Mahindra Bolero Maxi Bowser (750L)",
    },
    {
        "id": "partner_3",
        "name": "Arun Kumar",
        "phone": "+91 98450 33445",
        "rating": Decimal("4.90"),
        "rating_count": 210,
        "distance_km": Decimal("1.80"),
        "eta_minutes": 14,
        "is_available": True,
        "vehicle_number": "KA-05-GA-3003",
        "vehicle_model": "Ashok Leyland Dost Fuel Van (600L)",
    },
    {
        "id": "partner_4",
        "name": "Venkatesh Prasad",
        "phone": "+91 98450 44556",
        "rating": Decimal("4.60"),
        "rating_count": 86,
        "distance_km": Decimal("3.20"),
        "eta_minutes": 18,
        "is_available": True,
        "vehicle_number": "KA-04-HA-4004",
        "vehicle_model": "Force Shaktiman Tanker (1000L)",
    },
]

FUEL_STATIONS = [
    {
        "id": "station_1",
        "name": "Main Road Filling Station",
        "brand": "Indian Oil",
        "rating": Decimal("4.60"),
        "rating_count": 1234,
        "distance_km": Decimal("1.20"),
        "eta_minutes": 12,
        "price_per_litre": Decimal("102.50"),
        "availability": "available",
        "is_open": True,
        "address": "12, MG Road, Bengaluru",
        "latitude": Decimal("12.971600"),
        "longitude": Decimal("77.594600"),
    },
    {
        "id": "station_2",
        "name": "Ring Road Fuels",
        "brand": "BPCL",
        "rating": Decimal("4.30"),
        "rating_count": 890,
        "distance_km": Decimal("2.40"),
        "eta_minutes": 16,
        "price_per_litre": Decimal("101.90"),
        "availability": "available",
        "is_open": True,
        "address": "45, 100 Feet Road, Indiranagar, Bengaluru",
        "latitude": Decimal("12.978400"),
        "longitude": Decimal("77.640800"),
    },
    {
        "id": "station_3",
        "name": "Koramangala Petroleum Point",
        "brand": "HPCL",
        "rating": Decimal("4.50"),
        "rating_count": 1050,
        "distance_km": Decimal("1.80"),
        "eta_minutes": 14,
        "price_per_litre": Decimal("102.10"),
        "availability": "available",
        "is_open": True,
        "address": "80 Feet Road, 4th Block, Koramangala, Bengaluru",
        "latitude": Decimal("12.935200"),
        "longitude": Decimal("77.624500"),
    },
    {
        "id": "station_4",
        "name": "Whitefield Shell Station",
        "brand": "Shell",
        "rating": Decimal("4.80"),
        "rating_count": 1540,
        "distance_km": Decimal("4.50"),
        "eta_minutes": 22,
        "price_per_litre": Decimal("108.00"),
        "availability": "available",
        "is_open": True,
        "address": "ITPL Main Road, Brookefield, Whitefield, Bengaluru",
        "latitude": Decimal("12.969800"),
        "longitude": Decimal("77.750000"),
    },
    {
        "id": "station_5",
        "name": "HSR Layout Fuel Hub",
        "brand": "Indian Oil",
        "rating": Decimal("4.40"),
        "rating_count": 720,
        "distance_km": Decimal("3.00"),
        "eta_minutes": 18,
        "price_per_litre": Decimal("102.40"),
        "availability": "available",
        "is_open": True,
        "address": "27th Main Road, Sector 1, HSR Layout, Bengaluru",
        "latitude": Decimal("12.912100"),
        "longitude": Decimal("77.644600"),
    },
    {
        "id": "station_6",
        "name": "Outer Ring Road Express Fuels",
        "brand": "BPCL",
        "rating": Decimal("4.20"),
        "rating_count": 610,
        "distance_km": Decimal("3.60"),
        "eta_minutes": 20,
        "price_per_litre": Decimal("102.00"),
        "availability": "low",
        "is_open": True,
        "address": "Marathahalli - Sarjapur Outer Ring Road, Bellandur, Bengaluru",
        "latitude": Decimal("12.926000"),
        "longitude": Decimal("77.676200"),
    },
]

# ---------------------------------------------------------------------------
# 3. MARKETPLACE & PARTS DOMAIN DATA
# ---------------------------------------------------------------------------

MARKETPLACE_CATEGORIES = [
    {"id": "engine-parts", "name": "Engine Parts", "icon": "settings_rounded", "sort_order": 0},
    {"id": "brake-system", "name": "Brake System", "icon": "disc_full_rounded", "sort_order": 1},
    {"id": "oils", "name": "Oils & Fluids", "icon": "oil_barrel_rounded", "sort_order": 2},
    {"id": "tyres", "name": "Tyres & Tubes", "icon": "speed_rounded", "sort_order": 3},
    {"id": "batteries", "name": "Batteries", "icon": "battery_charging_full_rounded", "sort_order": 4},
    {"id": "accessories", "name": "Accessories", "icon": "backpack_rounded", "sort_order": 5},
    {"id": "cleaning", "name": "Cleaning & Detailing", "icon": "cleaning_services_rounded", "sort_order": 6},
    {"id": "lights", "name": "Lighting & Electrical", "icon": "lightbulb_rounded", "sort_order": 7},
]

MARKETPLACE_BRANDS = [
    {"id": "bosch", "name": "Bosch"},
    {"id": "tvs", "name": "TVS"},
    {"id": "rolon", "name": "Rolon"},
    {"id": "ngk", "name": "NGK"},
    {"id": "castrol", "name": "Castrol"},
    {"id": "motul", "name": "Motul"},
    {"id": "mrf", "name": "MRF"},
    {"id": "ceat", "name": "CEAT"},
    {"id": "exide", "name": "Exide"},
    {"id": "amaron", "name": "Amaron"},
    {"id": "3m", "name": "3M"},
    {"id": "philips", "name": "Philips"},
]

MARKETPLACE_OFFERS = [
    {
        "id": "offer-brake",
        "title": "Brake & Filter Mega Sale",
        "subtitle": "Up to 40% off on braking and filtration parts",
        "code": "MECHA40",
        "category_id": "brake-system",
        "gradient_start": "#F15A22",
        "gradient_end": "#D44A15",
    },
    {
        "id": "offer-tyre",
        "title": "Tyre Week Special",
        "subtitle": "Free doorstep fitting on all premium bike and car tyres",
        "code": "TYRE20",
        "category_id": "tyres",
        "gradient_start": "#4285F4",
        "gradient_end": "#1565C0",
    },
    {
        "id": "offer-oil",
        "title": "Engine Care Season",
        "subtitle": "Synthetic oils and lubricants starting at ₹349",
        "code": "OIL25",
        "category_id": "oils",
        "gradient_start": "#10B981",
        "gradient_end": "#065F46",
    },
]

MARKETPLACE_COUPONS = [
    {
        "id": "coupon-mecha10",
        "code": "MECHA10",
        "title": "10% off up to ₹500",
        "description": "Valid on auto parts orders above ₹499",
        "type": "percent",
        "value": Decimal("10.00"),
        "max_discount": Decimal("500.00"),
        "min_order_value": Decimal("499.00"),
        "valid_from": datetime(2026, 1, 1, 0, 0, tzinfo=timezone.utc),
        "valid_until": datetime(2026, 12, 31, 23, 59, tzinfo=timezone.utc),
    },
    {
        "id": "coupon-mecha20",
        "code": "MECHA20",
        "title": "20% off up to ₹1,000",
        "description": "Valid on bulk spare parts orders above ₹1,499",
        "type": "percent",
        "value": Decimal("20.00"),
        "max_discount": Decimal("1000.00"),
        "min_order_value": Decimal("1499.00"),
        "valid_from": datetime(2026, 1, 1, 0, 0, tzinfo=timezone.utc),
        "valid_until": datetime(2026, 12, 31, 23, 59, tzinfo=timezone.utc),
    },
    {
        "id": "coupon-freeship",
        "code": "FREESHIP",
        "title": "Free Delivery",
        "description": "Free standard doorstep delivery on any order",
        "type": "freeDelivery",
        "value": Decimal("0.00"),
        "max_discount": Decimal("50.00"),
        "min_order_value": Decimal("0.00"),
        "valid_from": datetime(2026, 1, 1, 0, 0, tzinfo=timezone.utc),
        "valid_until": datetime(2026, 12, 31, 23, 59, tzinfo=timezone.utc),
    },
]

MARKETPLACE_PRODUCTS = [
    # 1. Engine Parts
    {
        "id": "p-chain-kit",
        "brand_id": "rolon",
        "category_id": "engine-parts",
        "name": "Rolon Heavy Duty Chain Sprocket Kit",
        "price": Decimal("899.00"),
        "mrp": Decimal("1199.00"),
        "rating": Decimal("4.40"),
        "rating_count": 340,
        "stock": 35,
        "image_url": "assets/chain kit.png",
        "icon": "settings_rounded",
        "description": "Heavy-duty Rolon chain sprocket kit with pre-greased O-ring chain for smooth and durable power transmission.",
        "warranty": "1 Year Brand Warranty",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 85,
        "age_days": 45,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Type", "Chain Sprocket Kit", 0),
            ("Pitch", "428", 1),
            ("Links", "110", 2),
            ("Material", "High-Carbon Steel", 3),
        ],
        "vehicles": ["bike"],
        "compat": ["Pulsar 150", "Discover 125", "Honda CB Shine"],
        "reviews": [
            ("Karthik R.", Decimal("5.00"), "Perfect fit on my Pulsar 150. Vibration reduced considerably.", date(2026, 9, 3)),
        ],
    },
    {
        "id": "p-spark-plug",
        "brand_id": "ngk",
        "category_id": "engine-parts",
        "name": "NGK Iridium IX High Performance Spark Plug",
        "price": Decimal("289.00"),
        "mrp": Decimal("399.00"),
        "rating": Decimal("4.80"),
        "rating_count": 512,
        "stock": 120,
        "image_url": "assets/spark plugs.png",
        "icon": "bolt_rounded",
        "description": "Laser welded Iridium tip ensures high durability and a consistently stable spark for improved acceleration and fuel economy.",
        "warranty": "6 Months Replacement Warranty",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 92,
        "age_days": 30,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Electrode", "0.6mm Iridium Tip", 0),
            ("Thread Diameter", "14mm", 1),
            ("Heat Range", "7", 2),
        ],
        "vehicles": ["bike", "car"],
        "compat": ["Royal Enfield Classic 350", "KTM Duke 200", "Maruti Swift"],
        "reviews": [
            ("Rohit Sen", Decimal("5.00"), "Cold starts are instantaneous now on my Classic 350.", date(2026, 9, 5)),
        ],
    },
    {
        "id": "p-clutch-lever",
        "brand_id": "tvs",
        "category_id": "engine-parts",
        "name": "TVS Genuine CNC Alloy Clutch Lever",
        "price": Decimal("189.00"),
        "mrp": Decimal("249.00"),
        "rating": Decimal("4.20"),
        "rating_count": 88,
        "stock": 50,
        "image_url": "assets/clutch lever.png",
        "icon": "settings_rounded",
        "description": "Ergonomic cast aluminum clutch lever providing comfortable finger grip and smooth cable pull.",
        "warranty": "6 Months Warranty",
        "delivery_estimate": "Delivery in 3-4 days",
        "popularity": 60,
        "age_days": 60,
        "is_featured": False,
        "is_best_seller": False,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": False,
        "specs": [
            ("Material", "Cast Aluminum Alloy", 0),
            ("Finish", "Matte Black Anodized", 1),
        ],
        "vehicles": ["bike"],
        "compat": ["TVS Apache RTR 160", "TVS Raider 125", "TVS Ronin"],
        "reviews": [
            ("Vimal K.", Decimal("4.00"), "Good build quality, exact OEM replacement.", date(2026, 8, 20)),
        ],
    },
    # 2. Brake System
    {
        "id": "p-brake-pad",
        "brand_id": "bosch",
        "category_id": "brake-system",
        "name": "Bosch Front Disc Brake Pads Set",
        "price": Decimal("449.00"),
        "mrp": Decimal("599.00"),
        "rating": Decimal("4.60"),
        "rating_count": 420,
        "stock": 45,
        "image_url": "assets/break pads.png",
        "icon": "stop_circle_rounded",
        "description": "Asbestos-free organic friction material delivering silent, progressive braking and minimal rotor wear.",
        "warranty": "6 Months Warranty",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 88,
        "age_days": 20,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Friction Material", "Ceramic / Semi-Metallic", 0),
            ("Position", "Front Axle", 1),
            ("Wear Indicator", "Acoustic", 2),
        ],
        "vehicles": ["car", "suv"],
        "compat": ["Maruti Swift", "Hyundai i20", "Honda City", "Tata Nexon"],
        "reviews": [
            ("Sandeep V.", Decimal("5.00"), "No squeaking sounds at all, very sharp bite.", date(2026, 9, 1)),
        ],
    },
    {
        "id": "p-brake-shoe",
        "brand_id": "tvs",
        "category_id": "brake-system",
        "name": "TVS Heavy Duty Rear Drum Brake Shoe",
        "price": Decimal("219.00"),
        "mrp": Decimal("299.00"),
        "rating": Decimal("4.30"),
        "rating_count": 175,
        "stock": 65,
        "image_url": "assets/break pads.png",
        "icon": "disc_full_rounded",
        "description": "High-durability drum brake shoes with heat-resistant lining for maximum stopping power.",
        "warranty": "6 Months Warranty",
        "delivery_estimate": "Delivery in 3-5 days",
        "popularity": 70,
        "age_days": 50,
        "is_featured": False,
        "is_best_seller": False,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Diameter", "130mm", 0),
            ("Position", "Rear Drum", 1),
        ],
        "vehicles": ["bike"],
        "compat": ["TVS Jupiter", "Honda Activa", "Hero Splendor"],
        "reviews": [
            ("Dinesh M.", Decimal("4.00"), "Easy to replace on my scooter. Works well.", date(2026, 8, 29)),
        ],
    },
    # 3. Oils & Fluids
    {
        "id": "p-engine-oil-10w40",
        "brand_id": "castrol",
        "category_id": "oils",
        "name": "Castrol Power1 4T 10W-40 Synthetic Engine Oil 1L",
        "price": Decimal("389.00"),
        "mrp": Decimal("499.00"),
        "rating": Decimal("4.90"),
        "rating_count": 890,
        "stock": 80,
        "image_url": "assets/engine oil.png",
        "icon": "oil_barrel_rounded",
        "description": "Formulated with Power Release Technology that optimizes friction and delivers superior acceleration at the touch of the throttle.",
        "warranty": "Genuine Sealed Pack Guarantee",
        "delivery_estimate": "Delivery in 1-2 days",
        "popularity": 96,
        "age_days": 15,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": True,
        "is_flash_deal": True,
        "is_recommended": True,
        "specs": [
            ("Viscosity", "10W-40", 0),
            ("Volume", "1 Litre", 1),
            ("API Rating", "API SN / JASO MA2", 2),
            ("Type", "Part-Synthetic", 3),
        ],
        "vehicles": ["bike"],
        "compat": ["Bajaj Pulsar", "Yamaha FZ", "Royal Enfield Hunter", "TVS Apache"],
        "reviews": [
            ("Akash Deep", Decimal("5.00"), "Engine runs noticeable cooler and gears shift effortlessly.", date(2026, 9, 6)),
        ],
    },
    {
        "id": "p-engine-oil-5w30",
        "brand_id": "motul",
        "category_id": "oils",
        "name": "Motul 8100 X-cess 5W-30 Full Synthetic Car Oil 3.5L",
        "price": Decimal("2499.00"),
        "mrp": Decimal("3200.00"),
        "rating": Decimal("4.85"),
        "rating_count": 310,
        "stock": 25,
        "image_url": "assets/engine oil.png",
        "icon": "oil_barrel_rounded",
        "description": "100% Synthetic high-performance lubricant engineered for modern gasoline and diesel engines requiring API SP / ACEA A3/B4.",
        "warranty": "Genuine Sealed Pack Guarantee",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 90,
        "age_days": 25,
        "is_featured": True,
        "is_best_seller": False,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Viscosity", "5W-30", 0),
            ("Volume", "3.5 Litres", 1),
            ("API Rating", "API SP / ACEA A3/B4", 2),
            ("Type", "100% Synthetic", 3),
        ],
        "vehicles": ["car", "suv"],
        "compat": ["Hyundai Creta", "Maruti Brezza", "Kia Seltos", "Honda City"],
        "reviews": [
            ("Varun Nair", Decimal("5.00"), "Best oil for turbocharged petrol cars. Very smooth idle.", date(2026, 9, 2)),
        ],
    },
    {
        "id": "p-brake-fluid",
        "brand_id": "bosch",
        "category_id": "oils",
        "name": "Bosch DOT 4 High Performance Brake Fluid 500ml",
        "price": Decimal("179.00"),
        "mrp": Decimal("229.00"),
        "rating": Decimal("4.70"),
        "rating_count": 230,
        "stock": 90,
        "image_url": "assets/engine oil.png",
        "icon": "oil_barrel_rounded",
        "description": "High wet boiling point (>165°C) prevents vapor lock and ensures firm brake lever and pedal feel even under aggressive driving.",
        "warranty": "Sealed Bottle Guarantee",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 75,
        "age_days": 40,
        "is_featured": False,
        "is_best_seller": False,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Specification", "DOT 4", 0),
            ("Dry Boiling Point", ">260°C", 1),
            ("Volume", "500 ml", 2),
        ],
        "vehicles": ["bike", "car", "suv"],
        "compat": ["Universal Hydraulic Brake Systems"],
        "reviews": [
            ("Pawan G.", Decimal("5.00"), "Restored crisp braking on my bike after flush.", date(2026, 8, 15)),
        ],
    },
    # 4. Tyres & Tubes
    {
        "id": "p-tyre-rear",
        "brand_id": "mrf",
        "category_id": "tyres",
        "name": "MRF Zapper C 100/90-17 Tubeless Rear Bike Tyre",
        "price": Decimal("1849.00"),
        "mrp": Decimal("2300.00"),
        "rating": Decimal("4.75"),
        "rating_count": 640,
        "stock": 20,
        "image_url": "assets/bike tyre.jpg",
        "icon": "speed_rounded",
        "description": "Deep directional tread pattern provides outstanding wet and dry cornering grip with extended compound tread life.",
        "warranty": "5 Years Manufacturer Warranty",
        "delivery_estimate": "Delivery in 2-4 days",
        "popularity": 94,
        "age_days": 20,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Size", "100/90-17", 0),
            ("Type", "Tubeless", 1),
            ("Position", "Rear", 2),
            ("Speed Rating", "P (up to 150 km/h)", 3),
        ],
        "vehicles": ["bike"],
        "compat": ["Bajaj Pulsar 150/180", "TVS Apache RTR", "Yamaha FZ"],
        "reviews": [
            ("Harish K.", Decimal("5.00"), "Excellent road grip in rainy Bengaluru traffic.", date(2026, 9, 4)),
        ],
    },
    {
        "id": "p-tyre-car",
        "brand_id": "ceat",
        "category_id": "tyres",
        "name": "CEAT SecuraDrive 185/65 R15 Tubeless Car Tyre",
        "price": Decimal("4199.00"),
        "mrp": Decimal("5200.00"),
        "rating": Decimal("4.60"),
        "rating_count": 280,
        "stock": 16,
        "image_url": "assets/bike tyre.jpg",
        "icon": "speed_rounded",
        "description": "High polymer blend with wide longitudinal grooves for silent high-speed cruising and aquaplaning resistance.",
        "warranty": "5 Years Warranty (2.5 Years Unconditional)",
        "delivery_estimate": "Delivery in 3-5 days",
        "popularity": 82,
        "age_days": 35,
        "is_featured": False,
        "is_best_seller": True,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Size", "185/65 R15", 0),
            ("Rim Diameter", "15 Inch", 1),
            ("Load Index", "88H", 2),
        ],
        "vehicles": ["car"],
        "compat": ["Maruti Swift", "Maruti Baleno", "Hyundai i20", "Honda Amaze"],
        "reviews": [
            ("Vijay Anand", Decimal("5.00"), "Cabin road noise dropped dramatically. Very plush ride.", date(2026, 8, 27)),
        ],
    },
    # 5. Batteries
    {
        "id": "p-battery-bike",
        "brand_id": "exide",
        "category_id": "batteries",
        "name": "Exide Xplore 12V 5Ah Maintenance-Free Bike Battery",
        "price": Decimal("1299.00"),
        "mrp": Decimal("1650.00"),
        "rating": Decimal("4.80"),
        "rating_count": 780,
        "stock": 25,
        "image_url": "assets/battery.png",
        "icon": "battery_charging_full_rounded",
        "description": "Advanced AGM VRLA technology ensures zero spill risk, high cranking amps, and zero maintenance throughout its lifespan.",
        "warranty": "48 Months (24 Free + 24 Pro-rata)",
        "delivery_estimate": "Delivery in 1-2 days",
        "popularity": 95,
        "age_days": 10,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Voltage", "12V", 0),
            ("Capacity", "5Ah (10HR)", 1),
            ("Technology", "VRLA / AGM", 2),
        ],
        "vehicles": ["bike"],
        "compat": ["Honda Activa", "Hero Maestro", "Suzuki Access 125", "TVS Jupiter"],
        "reviews": [
            ("Nitin S.", Decimal("5.00"), "Self-start works on first button press. Great doorstep delivery.", date(2026, 9, 6)),
        ],
    },
    {
        "id": "p-battery-car",
        "brand_id": "amaron",
        "category_id": "batteries",
        "name": "Amaron Flo 12V 35Ah Maintenance-Free Car Battery",
        "price": Decimal("3899.00"),
        "mrp": Decimal("4800.00"),
        "rating": Decimal("4.90"),
        "rating_count": 520,
        "stock": 14,
        "image_url": "assets/battery.png",
        "icon": "battery_charging_full_rounded",
        "description": "Patented Silven-X alloy plates provide extreme heat tolerance and long life in harsh stop-and-go city traffic.",
        "warranty": "55 Months (30 Free + 25 Pro-rata)",
        "delivery_estimate": "Delivery in 1-2 days",
        "popularity": 93,
        "age_days": 18,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Voltage", "12V", 0),
            ("Capacity", "35Ah", 1),
            ("Model Code", "AAM-FL-00042B20L", 2),
        ],
        "vehicles": ["car"],
        "compat": ["Maruti Alto", "Maruti WagonR", "Hyundai Santro", "Tata Tiago"],
        "reviews": [
            ("Abhishek M.", Decimal("5.00"), "Old battery was 5 years old. Replaced with Amaron and starts instantly.", date(2026, 9, 3)),
        ],
    },
    # 6. Accessories
    {
        "id": "p-puncture-kit",
        "brand_id": "3m",
        "category_id": "accessories",
        "name": "3M Heavy Duty Emergency Tubeless Tyre Puncture Kit",
        "price": Decimal("299.00"),
        "mrp": Decimal("450.00"),
        "rating": Decimal("4.50"),
        "rating_count": 390,
        "stock": 150,
        "image_url": "assets/tool kit.png",
        "icon": "backpack_rounded",
        "description": "Complete roadside emergency puncture repair kit containing heavy-duty T-handle reamer, insertion needle, rubber strips, and vulcanizing fluid.",
        "warranty": "1 Year Manufacturer Guarantee",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 86,
        "age_days": 40,
        "is_featured": False,
        "is_best_seller": True,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Kit Contents", "Reamer, Needle, 5 Strips, Glue, Cutter", 0),
            ("Handle Type", "Ergonomic Zinc-Alloy T-Handle", 1),
        ],
        "vehicles": ["bike", "car", "suv"],
        "compat": ["All Tubeless Tyres"],
        "reviews": [
            ("Manoj K.", Decimal("5.00"), "Essential kit for every car glovebox.", date(2026, 8, 25)),
        ],
    },
    {
        "id": "p-tire-inflator",
        "brand_id": "bosch",
        "category_id": "accessories",
        "name": "Bosch EasyPump Portable 150 PSI Digital Tyre Inflator",
        "price": Decimal("2799.00"),
        "mrp": Decimal("3499.00"),
        "rating": Decimal("4.85"),
        "rating_count": 210,
        "stock": 25,
        "image_url": "assets/tool kit.png",
        "icon": "speed_rounded",
        "description": "Compact cordless tyre inflator with auto-stop target pressure shutoff, USB-C recharging, and integrated LED worklight.",
        "warranty": "1 Year Bosch India Warranty",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 91,
        "age_days": 22,
        "is_featured": True,
        "is_best_seller": False,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Max Pressure", "150 PSI / 10.3 Bar", 0),
            ("Battery", "3.6V 3.0Ah Li-Ion USB-C", 1),
            ("Weight", "430 grams", 2),
        ],
        "vehicles": ["bike", "car", "suv"],
        "compat": ["Presta, Schrader, Dunlop valves"],
        "reviews": [
            ("Siddharth P.", Decimal("5.00"), "Top notch German build quality. Filled my car tyres from 25 to 33 psi in 2 mins.", date(2026, 9, 5)),
        ],
    },
    {
        "id": "p-gps-tracker",
        "brand_id": "3m",
        "category_id": "accessories",
        "name": "MechaConnect 4G Waterproof Real-Time GPS Vehicle Tracker",
        "price": Decimal("1499.00"),
        "mrp": Decimal("2199.00"),
        "rating": Decimal("4.60"),
        "rating_count": 145,
        "stock": 40,
        "image_url": "assets/gps tracker.png",
        "icon": "backpack_rounded",
        "description": "Hidden anti-theft GPS tracker with live engine immobilization, geofencing alarms, and battery backup.",
        "warranty": "1 Year Brand Warranty",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 79,
        "age_days": 35,
        "is_featured": False,
        "is_best_seller": False,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Network", "4G LTE + 2G Fallback", 0),
            ("Accuracy", "< 5 meters", 1),
            ("Waterproof Rating", "IP67", 2),
        ],
        "vehicles": ["bike", "car", "suv", "truck"],
        "compat": ["Universal 9V-36V Vehicle Wiring"],
        "reviews": [
            ("Kiran B.", Decimal("5.00"), "Gives great peace of mind when parking bike outdoors.", date(2026, 9, 2)),
        ],
    },
    # 7. Cleaning & Detailing
    {
        "id": "p-car-shampoo",
        "brand_id": "3m",
        "category_id": "cleaning",
        "name": "3M Auto Care Premium Car Wash Shampoo 1L",
        "price": Decimal("349.00"),
        "mrp": Decimal("499.00"),
        "rating": Decimal("4.70"),
        "rating_count": 480,
        "stock": 70,
        "image_url": "assets/tool kit.png",
        "icon": "cleaning_services_rounded",
        "description": "pH-neutral, high-foaming car wash concentrate that cuts road grime without stripping existing wax or ceramic coatings.",
        "warranty": "Original Bottle Guarantee",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 84,
        "age_days": 40,
        "is_featured": False,
        "is_best_seller": True,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": False,
        "specs": [
            ("Volume", "1 Litre", 0),
            ("Dilution Ratio", "1:100", 1),
            ("pH Level", "Neutral 7.0", 2),
        ],
        "vehicles": ["bike", "car", "suv"],
        "compat": ["All Automotive Paint & Glass Finishes"],
        "reviews": [
            ("Ramesh T.", Decimal("5.00"), "High foam and leaves a brilliant streak-free gloss.", date(2026, 8, 31)),
        ],
    },
    # 8. Lighting & Electrical
    {
        "id": "p-headlight-h4",
        "brand_id": "philips",
        "category_id": "lights",
        "name": "Philips X-tremeVision Pro150 H4 Headlight Halogen Bulb",
        "price": Decimal("649.00"),
        "mrp": Decimal("899.00"),
        "rating": Decimal("4.65"),
        "rating_count": 320,
        "stock": 45,
        "image_url": "assets/spark plugs.png",
        "icon": "lightbulb_rounded",
        "description": "Up to 150% brighter light throw and 70 meters longer beam distance for safer night driving on dark highway roads.",
        "warranty": "1 Year Replacement Guarantee",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 87,
        "age_days": 30,
        "is_featured": False,
        "is_best_seller": False,
        "is_trending": True,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Fitting", "H4 (12V 60/55W)", 0),
            ("Color Temperature", "3400 Kelvin", 1),
            ("Beam Throw", "+150% over standard", 2),
        ],
        "vehicles": ["bike", "car"],
        "compat": ["Maruti Swift", "Hyundai i10", "Honda Activa", "Royal Enfield"],
        "reviews": [
            ("Sameer J.", Decimal("5.00"), "Noticeably longer throw than stock factory bulbs.", date(2026, 9, 4)),
        ],
    },
    {
        "id": "p-wiper-blades",
        "brand_id": "bosch",
        "category_id": "accessories",
        "name": "Bosch Clear Advantage Frameless Wiper Blade Set (24\"/16\")",
        "price": Decimal("699.00"),
        "mrp": Decimal("950.00"),
        "rating": Decimal("4.75"),
        "rating_count": 410,
        "stock": 50,
        "image_url": "assets/wipers.png",
        "icon": "backpack_rounded",
        "description": "Aerodynamic wind spoiler and graphite-coated dual rubber edge for streak-free visibility during heavy monsoon showers.",
        "warranty": "6 Months Warranty",
        "delivery_estimate": "Delivery in 2-3 days",
        "popularity": 92,
        "age_days": 18,
        "is_featured": True,
        "is_best_seller": True,
        "is_trending": False,
        "is_flash_deal": False,
        "is_recommended": True,
        "specs": [
            ("Sizes", "Driver 24\" / Passenger 16\"", 0),
            ("Blade Type", "Beam / Frameless", 1),
            ("Connector", "Hook 9x3 / 9x4", 2),
        ],
        "vehicles": ["car", "suv"],
        "compat": ["Honda City", "Hyundai Creta", "Maruti Baleno", "Kia Seltos"],
        "reviews": [
            ("Prashant K.", Decimal("5.00"), "Replaced old chatter wipers. Silent and completely streak free.", date(2026, 9, 5)),
        ],
    },
]


# ---------------------------------------------------------------------------
# SEEDING EXECUTION ENGINE
# ---------------------------------------------------------------------------

async def seed_mechanics(session: AsyncSession) -> dict[str, int]:
    """Seed mechanic catalog and attribute tables."""
    counts = {}

    # 1. Categories
    for cat in MECHANIC_CATEGORIES:
        stmt = (
            pg_insert(MechanicCategory)
            .values(**cat)
            .on_conflict_do_update(
                index_elements=[MechanicCategory.id],
                set_={
                    "name": cat["name"],
                    "icon": cat["icon"],
                    "color": cat["color"],
                    "bg_color": cat["bg_color"],
                    "description": cat["description"],
                    "sort_order": cat["sort_order"],
                },
            )
        )
        await session.execute(stmt)
    counts["mechanic_categories"] = len(MECHANIC_CATEGORIES)

    # 2. Services
    for svc in MECHANIC_SERVICES:
        stmt = (
            pg_insert(MechanicService)
            .values(**svc)
            .on_conflict_do_update(
                index_elements=[MechanicService.id],
                set_={
                    "name": svc["name"],
                    "icon": svc["icon"],
                    "price": svc["price"],
                    "estimated_minutes": svc["estimated_minutes"],
                    "description": svc["description"],
                },
            )
        )
        await session.execute(stmt)
    counts["mechanic_services"] = len(MECHANIC_SERVICES)

    # 3. Mechanics & nested attributes
    total_skills = 0
    total_languages = 0
    total_hours = 0
    total_services_offered = 0

    for mech in MECHANICS:
        mech_data = {
            "id": mech["id"],
            "name": mech["name"],
            "rating": mech["rating"],
            "review_count": mech["review_count"],
            "experience_years": mech["experience_years"],
            "distance_km": mech["distance_km"],
            "eta_minutes": mech["eta_minutes"],
            "is_available": mech["is_available"],
            "price_starting": mech["price_starting"],
            "phone": mech["phone"],
            "about": mech["about"],
            "is_verified": mech["is_verified"],
        }
        stmt = (
            pg_insert(Mechanic)
            .values(**mech_data)
            .on_conflict_do_update(
                index_elements=[Mechanic.id],
                set_={
                    "name": mech_data["name"],
                    "rating": mech_data["rating"],
                    "review_count": mech_data["review_count"],
                    "experience_years": mech_data["experience_years"],
                    "distance_km": mech_data["distance_km"],
                    "eta_minutes": mech_data["eta_minutes"],
                    "is_available": mech_data["is_available"],
                    "price_starting": mech_data["price_starting"],
                    "phone": mech_data["phone"],
                    "about": mech_data["about"],
                    "is_verified": mech_data["is_verified"],
                },
            )
        )
        await session.execute(stmt)

        # Skills
        for sk in mech["skills"]:
            stmt_sk = (
                pg_insert(MechanicSkill)
                .values(mechanic_id=mech["id"], skill=sk)
                .on_conflict_do_nothing()
            )
            await session.execute(stmt_sk)
            total_skills += 1

        # Languages
        for lang in mech["languages"]:
            stmt_lang = (
                pg_insert(MechanicLanguage)
                .values(mechanic_id=mech["id"], language=lang)
                .on_conflict_do_nothing()
            )
            await session.execute(stmt_lang)
            total_languages += 1

        # Working hours
        for wh in mech["working_hours"]:
            stmt_wh = (
                pg_insert(MechanicWorkingHour)
                .values(mechanic_id=mech["id"], day=wh["day"], open=wh["open"], close=wh["close"])
                .on_conflict_do_update(
                    index_elements=[MechanicWorkingHour.mechanic_id, MechanicWorkingHour.day],
                    set_={"open": wh["open"], "close": wh["close"]},
                )
            )
            await session.execute(stmt_wh)
            total_hours += 1

        # Services offered
        for svc_id in mech["services"]:
            stmt_so = (
                pg_insert(MechanicServiceOffered)
                .values(mechanic_id=mech["id"], service_id=svc_id)
                .on_conflict_do_nothing()
            )
            await session.execute(stmt_so)
            total_services_offered += 1

    counts["mechanics"] = len(MECHANICS)
    counts["mechanic_skills"] = total_skills
    counts["mechanic_languages"] = total_languages
    counts["mechanic_working_hours"] = total_hours
    counts["mechanic_service_offered"] = total_services_offered

    # 4. Reviews
    for rev in MECHANIC_REVIEWS:
        stmt_rev = (
            pg_insert(MechanicReview)
            .values(**rev)
            .on_conflict_do_update(
                index_elements=[MechanicReview.id],
                set_={
                    "mechanic_id": rev["mechanic_id"],
                    "reviewer_name": rev["reviewer_name"],
                    "rating": rev["rating"],
                    "comment": rev["comment"],
                    "reviewed_at": rev["reviewed_at"],
                    "vehicle": rev["vehicle"],
                },
            )
        )
        await session.execute(stmt_rev)
    counts["mechanic_reviews"] = len(MECHANIC_REVIEWS)

    return counts


async def seed_fuel(session: AsyncSession) -> dict[str, int]:
    """Seed fuel delivery partners and partner stations."""
    counts = {}

    # 1. Partners
    for partner in FUEL_PARTNERS:
        stmt = (
            pg_insert(FuelPartner)
            .values(**partner)
            .on_conflict_do_update(
                index_elements=[FuelPartner.id],
                set_={
                    "name": partner["name"],
                    "phone": partner["phone"],
                    "rating": partner["rating"],
                    "rating_count": partner["rating_count"],
                    "distance_km": partner["distance_km"],
                    "eta_minutes": partner["eta_minutes"],
                    "is_available": partner["is_available"],
                    "vehicle_number": partner["vehicle_number"],
                    "vehicle_model": partner["vehicle_model"],
                },
            )
        )
        await session.execute(stmt)
    counts["fuel_partners"] = len(FUEL_PARTNERS)

    # 2. Stations
    for station in FUEL_STATIONS:
        stmt = (
            pg_insert(FuelStation)
            .values(**station)
            .on_conflict_do_update(
                index_elements=[FuelStation.id],
                set_={
                    "name": station["name"],
                    "brand": station["brand"],
                    "rating": station["rating"],
                    "rating_count": station["rating_count"],
                    "distance_km": station["distance_km"],
                    "eta_minutes": station["eta_minutes"],
                    "price_per_litre": station["price_per_litre"],
                    "availability": station["availability"],
                    "is_open": station["is_open"],
                    "address": station["address"],
                    "latitude": station["latitude"],
                    "longitude": station["longitude"],
                },
            )
        )
        await session.execute(stmt)
    counts["fuel_stations"] = len(FUEL_STATIONS)

    return counts


async def seed_marketplace(session: AsyncSession) -> dict[str, int]:
    """Seed marketplace categories, brands, offers, coupons, products, and child records."""
    counts = {}

    # 1. Categories
    for cat in MARKETPLACE_CATEGORIES:
        stmt = (
            pg_insert(Category)
            .values(**cat)
            .on_conflict_do_update(
                index_elements=[Category.id],
                set_={"name": cat["name"], "icon": cat["icon"], "sort_order": cat["sort_order"]},
            )
        )
        await session.execute(stmt)
    counts["categories"] = len(MARKETPLACE_CATEGORIES)

    # 2. Brands
    for brand in MARKETPLACE_BRANDS:
        stmt = (
            pg_insert(Brand)
            .values(**brand)
            .on_conflict_do_update(
                index_elements=[Brand.id],
                set_={"name": brand["name"]},
            )
        )
        await session.execute(stmt)
    counts["brands"] = len(MARKETPLACE_BRANDS)

    # 3. Offers
    for offer in MARKETPLACE_OFFERS:
        stmt = (
            pg_insert(Offer)
            .values(**offer)
            .on_conflict_do_update(
                index_elements=[Offer.id],
                set_={
                    "title": offer["title"],
                    "subtitle": offer["subtitle"],
                    "code": offer["code"],
                    "category_id": offer["category_id"],
                    "gradient_start": offer["gradient_start"],
                    "gradient_end": offer["gradient_end"],
                },
            )
        )
        await session.execute(stmt)
    counts["offers"] = len(MARKETPLACE_OFFERS)

    # 4. Coupons
    for coupon in MARKETPLACE_COUPONS:
        stmt = (
            pg_insert(Coupon)
            .values(**coupon)
            .on_conflict_do_update(
                index_elements=[Coupon.id],
                set_={
                    "code": coupon["code"],
                    "title": coupon["title"],
                    "description": coupon["description"],
                    "type": coupon["type"],
                    "value": coupon["value"],
                    "max_discount": coupon["max_discount"],
                    "min_order_value": coupon["min_order_value"],
                    "valid_from": coupon["valid_from"],
                    "valid_until": coupon["valid_until"],
                },
            )
        )
        await session.execute(stmt)
    counts["coupons"] = len(MARKETPLACE_COUPONS)

    # 5. Products & Child records
    total_specs = 0
    total_vehicle_types = 0
    total_compat = 0
    total_reviews = 0

    for prod in MARKETPLACE_PRODUCTS:
        prod_data = {
            "id": prod["id"],
            "brand_id": prod["brand_id"],
            "category_id": prod["category_id"],
            "name": prod["name"],
            "price": prod["price"],
            "mrp": prod["mrp"],
            "rating": prod["rating"],
            "rating_count": prod["rating_count"],
            "stock": prod["stock"],
            "image_url": prod["image_url"],
            "icon": prod["icon"],
            "description": prod["description"],
            "warranty": prod["warranty"],
            "delivery_estimate": prod["delivery_estimate"],
            "popularity": prod["popularity"],
            "age_days": prod["age_days"],
            "is_featured": prod["is_featured"],
            "is_best_seller": prod["is_best_seller"],
            "is_trending": prod["is_trending"],
            "is_flash_deal": prod["is_flash_deal"],
            "is_recommended": prod["is_recommended"],
        }
        stmt_prod = (
            pg_insert(Product)
            .values(**prod_data)
            .on_conflict_do_update(
                index_elements=[Product.id],
                set_={
                    "brand_id": prod_data["brand_id"],
                    "category_id": prod_data["category_id"],
                    "name": prod_data["name"],
                    "price": prod_data["price"],
                    "mrp": prod_data["mrp"],
                    "rating": prod_data["rating"],
                    "rating_count": prod_data["rating_count"],
                    "stock": prod_data["stock"],
                    "image_url": prod_data["image_url"],
                    "icon": prod_data["icon"],
                    "description": prod_data["description"],
                    "warranty": prod_data["warranty"],
                    "delivery_estimate": prod_data["delivery_estimate"],
                    "popularity": prod_data["popularity"],
                    "age_days": prod_data["age_days"],
                    "is_featured": prod_data["is_featured"],
                    "is_best_seller": prod_data["is_best_seller"],
                    "is_trending": prod_data["is_trending"],
                    "is_flash_deal": prod_data["is_flash_deal"],
                    "is_recommended": prod_data["is_recommended"],
                },
            )
        )
        await session.execute(stmt_prod)

        # Specifications (deterministic UUIDv5)
        for label, val, s_order in prod["specs"]:
            spec_uuid = str(uuid.uuid5(SEED_NAMESPACE, f"{prod['id']}:spec:{s_order}:{label}"))
            stmt_spec = (
                pg_insert(ProductSpecification)
                .values(
                    id=spec_uuid,
                    product_id=prod["id"],
                    label=label,
                    value=val,
                    sort_order=s_order,
                )
                .on_conflict_do_update(
                    index_elements=[ProductSpecification.id],
                    set_={"label": label, "value": val, "sort_order": s_order},
                )
            )
            await session.execute(stmt_spec)
            total_specs += 1

        # Vehicle Types
        for vt in prod["vehicles"]:
            stmt_vt = (
                pg_insert(ProductVehicleType)
                .values(product_id=prod["id"], vehicle_type=vt)
                .on_conflict_do_nothing()
            )
            await session.execute(stmt_vt)
            total_vehicle_types += 1

        # Compatibility
        for comp in prod["compat"]:
            stmt_comp = (
                pg_insert(ProductCompatibility)
                .values(product_id=prod["id"], compatible_with=comp)
                .on_conflict_do_nothing()
            )
            await session.execute(stmt_comp)
            total_compat += 1

        # Reviews (deterministic UUIDv5)
        for author, rating, comment, rev_date in prod["reviews"]:
            rev_uuid = str(uuid.uuid5(SEED_NAMESPACE, f"{prod['id']}:rev:{author}"))
            stmt_pr = (
                pg_insert(ProductReview)
                .values(
                    id=rev_uuid,
                    product_id=prod["id"],
                    author=author,
                    rating=rating,
                    comment=comment,
                    reviewed_at=rev_date,
                    is_verified_purchase=True,
                    helpful_count=5,
                )
                .on_conflict_do_update(
                    index_elements=[ProductReview.id],
                    set_={"author": author, "rating": rating, "comment": comment, "reviewed_at": rev_date},
                )
            )
            await session.execute(stmt_pr)
            total_reviews += 1

    counts["products"] = len(MARKETPLACE_PRODUCTS)
    counts["product_specifications"] = total_specs
    counts["product_vehicle_types"] = total_vehicle_types
    counts["product_compatibility"] = total_compat
    counts["product_reviews"] = total_reviews

    return counts


async def seed_pilot_catalog() -> int:
    """Execute catalog seeding within a single atomic async transaction."""
    if not settings.DATABASE_URL:
        print("[seed][ERROR] DATABASE_URL is not configured in backend/.env.")
        return 1

    masked_host = settings.DATABASE_URL.split("@")[-1]
    print("=" * 60)
    print("MECHA CONNECT — PILOT CATALOG SEEDER")
    print("=" * 60)
    print(f"Target Database Host: {masked_host}")
    print("Pilot Geography: Bengaluru, Karnataka (12.9716, 77.5946)")
    print("-" * 60)

    try:
        await configure_database()
        if db_module.engine is None:
            print("[seed][ERROR] Failed to initialize SQLAlchemy engine.")
            return 2

        async with AsyncSession(db_module.engine) as session:
            async with session.begin():
                print("[seed] Seeding mechanics catalog ...")
                mech_counts = await seed_mechanics(session)
                for table, count in mech_counts.items():
                    print(f"  -> {table}: {count} records upserted")

                print("[seed] Seeding fuel delivery catalog ...")
                fuel_counts = await seed_fuel(session)
                for table, count in fuel_counts.items():
                    print(f"  -> {table}: {count} records upserted")

                print("[seed] Seeding marketplace catalog ...")
                mkt_counts = await seed_marketplace(session)
                for table, count in mkt_counts.items():
                    print(f"  -> {table}: {count} records upserted")

                print("-" * 60)
                print("[seed] Validating data constraints ...")
                # Basic in-transaction sanity assertions
                assert mech_counts["mechanics"] >= 8, "Mechanic count below 8"
                assert fuel_counts["fuel_stations"] >= 6, "Fuel station count below 6"
                assert mkt_counts["products"] >= 18, "Product count below 18"
                assert mkt_counts["coupons"] >= 3, "Coupon count below 3"
                print("[seed] In-transaction validation: PASSED")
                print("[seed] Committing transaction ...")

        print("=" * 60)
        print("SUCCESS: Pilot catalog successfully seeded and committed.")
        print("=" * 60)
        return 0

    except Exception as exc:
        print("=" * 60)
        print(f"[seed][ERROR] Seeding failed: {type(exc).__name__}: {exc}")
        print("[seed][ROLLBACK] Transaction rolled back. Zero partial state saved.")
        print("=" * 60)
        import traceback
        traceback.print_exc()
        return 3

    finally:
        await dispose_engine()


if __name__ == "__main__":
    import asyncio
    sys.exit(asyncio.run(seed_pilot_catalog()))
