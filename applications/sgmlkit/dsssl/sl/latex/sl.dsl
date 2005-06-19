<!DOCTYPE programcode PUBLIC "-//Starlink//DTD DSSSL Source Code 0.7//EN" [
<!ENTITY sldocs.dsl		SYSTEM "sldocs.dsl">
<!ENTITY slsect.dsl		SYSTEM "slsect.dsl">
<!ENTITY slmisc.dsl		SYSTEM "slmisc.dsl">
<!ENTITY slroutines.dsl		SYSTEM "slroutines.dsl">
<!ENTITY slmaths.dsl		SYSTEM "slmaths.dsl">
<!ENTITY sllinks.dsl		SYSTEM "sllinks.dsl">
<!ENTITY sltables.dsl		SYSTEM "sltables.dsl">

<!ENTITY commonparams.dsl	PUBLIC "-//Starlink//TEXT DSSSL Common Parameterisation//EN">
<!ENTITY slparams.dsl		PUBLIC "-//Starlink//TEXT DSSSL LaTeX Parameterisation//EN">

<!ENTITY lib.dsl		SYSTEM "../lib/sllib.dsl" SUBDOC>
<!ENTITY common.dsl		SYSTEM "../common/slcommon.dsl" SUBDOC>
<!ENTITY slback.dsl		SYSTEM "slback.dsl" SUBDOC>
]>

<!-- $Id$ -->

<docblock>
<title>Starlink to LaTeX stylesheet
<description>
This is the stylesheet for converting the Starlink General DTD to LaTeX.
<p>It requires a <em>modified</em> version of Jade, which supports the
<code>-t latex</code> back-end.

<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council


<codereference doc="lib.dsl" id="code.lib">
<title>Library code
<description>
<p>Some of this library code is from the standard, some from Norm
Walsh's stylesheet, other parts from me

<codereference doc="common.dsl" id="code.common">
<title>Common code
<description>
<p>Code which is common to both the HTML and print stylesheets.

<codereference doc="slback.dsl" id=code.back>
<title>Back-matter
<description>Handles notes, bibliography and indexing

<codegroup
  use="code.lib code.common code.back" id=latex>
<title>Conversion to LaTeX

<routine>
<description>Declare the flow-object-classes to support the LaTeX back-end
of Jade, written by me.
<codebody>
(declare-flow-object-class command
  "UNREGISTERED::Norman Gray//Flow Object Class::command")
(declare-flow-object-class empty-command
  "UNREGISTERED::Norman Gray//Flow Object Class::empty-command")
(declare-flow-object-class environment
  "UNREGISTERED::Norman Gray//Flow Object Class::environment")
(declare-flow-object-class fi
  "UNREGISTERED::James Clark//Flow Object Class::formatting-instruction")
(declare-flow-object-class entity
  "UNREGISTERED::James Clark//Flow Object Class::entity")
(declare-characteristic escape-tex?
  "UNREGISTERED::Norman Gray//Characteristic::escape-tex?"
  #t)


;; incorporate the simple stylesheets directly

&sldocs.dsl;
&slsect.dsl;
&slmisc.dsl;
&slroutines.dsl;
&slmaths.dsl;
&sllinks.dsl;
&sltables.dsl;
&commonparams.dsl;
&slparams.dsl;

<routine>
<description>
The root rule.  Simply generate the LaTeX document at present.
<codebody>
(root
    (make sequence
      (process-children)
      (make-manifest)
      ))

<![ IGNORE [
<codegroup>
<title>The default rule
<description>There should be no default rule in the main group
(<code>style-specification</codebody> in the terms of the DSSSL architecture),
so that it doesn't take priority over mode-less rules in other process
specification parts.  See the DSSSL standard, sections 7.1 and 12.4.1.

<p>Put a sample default rule in here, just to keep it out of the way
(it's ignored).
<routine>
<description>The default rule
<codebody>
(default
  (process-children))
]]>

<routine>
<routinename>make-manifest
<description>Construct a list of the LaTeX files generated by the main
processing.  Done only if <code>suppress-manifest</code> is false and 
<code>%latex-manifest%</code> is true, giving the
name of a file to hold the manifest.  
<p>This is reasonably simple, since the manifest will typically consist
of no more than the main output file, plus whatever files are used
by the "figurecontent" element.
<argumentlist>
<parameter optional default='(current-node)'>nd<type>singleton-node-list
  <description>Node which identifies the grove to be processed.
<codebody>
(define (make-manifest #!optional (nd (current-node)))
  (if (and %latex-manifest% (not suppress-manifest))
      (let ((element-list (list (normalize "figure")))
	    (rde (document-element nd)))
	(make entity system-id: %latex-manifest%
	      (make fi
		data: (string-append (index-file-name) ".tex
")) ; see sldocs.dsl
	      (with-mode make-manifest-mode
		(process-node-list
		 (node-list rde		;include current file
			    (node-list-filter-by-gi
			     (select-by-class (descendants rde)
					      'element)
			     element-list))))))
      (empty-sosofo)))

(mode make-manifest-mode
  (default 
    (empty-sosofo))

  ;; The selection here should match the processing in slmisc.dsl
  (element figure
    (let ((content
           (figurecontent-to-notation-map
            (node-list (select-elements (children (current-node))
                                        (normalize "figurecontent"))))))
      (if content
          (process-node-list
           (apply node-list (map (lambda (p)
                                   (if (member (car p)
                                               '("eps" "pdf"))
                                       (cdr p)
                                       (empty-node-list)))
                                 content)))
          (empty-sosofo))))

  (element coverimage
    (let ((content
           (figurecontent-to-notation-map
            (node-list (select-elements (children (current-node))
                                        (normalize "figurecontent"))))))
      (if content
          (process-node-list
           (apply node-list (map (lambda (p)
                                   (if (member (car p)
                                               '("eps" "pdf"))
                                       (cdr p)
                                       (empty-node-list)))
                                 content)))
          (empty-sosofo))))
  
;  (element coverimage
;    (let* ((kids (children (current-node)))
;	   (content (get-best-figurecontent
;		     (select-elements kids (normalize "figurecontent"))
;		     '("eps" "pdf"))))
;      (if content
;	  (process-node-list content)
;	  (empty-sosofo))))
  ;; the figurecontent element writes out TWO fields in the manifest:
  ;; the first is the sysid of the figure as referred to by the
  ;; generated LaTeX, which will have no path, and the second is the sysid as
  ;; declared in the entity, which may well have a path.  Locations may
  ;; need some post-processing.
  (element figurecontent
    (let* ((image-ent (attribute-string (normalize "image")
					(current-node)))
	   (full-sysid (and image-ent
			    (entity-system-id image-ent)))
	   (base-sysid (and image-ent
			    (car (reverse
				  (tokenise-string
				   (entity-system-id image-ent)
				   boundary-char?: (lambda (c)
						     (char=? c #\/))))))))
      (if image-ent
	  (make fi data: (string-append base-sysid " " full-sysid "
"))
	  (empty-sosofo)))))



