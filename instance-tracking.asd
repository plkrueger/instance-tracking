(asdf:defsystem #:instance-tracking
  :name "instance-tracking"
  :author "plkrueger"
  :maintainer "plkrueger"
  :licence "MIT"
  :description "Defines a class that tracks its instances"
  :depends-on (:bordeaux-threads)
  :components ((:file "instance-tracking")))