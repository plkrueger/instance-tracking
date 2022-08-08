;; instance-tracking.lisp

#|
The MIT license.

Copyright (c) 2022 Paul L. Krueger

Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
and associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

|#

#|
Users of systems other than CCL and SBCL should modify the defpackage form to use whatever package contains
calls for the common-lisp meta-object protocol (MOP).

This version of instance-tracking is thread-safe. Tracked instances may be created in any thread without
worrying about damage to tracking values that are kept in class-slots.
|#

(defpackage :pk-inst-track
  (:use 
   #+ccl :ccl
   #+sbcl :sb-mop
   :common-lisp)
  (:export
   instance-tracking
   instance-tracking-classes
   instances-of
   untrack-all-instances
   untrack-instance))

(in-package :pk-inst-track)

;; Global variables
(defvar it-lock (bt::make-lock))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; instance-tracking
;;
;; defines a class that tracks all instances of itself
;; Intended to be inherited by other classes to provide this ability

(defclass inst-track ()
  ())

(defclass instance-tracking (standard-class)
  ;; the :metaclass argument that should be used when defining a class to 
  ;; be instance-tracking
  ((class-instances :accessor class-instances
                    :initform nil
                    :allocation :class)))

(defmethod initialize-instance :after ((class instance-tracking) &key &allow-other-keys)
  ;; collect all instances of instance-tracking classes
  (bt::with-lock-held (it-lock)
    (pushnew class (class-instances class))))

(defun instance-tracking-classes ()
  (class-instances (class-prototype (find-class 'instance-tracking))))

(defmethod validate-superclass ((class instance-tracking) (superclass standard-class))
  t)

(defmethod ensure-class-using-class :around (class class-name
                                             &key
                                             direct-default-initargs
                                             direct-slots
                                             direct-superclasses
                                             name
                                             metaclass)
  (if (eq metaclass 'instance-tracking)
      (call-next-method class class-name 
                    :direct-default-initargs direct-default-initargs
                    :direct-slots (cons (list :NAME 'INSTANCES
                                              :INITFORM 'NIL 
                                              :INITFUNCTION (CONSTANTLY NIL)
                                              :READERS '(INSTANCES)
                                              :WRITERS '((SETF INSTANCES))
                                              :ALLOCATION ':CLASS)
                                        direct-slots)
                    :direct-superclasses (cons 'inst-track direct-superclasses)
                    :name name
                    :metaclass metaclass)
      (call-next-method)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; inst-track methods

(defmethod initialize-instance :after ((self inst-track) &key &allow-other-keys)
  (bt::with-lock-held (it-lock)
    (push self (instances self))))

(defmethod untrack-instance ((self inst-track))
  (bt::with-lock-held (it-lock)
    (setf (instances self)
          (delete self (instances self))))
  nil)

(defmethod untrack-all-instances ((class instance-tracking))
  (bt::with-lock-held (it-lock)
    (setf (instances (class-prototype class)) nil)))

(defmethod instances-of ((class instance-tracking))
  (instances (class-prototype class)))

(defmethod instances-of ((obj inst-track))
  (instances-of (class-of obj)))

(defmethod instances-of ((class symbol))
  (instances-of (find-class class nil)))

(defmethod instances-of ((class string))
  (instances-of (read-from-string class nil nil)))

(defmethod instances-of (something-else)
  (declare (ignore something-else))
  nil)

(defmethod instances-of ((x null))
  nil)

;;;;;;;;;;;  test stuff
#|
(defclass tst ()
  ((tst-slot1 :accessor tst-slot1
              :initform nil)
   (tst-slot2 :accessor tst-slot2
              :initform nil
              :allocation :class))
  (:metaclass instance-tracking))

(defun test-inst-track ()
  (let ((i1 (make-instance 'tst))
        (i2 (make-instance 'tst)))
    (setf (tst-slot1 i1) 1)
    (setf (tst-slot2 i2) 2)
    (format t "~%Instances: ~s" (instances-of 'tst))
    (untrack-instance i1)
    (format t "~%Instances: ~s" (instances-of 'tst))
    (untrack-instance i2)
    (format t "~%Instances: ~s" (instances-of 'tst))))
  
|#