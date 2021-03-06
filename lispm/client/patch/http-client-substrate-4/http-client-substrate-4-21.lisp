;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: USER; Base: 10; Patch-File: t -*-
;;; Patch file for HTTP-CLIENT-SUBSTRATE version 4.21
;;; Reason: Function (CLOS:METHOD HTTP::SNAPSHOT-LOG-ENTRY (HTTP::COMMON-FILE-FORMAT-MIXIN HTTP::CLIENT-LOGGING-MIXIN)):  update to capture bytes transmitted
;;; Move client proxy code into its own file.
;;; Written by JCMa, 11/06/01 15:27:31
;;; while running on FUJI-VLM from FUJI:/usr/lib/symbolics/ComLink-39-8-F-MIT-8-5.vlod
;;; with Open Genera 2.0, Genera 8.5, Lock Simple 437.0, Version Control 405.0,
;;; Compare Merge 404.0, VC Documentation 401.0,
;;; Logical Pathnames Translation Files NEWEST, CLIM 72.0, Genera CLIM 72.0,
;;; PostScript CLIM 72.0, MAC 414.0, 8-5-Patches 2.19, Statice Runtime 466.1,
;;; Statice 466.0, Statice Browser 466.0, Statice Documentation 426.0, Joshua 237.6,
;;; CLIM Documentation 72.0, Showable Procedures 36.3, Binary Tree 34.0,
;;; Mailer 438.0, Working LispM Mailer 8.0, HTTP Server 70.154,
;;; W3 Presentation System 8.1, CL-HTTP Server Interface 53.0,
;;; Symbolics Common Lisp Compatibility 4.0, Comlink Packages 6.0,
;;; Comlink Utilities 10.4, COMLINK Cryptography 2.0, Routing Taxonomy 9.0,
;;; COMLINK Database 11.26, Email Servers 12.0, Comlink Customized LispM Mailer 7.1,
;;; Dynamic Forms 14.5, Communications Linker Server 39.8,
;;; Lambda Information Retrieval System 22.5, Jcma 44,
;;; Experimental Genera 8 5 Patches 1.0, Genera 8 5 System Patches 1.39,
;;; Genera 8 5 Mailer Patches 1.1, Genera 8 5 Joshua Patches 1.0,
;;; Genera 8 5 Statice Runtime Patches 1.0, Genera 8 5 Statice Patches 1.0,
;;; Genera 8 5 Statice Server Patches 1.0,
;;; Genera 8 5 Statice Documentation Patches 1.0, Genera 8 5 Clim Patches 1.3,
;;; Genera 8 5 Genera Clim Patches 1.0, Genera 8 5 Postscript Clim Patches 1.0,
;;; Genera 8 5 Clim Doc Patches 1.0, Genera 8 5 Lock Simple Patches 1.0,
;;; HTTP Proxy Server 6.27, HTTP Client Substrate 4.20, Statice Server 466.2,
;;; Ivory Revision 5, VLM Debugger 329, Genera program 8.16,
;;; DEC OSF/1 V4.0 (Rev. 110),
;;; 1280x994 8-bit PSEUDO-COLOR X Screen FUJI:0.0 with 224 Genera fonts (DECWINDOWS Digital Equipment Corporation Digital UNIX V4.0 R1),
;;; Machine serial number -2141189585,
;;; Domain Fixes (from CML:MAILER;DOMAIN-FIXES.LISP.33),
;;; Don't force in the mail-x host (from CML:MAILER;MAILBOX-FORMAT.LISP.24),
;;; Make Mailer More Robust (from CML:MAILER;MAILER-FIXES.LISP.15),
;;; Patch TCP hang on close when client drops connection. (from HTTP:LISPM;SERVER;TCP-PATCH-HANG-ON-CLOSE.LISP.10),
;;; Add CLIM presentation and text style format directives. (from FV:SCLC;FORMAT.LISP.20),
;;; Fix Statice Lossage (from CML:LISPM;STATICE-PATCH.LISP.3),
;;; Make update schema work on set-value attributes with accessor names (from CML:LISPM;STATICE-SET-VALUED-UPDATE.LISP.1),
;;; COMLINK Mailer Patches. (from CML:LISPM;MAILER-PATCH.LISP.107),
;;; Clim patches (from CML:DYNAMIC-FORMS;CLIM-PATCHES.LISP.48),
;;; Domain ad host patch (from W:>reti>domain-ad-host-patch.lisp.21),
;;; Background dns refreshing (from W:>reti>background-dns-refreshing.lisp.11),
;;; Cname level patch (from W:>Reti>cname-level-patch.lisp.10),
;;; Fix FTP Directory List for Periods in Directory Names (from W:>Reti>fix-ftp-directory-list.lisp.7),
;;; TCP-FTP-PARSE-REPLY signal a type error when control connection lost. (from W:>Reti>tcp-ftp-parse-reply-patch.lisp.1).



(SCT:FILES-PATCHED-IN-THIS-PATCH-FILE 
  "HTTP:CLIENT;CLIENT.LISP.292")


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:CLIENT;CLIENT.LISP.292")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: http -*-")

(defmethod snapshot-log-entry ((log common-file-format-mixin) (client client-logging-mixin))
   (let ((host-name (if *server* (server-host-domain-name *server*) (client-host-domain-name client)))
	   (request (client-request client))	; don't lose when transaction reset
	   (request-time (client-request-time client))
           (method (client-method client))
	   (status (client-status client))
	   (bytes-received (client-bytes-received client))	;total bytes
           (bytes-transmitted (client-bytes-transmitted client)))
      (allocate-common-log-entry log host-name request request-time method status bytes-received bytes-transmitted nil)))


;========================
(SCT:BEGIN-PATCH-SECTION)
; From buffer proxy.lisp >http>client W: (2)
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: http -*-")

(PROGN
;;;-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: http -*-

;;; (C) Copyright 2000-2001, John C. Mallery
;;;     All Rights Reserved.
;;;
;;;------------------------------------------------------------------- 
;;;
;;; CL-HTTP CLIENT UPSTREAM PROXY FACILITIES
;;;

(in-package :http)

(defclass proxy () () (:documentation "Any proxy object."))

(defclass basic-proxy-mixin
   (proxy property-list-mixin)
   ((protocols :initform nil :initarg :protocols :accessor proxy-protocols)
     (host :initform nil :initarg :host :accessor proxy-host)
     (port :initform nil :initarg :port :accessor proxy-port)
     (domain-name :initform nil :initarg :domain-name :accessor proxy-domain-name))) 

(defclass proxy-authentication-mixin
	  ()
    ((authentication-method :initform nil :initarg :authentication-method :accessor proxy-authentication-method)
     (authentication-header :initform nil :initarg :authentication-header :accessor proxy-authentication-header)))

(defclass http-proxy
	  (proxy-authentication-mixin basic-proxy-mixin)
    ()
  (:documentation "HTTP Proxy object.")) 

(defclass null-proxy-mixin (proxy) ()) 

(defclass null-proxy
   (null-proxy-mixin)
   ()
   (:documentation "The null Proxy object."))

(defstruct proxy-control
  (protocol nil :type keyword)
  (standard-proxy nil :type proxy)
  (port-proxy nil :type list)
  (url-table nil)
  (next-protocol nil :type (or null proxy-control)))

(defmethod print-object ((proxy basic-proxy-mixin) stream)
  (print-unreadable-object (proxy stream :type t :identity t)
    (let ((domain-name (proxy-domain-name proxy)))
      (when domain-name
        (format stream "~A:~D" domain-name (proxy-port proxy)))))
  proxy) 

(defmethod proxy-domain-name :before ((proxy basic-proxy-mixin))
  (with-slots (host domain-name) proxy
    (when (and (null domain-name) host)
      (setf domain-name (domain-name-for-parsed-ip-address host)))))

(define-generic proxy-host-and-port (proxy)
  (declare (values proxy-host proxy-port))
  (:documentation "Returns the parsed proxy host and port."))

(defmethod proxy-host-and-port ((proxy basic-proxy-mixin))
  (values (proxy-host proxy) (proxy-port proxy)))

(defun make-proxy (host port domain-name &optional protocols)
  "Returns a client proxy  accessible via HOST and PORT named DOMAIN-NAME."
  (check-type domain-name string)
  (check-type port fixnum)
  (check-type protocols list)
  (make-instance *proxy-class* :host host :port port :domain-name domain-name :protocols protocols))


;;;------------------------------------------------------------------- 
;;;
;;; NULL PROXY
;;;

(defvar +null-proxy+ nil
   "Holds the null proxy object used to suppress paths through proxied URL space.") 

(declaim (inline %maybe-get-null-proxy))

(defun %maybe-get-null-proxy (domain-name)
  (when (and (eql (length domain-name) 10)
	     (string-equal "Null-Proxy" domain-name :start1 0 :end1 10 :start2 0 :end2 10))
    (or +null-proxy+ (setq +null-proxy+ (make-instance 'null-proxy)))))


;;;------------------------------------------------------------------- 
;;;
;;; INTERNING CLIENT PROXIES
;;;

(defvar *proxy-table* (make-hash-table :test #'equalp)
   "A table of all known upstream proxies.")

(defun clear-client-proxy-mappings ()
  "Clears all known proxies and forgets any URL space which they handled."
  (setq *standard-proxy-control* nil
	+null-proxy+ nil)
  (clrhash *proxy-table*)) 

(defun %get-proxy (domain-name port)
  "Returns a proxy named DOMAIN-NAME operating on PORT that bridges PROTOCOL."
  (let ((entry (gethash domain-name *proxy-table*)))
    (when entry
      (loop for proxy in entry
	    when (eql port (proxy-port proxy))
	      return proxy
	    finally (return nil))))) 

(defmethod register ((proxy basic-proxy-mixin))
   (flet ((update-entry (key value found-p)
               (declare (ignore key))
               (cond (found-p
                          (push-ordered proxy value #'<  :key #'proxy-port)
                          value)
                        (t (list proxy)))))
      (declare (dynamic-extent #'update-entry))
      (let ((domain-name (proxy-domain-name proxy)))
         (check-type domain-name string)
         (modify-hash *proxy-table* domain-name #'update-entry))
      proxy)) 

(defun create-proxy (domain-name port)
  (let* ((host (parse-host domain-name))
	 (name (host-domain-name host)))
    (register (make-proxy host port name)))) 

(defun intern-proxy (domain-name port &key (if-does-not-exist :error))
  "Interns a proxy named DOMAIN-NAME operating on port PORT.
When using client proxies, it is sometime useful to specify that no 
proxy should be used.  This is done by using the null proxy, which is
returned when DOMAIN-NAME is \"Null-Proxy\"."
  (check-type port fixnum)
  (etypecase domain-name
    (string
      (or (%maybe-get-null-proxy domain-name)
	  (%get-proxy domain-name port)
	  (ecase if-does-not-exist
	    (:soft nil)
	    (:error (error "No HTTP proxy named, ~A, was found for port ~D." domain-name port))
	    (:create (values (create-proxy domain-name port) t)))))
    (null-proxy domain-name)
    (proxy
      (cond ((%get-proxy (proxy-domain-name domain-name) port))
	    (t (ecase if-does-not-exist
		 (:soft nil)
		 (:error (error " ~A is not an HTP proxy on port ~D." domain-name port))
		 (:create (values (create-proxy (proxy-domain-name domain-name) port) t))))))))

(defun map-client-proxies (function)
  "Maps FUNCTION over all the define client proxies.
FUNCTION is called on each proxy object in no particular order."
  (flet ((fctn (key value)
	   (declare (ignore key))
	   (mapc function value)))
    (declare (dynamic-extent #'fctn))
    (maphash #'fctn *proxy-table*)))


;;;------------------------------------------------------------------- 
;;;
;;; CLIENT PROXY OPERATIONS
;;;

(define-generic proxy-local-loop-p (server proxy)
  (:documentation "Returns non-null when PROXY creates a local loop back to sever."))

(defmethod proxy-local-loop-p ((server proxy-server-mixin) (proxy basic-proxy-mixin))
  (let ((proxy-host (proxy-host proxy)))
    (or (and (equalp (server-host server) proxy-host)	; Is the client and proxy host the same?
	     (equalp (local-host) proxy-host)	; Is the proxy host the local host?
	     (= (server-host-local-port server) (proxy-port proxy)))
	(virtual-host-p proxy-host (proxy-port proxy)))))

(defmethod proxy-local-loop-p ((server null) (proxy basic-proxy-mixin))
  nil)

(define-generic null-proxy-p (proxy)
  (:documentation "Returns non-null when PROXY is the null proxy."))

(defmethod null-proxy-p ((proxy basic-proxy-mixin))
   nil)

(defmethod null-proxy-p ((proxy null-proxy-mixin))
   t)

(define-generic proxy-note-protocol-bridge (proxy protocol)
  (:documentation "Updates the protocols that PROXY bridges to include PROTOCOL."))

(defmethod proxy-note-protocol-bridge ((proxy basic-proxy-mixin) (protocol symbol))
   (ecase protocol
      ((:http :ftp :nntp :wais :smtp)
        (pushnew protocol (proxy-protocols proxy)))))

(defmethod proxy-note-protocol-bridge ((proxy basic-proxy-mixin) (proxy-control proxy-control))
   (proxy-note-protocol-bridge proxy (proxy-control-protocol proxy-control)))

(defmethod proxy-note-protocol-bridge ((proxy basic-proxy-mixin) (url url))
   (proxy-note-protocol-bridge proxy (url:protocol url)))

(defmethod proxy-note-protocol-bridge ((proxy null-proxy-mixin) proxy-control)
  (declare (ignore proxy-control))
  nil)

(define-generic proxy-clear-protocol-bridge (proxy protocol)
  (:documentation "Updates the protocols that PROXY bridges to include PROTOCOL."))

(defmethod proxy-clear-protocol-bridge ((proxy basic-proxy-mixin) (protocol symbol))
   (ecase protocol
      ((:http :ftp :nntp :wais :smtp)
        (setf (proxy-protocols proxy) (delete protocol (proxy-protocols proxy))))))

(defmethod proxy-clear-protocol-bridge ((proxy null-proxy-mixin) proxy-control)
  (declare (ignore proxy-control))
  nil)

(define-generic proxy-bridges-protocol-p (proxy protocol)
  (:documentation "Returns non-null if PROXY bridges between HTTP and PROTOCOL."))

(defmethod proxy-bridges-protocol-p ((proxy basic-proxy-mixin) (protocol symbol))
   (member protocol (proxy-protocols proxy)))

(defmethod proxy-bridges-protocol-p ((proxy null-proxy-mixin) (protocol (eql :http)))
  t)



;;;------------------------------------------------------------------- 
;;;
;;; OPERATIONS ON PROXY CONTROLS
;;;

(defun %get-proxy-control (protocol &optional create-p)
  (loop for prev = nil then proxy-control
	for proxy-control = *standard-proxy-control* then (proxy-control-next-protocol proxy-control)
	while proxy-control
	when (eq protocol (proxy-control-protocol proxy-control))
	  return proxy-control
	finally (return (when create-p
			  (let ((new (make-proxy-control :protocol protocol)))
			    (if prev
				(setf (proxy-control-next-protocol prev) new)
				(setq *standard-proxy-control* new)))))))

(defun %remove-proxy-control (proxy-control)
  (cond ((eq proxy-control *standard-proxy-control*)
	 (setf *standard-proxy-control* (proxy-control-next-protocol proxy-control))
	 (values t proxy-control))
	(t (loop for prev = *standard-proxy-control*
		 for pc = (proxy-control-next-protocol prev)
		 when (eq pc proxy-control)
		   do (setf (proxy-control-next-protocol prev) (proxy-control-next-protocol pc))
		      (return (values t proxy-control))
		 finally (return nil))))) 

(defun %map-proxy-controls (function)
  (loop for proxy-control = *standard-proxy-control* then (proxy-control-next-protocol proxy-control)
	while proxy-control
	do (funcall function proxy-control)))

(defun %maybe-gc-proxy-control (proxy-control)
  (unless (or (proxy-control-standard-proxy proxy-control)
	      (proxy-control-port-proxy proxy-control)
	      (proxy-control-url-table proxy-control))
    (%remove-proxy-control proxy-control))) 

(defgeneric set-standard-proxy (proxy protocol &optional port)
  (:documentation "Sets PROXY as the standard proxy for handling requests on PORT for PROTOCOL URLs.
If PORT is null, PROXY is the default proxy for all ports.
If PORT is a port number, PORXY is the default proxy  only for requests on PORT for PROTOCOL URLs."))

(defmethod set-standard-proxy ((proxy proxy) (proxy-control proxy-control) &optional port)
  (etypecase port
    (fixnum (setf (getf (proxy-control-port-proxy proxy-control) port) proxy))
    (symbol 
      (ecase port
	((:default nil)
	 (setf (proxy-control-standard-proxy proxy-control) proxy)))))
  ;; record the protocol that the proxy is known to bridge.
  (proxy-note-protocol-bridge proxy proxy-control)
  proxy)

(defmethod set-standard-proxy (proxy (protocol symbol) &optional port)
  (check-type protocol keyword)
  (set-standard-proxy proxy (%get-proxy-control protocol t) port))

(defgeneric clear-standard-proxy (protocol &optional port)
  (:documentation "Removes the standard proxy for PROTOCOL on PORT.
If PORT is :DEFAULT, this removes the default proxy for PROTOCOL .
If PORT is a port number, the default proxy for PROTOCOL on that port is removed.
If PORT is :ALL, all standard proxies for PROTOCOL are removed from all ports."))

(defmethod clear-standard-proxy ((proxy-control proxy-control) &optional port) 
  (prog1
    (etypecase port
      (integer (remf (proxy-control-port-proxy proxy-control) port))
      (symbol
	(ecase port
	  ((:default nil)
	   (setf (proxy-control-standard-proxy proxy-control) nil))
	  (:all (remf (proxy-control-port-proxy proxy-control) port)
	   (setf (proxy-control-standard-proxy proxy-control) nil)))))
    (%maybe-gc-proxy-control proxy-control)))

(defmethod clear-standard-proxy ((protocol symbol) &optional port)
  (check-type protocol keyword)
  (let ((proxy-control (%get-proxy-control protocol nil)))
    (when proxy-control
      (clear-standard-proxy proxy-control port)))) 

(defgeneric set-proxy-url-mapping (proxy url)
  (:documentation "Sets the client PROXY for URL.
All  HTTP client requests made for a URL that matches URL will be directed as proxy requests through PROXY.
URL is matched as follows: SCHEME://HOSTNAME:PORT/RELATIVE-DIRECTORY/
        SCHEME selects the protocol that PROXY must bridge
        HOSTNAME and PORT serve to locate the proxy.
        The relative directory path for URL is then used to find the specific proxy.

SCHEME and HOSTNAME are required. Subspaced within the URL space may be assigned
to different proxies according to application requirements.")) 

(defmethod set-proxy-url-mapping ((proxy proxy) url)
  (set-proxy-url-mapping proxy (url:intern-url url :if-does-not-exist :uninterned)))

(defmethod set-proxy-url-mapping ((proxy proxy) (url url))
  (labels ((create-url-mapping (url proxy)
	     (let* ((key (copy-seq (url::relative-path-string url)))
		    (size (length key)))
	       (proxy-note-protocol-bridge proxy url)
	       `(,key ,size .,proxy)))
	   (create-port-url-mapping (proxy url port root-url-p)
	     (if root-url-p
		 `(,port ,proxy) 
		 `(,port nil ,(create-url-mapping url proxy)))))
    (let* ((host-string (url:host-string url))
	   (port (url:host-port url))
	   (root-url-p (url:root-url-p url))
	   (proxy-control (%get-proxy-control (url:protocol url) t))
	   (url-table (proxy-control-url-table proxy-control))
	   entry port-url-mappings url-mapping)
      ;; Ensure URL table present
      (cond (url-table
	     (setq entry (gethash host-string url-table)))
	    (t (setq url-table (make-hash-table :test #'equalp))
	       (setf (proxy-control-url-table proxy-control) url-table)))
      ;; handle the entry
      (cond ((null entry) 
	     (setf (gethash host-string url-table) (list (create-port-url-mapping proxy url port root-url-p))))
	    ((null (setq port-url-mappings (assoc port entry)))
	     (nconc entry (list (create-port-url-mapping proxy url port root-url-p))))
	    (root-url-p 
	     (setf (second port-url-mappings) proxy))
	    ((setq url-mapping (assoc (url::relative-path-string url) (cddr port-url-mappings) :test #'string=))
	     (setf (cddr url-mapping) proxy))
	    (t (setf (cddr port-url-mappings) (nconc (cddr port-url-mappings) (list (create-url-mapping url proxy)))))))))

(define-generic clear-standard-proxy-url (url)
  (:documentation "Clears any proxy that is directly associated with URL."))

(defmethod clear-standard-proxy-url ((url url))
  (let* ((url (url:intern-url url :if-does-not-exist :uninterned))
	 (dispatch-key (copy-seq (url:relative-path-string url)))
	 (host-string (url:host-string url))
	 (port (url:host-port url))
	 (proxy-control (%get-proxy-control (url:protocol url) t))
	 (url-table (proxy-control-url-table proxy-control))
	 entry port-alist dispatch-entry)
    (when url-table
      (when (setq entry (gethash host-string url-table))
	(when (setq port-alist (assoc port entry))
	  (when (setq dispatch-entry (assoc dispatch-key (cdr port-alist) :test #'string=))
	    (setf (cdr port-alist) (delete dispatch-entry (cdr port-alist)))
	    (unless (cdr port-alist)
	      (cond ((setf entry (delete port-alist entry))
		     (remhash host-string url-table)
		     (when (zerop (hash-table-count url-table))
		       (setf (proxy-control-url-table proxy-control) nil)))
		    (t (setf (gethash host-string url-table) entry))))
	    t))))))

(define-generic standard-proxy (URL)
  (:documentation "Returns the proxy associated with URL or null."))

;; Add domain matching so that hosts do not have to be enumerated once somebody complains. -- JCMa 5/2/2000.
;; This should be as efficient as possible.
(defmethod standard-proxy ((url url::host-port-mixin))
  (flet ((get-proxy-for-url  (proxy-control url &aux url-table entry port-entry)
	   (when (and (setq url-table (proxy-control-url-table proxy-control))
		      (setq entry (gethash (url:host-string url) url-table))
		      (setq port-entry (assoc (url:host-port url) entry)))
	     (destructuring-bind (default-proxy . port-url-mappings) (cdr port-entry)
	       (cond (port-url-mappings
		      (let* ((dispatch-key (url:name-string url))
			     (dispatch-key-size (length dispatch-key)))
			(url::with-relative-path-string-indices (dispatch-key 0 dispatch-key-size)
			  (loop for (key key-size . proxy) in port-url-mappings
				when (and (= key-size (the fixnum (- (the fixnum end) (the fixnum start))))
					  (string=  key dispatch-key :start1 0 :end1 key-size :start2 start :end2 end))
				  do (return proxy)
				     #|else do (break "foo: ~S" `(and (= ,key-size ,(- end start))
                                                                      (string=  ,key ,dispatch-key :start1 0 :end1 ,key-size :start2 ,start :end2 ,end)))|#
				finally (return default-proxy)))))
		     (t default-proxy))))))
    (declare (inline get-proxy-for-url))
    (let ((proxy-control (%get-proxy-control (protocol url) nil)))
      (when proxy-control
	(let (proxy)
	  ;; Precedence order of proxies
	  (setq proxy (or (get-proxy-for-url proxy-control url)
			  (getf (proxy-control-port-proxy proxy-control) *standard-http-port*)
			  (proxy-control-standard-proxy proxy-control)))
	  (etypecase proxy
	    (null nil)
	    (null-proxy nil)			; intercept the null proxy here and return NIL
	    (proxy proxy)))))))

(define-generic choose-proxy (url)
  (:documentation "Determine the proxy for a given URL.
Returns a proxy object or null."))

(defmethod choose-proxy ((url url::host-port-mixin))
   "Determine the proxy for a HOST-STRING and PORT. 
Returns a proxy object."
   (declare (values proxy))
   (let ((proxy (standard-proxy url)))
      (if (and proxy (not (proxy-local-loop-p *server* proxy)))
         proxy
         nil)))

(defgeneric get-client-proxy (url)
  (declare (values proxy-or-null))
  (:documentation "Returns the client proxy for URL or null.
If there is no proxy accessible from the current client, this computes the proxy for URL."))

(defmethod get-client-proxy ((url url::host-port-mixin) &aux client)
  (or (and (setq client *client*) (client-proxy client))
      (choose-proxy url))) 

(defmethod get-client-proxy ((url string))
  (get-client-proxy (or (intern-url url :if-does-not-exist :soft)
			(intern-url url :if-does-not-exist :uninterned))))


;;;------------------------------------------------------------------- 
;;;
;;; DESCRIBE CLIENT PROXY MAPPINGS
;;;

(defmethod describe-proxy-control ((proxy-control proxy-control) &optional (stream *standard-output*))
   (let ((port-proxies (proxy-control-port-proxy proxy-control))
           (url-table (proxy-control-url-table proxy-control)))
      (format stream "~&Protocol: ~A~&Standard Proxy: ~:[none~;~:*~A~]~&Port Prox~@P:~:*~:[ none~;~]"
                   (proxy-control-protocol proxy-control) (proxy-control-standard-proxy proxy-control) port-proxies)
      (cond-every
        (port-proxies
          (loop for (port proxy) on port-proxies by #'cddr
                   do (format stream "~14T~D => ~A~&" port  proxy)))
        (url-table
          (flet ((describe-entry (host-string entry)
                      (format stream "~&Host: ~A" host-string)
                      (loop for (port default . url-mappings) in entry
                               do (format stream "~&~5TPort: ~D~&~5TDefault: ~:[none~;~:*~A~]" port default)
                               (loop for (url size . proxy) in url-mappings
                                        do (format stream "~&~10T~A: ~A" proxy url size)))))
             (declare (dynamic-extent #'describe-entry))
             (maphash #'describe-entry url-table))))
      proxy-control))

(defun describe-client-proxy-mappings (&optional (stream *standard-output*))
  "Describes the current mappings of proxies to to protocols and URLs."
  (flet ((describe-it (proxy-control)
	   (describe-proxy-control proxy-control stream)))
    (declare (dynamic-extent #'describe-it))
    (%map-proxy-controls #'describe-it))) 


;;;------------------------------------------------------------------- 
;;;
;;; INITIALIZING CLIENT PROXY MAPPINGS
;;;

(defun %define-client-proxy-mapping (&key standard-proxies url-mappings)
  "Top-level function for initializing client proxy mappings."
   (clear-client-proxy-mappings)
   (loop for (protocol port proxy-name proxy-port) in standard-proxies
            for proxy = (intern-proxy proxy-name proxy-port :if-does-not-exist :create)
            do (set-standard-proxy proxy protocol port))
   (loop for (proxy-name proxy-port url) in url-mappings
            for proxy = (intern-proxy proxy-name proxy-port :if-does-not-exist :create)
            do (set-proxy-url-mapping proxy url))
   t)

(defmacro define-client-proxy-mapping (&key standard-proxies url-mappings)
  "Standard form for defining how clients access URLs via upstream proxies.
This allows, for example, HTTP gateways to specific protocols to be specified.
A typical usage involves specifying a proxy for resolving FTP URLs. Often
sites will use HTTP proxies to improve performance to remote sites and
specify that local hosts be access directly.  Here, standard proxies can be specified
and specific local hosts can accessed directly. 

STANDARD-PROXIES defines the default proxies which the client uses when making
requests for URLs. STANDARD-PROXIES is a list of:

     (PROTOCOL-KEYWORD REQUEST-PORT REMOTE-PROXY REMOTE-PROXY-PORT),

     where

     PROTOCOL-KEYWORD is one of :HTTP, :FTP, :WAIS, or :GOPHER.
     REQUEST-PORT is either :DEFAULT or a port number on which a local proxy operates.
     REMOTE-PROXY is the domain name of the remote proxy.
     REMOTE-PROXY-PORT is the port on which the remote proxy operates.

URL-MAPPINGS allows specific URLs to be mapped to a proxy, which might be
different from the standard proxies.  URL-MAPPINGS is a list of:

     (REMOTE-PROXY REMOTE-PROXY-PORT URL)

      where URL must be fully specified, in most cases as a URL path.

The specifications in URL-MAPPINGS are matched by lexically comparing
the host domain name, verifying that the ports are equal, and finally matching
the relative directory of URL to that  requested.  When URL is the root URL,
it is interpreted as the specifying the default proxy for the host and port
it contains. Unless a more specific URL mapping (i.e, one containing path
information) is found, that default will be used for all requests to
the specified host on the specified port. When the port does not appear
in the URL specification, the default port for the protocol is assumed.

The various ways of specifying proxies to use are interpreted in the
following precedence order:

     Most specific URL with path information
     Default host and port.
     Standard proxy for the specific local proxy port.
     Standard proxy for any port."
  `(%define-client-proxy-mapping :standard-proxies ',standard-proxies :url-mappings ',url-mappings))

(export 'define-client-proxy-mapping :http)

#|

(define-client-proxy-mapping
  :standard-proxies ((:http :default "gnoscere.ai.mit.edu" 80))
  :url-mappings (("Null-Proxy" 0 "http://wilson.ai.mit.edu/")))

(clear-client-proxy-mappings)

(describe-client-proxy-mappings)

|#

)
