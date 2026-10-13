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

; NOTE: in #lang racket/load every form, including these requires, is
; evaluated at runtime, so `raco exe` cannot see them. The libraries the
; standalone app needs are listed with ++lib in make-mac-app.sh instead.
; racket/load's top level already provides everything in `racket`
; (racket/string, racket/system, racket/class, ...).
(require racket/gui)
; Needed for the macOS Spaces fix below. Safe to require on Linux too:
; ffi/unsafe/objc tolerates a missing libobjc, and the calls that need
; it are guarded by an OS check.
(require ffi/unsafe ffi/unsafe/objc ffi/unsafe/global)
(require (file "~/.starlight/loader.rkt"))

(define *VERSION* "0.99")

(define arg-separator ":")

; the default matching? function is string-prefix?. Like arg-separator,
; this must be defined BEFORE load-rc runs so that a config file can
; override it; a define placed after load-rc would clobber the config's.
(define matching? (make-parameter string-prefix?))

(define inputcontents "")

(define PORT 9876)

(define SHOWN? #t)

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))


(define (load-rc)
  (parameterize ([current-namespace ns])
    (load incpath)))

(load-rc)

(define mac? (eq? (system-type 'os) 'macosx))

; mac-show-panel! is a no-op except on macOS, where it is redefined
; below once the window exists.
(define (mac-show-panel!) (void))

(define (SHOW!)
  (send topframe show #t)
  (mac-show-panel!)
  (set! SHOWN? #t)
  (populate-field app-field lookup "")
  (send input focus))

(define (HIDE!)
  (send topframe show #f)
  (set! SHOWN? #f))

(define (get-exec-form lookup csym)
  (car (cdr (assoc csym lookup))))

(define (populate-field afield lookup prefix)
  (let* ([allapps (map symbol->string (map car lookup))]
         [passing-apps (filter (lambda (x) ((matching?) x prefix)) allapps)])
    (send app-field set-value (string-join passing-apps "\n"))
    passing-apps))

(define (exec this)
  (log-warning "executing: ~A~%" this)
  (let ([null-out (open-output-file "/dev/null" #:exists 'append)]
        [null-in  (open-input-file  "/dev/null")])
    (begin0
      (process/ports null-out null-in 'stdout this)
      (close-output-port null-out)
      (close-input-port  null-in))))

(define (done bool)
  (send input set-value "")
  (populate-field app-field lookup "")
  (when bool
    (HIDE!)))


; If a target's form raises, show the error instead of letting it die
; on stderr. The launcher stays up with the input intact so the typo
; (or missing argument) can be fixed and re-run.
(define (report-target-error winner e)
  (log-warning "target '~A' failed: ~A" winner (exn-message e))
  (message-box "Starlight: target failed"
               (format "~A\n\n~A" winner (exn-message e))
               topframe
               '(ok stop))
  (send input focus))

(define (do-target-match winner contents)
  (set! inputcontents contents)
  (let [(exec-form (get-exec-form lookup (string->symbol winner)))]
    (with-handlers ([exn:fail? (lambda (e) (report-target-error winner e))])
      (done (eval exec-form ns)))))


; GUI components
; On macOS the chooser is a floating panel (an NSPanel) rather than a
; regular window; see the Spaces handling below. On other platforms
; 'float would make it a utility window, which we don't want.
(define topframe
  (new frame% [label "Starlight"] [style (if mac? '(no-caption float) '(no-caption))]
       [x 100] [y 60]))

; macOS Spaces handling. The goal is for the chooser to appear wherever
; the user is, including over a full-screen app, instead of dragging
; them to the Space it was last on. The approach is the one launchers
; like Spotlight and Alfred use: a non-activating floating panel.
;
; 1. The native window is flagged so it may join every Space, including
;    the exclusive Space of a full-screen app, and floats above others.
;      NSWindowCollectionBehaviorCanJoinAllSpaces    = 1
;      NSWindowCollectionBehaviorFullScreenAuxiliary = 1 << 8
;      NSFloatingWindowLevel                         = 3
;
; 2. The panel is made non-activating: it can take keyboard focus
;    without Starlight becoming the active application. That matters
;    because activating a separate app is exactly what makes macOS
;    leave a full-screen Space (or refuse to bring the window into it).
;    NSPanels hide themselves when their app is inactive by default,
;    which must be switched off since ours is never active.
;      NSWindowStyleMaskNonactivatingPanel = 1 << 7
;
; 3. Starlight runs as an "accessory" app (no Dock icon). racket/gui
;    resets the policy to Regular and tries to activate the app on every
;    show; the Racket-GUI-no-front process global suppresses the
;    activation, and the policy is set back after each show.
;      NSApplicationActivationPolicyAccessory = 1
(when mac?
  (register-process-global #"Racket-GUI-no-front" #"1")
  (import-class NSApplication)
  (define nsapp (tell NSApplication sharedApplication))
  (define nswin (cast (send topframe get-handle) _pointer _id))
  (tellv nswin setCollectionBehavior: #:type _uint64
         (bitwise-ior 1 (arithmetic-shift 1 8)))
  (tellv nswin setLevel: #:type _int64 3)
  (tellv nswin setStyleMask: #:type _uint64
         (bitwise-ior (tell #:type _uint64 nswin styleMask) (arithmetic-shift 1 7)))
  (tellv nswin setHidesOnDeactivate: #:type _BOOL #f)
  (set! mac-show-panel!
    (lambda ()
      (tellv nsapp setActivationPolicy: #:type _int64 1)
      (tellv nswin makeKeyAndOrderFront: #f))))

(define input
  (new text-field%
       [parent topframe] [label #f] [min-width 200]
       [callback
         (lambda (a b)
           (let* ([etype (send b get-event-type)]
                  [contents (send input get-value)]
                  [separated (string-split contents arg-separator)]
                  [firstitem (if (null? separated) "" (car separated))])
             (let ([passing (populate-field app-field lookup firstitem)])
               (cond [(and (eq? etype 'text-field-enter) (= 1 (length passing)))
                      (do-target-match (car passing) contents)]
                     [(and (equal? contents "") (eq? etype 'text-field-enter)) (done #t)]))))]))


(define app-field
  (new text-field% [parent topframe] [label #f] [min-width 300]
       [min-height 600] [enabled #f]))


(populate-field app-field lookup "")
(send topframe center)
(SHOW!)

(define about-dialog
  (new dialog% [label "About"] [min-width 200] [min-height 100]
       [stretchable-width #t] [stretchable-height #t]
       [style '(close-button)]))

(define about-message
  (new message% [label (string-append "Starlight v. " *VERSION*)]
       [parent about-dialog] [vert-margin 36]))


(define cmdout-dialog
  (new dialog% [label "Command Output"] [min-width 500] [min-height 600]
       [stretchable-width #t] [stretchable-height #t]
       [style '(close-button)]))



(define (serve port-no)
  (define listener (tcp-listen port-no 5 #t "127.0.0.1"))
  (define (loop) (accept-and-handle listener) (loop))
  (define t (thread loop))
  (lambda () (kill-thread t) (tcp-close listener)))

(define (accept-and-handle listener)
  (define-values (in out) (tcp-accept listener))
  (handle in out)
  (close-input-port in)
  (close-output-port out))

(define (handle in out)
  (queue-callback
    (lambda ()
      (if SHOWN?
        (HIDE!)
        (SHOW!)))))

(define stop-server (serve PORT))

(log-warning "started tcp listener")

(yield never-evt)

