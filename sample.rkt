
; for os specific recipies
(define os (system-type 'os))

; defining the arg separator provides the boundary
; after which starlight will ignore the rest of
; the contents of the input field for the purposes
; of matching a target
(define arg-separator #rx"[ :]")

; function to get the contents after the colon
(define (get-after-colon theinput)
  (let ([separated (string-split theinput ":")])
    (string-trim (car (cdr separated)))))


(define lookup
  `((reload (load-rc))
    (kill (exit 0))))

(define mac-lookup
  `((firefox (exec "open /Applications/Firefox.app"))
    (terminal (exec "open /Applications/iTerm.app/"))
    (vim (exec "open /Applications/MacVim.app"))
    (calendar (exec "open /Applications/Calendar.app"))
    (contacts (exec "open /Applications/Contacts.app/"))
    (whatsapp (exec "open /Applications/WhatsApp.app/"))
    (itunes (exec "open /Applications/iTunes.app/"))
    (spotify (exec "open /Applications/Spotify.app/"))
    (image-capture (exec "open /Applications/Image Capture.app/"))
    (todo (exec "open /Applications/2Do.app/"))
    (monitor (exec "open /Applications/Utilities/Activity\\ Monitor.app"))
    (repl (graphical-read-eval-print-loop))
    (gmail (exec "open 'http://gmail.com'"))
    (preview (exec "open /Applications/Preview.app"))
<<<<<<< HEAD
    (slack (exec "open /Applications/Slack.app/"))
=======
>>>>>>> a95f61f92b200a2bb6ad77740218e77f4460b45d
    (messages (exec "open /Applications/Messages.app"))
    (lock (exec "/System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine"))
    (google
      (let [(url (string-append
                   "open -a Firefox 'http://google.com/search?q="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (wiki
      (let [(url (string-append
                   "open -a Firefox 'http://en.wikipedia.org/wiki/Special:Search?search="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (youtube
      (let [(url (string-append
                   "open -a Firefox 'http://www.youtube.com/results?search_query="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (esen
      (let [(url (string-append
                   "open -a Firefox 'https://translate.google.com/#es/en/"
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (enes
      (let [(url (string-append
                   "open -a Firefox 'https://translate.google.com/#en/es/"
                   (get-after-colon inputcontents)  "'"))]
        (exec url)))
    ))


(if (eq? os 'macosx) (set! lookup (append lookup mac-lookup)) '())

