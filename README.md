# Starlight

A practical application launcher for impractical people

![Screenshot](images/strl-screenshot.png?raw=TRUE)


Preface
---
There's nothing like writing your own application launcher and
having complete control over what you can do with it.

This app (written in [Racket](https://racket-lang.org/)) is a powerful
framework for building your own personal app launcher. It's extensible and
*extremely* customizable in all the ways that matter and none of ways that
don't. This is the perfect solution for hackers that like to shoot themselves
in the foot.


So what's the big idea
---
So... when Starlight starts, it parses a file in your home directory called
`.starlight.rkt`. It populates the launcher window with targets defined in
the aforementioned file. As you type a target into the input window, your
the launcher will narrow down based on whether it matches what you are typing.
Once the app field is narrowed down to one selection, striking the "Enter"
key will run the code you assigned to that target. The launcher window will
then hide itself.

Starlight starts a TCP server and listener on port 8080. Any request to
`localhost:8080` will cause the launcher to re-appear. It disappears when you
  - run another target
  - strike "Enter" with nothing in the input field
  - or make another request to `localhost:8080`

Since the launcher is always running, it appears very quickly.


So why is it powerful
---

Starlight exploits the Lisp's powerful mechanisms for dynamic code
execution. As mentioned before, upon starting the Starlight "server",
it parses a file in your home directory called `.starlight.rkt`.
This file could contain any valid racket code you want,
but the necessary piece is that you `define` a (quoted) list of pairs
named `lookup`.  The first item each pair is a symbol; this is what you
type into the input field in the launcher to perform a particular action.
The second item in each pair is a form to execute when it's corresponding
symbol is chosen and run. For convenience, the function `exec` is defined
so that you can issue shell commands more easily.

For example, a two item starlight configuration would may look like this...

```racket
(define lookup
  `((firefox (exec "firefox"))
    (terminal (exec "gnome-terminal"))))
```

The `.starlight.rkt` file has access to all the variables and functions of
the code that runs the starlight "server". You can, therefore, make changes
to the `.starlight.rkt` file and have the server re-parse this file to make
changes to the app in *as the starlight code runs*. Another example `.starlight.rkt` file
may look like this....

```racket
(define lookup
  `((firefox (exec "firefox"))
    (terminal (exec "gnome-terminal"))
    (reload (load-rc))
    (repl (graphical-read-eval-print-loop))))
```

In this one, executing the "reload" target after you add pairs to `lookup`
will add these recipes to starlight the next time the window shows.
Executing the "repl" target will open up a racket REPL that _gives you
full access to the variables and functions of the running server_. The
opportunities to shoot yourself in the foot are endless!

The fact that `.starlight.rkt` can contain any valid Racket forms/code
creates the opportunity to do some really neat things. For example, you can
create a target called `wiki` that searches wikipedia for anything that comes
after `wiki` and a colon.

To do this, we have to (re)define the `arg-separator` global variable so
that Starlight will know to run the `wiki` target even though the input
field will contain more text...

```racket
(define arg-separator #rx"[ :]")
```

Now we can write a function that will return a string of the text after the
colon in the input field...

```racket
(define (get-after-colon theinput)
  (let ([separated (string-split theinput ":")])
    (string-trim (car (cdr separated)))))
```

Finally let's add another recipe to the `lookup` variable from before...


```racket
(define lookup
  `((firefox (exec "firefox"))
    (terminal (exec "gnome-terminal"))
    (reload (load-rc))
    (repl (graphical-read-eval-print-loop))
    ; this command's syntax is mac specific
    (wiki
      (let [(url (string-append
                   "open -a Firefox 'http://en.wikipedia.org/wiki/Special:Search?search="
                   (get-after-colon inputcontents) "'"))]
        (exec url)))))

```

Finally, the OS can be determined using the `(system-type 'os)` form in
racket.  This will allow you to test the OS and provide different lists
to `lookup` based on your current system. This is useful for having just
*one* `.starlight.rkt` configuration which will work across all your platforms.


Installation
---
First, you have to install racket. Then clone this project into your
home directory (or anywhere you'd like, really)...

```
git clone https://github.com/tonyfischetti/starlight.git ~/
```

Then create a starlight configuration file in your home directory, feel free
to use the `sample.rtk` file in this repository as a starting point.

To start the Starlight "server", run the `start-starlight.sh` shell script
in this repository. Alternatively, you can just run
`racket -e '(enter! "starlight.rkt")' &` in the shell. You may want to run
this command at startup so you don't have to remember to start the server
everytime you restart your computer.

Finally, we have to assign a keyboard shortcut to the command
`curl "http://localhost:8080"` which will be able to bring up (or tear down)
the launcher. On a Mac, I suggest
[ICanHazShortcut](https://github.com/deseven/icanhazshortcut) which is
delightfully easy to use. I like to map the `curl` command to
Shift+Backspace.


FAQ
---
_Is Starlight for everyone?_

I'd like anyone who is interested to look into it but Starlight is certainly
not for everybody. It's power is (strictly speaking) unecessary. Starlight
is probably best suited for use among Lisp hackers. Given that impractical
Lisp hackers tend to write practical solutions to all their problems
themselves, I predict no one but me will be using this. If you do, dear reader,
let me know :)


