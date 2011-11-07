# pdf-extract

Welcome! pdf-extract is a some-what generic PDF content extraction toolkit with a 
strong focus on extracting meaningful text from a PDF, such as a scholarly article's
references.

The latest version of pdf-extract is 0.0.7. As such it is in active development
and should not be expected to work out of the box for your PDFs. However, if you're
lucky, or by tweaking pdf-extract's setting you should be able to get reasonable
results when extracting regions of text, column boundries, headers, footers,
scholarly references and so on.

The development of pdf-extract has so far concentrated on the extraction of unstructured
references from scholarly articles. To do that pdf-extract has to understand regions
of text, text flow between columns and header/subheader section separation. However the
extraction of these more generic features is currently only as good as is required to
find scholarly references. In the future pdf-extract will better support generic 
extraction, such as regions and so on. Disclaimers aside, it is currently possible to 
get good text region, header, footer and column boundry extraction by only tweaking 
three values, namely the char_slop, line_slop and words_slop settings. These define
the maximum permitted space between characters, words and lines when joining characters
first into lines and then regions of text. For example:

  $ pdf-extract extract --regions myfile.pdf

This will produce XML output defining regions of text within the PDF. If it looked
like regions were joined together, a smaller line slop could be applied:

  $ pdf-extract extract --regions --set line_slop:0.5 myfile.pdf

The default line_slop can be printed to screen with the command:

  $ pdf-extract settings

## Usage

 - Extract a few spatial object types

 - Mark

 - Settings

### Selecting spatial object types

### Extracting content as XML

#### No line mode

#### Outline mode (hide all content)

### Marking a PDF with spatial object boundries

## Design

pdf-extract's is split into functional units called "parsers", each of which 
constructs a single "spatial object" type. For example, pdf-extract comes with 
a number of default parsers, each one of which outputs one of these types of 
spatial object:

- characters
- text runs
- regions
- columns
- headers
- footers
- bodies

Each of these parsers constructs a list of spatial objects (modelled as a list of
raw Ruby Hash objects) from either PDF page streams or the output of other
parsers. Therefore some parsers have dependency on other parsers. For example, from
the list above only the "characters" parser does not have dependnecy on other parser
types. It creates character spatial objects, each of which defines the spatial location 
of one character within the PDF, from only the content of the PDF. The "text runs"
parser depends on "characters", which it takes as input and combines together to form
lines of text, or "text runs". "Regions" depends on "text runs", which it combines
into regions or blocks of consecutive lines.

Other parsers may not output spatial objects that represent text but instead some
form of feature boundry. "Columns", "headers" and "footers" are examples of such 
parsers. The "columns" parser dependends on region spatial objects, which it takes
as input, then analyzes each page for space that is not covered by a text region,
and finally uses this information to output "column" spatial objects that represent
the boundries of columns.

Other parser types depend on the output of more than one other parser. pdf-extract
can try to split the textual content of a PDF into sections. In this case, the flow
of text between columns must be understood, requiring the "sections" parser to
examine both column boundries and their incidence with text region boundries.

pdf-extract comes with a number of default parsers which are split into three
categories. The first category, model, includes generic parsing of text into
"characters", "text runs" and "regions". The second, analysis applies analysis that
is usually only relevent to article or report PDFs, such as the detection of "headers",
"footers", "bodies", "columns" and "sections". Finally, the "reference" parser extracts
unstructured citations and is only really applicable to scholarly articles. 

## Extensibility

Additional parsers can be registered with pdf-extract. New parsers can extract
information directly from the PDF or use the output of other parsers.

 - Paged and non-paged

 - Settings

pdf-extract also contains an extensible "view" component. Extracted spatial objects
can be viewed in a number of ways, and pdf-extract currently allows extracted
spatial objects to be represented as XML or raw Ruby Hashes. There is also a PDF
view that renders spatial object boundries over the top of input PDFs.

