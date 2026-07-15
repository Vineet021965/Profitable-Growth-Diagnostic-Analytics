import pandas as pd
import numpy as np
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent

INPUT_FILE = (
    BASE_DIR / "data" / "processed" / "cleaned_order_items.csv"
)

OUTPUT_FILE = (
    BASE_DIR / "data" / "processed" / "customer_acquisition.csv"
)


# Load transaction data

df = pd.read_csv(
    INPUT_FILE,
    parse_dates=["order_purchase_timestamp"]
)


# Create customer-level dataset

customers = (
    df.groupby("customer_unique_id", as_index=False)
    .agg(
        acquisition_date=("order_purchase_timestamp", "min")
    )
)

customers["acquisition_year"] = (
    customers["acquisition_date"].dt.year
)


# Reproducible random generator

rng = np.random.default_rng(42)


# Assign acquisition channels

channels = [
    "Organic",
    "Referral",
    "Paid Search",
    "Paid Social"
]


def assign_channels(year, size):

    if year == 2018:

        probabilities = [
            0.20,  # Organic
            0.15,  # Referral
            0.30,  # Paid Search
            0.35   # Paid Social
        ]

    else:

        probabilities = [
            0.35,
            0.25,
            0.25,
            0.15
        ]

    return rng.choice(
        channels,
        size=size,
        p=probabilities
    )


customers["acquisition_channel"] = None

for year in customers["acquisition_year"].unique():

    mask = customers["acquisition_year"] == year

    customers.loc[
        mask,
        "acquisition_channel"
    ] = assign_channels(
        year,
        mask.sum()
    )


# Assign synthetic CAC

cac_ranges = {
    "Organic": (1, 3),
    "Referral": (2, 5),
    "Paid Search": (8, 15),
    "Paid Social": (12, 22)
}


customers["cac"] = customers[
    "acquisition_channel"
].apply(
    lambda channel: round(
        rng.uniform(*cac_ranges[channel]),
        2
    )
)


# Additional 2018 paid-channel cost inflation

paid_2018_mask = (
    (customers["acquisition_year"] == 2018)
    &
    (
        customers["acquisition_channel"]
        .isin(["Paid Search", "Paid Social"])
    )
)

customers.loc[paid_2018_mask, "cac"] *= 1.15

customers["cac"] = customers["cac"].round(2)


# Validate

print("Customer rows:", len(customers))

print(
    "Duplicate customers:",
    customers["customer_unique_id"].duplicated().sum()
)

print("\nChannel distribution by acquisition year:")

print(
    pd.crosstab(
        customers["acquisition_year"],
        customers["acquisition_channel"],
        normalize="index"
    ).round(3)
)

print("\nAverage CAC by year:")

print(
    customers.groupby("acquisition_year")["cac"]
    .mean()
    .round(2)
)


# Export

customers.to_csv(
    OUTPUT_FILE,
    index=False
)