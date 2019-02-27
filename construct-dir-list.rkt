

(define (construct-dir-list apath)
  (map (lambda (path) 
         (list (string->symbol (path->string path)) 
               `(begin (reset-top-level-lookup) (exec ,(string-append "\"open " (path->string (path->complete-path path apath)) "\""))) ))
       (directory-list apath)))


(construct-dir-list (current-directory))
