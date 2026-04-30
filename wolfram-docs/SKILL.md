---
name: wolfram-docs
description: 'Search and retrieve Wolfram Language documentation programmatically. Use for finding functions, extracting usage examples, analyzing documentation structure, caching reference materials. Triggers: "search Wolfram docs", "find function documentation", "get Wolfram examples", "documentation analysis".'
argument-hint: 'query or function name to search for'
---

# Wolfram Documentation Search and Retrieval

Systematically search, extract, and analyze Wolfram Language documentation using the DocumentationSearchUtilities package for LLM workflows.

## When to Use

- **Function discovery**: Find Wolfram functions by description or use case
- **Usage extraction**: Get detailed function documentation and examples
- **Documentation analysis**: Extract structured information from doc pages
- **Reference caching**: Build local documentation databases
- **Content mining**: Parse YAML metadata and sections from online docs

## Setup

First, load the documentation utilities:

```wolfram
SetDirectory["path/to/wolfram-docs"];
Get["utils/DocumentationSearchUtilities.wl"]
```

All functions provide detailed usage information on-demand via `?FunctionName` or `FunctionName::usage`. The usage messages contain comprehensive parameter descriptions, return value structures, and example patterns.

## Core Functions

### 1. Search Documentation (`DocuSearch`)

Search the Wolfram documentation database with pagination support.

**Key capabilities:**
- Full-text search across documentation
- Customizable metadata extraction  
- Paginated results for large result sets
- Returns structured data with titles, URIs, descriptions, and context

**Basic pattern:**
```wolfram
(* Search for plotting functions *)
results = DocuSearch["plot data visualization"];

(* Get more results with pagination *)
moreResults = DocuSearch["plot", "Start" -> 6, "Limit" -> 10];

(* Custom metadata fields *)
customResults = DocuSearch["integration", 
  "MetaData" -> {"Title", "URI", "Usage", "SeeAlso"}];
```

### 2. Cache Online Documentation (`FetchAndCacheOnlineDocPage`)

Download and locally cache online documentation pages for offline analysis.

**Key capabilities:**
- Automatic caching to local directory structure
- Markdown format preservation
- Force refresh options
- URL validation and conversion

**Caching workflow:**
```wolfram
(* Cache a specific page *)
cacheFile = FetchAndCacheOnlineDocPage[
  "https://reference.wolfram.com/language/ref/Plot.html"
];

(* Force refresh existing cache *)
FetchAndCacheOnlineDocPage[url, True];
```

### 3. Extract Documentation Elements (`OnlineDocsQuery`)

Parse specific elements from cached or online documentation pages.

**Key capabilities:**
- YAML frontmatter extraction and parsing
- Section-by-section content parsing
- Element size analysis
- Selective data extraction by keys

**Element extraction patterns:**
```wolfram
(* Get available elements *)
OnlineDocsQuery[url, "Elements"]

(* Extract specific sections *)
sections = OnlineDocsQuery[url, "Sections"];
yaml = OnlineDocsQuery[url, "StructuredYAML"];

(* Size analysis *)
OnlineDocsQuery[url, "FullText", "SizeSummary"]

(* Selective extraction *)
OnlineDocsQuery[url, "StructuredYAML", Key["title"]]
```

### 4. Data Structure Analysis (`DataSizeSummary`)

Generate formatted summaries of data structures for analysis and reporting.

**Analysis capabilities:**
- String metrics (characters, lines)
- Dataset analysis (rows, columns, keys)
- Array dimensions and element counts
- Association structure descriptions

## Workflow Examples

### Utilitiy function usage information

```wolfram
?DocuSearch
?FetchAndCacheOnlineDocPage
?OnlineDocsQuery
?DataSizeSummary
```


### Documentation Discovery Workflow

```wolfram
(* 1. Search for functions by topic *)
searchResults = DocuSearch["machine learning classification"];

(* 2. Extract URIs for detailed analysis *)
uris = Lookup[searchResults["Matches"], "URI"];

(* 3. Cache relevant documentation for offline use *)
urls = Lookup[searchResults["Matches"], "URL"];
cacheFiles = FetchAndCacheOnlineDocPage /@ urls;
```

### Content Analysis Workflow

```wolfram
(* 1. Cache documentation pages *)
urls = {
  "https://reference.wolfram.com/language/ref/Plot.html",
  "https://reference.wolfram.com/language/ref/Predict.html"
};

cacheFiles = FetchAndCacheOnlineDocPage /@ urls;

(* 2. Extract structured content *)
url = First[urls];
sectionHeaders = OnlineDocsQuery[url, "Sections", "Elements"]

(* Out[] = {"# Plot", "## Details and Options", ..., "### Neat Examples (1)", "## See Also", ...}*)

(* Extract a specific section *)
OnlineDocsQuery[url, "Sections", Key["### Neat Examples (1)"]]

(* 3. Check data size of a YAML element *)

DataSizeSummary @ OnlineDocsQuery[url, "StructuredYAML", Key["related_guides"]]

(*Out[] := "Dataset: 5 rows, 2 columns (title, link)"*)

(* extract the related guides for further analysis *)

OnlineDocsQuery[url, "StructuredYAML", Key["related_guides"]]

(* 4. Find specific elements in meta data and extract them *)
OnlineDocsQuery[url, "StructuredYAML", "Elements"]

(*Out[]= {"title", "language", "type", "summary", "keywords", "canonical_url", "source", "related_guides", "related_functions"} *)

DataSizeSummary @ OnlineDocsQuery[url, "StructuredYAML", Key["related_guides"]]

(* 5. Extract data from full text using regular expressions *)
StringCases[
  OnlineDocsQuery[url, "FullText"],
  RegularExpression["regular expression pattern to match specific content"]
]

```

## LLM Integration Patterns

### Function Recommendation System
Use search results to recommend appropriate Wolfram functions based on user descriptions.

### Example Generation  
Extract usage examples and code patterns from documentation for educational content.

### Documentation Quality Analysis
Analyze documentation completeness and structure across function categories.

### Reference Compilation
Build comprehensive reference materials by aggregating information from multiple sources.

## Best Practices

1. **Incremental caching**: Cache documentation progressively to build a local reference
2. **Metadata standardization**: Use consistent metadata fields across searches  
3. **Error handling**: Check return values for `Missing["NotFound"]` and `$Failed`
4. **Batch operations**: Process multiple URIs together for efficiency
5. **Size monitoring**: Use `DataSizeSummary` to manage memory usage with large datasets
6. **Element specification**: Use the `"Elements"` specification in `OnlineDocsQuery` to focus on relevant content for analysis and avoid unnecessary data processing. If necessary, add custom code (`KeyTake`, `Part`, `StringCases` etc.) to filter or transform extracted data for specific use cases.

## Troubleshooting

**Search returns no results**: Verify search terms, try broader queries, check for typos  
**Caching fails**: Ensure internet connectivity, validate URLs, check disk space  
**URI resolution errors**: Use exact URI format from search results, verify function exists  
**Memory issues with large datasets**: Process in smaller batches, use selective extraction  

## Output Formats

All functions return structured Wolfram Language associations and lists suitable for:
- Direct analysis and manipulation
- Export to JSON/CSV for external tools  
- Integration with other Wolfram Language workflows
- Serialization for long-term storage

The utilities maintain consistent data structures across operations, making them suitable for building automated documentation analysis pipelines.

## Folder Structure

The wolfram-docs skill is organized as follows:

```
wolfram-docs/
├── SKILL.md                           # This skill documentation
├── utils/
│   └── DocumentationSearchUtilities.wl   # Core utility package
└── cache/                             # Local documentation cache
    ├── .gitignore                     # Cache exclusion rules
    ├── guide/                         # Cached guide documents
    │   └── *.en.md                    # Markdown format docs
    ├── ref/                           # Cached reference pages
    │   └── *.en.md                    # Function documentation
    └── tutorial/                      # Cached tutorial content
        └── *.en.md                    # Tutorial materials
```

**Key components:**
- **`utils/`**: Contains the main DocumentationSearchUtilities.wl package with all search and extraction functions
- **`cache/`**: Automatically managed storage for downloaded documentation, organized by document type (guide, ref, tutorial)
- **`.gitignore`**: Prevents cached files from being committed to version control, keeping the repository clean while allowing local caching

The cache directory structure mirrors the Wolfram documentation organization, making it easy to locate specific types of content.