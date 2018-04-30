

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;      starlight.rkt      ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 ;
; Author: Tony Fischetti          ;
; Email: tony.fischetti@gmail.com ;
;                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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

(define arg-separator ":")

(define this-form '())
(define inputcontents "")


(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define-runtime-path
  appspath (string->path (string-append
                           (path->string (find-system-path 'home-dir))
                           ".starlight.rkt")))

(define (load-rc)
  (parameterize ([current-namespace ns])
    (load appspath)))

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

(define (do-target-match winner contents)
  (set! this-form (assoc (string->symbol winner) lookup))
  (set! inputcontents contents)
  (let [(exec-form (get-exec-form lookup (string->symbol winner)))]
    (eval exec-form ns))
  (done))


; GUI components
(define topframe
  (new frame% [label "Starlight"] [style '(no-caption)] [x 100] [y 100]))

(define input
  (new text-field%
       [parent topframe] [label #f] [min-width 200]
       [callback
         (lambda (a b)
           (let* ([etype (send b get-event-type)]
                  [contents (send input get-value)]
                  [separated (string-split contents arg-separator)]
                  [firstitem (if (not (equal? contents "")) (car separated) contents)])
             (let ([passing (populate-field app-field lookup firstitem)])
               (cond [(and (eq? etype 'text-field-enter) (= 1 (length passing)))
                      (do-target-match (car passing) contents)]
                     [(and (equal? contents "") (eq? etype 'text-field-enter)) (done)]))))]))

(define app-field
  (new text-field% [parent topframe] [label #f] [min-width 300]
       [min-height 700] [enabled #f]))


(send topframe center)
(send topframe show #t)
(define SHOWN? #t)
(populate-field app-field lookup "")


; listening server components
(define (serve port-no)
  (define listener (tcp-listen port-no 5 #t))
  (define (loop) (accept-and-handle listener) (loop))
  (define t (thread loop))
  (lambda () (kill-thread t) (tcp-close listener)))

(define (accept-and-handle listener)
  (define-values (in out) (tcp-accept listener))
  (handle in out)
  (close-input-port in)
  (close-output-port out))

(define (handle in out)
  (if SHOWN?
    (begin (send topframe show #f) (set! SHOWN? #f))
    (begin (send topframe show #t) (set! SHOWN? #t))))

(define stop (serve 8080))

(yield never-evt)
