(load "staged-load.scm")

;; Adapted from the nnf code in 'The Semantic Web Explained' by Péter
;; Szeredi, Gergely Lukácsy, and Tamás Benkő. Cambridge University
;; Press, 2014.
(define nnf
  (lambda (concept)
    `(letrec ((number?
               (lambda (n)
                 (match n
                   [`z #t]
                   [`(s . ,n-1)
                    (number? n-1)]
                   [else #f]))))
       (letrec ((positive?
                 (lambda (n)
                   (match n
                     [`z #f]
                     [`(s . ,n-1) #t]))))
         (letrec ((add1
                   (lambda (n)
                     (cons 's n))))
           (letrec ((sub1
                     (lambda (n)
                       (match n
                         [`(s . ,n-1) n-1]))))
             (letrec ((concept?
                       (lambda (c)
                         (match c
                           [`Top #t]
                           [`,(? symbol? concept-name)
                            #t]
                           [`(Not ,c) (concept? c)]
                           [`(And ,c1 ,c2)
                            (and (concept? c1) (concept? c1))]
                           [`(Or ,c1 ,c2)
                            (and (concept? c1) (concept? c1))]
                           [`(Exists ,(? symbol? r) ,c)
                            (concept? c)]
                           [`(All ,(? symbol? r) ,c)
                            (concept? c)]
                           [`(AtLeast ,k ,(? symbol? r))
                            (number? k)]
                           [`(AtMost ,k ,(? symbol? r))
                            (number? k)]
                           [else #f]))))
               (letrec ((nnf
                         (lambda (concept)
                           (match concept
                             [`(Not (Not ,c)) (nnf c)]
                             [`(Not (And ,c1 ,c2))
                              (list 'Or (nnf (list 'Not c1)) (nnf (list 'Not c2)))]
                             [`(Not (Or ,c1 ,c2))
                              (list 'And (nnf (list 'Not c1)) (nnf (list 'Not c2)))]
                             [`(Not (Exists ,(? symbol? r) ,c))
                              (list 'All r (nnf (list 'Not c)))]
                             [`(Not (All ,(? symbol? r) ,c))
                              (list 'Exists r (nnf (list 'Not c)))]
                             [`(Not (AtMost ,k ,(? symbol? r)))
                              (list 'AtLeast (add1 k) r)]
                             [`(Not (AtLeast ,k ,(? symbol? r)))
                              (if (positive? k)
                                  (list 'AtMost (sub1 k) r)
                                  (list 'Not 'Top))]    
                             [`(And ,c1 ,c2)
                              (list 'And (nnf c1) (nnf c2))]
                             [`(Or ,c1 ,c2)
                              (list 'Or (nnf c1) (nnf c2))]
                             [`(Exists ,(? symbol? r) ,c)
                              (list 'Exists r (nnf c))]
                             [`(All ,(? symbol? r) ,c)
                              (list 'All r (nnf c))]
                             [concept
                              (if (concept? concept)
                                  concept
                                  ;; simulate an error
                                  (car '())
                                  ;; #f ;; really an error
                                  )]))))
                 (nnf ',concept)))))))))

(record-bench 'staging 'nnf)
(define-staged-relation (nnfo concept nnf-concept)
  (evalo-staged
   (nnf concept)
   nnf-concept))

(record-bench 'staged 'nnf 0)
(time-test
  (run 10 (concept)
    (nnfo concept '(Not Top)))
  '((Not Top) (Not (Not (Not Top)))
  ((Not (AtLeast z _.0))
    $$
    (=/= ((_.0 call))
         ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not Top)))))
  ((Not (Not (Not (AtLeast z _.0))))
    $$
    (=/= ((_.0 call))
         ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not (Not (Not Top)))))))
  ((Not (Not (Not (Not (Not (AtLeast z _.0))))))
    $$
    (=/= ((_.0 call))
         ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))
  ((Not (Not (Not (Not (Not (Not (Not (AtLeast z _.0))))))))
    $$
    (=/= ((_.0 call))
         ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))))))

(record-bench 'unstaged 'nnf 0)
(time-test
  (run 10 (concept)
    (evalo-unstaged
     (nnf concept)
     '(Not Top)))
  '((Not Top)
    (Not (Not (Not Top)))
    (Not (Not (Not (Not (Not Top)))))
    (Not (Not (Not (Not (Not (Not (Not Top)))))))
    (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))
    (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))))
    ((Not (AtLeast z _.0))
     $$
     (=/= ((_.0 call)) ((_.0 call-code)) ((_.0 closure)) ((_.0 dynamic)) ((_.0 prim)))
     (sym _.0))
    (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))))))
    ((Not (Not (Not (AtLeast z _.0))))
     $$
     (=/= ((_.0 call)) ((_.0 call-code)) ((_.0 closure)) ((_.0 dynamic)) ((_.0 prim)))
     (sym _.0))
    (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))))))))))

;; Note the difference in order w.r.t. the unstaged version.
(record-bench 'run-staged 'nnf 0)
(time-test
  (run-staged 10 (concept)
    (evalo-staged
     (nnf concept)
     '(Not Top)))
  '((Not Top) (Not (Not (Not Top)))
  ((Not (AtLeast z _.0))
    $$
    (=/= ((_.0 call)) ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not Top)))))
  ((Not (Not (Not (AtLeast z _.0))))
    $$
    (=/= ((_.0 call)) ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not (Not (Not Top)))))))
  ((Not (Not (Not (Not (Not (AtLeast z _.0))))))
    $$
    (=/= ((_.0 call)) ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))
  ((Not (Not (Not (Not (Not (Not (Not (AtLeast z _.0))))))))
    $$
    (=/= ((_.0 call)) ((_.0 call-code))
         ((_.0 closure))
         ((_.0 dynamic))
         ((_.0 prim)))
    (sym _.0))
  (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not (Not Top)))))))))))))



(record-bench 'unstaged 'nnf 1)
(time-test
  (run* (nnf-concept)
    (evalo-unstaged
     (nnf '(Not (AtLeast z hasChild)))
     nnf-concept))
  '((Not Top)))

(record-bench 'run-staged 'nnf 1)
(time-test
  (run-staged #f (nnf-concept)
    (evalo-staged
     (nnf '(Not (AtLeast z hasChild)))
     nnf-concept))
  '((Not Top)))

(record-bench 'staged 'nnf 1)
(time-test
  (run* (nnf-concept)
    (nnfo '(Not (AtLeast z hasChild)) nnf-concept))
  '((Not Top)))


(record-bench 'unstaged 'nnf 2)
(time-test
  (run* (nnf-concept)
    (evalo-unstaged
     (nnf '(Not (AtMost (s . z) hasChild)))
     nnf-concept))
  '((AtLeast (s s . z) hasChild)))


(record-bench 'run-staged 'nnf 2)
(time-test
  (run-staged #f (nnf-concept)
    (evalo-staged
     (nnf '(Not (AtMost (s . z) hasChild)))
     nnf-concept))
  '((AtLeast (s s . z) hasChild)))

(record-bench 'staged 'nnf 2)
(time-test
  (run* (nnf-concept)
    (nnfo '(Not (AtMost (s . z) hasChild)) nnf-concept))
  '((AtLeast (s s . z) hasChild)))


(record-bench 'unstaged 'nnf 3)
(time-test
  (run* (nnf-concept)
    (evalo-unstaged
     (nnf '(Not (AtLeast (s s s . z) hasChild)))
     nnf-concept))
  '((AtMost (s s . z) hasChild)))

(record-bench 'run-staged 'nnf 3)
(time-test
  (run-staged #f (nnf-concept)
    (evalo-staged
     (nnf '(Not (AtLeast (s s s . z) hasChild))) nnf-concept))
  '((AtMost (s s . z) hasChild)))

(record-bench 'staged 'nnf 3)
(time-test
  (run* (nnf-concept)
    (nnfo '(Not (AtLeast (s s s . z) hasChild)) nnf-concept))
  '((AtMost (s s . z) hasChild)))
