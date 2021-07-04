(load "staged-load.scm")

;; Adapted from Matt Might's code for parsing with derivatives.

(define (parse body-expr)
  `(letrec ((regex-NULL (lambda () #f)))
     (letrec ((regex-BLANK (lambda () #t)))
       (letrec ((regex-alt?
                 (lambda (re) (and (pair? re) (equal? (car re) 'alt)))))
         (letrec ((regex-seq?
                   (lambda (re) (and (pair? re) (equal? (car re) 'seq)))))
           (letrec ((regex-rep?
                     (lambda (re) (and (pair? re) (equal? (car re) 'rep)))))
             (letrec ((regex-null? (lambda (re) (equal? re #f))))
               (letrec ((regex-empty? (lambda (re) (equal? re #t))))
                 (letrec ((regex-atom? (lambda (re) (symbol? re))))
                   (letrec ((match-seq
                             (lambda (re f)
                               (and (regex-seq? re)
                                    (f (car (cdr re)) (car (cdr (cdr re))))))))
                     (letrec ((match-alt
                               (lambda (re f)
                                 (and (regex-alt? re)
                                      (f (car (cdr re)) (car (cdr (cdr re))))))))
                       (letrec ((match-rep
                                 (lambda (re f)
                                   (and (regex-rep? re) (f (car (cdr re)))))))
                         (letrec ((seq
                                   (lambda (pat1 pat2)
                                     (if (regex-null? pat1)
                                         (regex-NULL)
                                         (if (regex-null? pat2)
                                             (regex-NULL)
                                             (if (regex-empty? pat1)
                                                 pat2
                                                 (if (regex-empty? pat2)
                                                     pat1
                                                     (list 'seq pat1 pat2))))))))
                           (letrec ((alt
                                     (lambda (pat1 pat2)
                                       (if (regex-null? pat1)
                                           pat2
                                           (if (regex-null? pat2)
                                               pat1
                                               (list 'alt pat1 pat2))))))
                             (letrec ((rep
                                       (lambda (pat)
                                         (if (regex-null? pat)
                                             (regex-BLANK)
                                             (if (regex-empty? pat)
                                                 (regex-BLANK)
                                                 (list 'rep pat))))))
                               (letrec ((regex-empty
                                         (lambda (re)
                                           (if (regex-empty? re)
                                               #t
                                               (if (regex-null? re)
                                                   #f
                                                   (if (regex-atom? re)
                                                       #f
                                                       (or (match-seq
                                                            re
                                                            (lambda (pat1 pat2)
                                                              (seq
                                                               (regex-empty pat1)
                                                               (regex-empty pat2))))
                                                           (match-alt
                                                            re
                                                            (lambda (pat1 pat2)
                                                              (alt
                                                               (regex-empty pat1)
                                                               (regex-empty pat2))))
                                                           (if (regex-rep? re)
                                                               #t
                                                               #f))))))))
                                 (letrec ((d/dc
                                           (lambda (re c)
                                             (if (regex-empty? re)
                                                 (regex-NULL)
                                                 (if (regex-null? re)
                                                     (regex-NULL)
                                                     (if (equal? c re)
                                                         (regex-BLANK)
                                                         (if (regex-atom? re)
                                                             (regex-NULL)
                                                             (or (match-seq
                                                                  re
                                                                  (lambda (pat1 pat2)
                                                                    (alt
                                                                     (seq
                                                                      (d/dc pat1 c)
                                                                      pat2)
                                                                     (seq
                                                                      (regex-empty pat1)
                                                                      (d/dc pat2 c)))))
                                                                 (match-alt
                                                                  re
                                                                  (lambda (pat1 pat2)
                                                                    (alt
                                                                     (d/dc pat1 c)
                                                                     (d/dc pat2 c))))
                                                                 (match-rep
                                                                  re
                                                                  (lambda (pat)
                                                                    (seq
                                                                     (d/dc pat c)
                                                                     (rep pat))))
                                                                 (regex-NULL)))))))))
                                   (letrec ((regex-match
                                             (lambda (pattern data)
                                               (if (null? data)
                                                   (regex-empty?
                                                    (regex-empty pattern))
                                                   (regex-match
                                                    (d/dc pattern (car data))
                                                    (cdr data))))))

                                     ,body-expr

                                     ))))))))))))))))))

(define-staged-relation (parseo body-expr parse-result)
  (evalo-staged
   (parse body-expr)
   parse-result))



(record-bench 'staged 'parse-0)
(time-test
  (run #f (parse-result)
    (parseo '(d/dc 'baz 'f) parse-result))
  '(#f))

(record-bench 'run-staged 'parse-0)
(time-test
  (run-staged #f (parse-result)
    (evalo-staged
      (parse '(d/dc 'baz 'f))
      parse-result))
  '(#f))

(record-bench 'unstaged 'parse-0)
(time-test
  (run #f (parse-result)
    (evalo-unstaged
      (parse '(d/dc 'baz 'f))
      parse-result))
  '(#f))



(record-bench 'staged 'parse-1)
(time-test
  (run #f (parse-result)
    (parseo '(d/dc '(seq foo barn) 'foo) parse-result))
  '(barn))

(record-bench 'run-staged 'parse-1)
(time-test
  (run-staged #f (parse-result)
    (evalo-staged
      (parse '(d/dc '(seq foo barn) 'foo))
      parse-result))
  '(barn))

(record-bench 'unstaged 'parse-1)
(time-test
  (run #f (parse-result)
    (evalo-unstaged
      (parse '(d/dc '(seq foo barn) 'foo))
      parse-result))
  '(barn))




(record-bench 'staged 'parse-2)
(time-test
  (run #f (parse-result)
    (parseo '(d/dc '(alt (seq foo bar) (seq foo (rep baz))) 'foo) parse-result))
  '((alt bar (rep baz))))

(record-bench 'run-staged 'parse-2)
(time-test
  (run-staged #f (parse-result)
    (evalo-staged
      (parse '(d/dc '(alt (seq foo bar) (seq foo (rep baz))) 'foo))
      parse-result))
  '((alt bar (rep baz))))

(record-bench 'unstaged 'parse-2)
(time-test
  (run #f (parse-result)
    (evalo-unstaged
      (parse '(d/dc '(alt (seq foo bar) (seq foo (rep baz))) 'foo))
      parse-result))
  '((alt bar (rep baz))))




(record-bench 'staged 'parse-3)
(time-test
  (run 1 (parse-result)
    (parseo '(regex-match '(seq foo (rep bar)) 
                          '(foo bar bar bar))
            parse-result))
  '(#t))

(record-bench 'run-staged 'parse-3)
(time-test
  (run-staged #f (parse-result)
    (evalo-staged
     (parse '(regex-match '(seq foo (rep bar)) 
                          '(foo bar bar bar)))
     parse-result))
  '(#t))

(record-bench 'unstaged 'parse-3)
(time-test
  (run #f (parse-result)
    (evalo-unstaged
      (parse '(regex-match '(seq foo (rep bar)) 
                           '(foo bar bar bar)))
      parse-result))
  '(#t))



(record-bench 'staged 'parse-4)
(time-test
  (run 1 (parse-result)
    (parseo '(regex-match '(seq foo (rep bar)) 
                          '(foo bar baz bar bar))
            parse-result))
  '(#f))

(record-bench 'run-staged 'parse-4)
(time-test
  (run-staged #f (parse-result)
    (evalo-staged
     (parse '(regex-match '(seq foo (rep bar)) 
                          '(foo bar baz bar bar)))
     parse-result))
  '(#f))

(record-bench 'unstaged 'parse-4)
(time-test
  (run #f (parse-result)
    (evalo-unstaged
      (parse '(regex-match '(seq foo (rep bar)) 
                          '(foo bar baz bar bar)))
      parse-result))
  '(#f))




(record-bench 'staged 'parse-5)
(time-test
  (run 1 (parse-result)
    (parseo '(regex-match '(seq foo (rep (alt bar baz))) 
                          '(foo bar baz bar bar))
            parse-result))
  '(#t))

(record-bench 'run-staged 'parse-5)
(time-test
  (run-staged #f (parse-result)
    (evalo-staged
     (parse '(regex-match '(seq foo (rep (alt bar baz))) 
                          '(foo bar baz bar bar)))
     parse-result))
  '(#t))

(record-bench 'unstaged 'parse-4)
(time-test
  (run #f (parse-result)
    (evalo-unstaged
     (parse '(regex-match '(seq foo (rep (alt bar baz))) 
                          '(foo bar baz bar bar)))
      parse-result))
  '(#t))
