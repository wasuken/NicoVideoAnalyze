;; (require \'asdf)

(in-package :cl-user)
(defpackage NicoVideoAnalyze-test-asd
  (:use :cl :asdf))
(in-package :NicoVideoAnalyze-test-asd)

(defsystem NicoVideoAnalyze-test
    :depends-on (:NicoVideoAnalyze)
    :version "1.0.0"
    :author "wasu"
    :license "MIT"
    :components ((:module "t" :components ((:file "NicoVideoAnalyze-test"))))
    :perform (test-op :after (op c)
                      (funcall (intern #.(string :run) :prove) c)))

