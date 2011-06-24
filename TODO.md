# TODO

## Tasks with unclassified time period

* DONE Pass receiver through to spatials calls, or construct receiver
  from method calls in spatials calls.
* DONE Write methods to create spatial objects.
* DONE Use show_text_with_positioning to construct text runs.
* DONE Record spatial objects that result from spatials method calls.
* DONE Complete the covert method - write spatial hashs out to xml.
* DONE Write Spatial class with alter method.

## Small tasks, 10 minutes or so

* DONE Improve inclusion of spatial object modules. Shouldn't need to 
  call, for example, include_text_runs.
* DONE Pass set of previously constructed spatial objects to sptials calls,
  via a new method in parser - parser.previous :text_runs { ... }.
  Spatial objects such as margins depend on the positions of text
  runs.
* DONE Determine units of and apply correctly :rise and :leading.
* Handle UserUnit transformations.
* DONE Reset global text state at the end of each page.
* Position coords appear a bit above and to the right of where they
  should. Graphics state or page translation?
* DONE Spaces appear one character before where they should in
  text_chunks.
* Apostrophes cause a chunk break.
* DONE Split views into View, PdfView, PngView. Pass only explicit
  spatials in an easier form for Views. Move into lib/view.
* DONE Move analysis modules into lib/analysis.
* Non-ascii chars that are transliterated are appearing in output one
  place before they should. Transliterated chars also cause a word
  break. Not getting their width correct in glyph width dict?
  ! Looks like this occurs for chars whose codes are in the font's
  @differences map.
* pdf_view.rb shouldn't call doc.go_to_page more than once per page.
  Causes objects to be rendered on the wrong page.
* pdf_view.rb should keep the same auto colour for object types on
  different pages.
* Some margins calculated with negative x or y. Because of characters
  incorrectly calculated to be out of the mediabox?
* Some characters don't get a correct width.
* Should merge with region above from right to left (or, in the
  opposite direction to writing direction). Causes last two lines of
  paragraphs to merge incorrectly.
* DONE Figure out which state, and when (text object start/end, page
  start/end, text show ops) should be pushed/popped.

## Tasks, up to 3 hours

* DONE Handle new line operators, and all show text operators.
* DONE Handle font metrics correctly, including glyph widths, displacement
  vectors and bounding boxes.
* Handle text matrix when it is applying a rotation.
* Handle type 3 font font matrices.
* Handle writing mode selection for composite fonts (type 0)
  (different font metrics). 
* Some way of splitting SpatialObjects by page.
* !! Handle type 3 font operators. These may not be supported by 
  pdf-reader!
* DONE Add spatials parser.post { }, use in text_runs to sort and merge
  adjacent runs. Or split text_runs into characters and text_runs.
* Implement PNG output. Should be able to specify opacity of each
  spatial object type, so that text runs can be seen even though
  groups and section are overlayed. Or, low opacity for all, auto
  select a different colour for each type.
* DONE For some PDFs, character width and height not detected correctly.
* DONE In some PDFs, ascent, descent and bbox info for fonts is not
  available. Seems to be those fonts whose base font is one of the
  base 14.
* DONE Prawn doesn't render over some PDFs.
* DONE Assign colour, font, font size to character objects. Pass on to
  text chunks and regions.
* DONE Characters appear too wide in some3.pdf test PDF.
* Characters on pages with images are sometimes not detected. Graphics
  state issue?

## Long tasks, greater than 3 hours

* Examine text_runs spatial definition and determine processing that
  is generic. Move into Parser methods. E.g. Handling global /
  object-specific state.
* Better organise pre/object/post call storage in pdf.rb . Perhaps
  a pre and post per object type.
