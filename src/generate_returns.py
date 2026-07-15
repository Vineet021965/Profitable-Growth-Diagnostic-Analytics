import pandas as pd
import numpy as np
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

INPUT_FILE = (
    BASE_DIR / "data" / "processed" / "cleaned_order_items.csv"
)

OUTPUT_FILE = (
    BASE_DIR / "data" / "processed" / "returns.csv"
)

df = pd.read_csv(INPUT_FILE)

rng = np.random.default_rng(42)


# Base return probability

df["return_probability"] = 0.04


# Higher return probability for selected categories

category_adjustments = {
    "beleza_saude": 0.04,
    "relogios_presentes": 0.05,
    "esporte_lazer": 0.03
}

for category, adjustment in category_adjustments.items():

    mask = (
        df["product_category_name"] == category
    )

    df.loc[
        mask,
        "return_probability"
    ] += adjustment


# Additional return deterioration in 2018

deterioration_mask = (
    (df["purchase_year"] == 2018)
    &
    (
        df["product_category_name"]
        .isin(category_adjustments.keys())
    )
)

df.loc[
    deterioration_mask,
    "return_probability"
] += 0.04


# Generate returns

df["is_returned"] = (
    rng.random(len(df))
    <
    df["return_probability"]
).astype(int)


# Refund loss assumption:
# Returned item loses 85% of merchandise value.

df["refund_loss"] = (
    df["price"]
    * 0.20
    * df["is_returned"]
).round(2)


# Reverse logistics cost

df["reverse_logistics_cost"] = (
    df["freight_value"]
    * 1.25
    * df["is_returned"]
).round(2)


returns = df[
    [
        "order_id",
        "order_item_id",
        "is_returned",
        "refund_loss",
        "reverse_logistics_cost"
    ]
].copy()


print("Return rows:", len(returns))

print(
    "Duplicate composite keys:",
    returns.duplicated(
        subset=["order_id", "order_item_id"]
    ).sum()
)

print(
    "Overall return rate:",
    round(returns["is_returned"].mean() * 100, 2),
    "%"
)

print(
    "Total refund loss:",
    round(returns["refund_loss"].sum(), 2)
)

print(
    "Total reverse logistics cost:",
    round(returns["reverse_logistics_cost"].sum(), 2)
)


returns.to_csv(
    OUTPUT_FILE,
    index=False
)