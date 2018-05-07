#!/usr/bin/env racket

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
(require racket/runtime-path
         (for-syntax racket/lang/reader))
(require (for-syntax racket/match/parse))
(require (file "/Users/tonyfischetti/.starlight/loader.rkt"))

(define arg-separator ":")

(define this-form '())
(define inputcontents "")

(define PORT 9876)

(define SHOWN? #t)

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

; (define-runtime-path
;   appspath "/Users/tonyfischetti/.starlight/loader.rkt")
  ; (string->path (string-append
  ;                          (path->string (find-system-path 'home-dir))
  ;                          "./.starlight/config.rkt")))

(define (load-rc)
  (parameterize ([current-namespace ns])
    (load incpath)))

(load-rc)

(define (SHOW!)
  (send topframe show #t)
  (set! SHOWN? #t)
  (send input focus))

(define (HIDE!)
  (send topframe show #f)
  (set! SHOWN? #f))

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
  (send input set-value "")
  (populate-field app-field lookup "")
  (HIDE!))

(define (do-target-match winner contents)
  (set! this-form (assoc (string->symbol winner) lookup))
  (set! inputcontents contents)
  (let [(exec-form (get-exec-form lookup (string->symbol winner)))]
    (eval exec-form ns))
  (done))


; GUI components
(define topframe
  (new frame% [label "Starlight"] [style '(no-caption)] [x 100] [y 90]))

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


(populate-field app-field lookup "")
(send topframe center)
(SHOW!)


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
    (HIDE!)
    (SHOW!)))

(define stop-server (serve PORT))

(yield never-evt)
