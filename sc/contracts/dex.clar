(define-data-var tokens ((name string) (symbol string) (supply uint)))
(define-data-var balances ((owner principal) (token-id uint) (amount uint)))

(define-read-only (get-token-info (token-id uint))
  (assert (<= token-id (length tokens)))
  (nth token-id tokens))

(define-private (get-balance (owner principal) (token-id uint))
  (fold balances 0
    (lambda (balance acc)
      (if (and (= (tuple-get balance 'owner) owner)
               (= (tuple-get balance 'token-id) token-id))
          (+ (tuple-get balance 'amount) acc)
          acc))))

(define-public (deposit (token-id uint) (amount uint))
  (let ((caller (get-caller))
        (balance (get-balance (get-caller) token-id)))
    ;; transfer tokens from the caller to the contract
    (transfer-tokens caller contract-address token-id amount)
    ;; update the balance
    (if (= balance 0)
        (setq balances (cons '(owner caller) (cons '(token-id token-id)
                                                         (cons '(amount amount) balances))))
        (setq balances (map balances
                          (lambda (balance)
                            (if (and (= (tuple-get balance 'owner) caller)
                                     (= (tuple-get balance 'token-id) token-id))
                                (tuple-set balance 'amount (+ (tuple-get balance 'amount) amount))
                                balance)))))))

(define-public (withdraw (token-id uint) (amount uint))
  (let* ((caller (get-caller))
         (balance (get-balance caller token-id)))
    (assert (> balance amount))
    ;; transfer tokens from the contract to the caller
    (transfer-tokens contract-address caller token-id amount)
    ;; update the balance
    (if (= (- balance amount) 0)
        (setq balances (filter balances
                             (lambda (balance)
                               (or (not (= (tuple-get balance 'owner) caller))
                                   (not (= (tuple-get balance 'token-id) token-id))))))
        (setq balances (map balances
                          (lambda (balance)
                            (if (and (= (tuple-get balance 'owner) caller)
                                     (= (tuple-get balance 'token-id) token-id))
                                (tuple-set balance 'amount (- (tuple-get balance 'amount) amount))
                                balance)))))))

(define-public (get-balance-of (owner principal) (token-id uint))
  (get-balance owner token-id))

(define-public (buy (token-id uint) (amount uint) (price-ust uint))
  (let ((caller (get-caller)))
    ;; transfer UST from the caller to the contract
    (transfer caller contract-address price-ust)

    ;; check the balance of the seller
    (let* ((seller (some (lambda (balance)
                           (and (= (tuple-get balance 'token-id) token-id)
                                (/= (tuple-get balance 'owner) caller)))
                         balances))
           (balance (get-balance seller token-id)))
      (assert (> balance amount))
      ;; transfer tokens from the seller to the buyer
      (transfer-tokens seller caller token-id amount)

      ;; calculate the fee
      (let ((fee (div (mul price-ust 3) 100)))
        ;; transfer the fee from the buyer to the contract owner
        (transfer caller contract-owner fee)
        ;; transfer the remaining UST from the buyer to the seller
        (transfer caller seller (- price-ust fee)))
      )))

(define-public (sell (token-id uint) (amount uint) (price-ust uint))
  (let ((caller (get-caller)))
    ;; check the balance of the seller
    (let ((balance (get-balance caller token-id)))
      (assert (> balance amount))
      ;; transfer tokens from the seller to the contract
      (transfer-tokens caller contract-address token-id amount)
      ;; create a new order
      (setq orders (cons (tuple caller token-id amount price-ust) orders))
      ;; emit an event
      (emit-event! "order-issued" (tuple caller token-id amount price-ust)))))

(define-read-only (get-orders (token-id uint))
  (filter orders
          (lambda (order)
            (= (tuple-get order 1) token-id))))
