"""
Pharmacy Medication Data Governance & Lineage Platform
Phase 2 - Synthetic Source Data Generator

Creates five synthetic datasets:
1. pharmacy_claims_raw.csv
2. drug_reference_raw.csv
3. formulary_raw.csv
4. drug_pricing_raw.csv
5. pharmacy_master_raw.csv

The script intentionally injects controlled data-quality issues so the
governance solution can detect, classify, and remediate them later.

Dependencies:
    pip install pandas numpy

Run:
    python pharmacy_governance_data_generator.py

Outputs are written to:
    ./pharmacy_governance_data/
"""

from __future__ import annotations

import random
import string
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd


# ---------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------

SEED = 42

N_DRUGS = 1_000
N_PHARMACIES = 500
N_FORMULARY_RECORDS = 2_500
N_PRICING_RECORDS = 6_000
N_CLAIMS = 50_000

OUTPUT_DIR = Path("pharmacy_governance_data")

rng = np.random.default_rng(SEED)
random.seed(SEED)


# ---------------------------------------------------------------------
# REFERENCE VALUES
# ---------------------------------------------------------------------

GENERIC_NAMES = [
    "Semaglutide", "Metformin", "Atorvastatin", "Lisinopril", "Amlodipine",
    "Losartan", "Omeprazole", "Gabapentin", "Levothyroxine", "Sertraline",
    "Rosuvastatin", "Escitalopram", "Montelukast", "Duloxetine", "Clopidogrel",
    "Pantoprazole", "Hydrochlorothiazide", "Apixaban", "Empagliflozin",
    "Sitagliptin", "Insulin Glargine", "Insulin Lispro", "Fluoxetine",
    "Bupropion", "Carvedilol", "Metoprolol", "Furosemide", "Spironolactone",
    "Albuterol", "Doxycycline"
]

BRAND_NAMES = [
    "Ozempic", "Glucophage", "Lipitor", "Prinivil", "Norvasc", "Cozaar",
    "Prilosec", "Neurontin", "Synthroid", "Zoloft", "Crestor", "Lexapro",
    "Singulair", "Cymbalta", "Plavix", "Protonix", "Microzide", "Eliquis",
    "Jardiance", "Januvia", "Lantus", "Humalog", "Prozac", "Wellbutrin",
    "Coreg", "Lopressor", "Lasix", "Aldactone", "Ventolin", "Vibramycin"
]

MANUFACTURERS = [
    "Northstar Pharma", "Summit Therapeutics", "Atlas Medications",
    "Evergreen Labs", "BlueRiver Pharmaceuticals", "Redwood Pharma",
    "Crescent Therapeutics", "Pioneer Medical", "Meridian Pharma",
    "Beacon Life Sciences"
]

DOSAGE_FORMS = [
    "Tablet", "Capsule", "Injection", "Solution", "Suspension",
    "Inhaler", "Cream", "Patch"
]

ROUTES = [
    "Oral", "Subcutaneous", "Intravenous", "Inhalation",
    "Topical", "Transdermal"
]

DRUG_CLASSES = [
    "Antidiabetic", "Antihypertensive", "Lipid Lowering",
    "Antidepressant", "Anticoagulant", "Gastrointestinal",
    "Respiratory", "Antibiotic", "Neurologic", "Endocrine"
]

STRENGTH_UNITS = ["mg", "mcg", "mg/mL", "units/mL"]

PHARMACY_TYPES = [
    "Retail", "Specialty", "Mail Order", "Hospital", "Independent"
]

NETWORK_STATUSES = ["In Network", "Preferred", "Out of Network"]

CLAIM_STATUSES = ["Paid", "Rejected", "Reversed"]

PRICING_METHODS = ["AWP", "WAC", "MAC", "NADAC", "Contract Rate"]

COVERAGE_STATUSES = ["Covered", "Non-Preferred", "Excluded"]

VALID_STATES = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
    "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
    "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN",
    "TX","UT","VT","VA","WA","WV","WI","WY"
]

CITIES_BY_STATE = {
    "FL": ["Orlando", "Tampa", "Fort Walton Beach", "Miami", "Jacksonville"],
    "TX": ["Dallas", "Austin", "Houston", "San Antonio", "Irving"],
    "CA": ["San Diego", "Los Angeles", "Sacramento", "Chico", "Fresno"],
    "CO": ["Denver", "Boulder", "Colorado Springs", "Fort Collins"],
    "MO": ["St. Louis", "Columbia", "Kansas City", "Springfield"],
    "PA": ["Philadelphia", "Pittsburgh", "King of Prussia", "Harrisburg"],
    "NY": ["New York", "Buffalo", "Albany", "Rochester"],
    "NC": ["Charlotte", "Raleigh", "Durham", "Greensboro"]
}


# ---------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------

def ensure_output_dir() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def random_digits(length: int) -> str:
    return "".join(random.choices(string.digits, k=length))


def generate_ndc11() -> str:
    """
    Generate a synthetic 11-digit NDC-like identifier.
    This is for portfolio/demo use only.
    """
    return f"{rng.integers(10000, 99999):05d}{rng.integers(1000, 9999):04d}{rng.integers(10, 99):02d}"


def format_ndc_variant(ndc11: str, variant: str) -> str:
    if variant == "11_digit":
        return ndc11
    if variant == "hyphenated":
        return f"{ndc11[:5]}-{ndc11[5:9]}-{ndc11[9:]}"
    if variant == "spaced":
        return f"{ndc11[:5]} {ndc11[5:9]} {ndc11[9:]}"
    if variant == "10_digit":
        return ndc11[1:]
    if variant == "9_digit":
        return ndc11[2:]
    if variant == "invalid_alpha":
        return ndc11[:5] + "X" + ndc11[6:]
    if variant == "short":
        return ndc11[:7]
    return ndc11


def random_date(start: str, end: str, size: int = 1) -> pd.Series:
    start_ts = pd.Timestamp(start)
    end_ts = pd.Timestamp(end)
    days = (end_ts - start_ts).days
    offsets = rng.integers(0, days + 1, size=size)
    return pd.Series(pd.to_datetime(start_ts + pd.to_timedelta(offsets, unit="D")))


def sample_indices(n_rows: int, pct: float, exclude: Iterable[int] | None = None) -> np.ndarray:
    count = max(1, int(round(n_rows * pct)))
    pool = np.arange(n_rows)
    if exclude is not None:
        pool = np.setdiff1d(pool, np.array(list(exclude), dtype=int))
    count = min(count, len(pool))
    if count == 0:
        return np.array([], dtype=int)
    return rng.choice(pool, size=count, replace=False)


# ---------------------------------------------------------------------
# DATASET 1: DRUG REFERENCE
# ---------------------------------------------------------------------

def build_drug_reference() -> pd.DataFrame:
    ndcs = set()
    while len(ndcs) < N_DRUGS:
        ndcs.add(generate_ndc11())
    ndcs = list(ndcs)

    effective_dates = random_date("2022-01-01", "2026-01-01", N_DRUGS)

    rows = []
    for i, ndc in enumerate(ndcs, start=1):
        base_idx = (i - 1) % len(GENERIC_NAMES)
        generic = GENERIC_NAMES[base_idx]
        brand = BRAND_NAMES[base_idx]

        strength_value = rng.choice([5, 10, 20, 25, 40, 50, 100, 250, 500, 1000])
        dosage_form = rng.choice(DOSAGE_FORMS)
        route = rng.choice(ROUTES)

        rows.append({
            "Drug_Reference_ID": f"DRG{i:05d}",
            "NDC": ndc,
            "Drug_Name": brand,
            "Generic_Name": generic,
            "Brand_Name": brand,
            "Strength": strength_value,
            "Strength_Unit": rng.choice(STRENGTH_UNITS),
            "Dosage_Form": dosage_form,
            "Route": route,
            "Manufacturer": rng.choice(MANUFACTURERS),
            "Drug_Class": rng.choice(DRUG_CLASSES),
            "Active_Flag": rng.choice(["Y", "Y", "Y", "Y", "N"]),
            "Effective_Date": effective_dates[i - 1].date(),
            "End_Date": pd.NaT,
            "Source_System": "DrugReferenceHub"
        })

    df = pd.DataFrame(rows)

    # Close out inactive records.
    inactive_mask = df["Active_Flag"].eq("N")
    inactive_count = inactive_mask.sum()
    if inactive_count:
        df.loc[inactive_mask, "End_Date"] = (
            pd.to_datetime(df.loc[inactive_mask, "Effective_Date"])
            + pd.to_timedelta(rng.integers(180, 1000, size=inactive_count), unit="D")
        ).dt.date.values

    # Intentional defects
    # Duplicate active NDCs
    dup_idx = sample_indices(len(df), 0.008)
    duplicates = df.loc[dup_idx].copy()
    duplicates["Drug_Reference_ID"] = [
        f"DRG_DUP{i:04d}" for i in range(1, len(duplicates) + 1)
    ]
    duplicates["Active_Flag"] = "Y"
    duplicates["End_Date"] = pd.NaT

    # Missing generic names
    idx = sample_indices(len(df), 0.012)
    df.loc[idx, "Generic_Name"] = None

    # Conflicting brand/drug names
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "Drug_Name"] = "UNKNOWN BRAND " + df.loc[idx, "Drug_Reference_ID"]

    # Malformed NDCs
    idx = sample_indices(len(df), 0.008)
    for row_idx in idx:
        df.at[row_idx, "NDC"] = format_ndc_variant(str(df.at[row_idx, "NDC"]), "invalid_alpha")

    # Manufacturer naming variation
    idx = sample_indices(len(df), 0.015)
    df.loc[idx, "Manufacturer"] = df.loc[idx, "Manufacturer"].str.upper()

    # Inconsistent dosage form values
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "Dosage_Form"] = df.loc[idx, "Dosage_Form"].str.upper()

    df = pd.concat([df, duplicates], ignore_index=True)

    return df


# ---------------------------------------------------------------------
# DATASET 2: PHARMACY MASTER
# ---------------------------------------------------------------------

def build_pharmacy_master() -> pd.DataFrame:
    chain_names = [
        "Walgreens", "CVS Pharmacy", "HealthMart", "Community Pharmacy",
        "CarePoint", "Wellness Rx", "Family Drug", "MedCenter Pharmacy",
        "Regional Specialty Pharmacy", "Premier Pharmacy"
    ]

    rows = []
    for i in range(1, N_PHARMACIES + 1):
        state = rng.choice(list(CITIES_BY_STATE.keys()))
        city = rng.choice(CITIES_BY_STATE[state])
        chain = rng.choice(chain_names)
        store_no = rng.integers(100, 9999)

        rows.append({
            "Pharmacy_Source_ID": f"PHM{i:05d}",
            "NPI": random_digits(10),
            "NCPDP_ID": random_digits(7),
            "Pharmacy_Name": f"{chain} #{store_no}",
            "Pharmacy_Type": rng.choice(PHARMACY_TYPES),
            "Address": f"{rng.integers(100, 9999)} {rng.choice(['Main', 'Oak', 'Pine', 'Market', 'Lake', 'Park'])} St",
            "City": city,
            "State": state,
            "ZIP": random_digits(5),
            "Network_Status": rng.choice(NETWORK_STATUSES, p=[0.65, 0.25, 0.10]),
            "Effective_Date": random_date("2020-01-01", "2025-12-31", 1).iloc[0].date(),
            "End_Date": pd.NaT,
            "Source_System": rng.choice(["NetworkHub", "ProviderMaster"])
        })

    df = pd.DataFrame(rows)

    # Duplicate NPI
    idx = sample_indices(len(df), 0.010)
    dup_source = rng.choice(df.index, size=len(idx), replace=True)
    df.loc[idx, "NPI"] = df.loc[dup_source, "NPI"].values

    # Missing NPI
    idx = sample_indices(len(df), 0.012)
    df.loc[idx, "NPI"] = None

    # Invalid state code
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "State"] = rng.choice(["XX", "ZZ", "FLO", "TEX"], size=len(idx))

    # Malformed ZIP
    idx = sample_indices(len(df), 0.012)
    df.loc[idx, "ZIP"] = rng.choice(["ABCDE", "1234", "999999", ""], size=len(idx))

    # Name variants for likely same pharmacy
    idx = sample_indices(len(df), 0.015)
    for row_idx in idx:
        name = str(df.at[row_idx, "Pharmacy_Name"])
        if "Walgreens" in name:
            df.at[row_idx, "Pharmacy_Name"] = name.replace("Walgreens", "WALGREENS")
        elif "CVS Pharmacy" in name:
            df.at[row_idx, "Pharmacy_Name"] = name.replace("CVS Pharmacy", "CVS")
        else:
            df.at[row_idx, "Pharmacy_Name"] = name.upper()

    # Terminated pharmacy still marked as in network
    idx = sample_indices(len(df), 0.008)
    for row_idx in idx:
        eff = pd.Timestamp(df.at[row_idx, "Effective_Date"])
        df.at[row_idx, "End_Date"] = (eff + pd.Timedelta(days=int(rng.integers(365, 1200)))).date()
        df.at[row_idx, "Network_Status"] = "In Network"

    return df


# ---------------------------------------------------------------------
# DATASET 3: FORMULARY
# ---------------------------------------------------------------------

def build_formulary(drug_reference: pd.DataFrame) -> pd.DataFrame:
    valid_drugs = drug_reference[
        drug_reference["NDC"].astype(str).str.fullmatch(r"\d{11}", na=False)
    ].drop_duplicates("NDC")

    sampled = valid_drugs.sample(
        n=N_FORMULARY_RECORDS,
        replace=True,
        random_state=SEED
    ).reset_index(drop=True)

    rows = []
    plans = [f"PLAN{i:03d}" for i in range(1, 21)]

    for i, row in sampled.iterrows():
        effective = random_date("2024-01-01", "2026-06-01", 1).iloc[0]
        end_date = effective + pd.Timedelta(days=int(rng.integers(180, 730)))

        rows.append({
            "Formulary_Record_ID": f"FRM{i+1:06d}",
            "Plan_ID": rng.choice(plans),
            "NDC": row["NDC"],
            "Drug_Name": row["Drug_Name"],
            "Formulary_Tier": int(rng.choice([1, 2, 3, 4, 5])),
            "Coverage_Status": rng.choice(COVERAGE_STATUSES, p=[0.75, 0.18, 0.07]),
            "Prior_Authorization_Flag": rng.choice(["Y", "N"], p=[0.25, 0.75]),
            "Step_Therapy_Flag": rng.choice(["Y", "N"], p=[0.15, 0.85]),
            "Quantity_Limit_Flag": rng.choice(["Y", "N"], p=[0.20, 0.80]),
            "Effective_Date": effective.date(),
            "End_Date": end_date.date(),
            "Source_System": "FormularyManager"
        })

    df = pd.DataFrame(rows)

    # NDC not in master
    idx = sample_indices(len(df), 0.012)
    df.loc[idx, "NDC"] = [generate_ndc11() for _ in idx]

    # Invalid formulary tiers
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "Formulary_Tier"] = rng.choice([0, 6, 9], size=len(idx))

    # Missing coverage status
    idx = sample_indices(len(df), 0.008)
    df.loc[idx, "Coverage_Status"] = None

    # Conflicting drug name
    idx = sample_indices(len(df), 0.012)
    df.loc[idx, "Drug_Name"] = "FORMULARY NAME MISMATCH"

    # Duplicate formulary assignments
    idx = sample_indices(len(df), 0.008)
    duplicates = df.loc[idx].copy()
    duplicates["Formulary_Record_ID"] = [
        f"FRM_DUP{i:05d}" for i in range(1, len(duplicates) + 1)
    ]

    # Overlapping coverage periods
    idx = sample_indices(len(df), 0.010)
    overlaps = df.loc[idx].copy()
    overlaps["Formulary_Record_ID"] = [
        f"FRM_OVR{i:05d}" for i in range(1, len(overlaps) + 1)
    ]
    overlaps["Effective_Date"] = (
        pd.to_datetime(overlaps["Effective_Date"]) + pd.Timedelta(days=30)
    ).dt.date
    overlaps["End_Date"] = (
        pd.to_datetime(overlaps["End_Date"]) + pd.Timedelta(days=90)
    ).dt.date

    df = pd.concat([df, duplicates, overlaps], ignore_index=True)

    return df


# ---------------------------------------------------------------------
# DATASET 4: DRUG PRICING
# ---------------------------------------------------------------------

def build_drug_pricing(drug_reference: pd.DataFrame) -> pd.DataFrame:
    valid_drugs = drug_reference[
        drug_reference["NDC"].astype(str).str.fullmatch(r"\d{11}", na=False)
    ].drop_duplicates("NDC")

    ndc_choices = valid_drugs["NDC"].tolist()

    rows = []
    for i in range(1, N_PRICING_RECORDS + 1):
        ndc = rng.choice(ndc_choices)
        methodology = rng.choice(PRICING_METHODS)
        unit_price = round(float(rng.lognormal(mean=2.0, sigma=1.0)), 4)
        package_price = round(unit_price * float(rng.integers(10, 100)), 2)
        effective = random_date("2023-01-01", "2026-06-01", 1).iloc[0]
        end = effective + pd.Timedelta(days=int(rng.integers(90, 720)))

        rows.append({
            "Pricing_Record_ID": f"PRC{i:07d}",
            "NDC": ndc,
            "Pricing_Methodology": methodology,
            "Unit_Price": unit_price,
            "Package_Price": package_price,
            "Effective_Date": effective.date(),
            "End_Date": end.date(),
            "Source_System": rng.choice(["PricingFeedA", "PricingFeedB"]),
            "Last_Updated": random_date("2025-01-01", "2026-08-15", 1).iloc[0]
        })

    df = pd.DataFrame(rows)

    # Negative price
    idx = sample_indices(len(df), 0.006)
    df.loc[idx, "Unit_Price"] = -abs(df.loc[idx, "Unit_Price"])
    df.loc[idx, "Package_Price"] = -abs(df.loc[idx, "Package_Price"])

    # Missing price
    idx = sample_indices(len(df), 0.008)
    df.loc[idx, "Unit_Price"] = np.nan

    # Unknown NDC
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "NDC"] = [generate_ndc11() for _ in idx]

    # Unsupported pricing methodology
    idx = sample_indices(len(df), 0.006)
    df.loc[idx, "Pricing_Methodology"] = "UNKNOWN_METHOD"

    # Duplicate pricing records
    idx = sample_indices(len(df), 0.006)
    duplicates = df.loc[idx].copy()
    duplicates["Pricing_Record_ID"] = [
        f"PRC_DUP{i:05d}" for i in range(1, len(duplicates) + 1)
    ]

    # Overlapping/conflicting active price records
    idx = sample_indices(len(df), 0.010)
    overlaps = df.loc[idx].copy()
    overlaps["Pricing_Record_ID"] = [
        f"PRC_OVR{i:05d}" for i in range(1, len(overlaps) + 1)
    ]
    overlaps["Effective_Date"] = (
        pd.to_datetime(overlaps["Effective_Date"]) + pd.Timedelta(days=15)
    ).dt.date
    overlaps["End_Date"] = (
        pd.to_datetime(overlaps["End_Date"]) + pd.Timedelta(days=120)
    ).dt.date
    overlaps["Unit_Price"] = (overlaps["Unit_Price"].fillna(1) * 1.15).round(4)
    overlaps["Package_Price"] = (overlaps["Package_Price"] * 1.15).round(2)

    df = pd.concat([df, duplicates, overlaps], ignore_index=True)

    return df


# ---------------------------------------------------------------------
# DATASET 5: PHARMACY CLAIMS
# ---------------------------------------------------------------------

def build_pharmacy_claims(
    drug_reference: pd.DataFrame,
    pharmacy_master: pd.DataFrame
) -> pd.DataFrame:

    valid_drugs = drug_reference[
        drug_reference["NDC"].astype(str).str.fullmatch(r"\d{11}", na=False)
    ].drop_duplicates("NDC")

    valid_pharmacies = pharmacy_master[
        pharmacy_master["Pharmacy_Source_ID"].notna()
    ].drop_duplicates("Pharmacy_Source_ID")

    drug_lookup = valid_drugs[["NDC", "Drug_Name"]].reset_index(drop=True)
    pharmacy_ids = valid_pharmacies["Pharmacy_Source_ID"].tolist()

    claim_dates = random_date("2025-01-01", "2026-08-15", N_CLAIMS)
    members = [f"MBR{i:07d}" for i in range(1, 15_001)]

    rows = []

    for i in range(1, N_CLAIMS + 1):
        drug_row = drug_lookup.iloc[int(rng.integers(0, len(drug_lookup)))]
        ndc11 = str(drug_row["NDC"])

        ndc_variant = rng.choice(
            ["11_digit", "hyphenated", "spaced", "10_digit"],
            p=[0.83, 0.08, 0.04, 0.05]
        )

        quantity = int(rng.choice([30, 60, 90, 1, 5, 10, 20]))
        days_supply = int(rng.choice([30, 60, 90, 14, 7]))
        ingredient_cost = round(float(rng.lognormal(mean=4.0, sigma=1.0)), 2)
        dispensing_fee = round(float(rng.uniform(1.00, 15.00)), 2)
        member_pay = round(float(rng.uniform(0.00, 150.00)), 2)
        plan_pay = round(max(ingredient_cost + dispensing_fee - member_pay, 0.00), 2)
        paid_amount = round(member_pay + plan_pay, 2)

        rows.append({
            "Claim_ID": f"CLM{i:08d}",
            "Member_ID": rng.choice(members),
            "Claim_Date": claim_dates[i - 1].date(),
            "NDC": format_ndc_variant(ndc11, ndc_variant),
            "Drug_Name": drug_row["Drug_Name"],
            "Pharmacy_ID": rng.choice(pharmacy_ids),
            "Quantity": quantity,
            "Days_Supply": days_supply,
            "Ingredient_Cost": ingredient_cost,
            "Dispensing_Fee": dispensing_fee,
            "Member_Pay": member_pay,
            "Plan_Pay": plan_pay,
            "Paid_Amount": paid_amount,
            "Claim_Status": rng.choice(CLAIM_STATUSES, p=[0.90, 0.06, 0.04]),
            "Source_System": rng.choice(["PBM_A", "PBM_B", "PBM_C"], p=[0.55, 0.30, 0.15])
        })

    df = pd.DataFrame(rows)

    # Missing NDC
    idx = sample_indices(len(df), 0.008)
    df.loc[idx, "NDC"] = None

    # Invalid NDC
    idx = sample_indices(len(df), 0.010)
    for row_idx in idx:
        base = generate_ndc11()
        df.at[row_idx, "NDC"] = format_ndc_variant(base, rng.choice(["invalid_alpha", "short"]))

    # Unknown but syntactically valid NDC
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "NDC"] = [generate_ndc11() for _ in idx]

    # Drug-name conflicts
    idx = sample_indices(len(df), 0.010)
    df.loc[idx, "Drug_Name"] = "CLAIM DRUG NAME MISMATCH"

    # Missing pharmacy
    idx = sample_indices(len(df), 0.008)
    df.loc[idx, "Pharmacy_ID"] = None

    # Unknown pharmacy
    idx = sample_indices(len(df), 0.006)
    df.loc[idx, "Pharmacy_ID"] = [
        f"PHM_UNKNOWN_{i:04d}" for i in range(1, len(idx) + 1)
    ]

    # Negative paid amounts
    idx = sample_indices(len(df), 0.006)
    df.loc[idx, "Paid_Amount"] = -abs(df.loc[idx, "Paid_Amount"])

    # Paid claim with $0 paid amount
    idx = sample_indices(len(df), 0.006)
    df.loc[idx, "Claim_Status"] = "Paid"
    df.loc[idx, "Paid_Amount"] = 0.0

    # Invalid days supply
    idx = sample_indices(len(df), 0.008)
    df.loc[idx, "Days_Supply"] = rng.choice([0, -30, 400, 999], size=len(idx))

    # Invalid claim status
    idx = sample_indices(len(df), 0.004)
    df.loc[idx, "Claim_Status"] = "UNKNOWN"

    # Duplicate claims
    idx = sample_indices(len(df), 0.008)
    duplicates = df.loc[idx].copy()
    # Keep the same Claim_ID intentionally to make duplicate detection obvious.
    df = pd.concat([df, duplicates], ignore_index=True)

    return df


# ---------------------------------------------------------------------
# QUALITY MANIFEST
# ---------------------------------------------------------------------

def build_quality_manifest() -> pd.DataFrame:
    rules = [
        ("DQ001", "Medication", "NDC is missing", "Critical"),
        ("DQ002", "Medication", "NDC cannot be standardized to NDC-11", "Critical"),
        ("DQ003", "Medication", "NDC not found in medication master", "Critical"),
        ("DQ004", "Medication", "Duplicate active NDC", "Critical"),
        ("DQ005", "Medication", "Drug name conflicts with governed medication", "High"),
        ("DQ006", "Medication", "Missing generic name", "Medium"),
        ("DQ007", "Pricing", "No active pricing record", "High"),
        ("DQ008", "Pricing", "Multiple active prices", "High"),
        ("DQ009", "Pricing", "Price is zero or negative", "Critical"),
        ("DQ010", "Formulary", "NDC missing from drug master", "High"),
        ("DQ011", "Formulary", "Invalid formulary tier", "Medium"),
        ("DQ012", "Formulary", "Effective dates overlap", "High"),
        ("DQ013", "Claims", "Duplicate claim", "High"),
        ("DQ014", "Claims", "Paid amount is unexpectedly negative", "High"),
        ("DQ015", "Claims", "Pharmacy not found", "High"),
        ("DQ016", "Pharmacy", "Duplicate NPI", "Critical"),
        ("DQ017", "Pharmacy", "Missing NPI", "Medium"),
        ("DQ018", "Pharmacy", "Invalid state code", "Low"),
        ("DQ019", "Claims", "Paid claim has zero paid amount", "Medium"),
        ("DQ020", "Claims", "Days supply outside accepted range", "Medium"),
    ]

    return pd.DataFrame(
        rules,
        columns=["Rule_ID", "Domain", "Rule_Description", "Severity"]
    )


# ---------------------------------------------------------------------
# OUTPUT / SUMMARY
# ---------------------------------------------------------------------

def save_csv(df: pd.DataFrame, filename: str) -> None:
    path = OUTPUT_DIR / filename
    df.to_csv(path, index=False)
    print(f"Created: {path} | rows={len(df):,}")


def profile_dataset(name: str, df: pd.DataFrame) -> dict:
    return {
        "Dataset": name,
        "Rows": len(df),
        "Columns": len(df.columns),
        "Missing_Values": int(df.isna().sum().sum()),
        "Duplicate_Rows": int(df.duplicated().sum())
    }


def main() -> None:
    ensure_output_dir()

    print("=" * 72)
    print("PHARMACY DATA GOVERNANCE - SYNTHETIC DATA GENERATOR")
    print("=" * 72)

    print("\n1. Building drug reference...")
    drug_reference = build_drug_reference()

    print("2. Building pharmacy master...")
    pharmacy_master = build_pharmacy_master()

    print("3. Building formulary...")
    formulary = build_formulary(drug_reference)

    print("4. Building drug pricing...")
    drug_pricing = build_drug_pricing(drug_reference)

    print("5. Building pharmacy claims...")
    pharmacy_claims = build_pharmacy_claims(drug_reference, pharmacy_master)

    print("\nSaving datasets...")
    save_csv(pharmacy_claims, "pharmacy_claims_raw.csv")
    save_csv(drug_reference, "drug_reference_raw.csv")
    save_csv(formulary, "formulary_raw.csv")
    save_csv(drug_pricing, "drug_pricing_raw.csv")
    save_csv(pharmacy_master, "pharmacy_master_raw.csv")

    quality_manifest = build_quality_manifest()
    save_csv(quality_manifest, "data_quality_rules.csv")

    profiles = pd.DataFrame([
        profile_dataset("pharmacy_claims_raw", pharmacy_claims),
        profile_dataset("drug_reference_raw", drug_reference),
        profile_dataset("formulary_raw", formulary),
        profile_dataset("drug_pricing_raw", drug_pricing),
        profile_dataset("pharmacy_master_raw", pharmacy_master)
    ])

    save_csv(profiles, "dataset_profile_summary.csv")

    print("\n" + "=" * 72)
    print("GENERATION COMPLETE")
    print("=" * 72)
    print(profiles.to_string(index=False))
    print(f"\nOutput folder: {OUTPUT_DIR.resolve()}")
    print(
        "\nImportant: All data is synthetic and intended only for "
        "portfolio / demonstration purposes."
    )


if __name__ == "__main__":
    main()
