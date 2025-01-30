;; EnergyFlow - Decentralized Energy Trading Smart Contract

;; Define constants
(define-constant contract-admin tx-sender)
(define-constant error-admin-only (err u100))
(define-constant error-insufficient-funds (err u101))
(define-constant error-transaction-failed (err u102))
(define-constant error-invalid-rate (err u103))
(define-constant error-invalid-quantity (err u104))
(define-constant error-invalid-fee-rate (err u105))
(define-constant error-return-failed (err u106))
(define-constant error-self-trade (err u107))
(define-constant error-capacity-exceeded (err u108))
(define-constant error-invalid-capacity (err u109))

;; Define data variables
(define-data-var unit-price uint u100) 
(define-data-var user-capacity-limit uint u10000) 
(define-data-var platform-fee uint u5) 
(define-data-var return-rate uint u90) 
(define-data-var system-capacity-limit uint u1000000) 
(define-data-var current-system-load uint u0)

;; Define data maps
(define-map user-energy-holdings principal uint)
(define-map user-token-holdings principal uint)
(define-map energy-listing {provider: principal} {quantity: uint, rate: uint})

;; Private functions
(define-private (calculate-platform-fee (quantity uint))
  (/ (* quantity (var-get platform-fee)) u100))

(define-private (calculate-return-amount (quantity uint))
  (/ (* quantity (var-get unit-price) (var-get return-rate)) u100))

(define-private (update-system-load (delta int))
  (let (
    (current-load (var-get current-system-load))
    (new-load (if (< delta 0)
                   (if (>= current-load (to-uint (- 0 delta)))
                       (- current-load (to-uint (- 0 delta)))
                       u0)
                   (+ current-load (to-uint delta))))
  )
    (asserts! (<= new-load (var-get system-capacity-limit)) error-capacity-exceeded)
    (var-set current-system-load new-load)
    (ok true)))

;; Admin functions
(define-public (update-unit-price (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) error-admin-only)
    (asserts! (> new-rate u0) error-invalid-rate)
    (var-set unit-price new-rate)
    (ok true)))

(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) error-admin-only)
    (asserts! (<= new-fee u100) error-invalid-fee-rate)
    (var-set platform-fee new-fee)
    (ok true)))

(define-public (update-return-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) error-admin-only)
    (asserts! (<= new-rate u100) error-invalid-fee-rate)
    (var-set return-rate new-rate)
    (ok true)))

(define-public (update-system-capacity (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-admin) error-admin-only)
    (asserts! (>= new-limit (var-get current-system-load)) error-invalid-capacity)
    (var-set system-capacity-limit new-limit)
    (ok true)))

;; Trading functions
(define-public (list-energy (quantity uint) (rate uint))
  (let (
    (current-holdings (default-to u0 (map-get? user-energy-holdings tx-sender)))
    (current-listed (get quantity (default-to {quantity: u0, rate: u0} 
                   (map-get? energy-listing {provider: tx-sender}))))
    (new-listing-amount (+ quantity current-listed))
  )
    (asserts! (> quantity u0) error-invalid-quantity)
    (asserts! (> rate u0) error-invalid-rate)
    (asserts! (>= current-holdings new-listing-amount) error-insufficient-funds)
    (try! (update-system-load (to-int quantity)))
    (map-set energy-listing {provider: tx-sender} 
             {quantity: new-listing-amount, rate: rate})
    (ok true)))

(define-public (delist-energy (quantity uint))
  (let (
    (current-listed (get quantity (default-to {quantity: u0, rate: u0} 
                   (map-get? energy-listing {provider: tx-sender}))))
  )
    (asserts! (>= current-listed quantity) error-insufficient-funds)
    (try! (update-system-load (to-int (- quantity))))
    (map-set energy-listing {provider: tx-sender} 
             {quantity: (- current-listed quantity), 
              rate: (get rate (default-to {quantity: u0, rate: u0} 
                    (map-get? energy-listing {provider: tx-sender})))})
    (ok true)))

;; Read functions
(define-read-only (get-current-price)
  (ok (var-get unit-price)))

(define-read-only (get-platform-fee)
  (ok (var-get platform-fee)))

(define-read-only (get-return-rate)
  (ok (var-get return-rate)))

(define-read-only (get-energy-balance (user principal))
  (ok (default-to u0 (map-get? user-energy-holdings user))))

(define-read-only (get-token-balance (user principal))
  (ok (default-to u0 (map-get? user-token-holdings user))))

(define-read-only (get-listed-energy (provider principal))
  (ok (default-to {quantity: u0, rate: u0} 
      (map-get? energy-listing {provider: provider}))))

(define-read-only (get-user-capacity-limit)
  (ok (var-get user-capacity-limit)))

(define-read-only (get-system-load)
  (ok (var-get current-system-load)))

(define-read-only (get-system-capacity)
  (ok (var-get system-capacity-limit)))
