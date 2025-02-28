# Clarity Property Ledger

## Overview
Clarity Property Ledger is a decentralized smart contract system built using the Clarity programming language. It allows users to securely store, track, and manage property-related documentation on the blockchain. The contract enforces ownership verification, metadata tagging, and access control mechanisms to ensure transparency and security.

## Features
- **Decentralized Storage:** Property records are stored on-chain with immutable data integrity.
- **Ownership Verification:** Property records are owned by principals (users) and can be transferred securely.
- **Metadata Management:** Each record can store detailed property information and metadata tags.
- **Access Control:** Owners can define access permissions for other users.
- **Record Modification & Deletion:** Owners can update or remove records.
- **Security Measures:** Error handling and validation mechanisms prevent unauthorized modifications.

## Smart Contract Components

### Data Structures
- **`records-total (uint)`**: A counter to track the total number of property records.
- **`property-records (map)`**: Stores property details including:
  - `record-name (string-ascii 64)`: Name of the record.
  - `record-holder (principal)`: The owner of the record.
  - `content-bytes (uint)`: The size of the record's content.
  - `submission-height (uint)`: Block height at which the record was added.
  - `details-text (string-ascii 128)`: Additional information about the record.
  - `metadata-labels (list 10 (string-ascii 32))`: A list of metadata labels for classification.
- **`access-controls (map)`**: Manages permission access for different users.

### Error Codes
- `u301`: Record does not exist.
- `u302`: Record already exists.
- `u303`: Invalid name format.
- `u304`: Invalid content size.
- `u305`: Access denied.
- `u306`: Ownership violation.
- `u307`: View restriction applied.
- `u308`: Metadata validation error.

### Core Functions

#### Record Management
- **`(create-record name size details labels)`**
  - Adds a new property record with metadata.
  - Ensures input validation before storage.
  - Assigns ownership to the creator.
  - Returns the new record ID.

- **`(modify-record record-id updated-name updated-size updated-details updated-labels)`**
  - Allows record owners to update record information.
  - Ensures validation for all input fields.

- **`(remove-record record-id)`**
  - Deletes a record if the caller is the owner.

- **`(transfer-ownership record-id recipient)`**
  - Transfers ownership of a record to another principal.

#### Access Control
- **`(record-exists record-id)`**: Checks if a record exists.
- **`(is-owner-of record-id accessor)`**: Verifies if a user owns a record.
- **`(get-content-size record-id)`**: Retrieves the content size of a record.
- **`(is-valid-label label)`**: Ensures metadata labels meet format requirements.
- **`(validate-label-set labels)`**: Validates metadata label sets.

## Usage

### Deploying the Contract
1. Install the Clarity CLI or use the Stacks Blockchain API.
2. Deploy the contract using:
   ```sh
   clarinet contract publish clarity-property-ledger
