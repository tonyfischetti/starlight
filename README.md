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
So... when Starlight starts, it loads a file in your home directory called
`~/.starlight/config.rkt`. It populates the launcher window with targets
defined in the aforementioned file. As you type a target into the input
window, the launcher will narrow down based on whether it matches what you
are typing. Once the app field is narrowed down to one selection, striking
the "Enter" key will run the code you assigned to that target. The launcher
window will then hide itself.

Starlight starts a TCP listener on port 9876, bound to localhost only. Any
connection to `localhost:9876` will cause the launcher to re-appear. It
disappears when you
  - run a target (unless the target's form returns `#f`, see below)
  - strike "Enter" with nothing in the input field
  - or make another connection to `localhost:9876`

If a target's code raises an error, a dialog shows the error message and
the launcher stays up with your input intact so you can fix it and try again.

On a Mac, the launcher is a floating panel that appears on whatever Space
you are currently on, including the Space of a full-screen app, and it
takes keyboard focus without stealing it from the app you were using.
Starlight runs as a background ("accessory") app there, so it has no Dock
icon; to quit it, use a target that calls `(exit 0)` (the sample config's
`kill`) or `pkill Starlight`.

Since the launcher is always running, it appears very quickly.


So why is it powerful
---

Starlight exploits Lisp's powerful mechanisms for dynamic code
execution. As mentioned before, upon starting the Starlight "server",
it loads a file in your home directory called `~/.starlight/config.rkt`.
This file could contain any valid racket code you want,
but the necessary piece is that you `define` a (quoted) list of pairs
named `lookup`.  The first item in each pair is a symbol; this is what you
type into the input field in the launcher to perform a particular action.
The second item in each pair is a form to execute when its corresponding
symbol is chosen and run. For convenience, the function `exec` is defined
so that you can issue shell commands more easily. The launched program's
standard input and output are pointed at `/dev/null`, so it is fully
detached from Starlight.

The form's return value decides whether the launcher hides afterwards: if
it returns `#f`, the window stays up. That is handy for targets that
change state (switching the matching mode, say, or swapping in a
different `lookup`) rather than launching something.

For example, a two item starlight configuration might look like this...

```racket
(define lookup
  `((firefox (exec "firefox"))
    (terminal (exec "gnome-terminal"))))
```

The `config.rkt` file has access to all the variables and functions of
the code that runs the starlight "server". You can, therefore, make changes
to `config.rkt` and have the server re-load this file to make
changes to the app *as the starlight code runs*. Another example `config.rkt`
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

The fact that `config.rkt` can contain any valid Racket forms/code
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

By default a target matches when it *starts with* what you've typed. The
matching function lives in a parameter called `matching?`, so you can swap
in `string-contains?` (or anything else that takes a candidate and the
typed text) from your config:

```racket
(define matching? (make-parameter string-contains?))
```

Finally, the OS can be determined using the `(system-type 'os)` form in
racket.  This will allow you to test the OS and provide different lists
to `lookup` based on your current system. This is useful for having just
*one* `config.rkt` which will work across all your platforms.


Installation
---

**On any platform, first:**
Install [Racket](https://racket-lang.org/) and clone this project into
your home directory (or anywhere you'd like, really)...

```
git clone https://github.com/tonyfischetti/starlight.git ~/starlight
```

Then make the appropriate files in a directory called `.starlight` in your
home folder. To do it most easily, run
```
git clone https://github.com/tonyfischetti/starlight-config.git ~/.starlight
```
and make the configuration file (`config.rkt`) your own! That directory
also holds a tiny `loader.rkt` that tells Starlight where the config
lives; it must exist before you start (or build) Starlight.

**If you're using a mac**
With racket you can build a standalone `Starlight.app` that contains
a racket interpreter (and a cute dinosaur icon apropos of nothing).
From the repository, run
```
./make-mac-app.sh
```
which leaves the app in `./mac-app/Starlight.app`. Drag that into your
/Applications/ folder. You can have it start up every time you log in by
going to "System Settings -> General -> Login Items" and adding "Starlight".
Starlight handles Spaces itself, so don't assign it to "All Desktops" in
the Dock; that binding excludes full-screen Spaces and overrides the app's
own settings.

Then assign a keyboard shortcut to the command
`curl "http://localhost:9876"` which will be able to bring up (or tear down)
the launcher. I suggest
[ICanHazShortcut](https://github.com/deseven/icanhazshortcut) which is
delightfully easy to use. I like to map the `curl` command to
Shift+Backspace.


**If you don't have a mac**
*These directions work on a Mac, too, if you'd rather not build the app*
To start the Starlight "server", run the `start-starlight.sh` shell script
in this repository. (It assumes the repository lives at `~/starlight` and
that the Racket bin directory is in your PATH.) Alternatively, you can
just run `racket -e '(enter! "starlight.rkt")' &` from the repository
directory. You may want to run this command at startup so you don't have
to remember to start the server every time you restart your computer.

Finally, assign a keyboard shortcut to the command
`curl "http://localhost:9876"` which will be able to bring up (or tear down)
the launcher.


FAQ
---
_Is Starlight for everyone?_

I'd like anyone who is interested to look into it but Starlight is certainly
not for everybody. Its power is (strictly speaking) unnecessary. Starlight
is probably best suited for use among Lisp hackers. Given that impractical
Lisp hackers tend to write practical solutions to all their problems
themselves, I predict no one but me will be using this. If you do, dear reader,
let me know :)


