
(define os (system-type 'os))

(define lookup
  `((firefox (exec "open /Applications/Firefox.app"))
    (terminal (exec "open /Applications/iTerm.app/"))
    (vim (exec "open /Applications/MacVim.app"))
    (calendar (exec "open /Applications/Calendar.app"))
    (contacts (exec "open /Applications/Contacts.app/"))
    (whatsapp (exec "open /Applications/WhatsApp.app/"))
    (itunes (exec "open /Applications/iTunes.app/"))
    (spotify (exec "open /Applications/Spotify.app/"))
    (monitor (exec "open /Applications/Utilities/Activity\\ Monitor.app"))
    (reload (load-rc))
    (kill (exit 0))
    (gmail (exec "open 'http://gmail.com'"))
    (lock (exec "/System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine"))
    (google (let [(url (string-append "open -a Firefox 'http://google.com/search?q=" args "'"))] (exec url)))
    (wiki (let [(url (string-append "open -a Firefox 'http://en.wikipedia.org/wiki/Special:Search?search=" args "'"))] (exec url)))
    (youtube (let [(url (string-append "open -a Firefox 'http://www.youtube.com/results?search_query=" args "'"))] (exec url)))
    (esen (let [(url (string-append "open -a Firefox 'https://translate.google.com/#es/en/" args "'"))] (exec url)))
    (enes (let [(url (string-append "open -a Firefox 'https://translate.google.com/#en/es/" args "'"))] (exec url)))
    ))


(if (eq? os 'macosx)
  (let ([more
          `((messages (exec "open /Applications/Messages.app")))])
    (set! lookup (append lookup more)))
  '())

