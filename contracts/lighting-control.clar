;; Lighting Control Contract
;; Manages court illumination for evening play

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u202))
(define-constant ERR-INVALID-TIME (err u105))
(define-constant ERR-COURT-NOT-FOUND (err u406))
(define-constant ERR-LIGHTING-CONFLICT (err u302))
(define-constant ERR-INVALID-SCHEDULE (err u106))

;; Data Variables
(define-data-var lighting-cost-per-hour uint u100000) ;; 0.1 STX per hour
(define-data-var auto-lighting-enabled bool true)
(define-data-var default-lighting-hours { start: uint, end: uint } { start: u18, end: u22 })

;; Data Maps
(define-map court-lighting
  { court-id: uint }
  {
    is-installed: bool,
    is-active: bool,
    power-rating: uint,
    last-maintenance: uint,
    total-usage-hours: uint
  }
)

(define-map lighting-schedule
  { court-id: uint, date: uint }
  {
    start-time: uint,
    end-time: uint,
    is-manual: bool,
    requested-by: (optional principal),
    cost: uint,
    is-active: bool
  }
)

(define-map lighting-usage
  { court-id: uint, usage-date: uint }
  {
    hours-used: uint,
    energy-cost: uint,
    maintenance-needed: bool
  }
)

(define-map manual-overrides
  { override-id: uint }
  {
    court-id: uint,
    requested-by: principal,
    start-time: uint,
    duration: uint,
    reason: (string-ascii 100),
    approved: bool,
    created-at: uint
  }
)

(define-data-var override-counter uint u0)

;; Private Functions
(define-private (is-valid-lighting-time (start-time uint) (end-time uint))
  (and
    (>= start-time u17) ;; 5PM earliest
    (<= end-time u23)   ;; 11PM latest
    (< start-time end-time)
  )
)

(define-private (calculate-lighting-cost (duration uint))
  (* duration (var-get lighting-cost-per-hour))
)

(define-private (is-lighting-available (court-id uint) (start-time uint) (end-time uint) (date uint))
  (match (map-get? lighting-schedule { court-id: court-id, date: date })
    existing-schedule
    (or
      (>= start-time (get end-time existing-schedule))
      (<= end-time (get start-time existing-schedule))
    )
    true
  )
)

;; Public Functions
(define-public (install-lighting (court-id uint) (power-rating uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> power-rating u0) ERR-INVALID-SCHEDULE)

    (map-set court-lighting
      { court-id: court-id }
      {
        is-installed: true,
        is-active: true,
        power-rating: power-rating,
        last-maintenance: block-height,
        total-usage-hours: u0
      }
    )
    (ok court-id)
  )
)

(define-public (set-lighting (court-id uint) (is-on bool) (start-time uint) (end-time uint))
  (let (
    (duration (- end-time start-time))
    (cost (calculate-lighting-cost duration))
    (current-date (/ block-height u144)) ;; Approximate day
  )
    (asserts! (is-some (map-get? court-lighting { court-id: court-id })) ERR-COURT-NOT-FOUND)
    (asserts! (is-valid-lighting-time start-time end-time) ERR-INVALID-TIME)
    (asserts! (is-lighting-available court-id start-time end-time current-date) ERR-LIGHTING-CONFLICT)

    (if is-on
      (begin
        ;; Charge for lighting usage
        (try! (stx-transfer? cost tx-sender CONTRACT-OWNER))

        ;; Set lighting schedule
        (map-set lighting-schedule
          { court-id: court-id, date: current-date }
          {
            start-time: start-time,
            end-time: end-time,
            is-manual: true,
            requested-by: (some tx-sender),
            cost: cost,
            is-active: true
          }
        )

        ;; Update usage statistics
        (match (map-get? court-lighting { court-id: court-id })
          lighting-info
          (map-set court-lighting
            { court-id: court-id }
            (merge lighting-info {
              total-usage-hours: (+ (get total-usage-hours lighting-info) duration)
            })
          )
          false
        )
      )
      ;; Turn off lighting
      (map-set lighting-schedule
        { court-id: court-id, date: current-date }
        {
          start-time: u0,
          end-time: u0,
          is-manual: true,
          requested-by: (some tx-sender),
          cost: u0,
          is-active: false
        }
      )
    )
    (ok is-on)
  )
)

(define-public (request-lighting-override (court-id uint) (start-time uint) (duration uint) (reason (string-ascii 100)))
  (let (
    (override-id (+ (var-get override-counter) u1))
    (end-time (+ start-time duration))
  )
    (asserts! (is-some (map-get? court-lighting { court-id: court-id })) ERR-COURT-NOT-FOUND)
    (asserts! (is-valid-lighting-time start-time end-time) ERR-INVALID-TIME)
    (asserts! (> duration u0) ERR-INVALID-SCHEDULE)

    (map-set manual-overrides
      { override-id: override-id }
      {
        court-id: court-id,
        requested-by: tx-sender,
        start-time: start-time,
        duration: duration,
        reason: reason,
        approved: false,
        created-at: block-height
      }
    )

    (var-set override-counter override-id)
    (ok override-id)
  )
)

(define-public (approve-lighting-override (override-id uint))
  (match (map-get? manual-overrides { override-id: override-id })
    override-data
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

      (map-set manual-overrides
        { override-id: override-id }
        (merge override-data { approved: true })
      )

      ;; Automatically set lighting based on approved override
      (let (
        (court-id (get court-id override-data))
        (start-time (get start-time override-data))
        (end-time (+ start-time (get duration override-data)))
        (current-date (/ block-height u144))
      )
        (map-set lighting-schedule
          { court-id: court-id, date: current-date }
          {
            start-time: start-time,
            end-time: end-time,
            is-manual: true,
            requested-by: (some (get requested-by override-data)),
            cost: (calculate-lighting-cost (get duration override-data)),
            is-active: true
          }
        )
      )

      (ok true)
    )
    ERR-COURT-NOT-FOUND
  )
)

(define-public (set-auto-lighting (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set auto-lighting-enabled enabled)
    (ok enabled)
  )
)

(define-public (update-lighting-cost (new-cost uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set lighting-cost-per-hour new-cost)
    (ok new-cost)
  )
)

;; Read-only Functions
(define-read-only (get-lighting-info (court-id uint))
  (map-get? court-lighting { court-id: court-id })
)

(define-read-only (get-lighting-schedule (court-id uint) (date uint))
  (map-get? lighting-schedule { court-id: court-id, date: date })
)

(define-read-only (get-lighting-cost-per-hour)
  (var-get lighting-cost-per-hour)
)

(define-read-only (is-auto-lighting-enabled)
  (var-get auto-lighting-enabled)
)

(define-read-only (get-override-request (override-id uint))
  (map-get? manual-overrides { override-id: override-id })
)

(define-read-only (get-default-lighting-hours)
  (var-get default-lighting-hours)
)
