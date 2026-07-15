import pandas as pd
import numpy as np
from pathlib import Path


# ------------------------------------------------------------
# File Paths
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent

INPUT_FILE = (
    BASE_DIR
    / "data"
    / "processed"
    / "cleaned_order_items.csv"
)

OUTPUT_FILE = (
    BASE_DIR
    / "data"
    / "processed"
    / "product_costs.csv"
)


# ------------------------------------------------------------
# Load Clean Transaction Data
# ------------------------------------------------------------

df = pd.read_csv(INPUT_FILE)


# ------------------------------------------------------------
# Create Product-Year Cost Table
#
# Grain:
# One row = One Product × Year
# ------------------------------------------------------------

product_costs = (
    df.groupby(
        [
            "product_id",
            "product_category_name",
            "purchase_year"
        ],
        as_index=False
    )
    .agg(
        reference_price=("price", "median")
    )
)


# ------------------------------------------------------------
# Generate Reproducible Base Cost Ratio
#
# Important:
# The same product receives the same base ratio across years.
# ------------------------------------------------------------

rng = np.random.default_rng(42)

unique_products = (
    product_costs[["product_id"]]
    .drop_duplicates()
    .copy()
)

unique_products["base_cost_ratio"] = rng.uniform(
    0.55,
    0.80,
    size=len(unique_products)
)

product_costs = product_costs.merge(
    unique_products,
    on="product_id",
    how="left",
    validate="many_to_one"
)


# ------------------------------------------------------------
# Define Synthetic Margin Compression
#
# These categories experienced strong real merchandise-revenue
# growth in the Olist dataset.
#
# Synthetic assumption:
# Selected categories experience higher product costs in 2018.
# ------------------------------------------------------------

margin_compression = {
    "beleza_saude": 0.08,
    "relogios_presentes": 0.10,
    "esporte_lazer": 0.07
}


# ------------------------------------------------------------
# Apply Year-Specific Cost Adjustments
# ------------------------------------------------------------

product_costs["cost_ratio_adjustment"] = 0.0

for category, adjustment in margin_compression.items():

    mask = (
        (product_costs["product_category_name"] == category)
        &
        (product_costs["purchase_year"] == 2018)
    )

    product_costs.loc[
        mask,
        "cost_ratio_adjustment"
    ] = adjustment


product_costs["final_cost_ratio"] = (
    product_costs["base_cost_ratio"]
    + product_costs["cost_ratio_adjustment"]
).clip(upper=0.95)


# ------------------------------------------------------------
# Calculate Synthetic Unit Product Cost
# ------------------------------------------------------------

product_costs["unit_product_cost"] = (
    product_costs["reference_price"]
    * product_costs["final_cost_ratio"]
).round(2)


# ------------------------------------------------------------
# Validate Product-Year Grain
# ------------------------------------------------------------

duplicate_product_years = (
    product_costs.duplicated(
        subset=["product_id", "purchase_year"]
    ).sum()
)


# ------------------------------------------------------------
# Export Dataset
# ------------------------------------------------------------

product_costs.to_csv(
    OUTPUT_FILE,
    index=False
)


# ------------------------------------------------------------
# Validation Output
# ------------------------------------------------------------

print("Product-year cost rows:", len(product_costs))

print(
    "Duplicate product-year keys:",
    duplicate_product_years
)

print("\nFinal cost ratio summary:")

print(
    product_costs["final_cost_ratio"].describe()
)

print("\n2018 compressed-category cost ratios:")

print(
    product_costs[
        (product_costs["purchase_year"] == 2018)
        &
        (
            product_costs["product_category_name"]
            .isin(margin_compression.keys())
        )
    ]
    .groupby("product_category_name")
    ["final_cost_ratio"]
    .mean()
    .round(3)
)