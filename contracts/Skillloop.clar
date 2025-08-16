(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_SKILL_NOT_FOUND (err u101))
(define-constant ERR_REQUEST_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_CANNOT_REQUEST_OWN_SKILL (err u105))
(define-constant ERR_INSUFFICIENT_BALANCE (err u106))
(define-constant ERR_CERTIFICATION_NOT_FOUND (err u107))
(define-constant ERR_ALREADY_ENDORSED (err u108))
(define-constant ERR_CANNOT_ENDORSE_SELF (err u109))
(define-constant ERR_INSUFFICIENT_ENDORSEMENTS (err u110))
(define-constant ERR_INSUFFICIENT_COMPLETIONS (err u111))
(define-constant ERR_MENTORSHIP_NOT_FOUND (err u112))
(define-constant ERR_ALREADY_ENROLLED (err u113))
(define-constant ERR_NOT_ENROLLED (err u114))
(define-constant ERR_PHASE_NOT_COMPLETED (err u115))
(define-constant ERR_INVALID_PHASE (err u116))
(define-constant ERR_MENTORSHIP_FULL (err u117))

(define-data-var skill-id-counter uint u0)
(define-data-var request-id-counter uint u0)
(define-data-var certification-id-counter uint u0)
(define-data-var mentorship-id-counter uint u0)

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

(define-map skill-certifications
  { certification-id: uint }
  {
    skill-category: (string-ascii 50),
    certification-name: (string-ascii 100),
    description: (string-ascii 300),
    required-endorsements: uint,
    required-completions: uint,
    skill-tokens-reward: uint,
    reputation-bonus: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map user-certifications
  { user: principal, certification-id: uint }
  {
    earned-at: uint,
    endorsement-count: uint,
    completion-count: uint,
    is-verified: bool
  }
)

(define-map certification-endorsements
  { certification-id: uint, endorser: principal, endorsed-user: principal }
  {
    endorsement-message: (string-ascii 200),
    skill-proof-id: uint,
    created-at: uint,
    is-verified: bool
  }
)

(define-map certification-applications
  { user: principal, certification-id: uint }
  {
    application-message: (string-ascii 300),
    submitted-at: uint,
    status: (string-ascii 20),
    reviewer: (optional principal),
    reviewed-at: (optional uint)
  }
)

;; Mentorship program data structures
(define-map mentorship-programs
  { mentorship-id: uint }
  {
    mentor: principal,
    skill-category: (string-ascii 50),
    program-title: (string-ascii 100),
    description: (string-ascii 400),
    total-phases: uint,
    max-mentees: uint,
    current-mentees: uint,
    tokens-per-phase: uint,
    reputation-reward: uint,
    is-active: bool,
    created-at: uint
  }
)

;; Phase definitions for each mentorship program
(define-map mentorship-phases
  { mentorship-id: uint, phase-number: uint }
  {
    phase-title: (string-ascii 80),
    phase-description: (string-ascii 300),
    required-hours: uint,
    learning-objectives: (string-ascii 200),
    completion-criteria: (string-ascii 200)
  }
)

;; Track mentee enrollment and progress
(define-map mentorship-enrollments
  { mentorship-id: uint, mentee: principal }
  {
    enrolled-at: uint,
    current-phase: uint,
    completed-phases: uint,
    total-hours-logged: uint,
    last-activity: uint,
    status: (string-ascii 20),
    graduation-date: (optional uint)
  }
)

;; Track individual phase completions
(define-map phase-completions
  { mentorship-id: uint, mentee: principal, phase-number: uint }
  {
    started-at: uint,
    completed-at: (optional uint),
    hours-logged: uint,
    mentor-feedback: (string-ascii 300),
    mentee-reflection: (string-ascii 300),
    completion-proof: (string-ascii 200),
    is-approved: bool
  }
)

;; Mentor session tracking
(define-map mentorship-sessions
  { mentorship-id: uint, mentee: principal, session-id: uint }
  {
    session-date: uint,
    duration-hours: uint,
    session-notes: (string-ascii 400),
    phase-focus: uint,
    mentor-rating: uint,
    mentee-rating: uint,
    recorded-by: principal
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

(define-public (create-certification
  (skill-category (string-ascii 50))
  (certification-name (string-ascii 100))
  (description (string-ascii 300))
  (required-endorsements uint)
  (required-completions uint)
  (skill-tokens-reward uint)
  (reputation-bonus uint)
)
  (if (is-eq tx-sender CONTRACT_OWNER)
    (let ((new-certification-id (+ (var-get certification-id-counter) u1)))
      (begin
        (map-set skill-certifications
          { certification-id: new-certification-id }
          {
            skill-category: skill-category,
            certification-name: certification-name,
            description: description,
            required-endorsements: required-endorsements,
            required-completions: required-completions,
            skill-tokens-reward: skill-tokens-reward,
            reputation-bonus: reputation-bonus,
            is-active: true,
            created-at: stacks-block-height
          }
        )
        (var-set certification-id-counter new-certification-id)
        (ok new-certification-id)
      )
    )
    ERR_NOT_AUTHORIZED
  )
)

(define-public (apply-for-certification (certification-id uint) (application-message (string-ascii 300)))
  (let (
    (certification (unwrap! (map-get? skill-certifications { certification-id: certification-id }) ERR_CERTIFICATION_NOT_FOUND))
    (user-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
    (existing-application (map-get? certification-applications { user: tx-sender, certification-id: certification-id }))
  )
    (if (is-some existing-application)
      ERR_ALREADY_EXISTS
      (begin
        (map-set certification-applications
          { user: tx-sender, certification-id: certification-id }
          {
            application-message: application-message,
            submitted-at: stacks-block-height,
            status: "pending",
            reviewer: none,
            reviewed-at: none
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (endorse-for-certification 
  (certification-id uint) 
  (endorsed-user principal) 
  (endorsement-message (string-ascii 200))
  (skill-proof-id uint)
)
  (let (
    (certification (unwrap! (map-get? skill-certifications { certification-id: certification-id }) ERR_CERTIFICATION_NOT_FOUND))
    (endorser-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
    (endorsed-profile (unwrap! (map-get? user-profiles { user: endorsed-user }) ERR_NOT_AUTHORIZED))
    (existing-endorsement (map-get? certification-endorsements { certification-id: certification-id, endorser: tx-sender, endorsed-user: endorsed-user }))
    (skill-request (unwrap! (map-get? skill-requests { request-id: skill-proof-id }) ERR_REQUEST_NOT_FOUND))
  )
    (if (is-eq tx-sender endorsed-user)
      ERR_CANNOT_ENDORSE_SELF
      (if (is-some existing-endorsement)
        ERR_ALREADY_ENDORSED
        (if (and (is-eq (get status skill-request) "completed") (is-eq (get requester skill-request) endorsed-user))
          (begin
            (map-set certification-endorsements
              { certification-id: certification-id, endorser: tx-sender, endorsed-user: endorsed-user }
              {
                endorsement-message: endorsement-message,
                skill-proof-id: skill-proof-id,
                created-at: stacks-block-height,
                is-verified: true
              }
            )
            (ok true)
          )
          ERR_INVALID_STATUS
        )
      )
    )
  )
)

(define-public (process-certification-application (user principal) (certification-id uint))
  (let (
    (certification (unwrap! (map-get? skill-certifications { certification-id: certification-id }) ERR_CERTIFICATION_NOT_FOUND))
    (application (unwrap! (map-get? certification-applications { user: user, certification-id: certification-id }) ERR_REQUEST_NOT_FOUND))
    (user-profile (unwrap! (map-get? user-profiles { user: user }) ERR_NOT_AUTHORIZED))
    (endorsement-count (get-endorsement-count user certification-id))
    (completion-count (get skills-completed user-profile))
  )
    (if (is-eq tx-sender CONTRACT_OWNER)
      (if (and (>= endorsement-count (get required-endorsements certification)) (>= completion-count (get required-completions certification)))
        (begin
          (map-set user-certifications
            { user: user, certification-id: certification-id }
            {
              earned-at: stacks-block-height,
              endorsement-count: endorsement-count,
              completion-count: completion-count,
              is-verified: true
            }
          )
          (map-set certification-applications
            { user: user, certification-id: certification-id }
            (merge application {
              status: "approved",
              reviewer: (some tx-sender),
              reviewed-at: (some stacks-block-height)
            })
          )
          (map-set user-profiles
            { user: user }
            (merge user-profile {
              skill-tokens: (+ (get skill-tokens user-profile) (get skill-tokens-reward certification)),
              reputation-score: (+ (get reputation-score user-profile) (get reputation-bonus certification))
            })
          )
          (ok true)
        )
        (begin
          (map-set certification-applications
            { user: user, certification-id: certification-id }
            (merge application {
              status: "rejected",
              reviewer: (some tx-sender),
              reviewed-at: (some stacks-block-height)
            })
          )
          (if (< endorsement-count (get required-endorsements certification))
            ERR_INSUFFICIENT_ENDORSEMENTS
            ERR_INSUFFICIENT_COMPLETIONS
          )
        )
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-public (revoke-certification (user principal) (certification-id uint))
  (let (
    (certification (unwrap! (map-get? skill-certifications { certification-id: certification-id }) ERR_CERTIFICATION_NOT_FOUND))
    (user-certification (unwrap! (map-get? user-certifications { user: user, certification-id: certification-id }) ERR_CERTIFICATION_NOT_FOUND))
  )
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set user-certifications
          { user: user, certification-id: certification-id }
          (merge user-certification { is-verified: false })
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-public (deactivate-certification (certification-id uint))
  (let ((certification (unwrap! (map-get? skill-certifications { certification-id: certification-id }) ERR_CERTIFICATION_NOT_FOUND)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set skill-certifications
          { certification-id: certification-id }
          (merge certification { is-active: false })
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-read-only (get-certification (certification-id uint))
  (map-get? skill-certifications { certification-id: certification-id })
)

(define-read-only (get-user-certification (user principal) (certification-id uint))
  (map-get? user-certifications { user: user, certification-id: certification-id })
)

(define-read-only (get-certification-endorsement (certification-id uint) (endorser principal) (endorsed-user principal))
  (map-get? certification-endorsements { certification-id: certification-id, endorser: endorser, endorsed-user: endorsed-user })
)

(define-read-only (get-certification-application (user principal) (certification-id uint))
  (map-get? certification-applications { user: user, certification-id: certification-id })
)

(define-read-only (get-certification-counter)
  (var-get certification-id-counter)
)

(define-read-only (get-endorsement-count (user principal) (certification-id uint))
  (fold count-endorsements (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) u0)
)

(define-private (count-endorsements (item uint) (acc uint))
  acc
)

;; Mentorship program functions

;; Create a new mentorship program with structured phases
(define-public (create-mentorship-program
  (skill-category (string-ascii 50))
  (program-title (string-ascii 100))
  (description (string-ascii 400))
  (total-phases uint)
  (max-mentees uint)
  (tokens-per-phase uint)
  (reputation-reward uint)
)
  (let (
    (mentor-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
    (new-mentorship-id (+ (var-get mentorship-id-counter) u1))
  )
    ;; Only allow users with sufficient reputation to become mentors
    (if (>= (get reputation-score mentor-profile) u200)
      (begin
        (map-set mentorship-programs
          { mentorship-id: new-mentorship-id }
          {
            mentor: tx-sender,
            skill-category: skill-category,
            program-title: program-title,
            description: description,
            total-phases: total-phases,
            max-mentees: max-mentees,
            current-mentees: u0,
            tokens-per-phase: tokens-per-phase,
            reputation-reward: reputation-reward,
            is-active: true,
            created-at: stacks-block-height
          }
        )
        (var-set mentorship-id-counter new-mentorship-id)
        (ok new-mentorship-id)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Define learning phases for a mentorship program
(define-public (define-mentorship-phase
  (mentorship-id uint)
  (phase-number uint)
  (phase-title (string-ascii 80))
  (phase-description (string-ascii 300))
  (required-hours uint)
  (learning-objectives (string-ascii 200))
  (completion-criteria (string-ascii 200))
)
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
  )
    (if (is-eq tx-sender (get mentor program))
      (if (and (>= phase-number u1) (<= phase-number (get total-phases program)))
        (begin
          (map-set mentorship-phases
            { mentorship-id: mentorship-id, phase-number: phase-number }
            {
              phase-title: phase-title,
              phase-description: phase-description,
              required-hours: required-hours,
              learning-objectives: learning-objectives,
              completion-criteria: completion-criteria
            }
          )
          (ok true)
        )
        ERR_INVALID_PHASE
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Enroll a mentee in a mentorship program
(define-public (enroll-in-mentorship (mentorship-id uint))
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
    (mentee-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
    (existing-enrollment (map-get? mentorship-enrollments { mentorship-id: mentorship-id, mentee: tx-sender }))
  )
    (if (is-some existing-enrollment)
      ERR_ALREADY_ENROLLED
      (if (< (get current-mentees program) (get max-mentees program))
        (if (>= (get skill-tokens mentee-profile) (* (get tokens-per-phase program) (get total-phases program)))
          (begin
            ;; Enroll the mentee
            (map-set mentorship-enrollments
              { mentorship-id: mentorship-id, mentee: tx-sender }
              {
                enrolled-at: stacks-block-height,
                current-phase: u1,
                completed-phases: u0,
                total-hours-logged: u0,
                last-activity: stacks-block-height,
                status: "active",
                graduation-date: none
              }
            )
            ;; Update program mentee count
            (map-set mentorship-programs
              { mentorship-id: mentorship-id }
              (merge program { current-mentees: (+ (get current-mentees program) u1) })
            )
            (ok true)
          )
          ERR_INSUFFICIENT_BALANCE
        )
        ERR_MENTORSHIP_FULL
      )
    )
  )
)

;; Start a new phase for an enrolled mentee
(define-public (start-mentorship-phase (mentorship-id uint) (mentee principal) (phase-number uint))
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
    (enrollment (unwrap! (map-get? mentorship-enrollments { mentorship-id: mentorship-id, mentee: mentee }) ERR_NOT_ENROLLED))
    (existing-phase (map-get? phase-completions { mentorship-id: mentorship-id, mentee: mentee, phase-number: phase-number }))
  )
    (if (is-eq tx-sender (get mentor program))
      (if (and (is-eq (get current-phase enrollment) phase-number) (is-none existing-phase))
        (begin
          (map-set phase-completions
            { mentorship-id: mentorship-id, mentee: mentee, phase-number: phase-number }
            {
              started-at: stacks-block-height,
              completed-at: none,
              hours-logged: u0,
              mentor-feedback: "",
              mentee-reflection: "",
              completion-proof: "",
              is-approved: false
            }
          )
          (ok true)
        )
        ERR_INVALID_PHASE
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Complete a mentorship phase with feedback and proof
(define-public (complete-mentorship-phase
  (mentorship-id uint)
  (phase-number uint)
  (hours-logged uint)
  (mentee-reflection (string-ascii 300))
  (completion-proof (string-ascii 200))
)
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
    (enrollment (unwrap! (map-get? mentorship-enrollments { mentorship-id: mentorship-id, mentee: tx-sender }) ERR_NOT_ENROLLED))
    (phase-completion (unwrap! (map-get? phase-completions { mentorship-id: mentorship-id, mentee: tx-sender, phase-number: phase-number }) ERR_PHASE_NOT_COMPLETED))
    (mentee-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
  )
    (if (is-eq (get current-phase enrollment) phase-number)
      (if (is-none (get completed-at phase-completion))
        (begin
          ;; Update phase completion details
          (map-set phase-completions
            { mentorship-id: mentorship-id, mentee: tx-sender, phase-number: phase-number }
            (merge phase-completion {
              completed-at: (some stacks-block-height),
              hours-logged: hours-logged,
              mentee-reflection: mentee-reflection,
              completion-proof: completion-proof
            })
          )
          ;; Update enrollment progress
          (map-set mentorship-enrollments
            { mentorship-id: mentorship-id, mentee: tx-sender }
            (merge enrollment {
              completed-phases: (+ (get completed-phases enrollment) u1),
              total-hours-logged: (+ (get total-hours-logged enrollment) hours-logged),
              last-activity: stacks-block-height
            })
          )
          (ok true)
        )
        ERR_ALREADY_EXISTS
      )
      ERR_INVALID_PHASE
    )
  )
)

;; Approve phase completion and advance mentee (mentor only)
(define-public (approve-phase-completion
  (mentorship-id uint)
  (mentee principal)
  (phase-number uint)
  (mentor-feedback (string-ascii 300))
)
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
    (enrollment (unwrap! (map-get? mentorship-enrollments { mentorship-id: mentorship-id, mentee: mentee }) ERR_NOT_ENROLLED))
    (phase-completion (unwrap! (map-get? phase-completions { mentorship-id: mentorship-id, mentee: mentee, phase-number: phase-number }) ERR_PHASE_NOT_COMPLETED))
    (mentee-profile (unwrap! (map-get? user-profiles { user: mentee }) ERR_NOT_AUTHORIZED))
    (mentor-profile (unwrap! (map-get? user-profiles { user: tx-sender }) ERR_NOT_AUTHORIZED))
  )
    (if (is-eq tx-sender (get mentor program))
      (if (and (is-some (get completed-at phase-completion)) (not (get is-approved phase-completion)))
        (begin
          ;; Approve the phase completion
          (map-set phase-completions
            { mentorship-id: mentorship-id, mentee: mentee, phase-number: phase-number }
            (merge phase-completion {
              mentor-feedback: mentor-feedback,
              is-approved: true
            })
          )
          ;; Advance to next phase or graduate
          (if (< phase-number (get total-phases program))
            ;; Move to next phase
            (map-set mentorship-enrollments
              { mentorship-id: mentorship-id, mentee: mentee }
              (merge enrollment { current-phase: (+ phase-number u1) })
            )
            ;; Graduate mentee
            (map-set mentorship-enrollments
              { mentorship-id: mentorship-id, mentee: mentee }
              (merge enrollment {
                status: "graduated",
                graduation-date: (some stacks-block-height)
              })
            )
          )
          ;; Reward mentee with tokens and reputation
          (map-set user-profiles
            { user: mentee }
            (merge mentee-profile {
              skill-tokens: (+ (get skill-tokens mentee-profile) (get tokens-per-phase program)),
              reputation-score: (+ (get reputation-score mentee-profile) u15)
            })
          )
          ;; Reward mentor with reputation
          (map-set user-profiles
            { user: tx-sender }
            (merge mentor-profile {
              reputation-score: (+ (get reputation-score mentor-profile) (get reputation-reward program))
            })
          )
          (ok true)
        )
        ERR_PHASE_NOT_COMPLETED
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Record a mentorship session
(define-public (record-mentorship-session
  (mentorship-id uint)
  (mentee principal)
  (session-id uint)
  (duration-hours uint)
  (session-notes (string-ascii 400))
  (phase-focus uint)
  (mentor-rating uint)
  (mentee-rating uint)
)
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
    (enrollment (unwrap! (map-get? mentorship-enrollments { mentorship-id: mentorship-id, mentee: mentee }) ERR_NOT_ENROLLED))
  )
    (if (or (is-eq tx-sender (get mentor program)) (is-eq tx-sender mentee))
      (begin
        (map-set mentorship-sessions
          { mentorship-id: mentorship-id, mentee: mentee, session-id: session-id }
          {
            session-date: stacks-block-height,
            duration-hours: duration-hours,
            session-notes: session-notes,
            phase-focus: phase-focus,
            mentor-rating: mentor-rating,
            mentee-rating: mentee-rating,
            recorded-by: tx-sender
          }
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Deactivate a mentorship program
(define-public (deactivate-mentorship-program (mentorship-id uint))
  (let (
    (program (unwrap! (map-get? mentorship-programs { mentorship-id: mentorship-id }) ERR_MENTORSHIP_NOT_FOUND))
  )
    (if (is-eq tx-sender (get mentor program))
      (begin
        (map-set mentorship-programs
          { mentorship-id: mentorship-id }
          (merge program { is-active: false })
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Read-only functions for mentorship data retrieval

(define-read-only (get-mentorship-program (mentorship-id uint))
  (map-get? mentorship-programs { mentorship-id: mentorship-id })
)

(define-read-only (get-mentorship-phase (mentorship-id uint) (phase-number uint))
  (map-get? mentorship-phases { mentorship-id: mentorship-id, phase-number: phase-number })
)

(define-read-only (get-mentorship-enrollment (mentorship-id uint) (mentee principal))
  (map-get? mentorship-enrollments { mentorship-id: mentorship-id, mentee: mentee })
)

(define-read-only (get-phase-completion (mentorship-id uint) (mentee principal) (phase-number uint))
  (map-get? phase-completions { mentorship-id: mentorship-id, mentee: mentee, phase-number: phase-number })
)

(define-read-only (get-mentorship-session (mentorship-id uint) (mentee principal) (session-id uint))
  (map-get? mentorship-sessions { mentorship-id: mentorship-id, mentee: mentee, session-id: session-id })
)

(define-read-only (get-mentorship-counter)
  (var-get mentorship-id-counter)
)
