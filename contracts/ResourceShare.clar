;; ResourceShare: Decentralized Community Resource Sharing Platform
;; Version: 1.0.0

(define-data-var community-manager principal tx-sender)
(define-data-var total-sharing-points uint u0)
(define-data-var daily-rewards uint u30) ;; reward points per block
(define-data-var last-reward-block uint u0) ;; last block when rewards were calculated
(define-map member-points principal uint)

;; Helper function to ensure only the community manager can perform certain actions
(define-private (is-community-manager (caller principal))
  (begin
    (asserts! (is-eq caller (var-get community-manager)) (err u300))
    (ok true)))

;; Initialize the resource sharing system
(define-public (create-community (manager principal))
  (begin
    (asserts! (is-none (map-get? member-points manager)) (err u301))
    (var-set community-manager manager)
    (ok "ResourceShare community created successfully")))

;; Register resource sharing activity
(define-public (share-resources (points uint))
  (begin
    (asserts! (> points u0) (err u302))
    (let ((current-points (default-to u0 (map-get? member-points tx-sender))))
      (map-set member-points tx-sender (+ current-points points))
      (var-set total-sharing-points (+ (var-get total-sharing-points) points))
      (ok (+ current-points points)))))

;; Calculate daily community rewards
(define-public (distribute-rewards)
  (begin
    (try! (is-community-manager tx-sender))
    (let ((current-block tenure-height)
          (previous-distribution (var-get last-reward-block)))
      (asserts! (> current-block previous-distribution) (err u303))
      ;; Calculate rewards based on blocks elapsed
      (let ((elapsed (- current-block previous-distribution))
            (total-rewards (* elapsed (var-get daily-rewards))))
        (var-set last-reward-block current-block)
        (var-set total-sharing-points (+ (var-get total-sharing-points) total-rewards))
        (ok total-rewards)))))

;; Request community resources and claim rewards
(define-public (request-resources)
  (begin
    (let ((member-contribution (default-to u0 (map-get? member-points tx-sender))))
      (asserts! (> member-contribution u0) (err u304))
      (let ((total-points (var-get total-sharing-points))
            (new-rewards (* (var-get daily-rewards) (- tenure-height (var-get last-reward-block))))
            (contribution-ratio (/ (* member-contribution u100000) total-points)))
        ;; Calculate member's share of resources
        (let ((resource-share (/ (* contribution-ratio new-rewards) u100000)))
          (map-delete member-points tx-sender)
          (var-set total-sharing-points (- (var-get total-sharing-points) member-contribution))
          (ok (+ member-contribution resource-share)))))))