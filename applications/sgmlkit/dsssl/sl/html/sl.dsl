<!DOCTYPE programcode public "-//Starlink//DTD DSSSL Source Code 0.2//EN" [
<!entity sldocs.dsl		system "sldocs.dsl">
<!entity slmisc.dsl		system "slmisc.dsl">
<!entity slsect.dsl		system "slsect.dsl">
<!entity slroutines.dsl		system "slroutines.dsl">

<!entity slparams.dsl		system "slparams.dsl" subdoc>
<!entity slhtml.dsl		system "slhtml.dsl" subdoc>
<!entity lib.dsl		system "../lib/sllib.dsl" subdoc>
<!entity common.dsl		system "../common/slcommon.dsl" subdoc>
<!entity slnavig.dsl		system "slnavig.dsl" subdoc>
<!entity maths.dsl		system "slmaths.dsl" subdoc>
<!entity tables.dsl		system "sltables.dsl" subdoc>
<!entity sllinks.dsl		system "sllinks.dsl" subdoc>
<!entity slback.dsl		system "slback.dsl" subdoc>
]>

<!-- $Id$ -->

<docblock>
<title>Starlink to HTML stylesheet
<description>
<p>This is the DSSSL stylesheet for converting the Starlink DTD to HTML.

<p>Requires Jade, for the non-standard functions.  Lots of stuff learned from 
Mark Burton's dbtohtml.dsl style file, and Norm Walsh's DocBook DSSSL
stylesheets. 

<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council
<history>
<change author=ng date='09-FEB-1999'>Released a version 0.1 to the other
Starlink programmers.
</history>

<codereference doc="lib.dsl" id="code.lib">
<title>Library code
<description>
<p>Some of this library code is from the standard, some from Norm
Walsh's stylesheet, other parts from me

<codereference doc="common.dsl" id="code.common">
<title>Common code
<description>
<p>Code which is common to both the HTML and print stylesheets.

<codereference doc="slnavig.dsl" id=code.navig>
<title>Navigation code
<description>
Code to support the generation of HTML filenames, and the
links which navigate between documents

<codereference doc="maths.dsl" docid="code.maths.img" id="code.maths">
<title>Maths processing
<description>
Code to process the various maths elements.

<codereference doc="slhtml.dsl" id=code.html>
<title>HTML support
<description>
Code to support HTML generation

<codereference doc="slparams.dsl" id=code.params>
<title>Parameters
<description>
Miscellaneous parameters, which control detailed behaviour of the stylesheet.

<codereference doc="tables.dsl" id=code.tables>
<title>Tables support
<description>
Simple support for tables.

<codereference doc="sllinks.dsl" id=code.links>
<title>Inter- and Intra-document linking
<description>Handles <code/ref/, <code/docxref/, <code/webref/ and <code/url/.
Imposes the link policy.

<codereference doc="slback.dsl" id=code.back>
<title>Back-matter
<description>Handles notes, bibliography and indexing

<codegroup 
  use="code.lib code.common code.maths code.html code.navig code.params code.tables code.links code.back" 
  id=html>
<title>HTML-specific stylesheet code
<description>
This is the DSSSL stylesheet for converting the Starlink DTD to HTML.

<misccode>
<description>Declare the flow-object-classes to support the SGML
transformation extensions of Jade.</description>
<codebody>
(declare-flow-object-class element
  "UNREGISTERED::James Clark//Flow Object Class::element")
(declare-flow-object-class empty-element
  "UNREGISTERED::James Clark//Flow Object Class::empty-element")
(declare-flow-object-class document-type
  "UNREGISTERED::James Clark//Flow Object Class::document-type")
(declare-flow-object-class processing-instruction
  "UNREGISTERED::James Clark//Flow Object Class::processing-instruction")
(declare-flow-object-class entity
  "UNREGISTERED::James Clark//Flow Object Class::entity")
(declare-flow-object-class entity-ref
  "UNREGISTERED::James Clark//Flow Object Class::entity-ref")
(declare-flow-object-class formatting-instruction
  "UNREGISTERED::James Clark//Flow Object Class::formatting-instruction")
(define debug
  (external-procedure "UNREGISTERED::James Clark//Procedure::debug"))

(define %stylesheet-version%
  "Starlink HTML Stylesheet version 0.1")

<!-- include the other parts by reference -->

&slroutines.dsl

&sldocs.dsl

&slsect.dsl

&slmisc.dsl

<misccode>
<description>
The root rule.  This generates the HTML documents, then generates the
manifest and extracts the maths to an external document for postprocessing.
<codebody>
(root
 (make sequence
   (process-children)
   (make-manifest)
   (get-maths)))

<func>
<routinename>make-manifest
<description>Construct a list of the HTML files generated by the main
processing.  Done only if <code/%html-manifest%/ is true, giving the
name of a file to hold the manifest.
<returnvalue none>
<argumentlist>
<parameter optional default='(current-node)'>nd<type>singleton-node-list
  <description>Node which identifies the grove to be processed.
<codebody>
(define (make-manifest #!optional (nd (current-node)))
  (let ((rde (document-element nd)))
    (if %html-manifest%
	(make entity system-id: %html-manifest%
	      (with-mode make-manifest-mode
		(process-node-list
		 (node-list rde		;include current file
			    (node-list-filter-by-gi
			     (select-by-class (descendants rde)
					      'element)
			     (chunk-element-list))))))
	(empty-sosofo))))

(mode make-manifest-mode
  (default 
    (make sequence
      (make formatting-instruction data: (html-file))
      (make formatting-instruction data: "
")
      )))

<codegroup>
<title>The default rule
<description>This has to be in a separate group
(<code/style-specification/ in the terms of the DSSSL architecture),
so that it doesn't take priority over mode-less rules in other process
specification parts.  See the DSSSL standard, sections 7.1 and 12.4.1.
<misccode>
<description>The default rule
<codebody>
(default
  (process-children))
;; Make text that comes from unimplemented tags easy to spot
;(default
;  (make element gi: "FONT"
;	attributes: '(("COLOR" "RED"))
;	(make entity-ref name: "lt")
;	(literal (gi))
;	(make entity-ref name: "gt")
;	(process-children)
;	(make entity-ref name: "lt")
;	(literal "/" (gi))
;	(make entity-ref name: "gt")
;	))
