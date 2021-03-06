;;; -*- Syntax: ansi-common-lisp; Base: 10; Package: http; Mode: LISP -*-

;;; (C) Copyright 1994-97, John C. Mallery.
;;;     All Rights Reserved.
;;;
;;;------------------------------------------------------------------- 
;;;
;;; LISPM CLIENT SUPPORT 
;;;

(eval-when (compile eval load)
  (mapc #'(lambda (x)
            (let* ((pname (symbol-name x))
                   (sym (scl:intern-local-soft pname :www-utils)))
              (when sym (unintern sym :www-utils))
              (import x :www-utils)
              (export x :www-utils)))
        '(images:read-image images:show-image)))

(defmethod display ((http-url url:http-url) (major-type (eql :image)) (minor-type (eql :gif)) remote-stream out-stream)
  (with-binary-stream (remote-stream :input)
    (let ((image (images::read-image (url:name-string http-url) :gif remote-stream)))
      (images::show-image image :stream out-stream))))

(defmethod display ((http-url url:http-url) (major-type (eql :image)) (minor-type (eql :x-xbitmap)) remote-stream out-stream
                    &aux image)
  (flet ((read-client-line (&optional stream (eof-errorp t) eof-value recursive-p)
	   (declare (ignore eof-errorp recursive-p))
	   (read-delimited-line stream `(#\Return #\Linefeed) eof-value *client-line-buffer*)))
    (scl:letf ((#'lisp:read-line #'read-client-line))
      (setq image (images::read-image (url:name-string http-url) :xbm remote-stream))
      (images::show-image image :stream out-stream))))

;; this could be made better looking JCMa
(defun %get-user-name+pw (url-string realm method proxy-p &optional (stream *query-io*) user-name password)
  (declare (values user-name password))
  (flet ((proxy-string (url-string)
	   (let ((proxy (get-client-proxy url-string)))
	     (if proxy
		 (format nil "~A:~D" (proxy-domain-name proxy) (proxy-port proxy))
		 (format nil "Client associates no proxy with ~S." url-string)))))
    (loop with proxy-string = (and proxy-p (proxy-string url-string))
	  doing (dw:accepting-values 
		  (stream :own-window t
			  :label (format nil "      ~'bUser Name & Password~"))
		  (if proxy-string
		      (dw:redisplayable-format stream "      ~vConnect to Proxy~~2%~'bProxy:     ~A~" '(nil :bold :larger) proxy-string)
		      (dw:redisplayable-format stream "      ~vConnect to Server~~2%~'bURI:       ~A~" '(nil :bold :larger) url-string))
		  (dw:redisplayable-format stream "~'b~%User Name: ~")
		  (setq user-name (scl:accept 'scl:string :prompt nil :prompt-mode :raw :default user-name :query-identifier 1 :stream stream))
		  (dw:redisplayable-format stream "~'bPassword:~  ")
		  (setq password (scl:accept 'scl:string :prompt nil :prompt-mode :raw :default password :history nil :query-identifier 2 :stream stream))
		  (dw:redisplayable-format stream "~'bRealm:     ~:(~A~)~%Scheme:    ~:(~A~) Authentication~~%" realm method))
	  until (and user-name password)
	  finally (return (values user-name password)))))


;;;------------------------------------------------------------------- 
;;;
;;; LISPM COMMANDS
;;;

(scl:define-presentation-type user::uniform-resource-locator
      ()
   :expander 'scl:string
   :history t
   :description "a uniform resource locator")

(declaim (special *client-http-version*))

(cp:define-command (com-show-url :command-table "user")
    ((url 'user::uniform-resource-locator :prompt "URL")
     &key (format '(scl:member :headers :options :raw :standard :trace) :prompt "Format" :default :standard)
     (max-forwards '(scl:integer 0) :prompt "Max Forwards" :default 5 :when (eql :trace format))
     (version '(scl:member :http/1.0 :http/1.1) :default *client-http-version*
              :when (member format '(:headers :raw :standard)))
     (start '(scl:integer 0) :prompt "Start Byte" :when (eql :raw format))
     (end '(scl:integer 0) :prompt "End Byte" :when (eql :raw format)))
   (let ((*client-http-version* version))
     (ecase format
       (:headers (show-url-headers url :stream *standard-output*))
       (:options (show-url-options url :stream *standard-output*))
       (:raw (show-raw-url url :stream *standard-output* :start start :end end))
       (:standard (show-url url :stream *standard-output*))
       (:trace (show-url-trace url :max-forwards max-forwards :stream *standard-output*)))))

(cp:define-command (com-delete-url :command-table "user")
    ((url 'user::uniform-resource-locator :prompt "URL")
     &key (version '(scl:member :http/1.0 :http/1.1) :default *client-http-version*)
     (confirm 'scl:boolean :prompt "Confirm" :default t :mentioned-default nil))
   (when (or (null confirm) (y-or-n-p "Delete ~S? " url))
     (let ((*client-http-version* version))
       (delete-url url :stream *standard-output*))))

(cp:define-command (com-put-url :command-table "user")
    ((url 'user::uniform-resource-locator :prompt "URL")
     (pathname 'fs:pathname :prompt "Pathname")
     &key (source '(scl:member :file :buffer) :prompt "Source" :default :file)
     (version '(scl:member :http/1.0 :http/1.1) :default *client-http-version*))
   (let ((*client-http-version* version))
     (ecase source
       (:file
         (put-url url pathname :stream *standard-output*))
       (:buffer
         (zwei:with-editor-stream (stream :pathname pathname)
           (put-url url #'(lambda (s)
                            (stream-copy-until-eof stream s :text))
                    :stream *standard-output*))))))
