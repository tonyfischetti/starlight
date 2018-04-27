#lang racket/load

(require racket/gui)
(require racket/string)
(require racket/struct)
(require racket/system)
(require racket/class)
(require racket/snip)
(require racket/runtime-path)
(require framework)
(require xml net/url)

(define color-prefs:black-on-white #t)
; (define application:current-app-name "Starlight")

(define my-style (new style-list%))
(send my-style basic-style)

(define this-form '())
(define args "")

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define-runtime-path appspath (string->path "/Users/tonyfischetti/starlight/apps.rktl"))

(define (load-rc)
  (parameterize ([current-namespace ns])
    (load appspath)))
    ; (load ("apps.rktl"))))
    ; (load (string->path "apps.rktl"))))
    ; (load (string->path "/Users/tonyfischetti/starlight/apps.rktl"))))


(load-rc)


(define (get-exec-form lookup csym)
  (car (cdr (assoc csym lookup))))

(define (populate-field afield lookup prefix)
  (let* ([allapps (map symbol->string (map car lookup))]
         [passing-apps (filter (lambda (x) (string-prefix? x prefix)) allapps)])
    (send app-field set-value (string-join passing-apps "\n"))
    passing-apps))

(define (exec this)
  (process this))

(define (done)
  (send topframe show #f)
  (set! SHOWN? #f)
  (send input set-value "")
  (populate-field app-field lookup ""))

(define (dowith winner therest)
  (set! this-form (assoc (string->symbol winner) lookup))
  (set! args therest)
  (let [(exec-form (get-exec-form lookup (string->symbol winner)))]
    (eval exec-form ns))
  (done))


(define topframe (new frame% [label "Starlight"]
                             [style '(no-caption)]
                             [x 100]
                             [y 100]))

(define input (new text-field% [parent topframe]
                   [label #f]
                   [min-width 200]
                   [callback (lambda (a b)
                               (let* ([etype (send b get-event-type)]
                                      [contents (send input get-value)]
                                      [separated (string-split contents ":")]
                                      [firstitem
                                        (if (not (equal? contents ""))
                                          (car separated)
                                          contents)])
                                   (let ([passing
                                           (populate-field app-field
                                                           lookup
                                                           firstitem)])
                                     (cond
                                       [(and (eq? etype 'text-field-enter)
                                              (= 1 (length passing)))
                                          (dowith (car passing)
                                                  (if (= (length separated) 1)
                                                    '()
                                                    (string-trim
                                                      (car (cdr separated))
                                                      #:left? #t)))]
                                       [(and (equal? contents "")
                                             (eq? etype 'text-field-enter))
                                          (done)]))))]))



(define app-field (new text-field% [parent topframe]
                       [label #f]
                       [init-value "Camm me Ismael"]
                       [min-width 300]
                       [min-height 700]
                       [enabled #f]))


(send topframe center)
(send topframe show #t)
(define SHOWN? #t)
(populate-field app-field lookup "")


(define (serve port-no)
  (define listener (tcp-listen port-no 5 #t))
  (define (loop)
    (accept-and-handle listener)
    (loop))
  (define t (thread loop))
  (lambda ()
    (kill-thread t)
    (tcp-close listener)))

; (define (serve port-no)
;   (define listener (tcp-listen port-no 5 #t))
;   (define (loop)
;     (accept-and-handle listener)
;     (loop))
;   (loop))

(define (accept-and-handle listener)
  (define-values (in out) (tcp-accept listener))
  (handle in out)
  (close-input-port in)
  (close-output-port out))

(define (handle in out)
  (if SHOWN?
    (begin
      (send topframe show #f)
      (set! SHOWN? #f))
    (begin
      (send topframe show #t)
      (set! SHOWN? #t))))

(define stop (serve 8080))
; (serve 8080)

; (let loop ()
;   (read-line (current-input-port) 'any)
;   (loop))

; (read-line (current-input-port) 'any)

(yield never-evt)
