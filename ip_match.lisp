;;;; IP地址匹配。为客响中心开发。

(defun ipmask-to-iprange (ipexp)
  (let* ((parts (ztl:split ipexp "/"))
         (ip (car parts))
         (ipsegs (ztl:split ip "\\."))
         (s4 (parse-integer (fourth ipsegs)))
         (bs (cadr parts))
         (netbits (parse-integer bs))
         (ipbits (- 32 netbits))
         (cnt (expt 2 ipbits))
         (lastip (1- (+ s4 cnt)))
         (newexp (concatenate 'string ip "-" (prin1-to-string lastip))))
    ;(format t "~s: ~s, ~s, ~s, ~s, ~s, ~s, ~s, ~s~%" ipexp ip netbits ipbits cnt ipsegs s4 lastip newexp)
    newexp))

(defun iptrans ()
  (with-open-file (ist "/pub/ip-in.txt")
    (with-open-file (ost "/pub/ip-out.txt" :if-does-not-exist :create :if-exists :supersede :direction :output)
      (do ((s (read-line ist)
              (read-line ist nil 'eof)))
          ((eq s 'eof) "<EOF>")
        (format ost "~{~a~^ ~}~%" (mapcar #'ipmask-to-iprange (ztl:split s " ")))))))

(defun ip-to-num (doted-ip)
  (reduce (lambda (a b)
            (+ (* a 256) b))
          (mapcar #'parse-integer (ztl:split doted-ip "\\."))))

(defun ip-to-num-t (doted-ip)
  (let ((n 0)
        (m 0)
        (c0 (- (char-code #\0))))
    (loop for c across doted-ip do
      (cond ((char= c #\.) 
             (setf n (+ (* n 256) m)
                   m 0))
            (t (setf m (+ (* m 10)
                         (char-code c)
                         c0)))))
    (+ (* n 256) m)))

(defun ip-parse-range (iprg)
  (let ((b (ztl::split iprg "-")))
    (cons (ip-to-num (first b))
          (ip-to-num (second b)))))

(defun ip-parse-line (ln)
  (format t "~s~%" ln)
  (let* ((parts (ztl:split ln "\\t"))
         (ipsegs (ztl:split (ztl:nvl (second parts) "")))
         (ranges (mapcar #'ip-parse-range ipsegs)))
    (list ranges (car parts) ln)))

(defun ip-load-targets (fname)
  (format t "~s~%" fname)
  (mapcar #'ip-parse-line (ztl:readlines fname)))

(defun range-in (a b)
  "a, b must be doted cons cell and X.car <= X.cdr"
  (and (>= (car a) (car b))
       (<= (cdr a) (cdr b))))

(defun ip-seg-match (sfilename tfilename ofilename)
  (let* ((sources (ip-load-targets sfilename))
         (targets (ip-load-targets tfilename))
         (results (mapcar (lambda (src)
                            (third (find src targets
                                         :test (lambda (ss tt)
                                                 (let ((sranges (car ss))
                                                       (tranges (car tt)))
                                                   (every (lambda (sr)
                                                            (some (lambda (tr)
                                                                    (range-in sr tr))
                                                                  tranges))
                                                          sranges))))))
                          sources)))
    (with-open-file (ost ofilename :direction :output
                                   :if-does-not-exist :create
                                   :if-exists :supersede)
      (dolist (e results)
        (format ost "~a~%" e)))))
