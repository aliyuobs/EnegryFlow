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
