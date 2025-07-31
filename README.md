# Healthcare Data Cleaning Project
### Introduction

This case study demonstrates a comprehensive data cleaning process for a healthcare dataset using SQL. The project follows industry best practices to ensure data quality and consistency, making the dataset more reliable for analysis and reporting.

### Data Cleaning Best Practices Implemented

- Created a backup of the original dataset before making any changes

- Standardized data formats across multiple fields

- Removed duplicates to ensure each record is unique

- Checked for NULL values to maintain data completeness

- Validated data quality throughout the cleaning process

### Key Cleaning Operations Performed
- Name Standardization

    - Properly capitalized patient and doctor names (e.g., "john doe" → "John Doe")

    - Removed honorifics (Dr., Mr., Mrs., etc.) and suffixes (MD, PhD, etc.)

    - Ensured consistent name formatting across all records

- Hospital Name Normalization

    - Standardized hospital naming conventions

    - Corrected inconsistent comma placement (e.g., "Mayo, Clinic" → "Mayo Clinic")

    - Fixed "and" placement issues (e.g., "Jackson and Lane, Dillon" → "Dillon, Jackson, and Lane")

    - Moved business designators to end (e.g., "LLC Hospital" → "Hospital LLC")

    - Removed unnecessary commas and standardized "and sons" formatting

- Data Quality Assurance

    - Identified and removed duplicate records

    - Verified no NULL values existed in critical fields

    - Maintained data integrity throughout transformations

### Technical Approach

- The cleaning process used advanced SQL techniques including:

    - Regular expressions for pattern matching and replacement

    - String manipulation functions (SUBSTRING, TRIM, CONCAT)

    - Conditional logic with CASE statements

    - Temporary tables for deduplication

    - Transactional updates to ensure data safety

### Results

- The cleaned dataset now features:

    - Consistent naming conventions for patients, doctors, and hospitals

    - Properly formatted text fields

    - No duplicate records

    - Complete data with no NULL values in critical fields

This standardized dataset is now ready for analysis, reporting, and integration with other healthcare systems.
