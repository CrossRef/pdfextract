pdf-extract
===========

Install the latest version with:

    $ gem install pdf-extract

Welcome! pdf-extract is a some-what generic PDF content extraction toolkit with a 
strong focus on extracting meaningful text from a PDF, such as a scholarly article's
references.

The latest version of pdf-extract is **0.0.7**. As such it is in active development
and should not be expected to work out of the box for your PDFs. However, if you're
lucky, or by tweaking pdf-extract's setting you should be able to get reasonable
results when extracting regions of text, column boundaries, headers, footers,
scholarly references and so on.

The development of pdf-extract has so far concentrated on the extraction of unstructured
references from scholarly articles. To do that pdf-extract has to understand regions
of text, text flow between columns and header/subheader section separation. However the
extraction of these more generic features is currently only as good as is required to
find scholarly references. In the future it's hoped that pdf-extract will have better 
support of generic content extraction. Disclaimers aside, it is currently possible to 
get good text region, header, footer and column boundary extraction by only tweaking 
three values, namely the *char_slop*, *line_slop* and *words_slop* settings. These define
the maximum permitted space between characters, words and lines when joining characters
first into lines and then regions of text. For example:

    $ pdf-extract extract --regions myfile.pdf

This will produce XML output defining regions of text within the PDF. If this command
outputted regions of text that looked like they had been joined together, a smaller 
line slop could be applied:

    $ pdf-extract extract --regions --set line_slop:0.5 myfile.pdf

The default line_slop can be printed to screen with the command:

    $ pdf-extract settings

## On the command-line

To extract a spatial object type from a PDF on the command line use the extract 
command:

    $ pdf-extract extract --regions myfile.pdf

A list of spatial types can be printed to screen with:

    $ pdf-extract help

### Viewing spatial object boundaries

Spatial object boundaries can be drawn onto a PDF. This is helpful when debugging and
when trying to set reasonable values for pdf-extract's settings:

    $ pdf-extract mark --headers --footers --bodies myfile.pdf

This command will highlight the potential locations of headers, footers and the
spaces between (bodies) on each page in a new PDF, `myfile.mark.pdf`.

### Settings

Settings define the behavior of spatial object parsers. A list of settings, with
their descriptions, can be printed to screen with:

    $ pdf-extract settings

Settings can be altered on the command-line with the `--set` argument:

    $ pdf-extract extract --regions --set word_slop:0.3 --set line_slop:1 myfile.pdf

Alternatively, a configuration file can be passed on the command-line:

    $ pdf-extract extract --regions --config mysettings.json myfile.pdf

A configuration file is simply a JSON representation of a hash of some settings. For
example this settings file is equivalent to the command-line above that uses the
`--set` argument:

    mysettings.json
    ---------------
    {
      "word_slop": 0.3,
      "line_slop": 1
    }

### No line mode

By default, pdf-extract's XML output is verbose. When extracting regions or sections
the text of each spatial object will be split into many `<line>` elements. Instead
`--no-lines` will export text as a single text component of each region or section:

    $ pdf-extract extract --sections --no-lines myfile.pdf

### Outline mode (hide all content)

Using the `--outline` argument text content can be completely removed from XML output 
if only the spatial borders of objects are of interest:

    $ pdf-extract extract --sections --outline myfile.pdf

Though in this case pdf-extract will print many empty `<line>` elements within each 
`<section>` element. This can be avoided by using both '--no-lines' and `--outline`:

    $ pdf-extract extract --sections --outline --no-lines myfile.pdf

## As a Ruby library

There are two methods important to using pdf-extract as a Ruby library, 
`PdfExtract::parse` and `PdfExtract::view`. The first parses a PDF into spatial
objects represented by Ruby hashes. The second parses and then exports spatial
objects to a different representation, by default one of PDF, PNG or XML.
Here's an example of `parse`:

```ruby
require "pdf-extract"

objects = PdfExtract.parse "myfile.pdf" do |pdf|
  pdf.regions
  pdf.sections
  pdf.references
end
```

This code creates an `objects` hash which contains `region`, `section` and `reference`
spatial objects. Any spatial object type supported by pdf-extract can be parsed
by calling its spatial object method in a block like the one above. pdf-extract will
only execute explicitly declared parsers, like those above and parers from their 
dependency chains.

The example below shows how to read data from spatial objects:

```ruby
require "pdf-extract"

objects = PdfExtract.parse "myfile.pdf" {|pdf| pdf.regions}
objects[:regions].each do |region|
  puts "At (#{region[:x]}, #{region[:y]}):"
  puts PdfExtract::Spatial.get_text_content region
end
```

The `get_text_content` unwraps the lines within a region or section into a single
string. For other spatial types `object[:content]` can be used to access text
content, though `get_text_content` will return text content for all spatial object
types so it is best to always use it to access content.

The `PdfExtract::view` method can be used to output extracted content to XML, PNG
or PDF:

```ruby
require "pdf-extract"

xml = PdfExtract.view "myfile.pdf", :as => :xml do |pdf|
  pdf.footers
  pdf.headers
  pdf.columns
end
xml.write("myfile.xml")
```

## Design

pdf-extracts is composed of functional units called *parsers*, each of which 
constructs a single *spatial object* type. For example, pdf-extract comes with 
a number of default parsers, each one of which outputs one of these types of 
spatial object:

- characters
- line runs
- regions
- columns
- headers
- footers
- margins
- bodies
- titles
- sections
- references

Each of these parsers constructs a list of spatial objects (modeled as a list of
raw Ruby Hash objects) from either PDF page streams or the output of other
parsers. Therefore some parsers have dependency on other parsers. For example, from
the list above only the *characters* parser does not have dependency on other parser
types. It creates character spatial objects, each of which defines the spatial location 
of one character within the PDF, from only the content of the PDF. The *text runs*
parser depends on *characters*, which it takes as input and combines together to form
lines of text, or *text runs*. *Regions* depends on *text runs*, which it combines
into blocks of consecutive lines.

Other parsers may not output spatial objects that represent text but instead some
form of feature boundary. `Columns`, `headers` and `footers` are examples of such 
parsers. The `columns` parser dependents on region spatial objects, which it takes
as input, then analyzes each page for space that is not covered by a text region,
and finally uses this information to output `column` spatial objects that represent
the boundaries of columns.

Other parser types depend on the output of more than one other parser. pdf-extract
can try to split the textual content of a PDF into sections. In this case, the flow
of text between columns must be understood, requiring the "sections" parser to
examine both column boundaries and their incidence with text region boundaries.

pdf-extract comes with a number of default parsers which are split into three
categories. The first category, model, includes generic parsing of text into
`characters`, `text runs` and `regions`. The second, analysis applies analysis that
is usually only relevant to article or report PDFs, such as the detection of `headers`,
`footers`, `bodies`, `columns` and `sections`. Finally, the *reference* parser extracts
unstructured citations and is only really applicable to scholarly articles. 

## Extensibility

Additional parsers can be registered with pdf-extract. New parsers can extract
information directly from the PDF or use the output of other parsers. Here's one that
extracts DOIs from headers and footers:

```ruby
require "pdf-extract"

module Dois

  PdfExtract::Settings.default :dx_host, "dx.doi.org"

  def self.include_in pdf
    pdf.spatials :dois, :paged => true, :depends_on => [:regions, :headers, :footers] do |parser|
      dois = []
      current_header = nil
      current_footer = nil

      parser.before do
        dois = []
      end

      parser.objects :headers do |header|
        current_header = header
      end

      parser.objects :footers do |footer|
        current_footer = footer
      end

      parser.objects :regions do |region|
        if PdfExtract::Spatial.contains? header, region
            || PdfExtract::Spatial.contains? footer, region
          text = PdfExtract::Spatial.get_text_content(region)
          dois = dois + text.scan /doi:(10\.\d+\/[^\s]+)/
          dois = dois + text.scan /#{pdf.settings[:dx_host]}\/(10\.\d+\/[^\s]+)/
        end
      end
        
      parser.after do
        dois
      end       
  end
end     

PdfExtract::Pdf.add_parser Dois
```          

The above parser is dependent on `regions`, `headers` and `footers`. It also declares
that it wants `:paged` content, meaning that its before and after blocks are called
once for each page. If `:paged` is set to false before and after are called only once
for an entire PDF. Here paging allows us to look at the header and footer on each
page and check each region for incidence. Without paging, we would receive all headers
for all pages, then all footers for all pages, and finally all regions.

Though the use is contrived in the example above, settings can be declared via
`PdfExtract::Settings.default`. These must be declared to be accessed later in the
parser, using `pdf.settings`. An attempt to access an undeclared setting will result
in a fatal error.

