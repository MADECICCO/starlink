<!-- 
$Id$ 

<docblock>
<title>HTML navigation
<description>
<p>This module supports navigation.
<p>Some of the functions in this file are imported more-or-less intact from 
Norm Walsh's DocBook stylesheet, but have been substantially simplified.
This file was one of the first I wrote, so there are likely several
redundant functions in here which I don't yet have the time to 
winnow out.
<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray
<author id=mbt>Mark Taylor
<otherauthors>
<author id=nw>Norman Walsh
<authornote>The general structure of this file, plus some of the code,
has been adapted from version v1.12 (or thereabouts) of Norman Walsh's 
DocBook stylesheet. 

<codegroup>
<title>HTML navigation
-->

<routine>
<description>
<p>List of element types which should be broken into chunks.
Because of the way that section-footer-navigation finds its
subsections, I think there should be no `missing levels' in the set
of elements.  Ie, ("sect" "subsubsect") would be bad, since
"subsect" is missing.

<p>There are two constraints on the elements in this list.  (1) no
elements appear which are in the documentsummary DTD but not in the
General DTD, since <funcname/main-html-base/ relies on this to be able to
generate the same HTML file name in both cases.  It doesn't matter
if there are elements here which don't appear in the summary DTD,
since elements with those names will necessarily never be found
when processing an instance of the summary DTD.  (2) the list
must be a subset of the return value of <funcname/section-element-list/.
<codebody>
(define (chunk-element-list)
  (list (normalize "abstract")
        (normalize "sect")
	(normalize "subsect")
	(normalize "appendices")
	(normalize "routinelist")
	(normalize "codecollection")
	))

<routine>
<routinename>chunking?
<description>
Returns true if chunking is enabled.
<p>Currently, this simply returns <code/(not (or nochunks stream-output))/,
but could be more general in future.
<returnvalue type=boolean>True if chunking is enabled.
<codebody>
(define (chunking?)
  (not (or nochunks stream-output)))

<routine>
<routinename>chunk?
<description>
Return <code/#t/ if the given node is a chunk, taking account of whether
chunking has been turned off.
Given that chunking is on, this simply tests whether the
node is a member of <funcname/chunk-element-list/.
<returnvalue type=boolean>True if the node is a chunk
<p>Do <em/not/ modify this so that the document element is deemed to
be a chunk.  This may seem like a good idea, but it's important that
<funcname/chunk?/ <em/always/ returns false if chunking is off.
<argumentlist>
<parameter optional default='(current-node)'>
  nd
  <type>node-list
  <description>The node to test
<codebody>
(define (chunk? #!optional (nd (current-node)))
  (and (chunking?)
       (member (gi nd) (chunk-element-list))))

<routine>
<routinename>chunk-path
<description>
Return a string which describes the path to the given node through
nodes which are members of <funcname/chunk-element-list/.  Returns an empty
string if the <funcname/chunk-level-parent/ of the given node is empty.
Note that <funcname/chunk-level-parent nd/ returns nd if nd is a member of
<funcname/chunk-element-list/. 
<returnvalue type=string>String without spaces, listing the chunk-type
elements on the way to the current chunk
<argumentlist>
<parameter>nd<type>node-list<description>Node we want the path to
<codebody>
(define ($chunk-path-abbrev$ nd)
  (let* ((gi-map (list (cons (normalize "sect") "a")
		       (cons (normalize "subsect") "b")
		       (cons (normalize "subsubsect") "c")
		       (cons (normalize "subsubsubsect") "d")
		       (cons (normalize "appendices") "x")
		       (cons (normalize "routinelist") "r")
		       (cons (normalize "codecollection") "f")))
	 (nd-gi-map (assoc (gi nd) gi-map)))
    (if nd-gi-map
	(cdr nd-gi-map)
	(gi nd))))
(define (chunk-path nd)
  (let loop ((this-node (chunk-level-parent nd))
	     (path-string ""))
    (if (node-list-empty? this-node)
	path-string
	(loop (chunk-level-parent (parent this-node))
	      (string-append ($chunk-path-abbrev$ this-node) ;(gi this-node)
			     (number->string (child-number this-node))
			     path-string)))))

<routine>
<routinename>main-html-base
<description>
Return a string containing the name of the file which will hold the
given node.  Since this must work both for the general DTD and the
documentsummary DTD, we can't use <funcname/all-element-number/.  Since 
this current version uses <funcname/chunk-path/, it will break (in the sense
that different filenames will be generated for the same element when it
appears in the general and in the documentsummary DTD) if the elements in
<funcname/chunk-element-list/ (which <funcname/chunk-path/ uses) produce
different hierarchies in the two DTDs.
<returnvalue type=string>Base of filename
<argumentlist>
<parameter>nd<type>node-list<description>We want the basename of the file
which will hold this node
<codebody>
(define (main-html-base nd)
  (let* ((node-name-suffix (chunk-path nd))
	 (idbase (if (and %use-id-as-filename%
			  (attribute-string (normalize "id") nd))
		     (case-fold-down (attribute-string (normalize "id") nd))
		     #f)))
    (if idbase
	(string-append (root-file-name nd) idbase)
	(string-append (root-file-name nd)
		       "-"
		       (case-fold-down node-name-suffix)))))

<routine>
<routinename>html-file
<description>
Returns the filename of the html file that contains the given node.
<returnvalue type=string>Complete filename.  Will not return an empty string.
<argumentlist>
<parameter keyword default='(current-node)'>
  target_nd<type>node-list<description>Node whose file we want
<parameter keyword default='#f'>
  uniq<type>string<description>If present, this gives a unique string which 
  will be used to construct the file name.  This is need in the case of,
  for example, the note contents file, which has no associated element.
<codebody>
(define (html-file #!key (target_nd (current-node)) (uniq #f))
  (let* ((nd (chunk-parent target_nd))
	 (base (cond (uniq
		      (string-append (root-file-name target_nd) "-" uniq))
		     ((member (gi nd) (section-element-list))
		      (main-html-base nd))
		     ((node-list-empty? nd)
				; if the node-list nd is empty, then
				; this is because chunk-parent
				; couldn't find a parent chunk.  This
				; means either that we're not
				; chunking, or else that this is the
				; root chunk.
		      (if %override-root-file-name%
			  %override-root-file-name%
			  (index-file-name target_nd))
				; give target_nd as argument - this is
				; a singleton-node-list (required
				; argument for document-element), but
				; chunk-parent produces a node-list (mmm?)
		      )
		     ;; Following gives the same behaviour.  More rational?
		     ;((node-list=? input_nd (document-element))
		     ; (root-file-name))
		     ;; Catch-all.  It's probably better to return
		     ;; _something_ here, even if it's nonsense,
		     ;; rather than a confusing empty-string
		     (else "xxx1")
		     )))
    (string-append base %html-ext%)))

<routine>
<routinename>chunk-parent
<description>
Return the node-list for the element whose chunk nd is in, or an
empty node list if there is none such (which might happen if
chunking is turned off).
<returnvalue type=singleton-node-list>An element which is the `top level'
of a particular chunk
<argumentlist>
<parameter optional default='(current-node)'>
  nd<type>node-list<description>This node identifies the chunk we want
  the top level of.
<codebody>
(define (chunk-parent #!optional (nd (current-node)))
  (let loop ((p (chunk-level-parent nd)))
    (if (or (node-list-empty? p) (chunk? p))
	p
	(loop (chunk-level-parent (parent p))))))

<routine>
<routinename>chunk-level-parent
<description>
Return (a node-list containing) the nearest ancestor which is a
member of <funcname/chunk-element-list/.  The difference between this and
<funcname/chunk-parent/ is that <funcname/chunk-parent/ tests whether the 
node is 
actually chunked (ie, it also uses <funcname/chunk?/), whereas this one just
tests for membership of <funcname/chunk-element-list/.
<returnvalue type=singleton-node-list>`Top level' of the current chunk.
<argumentlist>
<parameter optional default='(current-node)'>
  nd<type>node-list<description>This node identifies the chunk we want the 
  parent of
<codebody>
(define (chunk-level-parent #!optional (nd (current-node)))
  (ancestor-member nd (chunk-element-list)))

<routine>
<routinename>chunk-children
<description>
Return the children of the current chunk, or an empty node-list if
there are none.
<returnvalue type=node-list>Children of the current chunk.
<argumentlist>
<parameter optional default='(current-node)'>
  nd<type>node-list<description>This node identifies the chunk we want the 
  children of.
<codebody>
(define (chunk-children #!optional (nd (current-node)))
  (node-list-filter-by-gi (select-by-class (children nd) 'element)
			  (chunk-element-list)))


<routine>
<routinename>html-contents
<purpose>Processing mode for html-contents lines
<description>The <funcname/section-reference/ processing mode is not
quite appropriate for HTML contents lines, since we don't want all
the numbers in that case.  This mode is based on that mode however,
and passes control explicitly to that mode for those elements which
it processes suitably for our purposes.  For the others it lets
<funcname/make-html-contents-line/ do the hard work.
<p>This mode should contain construction rules for all the elements 
in <funcname/section-element-list/.
<codebody>
(mode html-contents
  (element abstract
     (make-html-contents-line))
  (element sect
     (make-html-contents-line))
  (element subsect
     (make-html-contents-line))
  (element subsubsect
     (make-html-contents-line))
  (element subsubsubsect
     (make-html-contents-line))
  (element appendices
     (make-html-contents-line))
  (element routinelist
     (make-html-contents-line))
  (element codecollection
     (make-html-contents-line))
  (element title
     (with-mode section-reference (process-node-list (current-node))))
  (element docbody
     (with-mode section-reference (process-node-list (current-node))))
  (element subhead
     (with-mode section-reference (process-node-list (current-node))))
  )


<routine>
<routinename>make-html-contents-line
<purpose>Generate a line for inclusion in the HTML table of contents.
<description>This generates a line for inclusion in the HTML table
of contents; it consists of the child-number of the section, formatted
as appropriate, followed by its title or something else which serves
as such.
<p>It operates on the current node.
<returnvalue type=sosofo>A sosofo suitable for use as the content of a li 
element.
<codebody>
(define (make-html-contents-line)
   (let* ((el-gi (gi (current-node))) 
          (seclev (cond 
                    ((equal? el-gi (normalize "subsubsubsect")) 3)
                    ((equal? el-gi (normalize "subsubsect")) 2)
                    ((equal? el-gi (normalize "subsect")) 1)
                    ((equal? el-gi (normalize "sect")) 0)
                    (else #f)))
          (fmt-type (cond 
                      (seclev (list-ref 
                                 (if (have-ancestor? (normalize "appendices"))
                                    %appendix-fmts
                                    %section-fmts)
                                  seclev))
                      ((equal? el-gi (normalize "routinelist")) #f)
                      ((equal? el-gi (normalize "codecollection")) "1")
                      (else #f))))
    (sosofo-append
       (make element gi: "a" 
             attributes: (list (list "href" (href-to (current-node))))
         (if fmt-type
            (literal 
               (format-number (child-number (current-node)) fmt-type) ". ")
            (empty-sosofo))
         (cond 
            (seclev (process-first-descendant (normalize "title")))
            ((equal? el-gi (normalize "appendices")) 
                (literal "Appendices"))
            ((equal? el-gi (normalize "routinelist"))
                (literal "Routine list"))
            ((equal? el-gi (normalize "abstract"))
                (literal "Abstract"))
            ((equal? el-gi (normalize "codecollection"))
                (with-mode routine-ref-get-reference
                   (process-codecollection 
                      (attribute-string (normalize "doc"))))))))))


<routine>
<routinename>make-contents
<description>
Make a table of contents of the node argument, down to the specified depth.
This works by listing children of the current node which are
members of <funcname/section-element-list/, and possibly recursing to
list their children.  It does not supply any header.
<returnvalue type=sosofo>TOC, currently formatted as a UL
<argumentlist>
<parameter optional default='(current-node)'>start-element
  <type>singleton-node-list
  <description>Node we want the contents of.  All the children of this
  node which are members of <funcname/section-element-list/ will be
  listed.
<parameter optional default=1>depth
  <type>integer
  <description>Maximum number of levels of TOC we want.  Zero means
  return immediately.
<parameter>include-backmatter-contents
  <type>boolean
  <description>If true, then include a TOC for the backmatter
<codebody>
(define (make-contents #!optional
		       (start-element (current-node))
		       (depth 1)
		       (include-backmatter-contents #f))
  (let ((subsects (node-list-filter-by-gi (select-by-class
					   (children start-element)
					   'element)
					  (section-element-list))))
    (if (or (node-list-empty? subsects)
	    (<= depth 0))
	(empty-sosofo)
	(make element gi: "ul"
	      (sosofo-append
	       (node-list-reduce
		subsects
		(lambda (last el)
		  (sosofo-append
		   last
		   (make element gi: "li"
                         (with-mode html-contents (process-node-list el))
			 (make-contents el (- depth 1)))))
		(empty-sosofo))
	       (if (and include-backmatter-contents
			(hasbackmatter?))
		   (make-contents-backmatter)
		   (empty-sosofo)))))))


<routine>
<description>
Various functions to provide the links which navigate between the various
generated HTML documents.  
<codebody>
(define (header-navigation nd)
  (make sequence
    ($html-body-start$)
    (cond ((node-list=? nd (document-element))
	   (root-header-navigation nd))
	  ((member (gi nd) (section-element-list))
	   (section-header-navigation nd))
	  (else (empty-sosofo)))
    ($html-body-content-start$)))

(define (footer-navigation nd)
  (make sequence
    ($html-body-content-end$)
    ;(whereami "footer-navigation" "P" nd)
    (cond ((node-list=? nd (document-element))
	   (root-footer-navigation nd))
	  ((member (gi nd) (section-element-list))
	   (section-footer-navigation nd))
	  (else (empty-sosofo)))
    (nav-footer nd)
    ($html-body-end$)))

(define (root-header-navigation elemnode)
  (empty-sosofo))

;; This is like (ancestors), except that we list only ancestors which
;; are present in (chunk-element-list) or DOCBODY
(define (chunk-ancestors nl)
  (node-list-filter-by-gi (ancestors nl) (append (chunk-element-list)
						 (list (normalize "docbody")))))

(define (section-header-navigation elemnode)
  (let ((anc (chunk-ancestors elemnode)))
    (make element gi: "div" attributes: '(("class" "navbar"))
    (make element gi: "TABLE" attributes: %nav-header-table-attr%
	  (make sequence
	    (make element gi: "TR"
		  (make element gi: "TD" attributes: '(("ALIGN" "LEFT"))
			(make sequence
			  (node-list-reduce
			   anc ; (node-list-reduce) 10.2.2
			   (lambda (curr el)
			     (sosofo-append
			      curr
			      (make sequence
				(make element gi: "A"
				      attributes: (list (list "HREF"
							      (href-to el)))
				      (with-mode section-reference
					(process-node-list el)))
				(literal " / "))))
			   (empty-sosofo))
			  (with-mode section-reference
			    (process-node-list (current-node))))))
	    (make element gi: "TR"
		  (make element gi: "TD" attributes: '(("ALIGN" "RIGHT"))
			(make sequence
			  (if (nav-home? elemnode)
			      (make sequence
				(nav-home-link elemnode)
				(literal " / "))
			      (empty-sosofo))
			  (if (nav-up? elemnode)
			      (nav-up-link elemnode)
			      (make element gi: "EM"
				    (literal "Up")))
			  (literal " / ")
			  (if (nav-prev? elemnode)
			      (nav-prev-link elemnode)
			      (make element gi: "EM"
				    (literal "Prev")))
			  (literal " / ")
			  (if (nav-next? elemnode)
			      (nav-next-link elemnode)
			      (make element gi: "EM"
				    (literal "Next")))))))))))


;; We're producing the footer for the root element (SUN or MUD, or
;; whatever).  This doesn't have any element of (chunk-element-list)
;; as a child, so we have to give it some help.
;;
;; If we're not chunking, then we don't want to produce a table of
;; contents.  This is the only place we need to worry about this --
;; the section-footer-navigation functions will be invoked only if
;; we're chunking.
(define (root-footer-navigation elemnode)
  (if (chunking?)
      (make sequence
	(make element gi: "h3"
	      (literal "Contents"))
	(make-contents (getdocbody) 4 #t))
      (empty-sosofo)))

;(define (section-footer-navigation elemnode)
;  (let ((subsects (chunk-children elemnode)))
;    (make-subcontents subsects)))
(define (section-footer-navigation elemnode)
  (empty-sosofo))

;; Return a pair consisting of ("Legend" . (node-list with
;; the `next' chunk to go to))
(define (onwards #!optional (elemnode (current-node)))
  (let* ((subsects (chunk-children elemnode))
	 ;; If this is the root element, and we _are_ chunking, then
	 ;; return a list of the children of the root element.
	 ;; Otherwise, return an empty-node-list
	 ;; (this is because (chunk-children) doesn't find sections from within
	 ;; the root element, and so needs a special case).
	 (root-subsects (if (and (chunking?)
				 (node-list=? elemnode
					      (document-element)))
			    (chunk-children (select-elements
					     (children elemnode)
					     (normalize "docbody")))
			    (empty-node-list))))
    (cond ((not (node-list-empty? root-subsects))
	   (cons "Begin" (node-list-first root-subsects)))
	  ((not (node-list-empty? subsects))
					; first of any children
	   (cons "Next down" (node-list-first subsects)))
	  ((nav-next? elemnode)	; next at this level
	   (cons "Next" (nav-next-element elemnode)))
	  ((not (node-list-empty?
		 (nav-next-element
		  (nav-up-element elemnode))))
	   (cons "Next up" (nav-next-element
			    (nav-up-element elemnode))))
	  ;; Don't go UP - when there's no longer a `next up', 
	  ;; then we've got to the end of the trail.
	  (else (cons "End" (empty-node-list))))))

(define (nav-footer elemnode)
  (let* ((authors (children (getdocinfo 'authorlist)))
	 (rel (document-release-info))
	 (subsects (chunk-children elemnode))
	 (nextchunk (onwards)))
    (make element gi: "div" attributes: '(("class" "navbar")
					  ("align" "right"))
      (make element gi: "table" attributes: %nav-footer-table-attr%
	    (make sequence
	      (if (node-list-empty? subsects)
		  (empty-sosofo)
		  (make element gi: "tr"
			(make element gi: "td"
			      (make sequence
				(make element gi: "h4"
				      (literal "Contents"))
				(make-contents))
			      )))
	      (make element gi: "tr"
		    (make element gi: "td" attributes: '(("align" "right"))
			;(whereami "nav-footer")
			;(literal (car nextchunk))
			(if (node-list-empty? (cdr nextchunk))
			    (literal "END")
			    (make sequence
			      (make element gi: "em"
				    (literal (string-append (car nextchunk)
							    ": ")))
			      (make element gi: "a"
				    attributes: (list
						 (list "href"
						       (href-to (cdr nextchunk))))
				    (with-mode section-reference
				      (process-node-list (cdr nextchunk))))))
			))
	      (if (hasidindex?)
		  (make element gi: "tr"
			(make element gi: "td" attributes: '(("align" "right"))
			      (let* ((in-sect (ancestor-member
					       (current-node)
					       (list (normalize "sect"))))
				     (sect-id (and in-sect
						   (attribute-string
						    (normalize "id")
						    in-sect))))
				(make element gi: "a"
				      attributes:
				      (list
				       (list
					"href" (string-append
						(idindex-sys-id)
						"#"
						(if sect-id
						    (string-append
						     "xref__IDINDEX_" sect-id)
						    (idindex-frag-id)))))
				      (make element gi: "small"
					    (literal "ID index"))))))
		  (empty-sosofo))))
      (make element gi: "address"
	    (make element gi: "em"
		  (make sequence
		    (node-list-reduce authors
				      (lambda (result a)
					(sosofo-append
					 result
					 (make sequence
					   (process-node-list a)
					   (make empty-element gi: "br"))))
				      (empty-sosofo))
		    (literal (format-date (car rel)))
		    )))
      )))



;(define (nav-footer elemnode)
;  (let* ((authors (getdocinfo 'authorlist))
;	 (hist (getdocinfo 'history))
;	 (date (if hist			; HISTORY element present
;		   (attribute-string "date"
;				     (select-elements (descendants hist)
;						      'release))
;		   (data (getdocinfo 'docdate))))) ; must be docdate instead
;    (make sequence
;      (make element gi: "TABLE" attributes: %nav-footer-table-attr%
;	    (make element gi: "TR"
;		  (make element gi: "TD" attributes: '(("ALIGN"
;							"RIGHT"))
;			(whereami "nav-footer")
;			(literal "Next location..."))))
;      (make element gi: "P" attributes: '(("ALIGN" "RIGHT"))
;	    (make element gi: "EM"
;		  (process-node-list authors)
;		  (literal "Date: " date))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Navigation macros.  These navigate around the document, giving
;; parents, siblings, and so on

;; General navigation link, which nav-{up,home,next,prev}-link use
(define (nav-gen-link thisnode target title linktext)
  (if (node-list=? thisnode target)
      (literal (string-append "This node is " title))
      (make sequence
	(make element gi: "A"
	      attributes: (list (list "HREF" (href-to target))
				(list "TITLE" title))
	      linktext)
	;(literal (string-append " (" (href-to target) ")"))
	)))

;; Is there an Up definable?
(define (nav-up? elemnode)
  (let ((up (parent elemnode)))
    (if (or (node-list-empty? up)
	    (node-list=? up (document-element)))
	#f
	#t)))
(define (nav-up-element elemnode)
  (parent elemnode))

(define (nav-up-link elemnode)
  (let ((up (parent elemnode)))
    (nav-gen-link elemnode up "Up" (gentext-nav-up up))))

;; Returns a sosofo with the up link (or empty-sosofo if none)
;(define (nav-up-link elemnode)
;  (let ((up (parent elemnode)))
;    (if (or (node-list-empty? up)
;	    (node-list=? up (document-element)))
;	;(make entity-ref name: "nbsp")
;	;(empty-sosofo)
;	(literal "No up element")
;	(make element gi: "A"
;	      attributes: (list
;			   (list "HREF" (href-to up))
;			   (list "TITLE" "Up"))
;	      (gentext-nav-up up)))))

;; Is there a home link (say no, if we're currently the root element)
(define (nav-home? elemnode)
  (not (node-list=? elemnode (document-element))))

(define (nav-home elemnode)
  (document-element))

(define (nav-home-link elemnode)
  (let ((home (nav-home elemnode)))
    (nav-gen-link elemnode home "Home" (gentext-nav-home home))))

;;; make the home link (or empty-sosofo if none)
;(define (nav-home-link elemnode)
;  (let ((home (nav-home elemnode)))
;    (if (node-list=? elemnode home)
;	;(make entity-ref name: "nbsp")
;	;(empty-sosofo)
;	(literal "No home element")
;	(make element gi: "A"
;	      attributes: (list
;			   (list "HREF" (href-to home))
;			   (list "TITLE" "Home"))
;	      (gentext-nav-home home)))))

;; ifollow-by-gi and ipreced-by-gi return the next sibling node which
;; is in the list gilist, which need not be the same as the next
;; sibling (though it probably will be, in the present case)
(define (ifollow-by-gi nd gilist)
  (let loop ((next (ifollow nd)))
    (if (node-list-empty? next)
	(empty-node-list)
	(if (member (gi next) gilist)
	    next
	    (loop (ifollow next))))))

(define (ipreced-by-gi nd gilist)
  (let loop ((prev (ipreced nd)))
    (if (node-list-empty? prev)
	(empty-node-list)
	(if (member (gi prev) gilist)
	    prev
	    (loop (ipreced prev))))))

;; Is there a next link?
(define (nav-next-element elemnode)
  (ifollow-by-gi elemnode (chunk-element-list)))

(define (nav-next? elemnode)
  (not (node-list-empty? (nav-next-element elemnode))))

(define (nav-next-link elemnode)
  (let ((next (nav-next-element elemnode)))
    (nav-gen-link elemnode next "Next" (gentext-nav-next next))))

;;; return sosofo for 'next' link (or empty-sosofo if none)
;(define (nav-next-link elemnode)
;  (let ((next (ifollow-by-gi elemnode (chunk-element-list))))
;    (if (node-list-empty? next)
;	;(empty-sosofo)
;	(literal "No next element")
;	(make element gi: "A"
;	      attributes: (list (list "HREF" (href-to next))
;				(list "TITLE" "Next"))
;	      (gentext-nav-next next)))))

;; Is there a prev link?
(define (nav-prev-element elemnode)
  (ipreced-by-gi elemnode (chunk-element-list)))
(define (nav-prev? elemnode)
  (not (node-list-empty? (nav-prev-element elemnode))))

(define (nav-prev-link elemnode)
  (let ((prev (nav-prev-element elemnode)))
    (nav-gen-link elemnode prev "Prev" (gentext-nav-prev prev))))


<routine>
<description>
The following functions are miscellaneous odds-and-ends, some of which I'm
not sure if I still use!
<codebody>
;;; Debugging routine -- simply telltales the current GI
(define (whereami str #!optional (gitype "P") (nd (current-node)))
  (make element gi: gitype
	  (literal (string-append
		    str ": "
		    (gi nd)))))


;; I don't know what this `skipping' stuff is, but I've changed the
;; list to just "sect" rather than "sect1"
;; (I _think_ the `skipping' is that if a section starts with a
;; subsection, then the two are put on the same page, but you'd have
;; to burrow through the DocBook stylesheet to confirm that).
(define (chunk-skip-first-element-list)
  (list (normalize "sect")))

(define (subset testlist memberlist)
  ;; Returns #t if all the elements of testlist are also elements of memberlist
  (let loop ((l testlist))
    (if (null? l)
	#t
	(if (not (member (car l) memberlist))
	    #f
	    (loop (cdr l))))))

(define (nodelist-to-gilist nodelist) 
  (let loop ((nl nodelist) (gilist '()))
    (if (node-list-empty? nl)
	gilist
	(loop (node-list-rest nl) (append gilist (list (gi (node-list-first nl))))))))

(define (is-first-element nd)
  (equal? (child-number nd) 1))

;; Return an id for the element, either the element's ID if it has one, 
;; or one obtained from (generate-anchor).
;; Don't want this any more (partly because I've discarded (generate-anchor)
;; However, I might want to resurrect the more complicated version below, 
;; when and if I want to refer to titles (which don't have IDs in the General
;; DTD.
;(define (element-id #!optional (nd (current-node)))
;    (if (attribute-string (normalize "id") nd)
;	(attribute-string (normalize "id") nd)
;	(generate-anchor nd)))
;(define (element-id #!optional (nd (current-node)))
;  ;; IDs of TITLEs are the IDs of the PARENTs
;  (let ((elem (if (equal? (gi nd) (normalize "title"))
;		  (parent nd)
;		  nd)))
;    (if (attribute-string (normalize "id") elem)
;	(attribute-string (normalize "id") elem)
;	(generate-anchor elem))))

