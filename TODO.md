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

## Tasks, up to 3 hours

* DONE Handle new line operators, and all show text operators.
* DONE Handle font metrics correctly, including glyph widths, displacement
  vectors and bounding boxes.
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

## Long tasks, greater than 3 hours

* Examine text_runs spatial definition and determine processing that
  is generic. Move into Parser methods. E.g. Handling global /
  object-specific state.
