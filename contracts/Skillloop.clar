(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_SKILL_NOT_FOUND (err u101))
(define-constant ERR_REQUEST_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_CANNOT_REQUEST_OWN_SKILL (err u105))
(define-constant ERR_INSUFFICIENT_BALANCE (err u106))

(define-data-var skill-id-counter uint u0)
(define-data-var request-id-counter uint u0)

(define-map skills
  { skill-id: uint }
  {
    provider: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    duration-hours: uint,
    skill-tokens-required: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map skill-requests
  { request-id: uint }
  {
    requester: principal,
    skill-id: uint,
    message: (string-ascii 300),
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map user-profiles
  { user: principal }
  {
    username: (string-ascii 50),
    bio: (string-ascii 300),
    skill-tokens: uint,
    skills-completed: uint,
    skills-requested: uint,
    reputation-score: uint,
    is-active: bool
  }
)

(define-map user-skills
  { user: principal, skill-id: uint }
  { exists: bool }
)

(define-map skill-reviews
  { skill-id: uint, reviewer: principal }
  {
    rating: uint,
    comment: (string-ascii 200),
    created-at: uint
  }
)

(define-public (create-profile (username (string-ascii 50)) (bio (string-ascii 300)))
  (let ((existing-profile (map-get? user-profiles { user: tx-sender })))
    (if (is-some existing-profile)
      ERR_ALREADY_EXISTS
      (begin
        (map-set user-profiles
          { user: tx-sender }
          {
            username: username,
            bio: bio,
            skill-tokens: u100,
            skills-completed: u0,
            skills-requested: u0,
            reputation-score: u100,
            is-active: true
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (create-skill 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (duration-hours uint)
  (skill-tokens-required uint)
)
  (let ((new-skill-id (+ (var-get skill-id-counter) u1)))
    (begin
      (map-set skills
        { skill-id: new-skill-id }
        {
          provider: tx-sender,
          title: title,
          description: description,
          category: category,
          duration-hours: duration-hours,
          skill-tokens-required: skill-tokens-required,
          is-active: true,
          created-at: stacks-block-height
        }
      )
      (map-set user-skills
        { user: tx-sender, skill-id: new-skill-id }
        { exists: true }
      )
      (var-set skill-id-counter new-skill-id)
      (ok new-skill-id)
    )
  )
)

(define-public (request-skill (skill-id uint) (message (string-ascii 300)))
  (let (
    (skill (unwrap! (map-get? skills { skill-id: skill-id }) ERR_SKILL_NOT_FOUND))
    (requester-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
    (new-request-id (+ (var-get request-id-counter) u1))
  )
    (if (is-eq tx-sender (get provider skill))
      ERR_CANNOT_REQUEST_OWN_SKILL
      (if (< (get skill-tokens requester-profile) (get skill-tokens-required skill))
        ERR_INSUFFICIENT_BALANCE
        (begin
          (map-set skill-requests
            { request-id: new-request-id }
            {
              requester: tx-sender,
              skill-id: skill-id,
              message: message,
              status: "pending",
              created-at: stacks-block-height,
              completed-at: none
            }
          )
          (var-set request-id-counter new-request-id)
          (ok new-request-id)
        )
      )
    )
  )
)

(define-public (accept-request (request-id uint))
  (let (
    (request (unwrap! (map-get? skill-requests { request-id: request-id }) ERR_REQUEST_NOT_FOUND))
    (skill (unwrap! (map-get? skills { skill-id: (get skill-id request) }) ERR_SKILL_NOT_FOUND))
  )
    (if (is-eq tx-sender (get provider skill))
      (begin
        (map-set skill-requests
          { request-id: request-id }
          (merge request { status: "accepted" })
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-public (complete-skill (request-id uint))
  (let (
    (request (unwrap! (map-get? skill-requests { request-id: request-id }) ERR_REQUEST_NOT_FOUND))
    (skill (unwrap! (map-get? skills { skill-id: (get skill-id request) }) ERR_SKILL_NOT_FOUND))
    (requester-profile (unwrap! (map-get? user-profiles { user: (get requester request) }) ERR_NOT_AUTHORIZED))
    (provider-profile (unwrap! (map-get? user-profiles { user: (get provider skill) }) ERR_NOT_AUTHORIZED))
  )
    (if (is-eq tx-sender (get provider skill))
      (if (is-eq (get status request) "accepted")
        (begin
          (map-set skill-requests
            { request-id: request-id }
            (merge request { 
              status: "completed",
              completed-at: (some stacks-block-height)
            })
          )
          (map-set user-profiles
            { user: (get requester request) }
            (merge requester-profile {
              skill-tokens: (- (get skill-tokens requester-profile) (get skill-tokens-required skill)),
              skills-requested: (+ (get skills-requested requester-profile) u1)
            })
          )
          (map-set user-profiles
            { user: (get provider skill) }
            (merge provider-profile {
              skill-tokens: (+ (get skill-tokens provider-profile) (get skill-tokens-required skill)),
              skills-completed: (+ (get skills-completed provider-profile) u1),
              reputation-score: (+ (get reputation-score provider-profile) u10)
            })
          )
          (ok true)
        )
        ERR_INVALID_STATUS
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-public (add-review (skill-id uint) (rating uint) (comment (string-ascii 200)))
  (let ((skill (unwrap! (map-get? skills { skill-id: skill-id }) ERR_SKILL_NOT_FOUND)))
    (if (and (>= rating u1) (<= rating u5))
      (begin
        (map-set skill-reviews
          { skill-id: skill-id, reviewer: tx-sender }
          {
            rating: rating,
            comment: comment,
            created-at: stacks-block-height
          }
        )
        (ok true)
      )
      ERR_INVALID_STATUS
    )
  )
)

(define-public (deactivate-skill (skill-id uint))
  (let ((skill (unwrap! (map-get? skills { skill-id: skill-id }) ERR_SKILL_NOT_FOUND)))
    (if (is-eq tx-sender (get provider skill))
      (begin
        (map-set skills
          { skill-id: skill-id }
          (merge skill { is-active: false })
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-read-only (get-skill (skill-id uint))
  (map-get? skills { skill-id: skill-id })
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-skill-request (request-id uint))
  (map-get? skill-requests { request-id: request-id })
)

(define-read-only (get-skill-review (skill-id uint) (reviewer principal))
  (map-get? skill-reviews { skill-id: skill-id, reviewer: reviewer })
)

(define-read-only (get-skill-counter)
  (var-get skill-id-counter)
)

(define-read-only (get-request-counter)
  (var-get request-id-counter)
)

(define-read-only (has-user-skill (user principal) (skill-id uint))
  (is-some (map-get? user-skills { user: user, skill-id: skill-id }))
)