;; Property Records Distributed Ledger System
;; Securely store and manage property-related documentation on-chain

;; Main Storage Counter
(define-data-var records-total uint u0)

;; Core Data Structures
(define-map property-records
  { record-id: uint }
  {
    record-name: (string-ascii 64),
    record-holder: principal,
    content-bytes: uint,
    submission-height: uint,
    details-text: (string-ascii 128),
    metadata-labels: (list 10 (string-ascii 32))
  }
)

(define-map access-controls
  { record-id: uint, accessor: principal }
  { permission-granted: bool }
)

;; System Response Codes
(define-constant record-missing-code (err u301))
(define-constant record-exists-code (err u302))
(define-constant name-validation-code (err u303))
(define-constant size-validation-code (err u304))
(define-constant access-violation-code (err u305))
(define-constant ownership-violation-code (err u306))
(define-constant privileged-action-code (err u300))
(define-constant view-restriction-code (err u307))
(define-constant metadata-validation-code (err u308))

;; System Control
(define-constant system-controller tx-sender)

;; ===== Access & Validation Utilities =====

;; Verifies record existence
(define-private (record-exists (record-id uint))
  (is-some (map-get? property-records { record-id: record-id }))
)

;; Confirms if caller has ownership rights
(define-private (is-owner-of (record-id uint) (accessor principal))
  (match (map-get? property-records { record-id: record-id })
    record-info (is-eq (get record-holder record-info) accessor)
    false
  )
)

;; Retrieves content size for a record
(define-private (get-content-size (record-id uint))
  (default-to u0
    (get content-bytes
      (map-get? property-records { record-id: record-id })
    )
  )
)

;; Validates metadata label format
(define-private (is-valid-label (label (string-ascii 32)))
  (and
    (> (len label) u0)
    (< (len label) u33)
  )
)

;; Ensures all metadata labels are properly formatted
(define-private (validate-label-set (labels (list 10 (string-ascii 32))))
  (and
    (> (len labels) u0)
    (<= (len labels) u10)
    (is-eq (len (filter is-valid-label labels)) (len labels))
  )
)

;; ===== Modification Functions =====

;; Creates a new property record with complete metadata
(define-public (create-record 
  (name (string-ascii 64)) 
  (size uint) 
  (details (string-ascii 128)) 
  (labels (list 10 (string-ascii 32)))
)
  (let
    (
      (new-id (+ (var-get records-total) u1))
    )
    ;; Input validation
    (asserts! (> (len name) u0) name-validation-code)
    (asserts! (< (len name) u65) name-validation-code)
    (asserts! (> size u0) size-validation-code)
    (asserts! (< size u1000000000) size-validation-code)
    (asserts! (> (len details) u0) name-validation-code)
    (asserts! (< (len details) u129) name-validation-code)
    (asserts! (validate-label-set labels) metadata-validation-code)

    ;; Create record entry
    (map-insert property-records
      { record-id: new-id }
      {
        record-name: name,
        record-holder: tx-sender,
        content-bytes: size,
        submission-height: block-height,
        details-text: details,
        metadata-labels: labels
      }
    )

    ;; Set initial access for creator
    (map-insert access-controls
      { record-id: new-id, accessor: tx-sender }
      { permission-granted: true }
    )
    
    ;; Update counter
    (var-set records-total new-id)
    (ok new-id)
  )
)

;; Modifies an existing record's information
(define-public (modify-record 
  (record-id uint) 
  (updated-name (string-ascii 64)) 
  (updated-size uint) 
  (updated-details (string-ascii 128)) 
  (updated-labels (list 10 (string-ascii 32)))
)
  (let
    (
      (record-info (unwrap! (map-get? property-records { record-id: record-id }) record-missing-code))
    )
    ;; Validate ownership and input
    (asserts! (record-exists record-id) record-missing-code)
    (asserts! (is-eq (get record-holder record-info) tx-sender) ownership-violation-code)
    (asserts! (> (len updated-name) u0) name-validation-code)
    (asserts! (< (len updated-name) u65) name-validation-code)
    (asserts! (> updated-size u0) size-validation-code)
    (asserts! (< updated-size u1000000000) size-validation-code)
    (asserts! (> (len updated-details) u0) name-validation-code)
    (asserts! (< (len updated-details) u129) name-validation-code)
    (asserts! (validate-label-set updated-labels) metadata-validation-code)

    ;; Update record with new information
    (map-set property-records
      { record-id: record-id }
      (merge record-info { 
        record-name: updated-name, 
        content-bytes: updated-size, 
        details-text: updated-details, 
        metadata-labels: updated-labels 
      })
    )
    (ok true)
  )
)

;; Removes a record from the system
(define-public (remove-record (record-id uint))
  (let
    (
      (record-info (unwrap! (map-get? property-records { record-id: record-id }) record-missing-code))
    )
    ;; Ownership verification
    (asserts! (record-exists record-id) record-missing-code)
    (asserts! (is-eq (get record-holder record-info) tx-sender) ownership-violation-code)
    
    ;; Remove record
    (map-delete property-records { record-id: record-id })
    (ok true)
  )
)

;; Transfers record ownership to another principal
(define-public (transfer-ownership (record-id uint) (recipient principal))
  (let
    (
      (record-info (unwrap! (map-get? property-records { record-id: record-id }) record-missing-code))
    )
    ;; Verify caller is the current owner
    (asserts! (record-exists record-id) record-missing-code)
    (asserts! (is-eq (get record-holder record-info) tx-sender) ownership-violation-code)
    
    ;; Update ownership
    (map-set property-records
      { record-id: record-id }
      (merge record-info { record-holder: recipient })
    )
    (ok true)
  )
)

