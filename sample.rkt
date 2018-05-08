
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
    (repl (graphical-read-eval-print-loop))
    (about (send about-dialog show #t))
    (kill (begin (stop-server) (exit 0)))))

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
    (app-store (exec "open /Applications/App\\ Store.app/"))
    (todo (exec "open /Applications/2Do.app/"))
    (toodledo (exec "open 'http://toodledo.com'"))
    (monitor (exec "open /Applications/Utilities/Activity\\ Monitor.app"))
    (gmail (exec "open 'http://gmail.com'"))
    (preview (exec "open /Applications/Preview.app"))
    (slack (exec "open /Applications/Slack.app/"))
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
        (exec url)))))

(define unix-lookup
  '((firefox (exec "firefox &"))
    (lock (exec "xscreensaver-command -lock"))
    (notes (exec "xfce4-terminal -x vim /home/tony/Dropbox/Unclutter\\ Notes/arch-notes.txt &"))
    (gmail (exec "firefox --new-tab 'http://gmail.com'"))
    (todo (exec "firefox --new-tab 'http://toodledo.com'"))
    (chrome (exec "google-chrome-stable &"))
    (terminal (exec "xfce4-terminal &"))
    (chrome (exec "google-chrome-stable &"))
    (incognito (exec "google-chrome-stable --incognito &"))
    (explorer (exec "pcmanfm &"))
    (clock (exec "xclock -d -sharp -render -chime"))
    (watch (exec "xclock -sharp -render -chime"))
    (volume (exec "xfce4-terminal -x alsamixer"))
    (night (exec "redshift -O 2500"))
    (deepnight (exec "redshift -O 2000"))
    (day (exec "redshift -O 5500"))
    (time (exec "flash-time"))
    (spotify (exec "spotify &"))
    (whatsapp (exec "Whatsapp &"))
    (gnumeric (exec "gnumeric &"))
    (libreoffice (exec "libreoffice &"))
    (mendeley (exec "mendeleydesktop &"))
    (shutdown (exec "xfce4-terminal -x sudo shutdown -h now"))
    (reboot (exec "xfce4-terminal -x sudo shutdown -r now"))
    (google
      (let [(url (string-append
                   "firefox --new-tab 'http://www.google.com/search?q="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (wiki
      (let [(url (string-append
                   "firefox --new-tab 'http://en.wikipedia.org/wiki/Special:Search?search="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (youtube
      (let [(url (string-append
                   "firefox --new-tab 'http://www.youtube.com/results?search_query="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (esen
      (let [(url (string-append
                   "firefox --new-tab 'https://translate.google.com/#es/en/"
                   (get-after-colon inputcontents) "'"))]
        (exec url)))
    (enes
      (let [(url (string-append
                   "firefox --new-tab 'https://translate.google.com/#en/es/"
                   (get-after-colon inputcontents)  "'"))]
        (exec url)))))


(if (eq? os 'macosx) (set! lookup (append lookup mac-lookup)) '())
(if (eq? os 'unix) (set! lookup (append lookup unix-lookup)) '())

