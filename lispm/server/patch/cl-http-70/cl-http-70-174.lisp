;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: USER; Base: 10; Patch-File: t -*-
;;; Patch file for CL-HTTP version 70.174
;;; Reason: Function HTTP:COPY-FILE:  enhance documentation.
;;; Written by JCMa, 10/07/03 20:03:36
;;; while running on FUJI-VLM from FUJI:/usr/lib/symbolics/ComLink-39-8-F-MIT-8-5-inc1.vlod
;;; with Open Genera 2.0, Genera 8.5, Lock Simple 437.0, Version Control 405.0,
;;; Compare Merge 404.0, VC Documentation 401.0,
;;; Logical Pathnames Translation Files NEWEST, CLIM 72.0, Genera CLIM 72.0,
;;; PostScript CLIM 72.0, MAC 414.0, 8-5-Patches 2.19, Statice Runtime 466.1,
;;; Statice 466.0, Statice Browser 466.0, Statice Documentation 426.0, Joshua 237.4,
;;; CLIM Documentation 72.0, Showable Procedures 36.3, Binary Tree 34.0,
;;; Mailer 438.0, Working LispM Mailer 8.0, HTTP Server 70.173,
;;; W3 Presentation System 8.1, CL-HTTP Server Interface 53.0,
;;; Symbolics Common Lisp Compatibility 4.0, Comlink Packages 6.0,
;;; Comlink Utilities 10.4, COMLINK Cryptography 2.0, Routing Taxonomy 9.0,
;;; COMLINK Database 11.26, Email Servers 12.0, Comlink Customized LispM Mailer 7.1,
;;; Dynamic Forms 14.5, Communications Linker Server 39.8,
;;; Lambda Information Retrieval System 22.5, Experimental Genera 8 5 Patches 1.0,
;;; Genera 8 5 System Patches 1.41, Genera 8 5 Mailer Patches 1.1,
;;; Genera 8 5 Joshua Patches 1.0, Genera 8 5 Statice Runtime Patches 1.0,
;;; Genera 8 5 Statice Patches 1.0, Genera 8 5 Statice Documentation Patches 1.0,
;;; Genera 8 5 Clim Patches 1.3, Genera 8 5 Genera Clim Patches 1.0,
;;; Genera 8 5 Postscript Clim Patches 1.0, Genera 8 5 Clim Doc Patches 1.0,
;;; Genera 8 5 Image Substrate Patches 1.0, Genera 8 5 Lock Simple Patches 1.0,
;;; Jcma 44, HTTP Proxy Server 6.32, HTTP Client Substrate 4.22, HTTP Client 51.4,
;;; Image Substrate 440.4, Essential Image Substrate 433.0, Ivory Revision 5,
;;; VLM Debugger 329, Genera program 8.18, DEC OSF/1 V4.0 (Rev. 110),
;;; 1560x1120 24-bit TRUE-COLOR X Screen FUJI:1.0 with 224 Genera fonts (The Olivetti & Oracle Research Laboratory R3323),
;;; Machine serial number -2141194968,
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
;;; Background dns refreshing (from W:>reti>background-dns-refreshing).



(SCT:FILES-PATCHED-IN-THIS-PATCH-FILE 
  "HTTP:SERVER;UTILS.LISP.528")


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;UTILS.LISP.528")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-common-lisp; Package: HTTP; Base: 10; Mode: lisp -*-")

(define-generic copy-file (source destination &key copy-mode report-stream		
				  request-headers user-email-address &allow-other-keys)
  (declare (values destination))
  (:documentation "A portable file copy that works over files and URLs.

  Without the base client loaded, this copies files or lists of files.  If the
  name and type are omitted in DESTINATION, they are defaulted from SOURCE. When
  SOURCE is a list, files are copied to the directory specified in DESTINATION,
  with appropriate merging of name and type.

  COPY-MODE is one of :TEXT, :CRLF, or :BINARY.  When REPORT-STREAM is non-null,
  COPY-FILE reports its activities.

  With the base client loaded, copying can be done for any combination of
  pathnames and URLs. This facility is particularly useful in conjunction with
  writable Web directories provided by CL-HTTP (see: EXPORT-URL).

  When copying to a URL, REQUEST-HEADERS are a header property list that is sent
  to the destination server in addition to the normal request headers. Similarly,
  USER-EMAIL-ADDRESS identifies the author of the destination file."))

