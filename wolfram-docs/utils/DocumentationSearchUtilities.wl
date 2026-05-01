(* Wolfram Language Function Documentation Search Utilities *)

(* 
Public function usage can be found between the BeginPackage[...] and Begin[...] lines

Function definition sections are delineated with comments that look like:

(* ================ fun Start ================ *)

*fun definitions*

(* ================ fun End ================ *)

*)


Clear["DocumentationSearchUtilities`*", "DocumentationSearchUtilities`Private`*"]

BeginPackage["DocumentationSearchUtilities`"];


DocuSearch::usage = "DocuSearch[query, \"Start\" -> i, \"Limit\" -> n] returns search results for a given query string. The options Start (default: 1) \
and Limit (default: 5) are used for pagination of results. \n\n" <> StringTemplate[
	"The returned association has the following keys: `1`. \n\nThe key \"Matches\" returns a list of associations with keys determined by the value of the \"MetaData\" option. By default these keys are: `2`"][
	{"Query", "ParsedQuery", "Start", "Limit", "SearchTime", "TotalMatches", "Suggestions", "Matches"},
	{"Title", "Type", "ShortenedSummary", "URI", "URL", "Description", "Context"}
];


FetchAndCacheOnlineDocPage::usage = "FetchAndCacheOnlineDocPage[url] fetches the markdown version of a documentation page at a given URL. \
If successful, it will locally cache the page and return the file name of the cache.
FetchAndCacheOnlineDocPage[url, forceQ] allows the user to specify if the re-caching should be forced. The default for forceQ is False."

OnlineDocsQuery::usage = "OnlineDocsQuery[url, elements] extracts specific elements from the online documentation at the requested URL. The default value for elements is \"Elements\". The argument url can also be used to point to a local cache of the page.
OnlineDocsQuery[url, elements, spec] further specifies what to extract from a given element. The default is All.

Possible elements are:
Elements: A list of the possible elements that can be extracted.
YAML: A string with the YAML that can be found at the top of the file.
StructuredYAML: A Wolfram representation of the YAML front matter (i.e., associations and lists).
FullText: The entire markdown text.
Sections: An association with all the markdown section headers found in the file and the corresponding text.
{el_1, el_2, ...}: Extract multiple elements. Returns an association with the requested elements.

Possible values for the 3rd argument spec are:
SizeSummary: The amount of data in a given element. Returns a string with the relevant information such as number of elements, dimensions or keys.
Elements: The keys found in an extracted element. Only works for elements that return an association or a list of associations.
Key[key]: Extracts a specific key or column from the element. Only applicable to key-value type elements.
{Key[key_1], Key[key_2], ...}: Extracts multiple keys."

DataSizeSummary::usage = "DataSizeSummary[expr] returns a formatted string summarizing the size and structure of the given expression.
For strings, returns character count and line count.
For lists of associations (datasets), returns row count and column information. 
For arrays, returns dimensions and total element count.
For regular lists, returns element count.
For associations, returns key count and key names. 
For other expressions, returns argument count and head type."

YAMLToAssociation::usage = "YAMLToAssociation[string] converts a YAML string to an association."

Begin["`Private`"]

Needs["DocumentationSearch`" -> "ds`"]


(* ================ DocuSearch Start ================ *)

Options[DocuSearch] = {
	"MetaData" -> {"Title", "Type", "ShortenedSummary", "URI", "URL", "Description", "Context"},
	"Start" -> 1, "Limit" -> 5
};

DocuSearch[q_String, opts : OptionsPattern[]] := Enclose @ Module[{
	headers = OptionValue["MetaData"],
	result
},
	result = ConfirmMatch[
		ds`SearchDocumentation[q,
			"MetaData" -> headers,
			"Start" -> OptionValue["Start"], "Limit" -> OptionValue["Limit"]
		],
		KeyValuePattern[{"Query" -> _, "Matches" -> _List}],
		"Unexpected return value for DocumentationSearch`SearchDocumentation"
	];
	MapAt[
		ConfirmMatch[
			If[ Length[#] > 0,
				FromTabular[Tabular[#, headers], "Rows"],
				{}
			],
			{___Association},
			"Unexpected search results"
		]&,
		Association @ result,
		Key["Matches"]
	]
];

(* ================ DocuSearch End ================ *)


(* ================ DocPageSkeleton Start ================ *)

DocPageSkeleton::usage = "DocPageSkeleton[uri] returns an association with summary data in a doc page referred to by a given URI string (such as \"ref/Plot\").
DocPageSkeleton[{uri_1, uri_2, ...}] returns an association where the keys are the URIs and the values are the summary results. URIs that were not \
found will be dropped. \n\n" <> StringTemplate[
	"The returned summary data has the following possible keys (and potentially others), depending on the type of URI:\n`1`"][
	{
		"Abstract", "Caption", "Context", "Description", "Dictionary",  "DisplayedCategory", "ExactTitle", "ExampleText", "Frequency", 
		"FunctionsSubsection", "Keywords", "Language", "LinkedSymbols", "Location", "MathCaption", "NormalizedTitle", "NotebookPackage", 
		"NotebookStatus", "NotebookType", "PacletName", "ReferredBy", "SeeAlso", "ShortNotations", "SnippetPlaintext", "Synonyms", 
		"TableText", "Text", "Title", "TokenizedNotebookType", "URL", "Usage"
	}
];

DocPageSkeleton[uri_] := Enclose @ Module[{
	input = uri,
	files,
	results,
	output
},
	ConfirmMatch[input, _String | {___String}, "Invalid URI specification"];
	files = Discard[FailureQ] @ AssociationMap[
		uriToFileName,
		Flatten[{input}]
	];
	output = If[ Length[files] === 0,
		files,
		results = ConfirmMatch[
			ds`Skeletonizer`Skeletonize[Values[files]],
			{___Association},
			"Internal error"
		];
		Join[
			AssociationThread[Keys[files], Missing["NotFound"]],
			AssociationThread[Lookup[results, "URI"], KeyDrop[results, "URI"]]
		]
	];
	If[ ListQ[input],
		output,
		First[output, Missing["NotFound"]]
	]
];

uriToFileName[uri_String] := Replace[
	Module[{nb},
		UsingFrontEnd @ WithCleanup[
			nb = NotebookOpen["paclet:" <> uri, Visible -> False]
			,
			If[ !FailureQ[nb] && MatchQ[nb, _NotebookObject],
				NotebookFileName[nb],
				nb
			]
			,
			NotebookClose[nb]
		]
	],
	Except[_?FileExistsQ] :> $Failed
];
uriToFileName[_] := $Failed;

(* ================ DocPageSkeleton End ================ *)



(* ================ FetchAndCacheOnlineDocPage Start ================ *)

$cacheDir = FileNameJoin[ParentDirectory @ DirectoryName[$InputFileName], "cache"];

FetchAndCacheOnlineDocPage[url_, forceQ : _ : False] := Enclose @ Module[{
	mdURL = Confirm @ urlToMarkDown[url],
	cacheFileName, cachedQ, mdString
},
	ConfirmAssert[StringQ[mdURL] && StringStartsQ[mdURL, "https://reference.wolfram.com"], "Not a valid URL"];
	cacheFileName = FileNameJoin[{
		$cacheDir,
		Splice @ FileNameSplit[StringDelete[mdURL, StartOfString ~~ Shortest[__] ~~ "/language/"]]
	}];
	cachedQ = FileExistsQ[cacheFileName] && !TrueQ[forceQ];
	If[ !TrueQ[cachedQ],
		mdString = Confirm[Import[mdURL, "String"], "Import failure"];
		ConfirmAssert[
			StringQ[mdString] && StringStartsQ[mdString, "---\ntitle:"]
		];
		Export[cacheFileName, mdString, "String"]
	];

	ConfirmBy[cacheFileName, FileExistsQ]
];

urlToMarkDown[url_String] /; !StringEndsQ[url, ".en.md"] := StringDelete[url, ".html" ~~ EndOfString] <> ".en.md";
urlToMarkDown[expr_] := expr;


(* ================ FetchAndCacheOnlineDocPage End ================ *)


(* ================ DataSizeSummary Start ================ *)

DataSizeSummary[s_String] := StringTemplate["String: `1` characters, `2` lines"][
	StringLength[s],
	StringCount[s, "\n"] + 1
];

DataSizeSummary[l : {___Association}] /; Length[l] > 0 := Module[{
	rows = Length[l],
	cols = DeleteDuplicates @ Flatten[Keys /@ l]
},
	StringTemplate["Dataset: `1` rows, `2` columns (`3`)"][
		rows,
		Length[cols],
		StringRiffle[cols, ", "]
	]
];

DataSizeSummary[l : {___Association}] := "Dataset: 0 rows, 0 columns";

DataSizeSummary[l_List] /; ArrayQ[l] := Module[{
	dims = Dimensions[l]
},
	StringTemplate["Array: dimensions `1` (`2` elements)"][
		dims,
		Times @@ dims
	]
];

DataSizeSummary[l_List] := StringTemplate["List: `1` elements"][Length[l]];

DataSizeSummary[a_Association] := StringTemplate["Association: `1` keys (`2`)"][
	Length[a],
	StringRiffle[Keys[a], ", "]
];

DataSizeSummary[expr_] := StringTemplate["Expression: `1` arguments (Head: `2`)"][Length[expr], Head[expr]];

(* ================ DataSizeSummary End ================ *)





(* ================ OnlineDocsQuery Start ================ *)

(* Additional OnlineDocsQuery implementations *)

OnlineDocsQuery[url_] := OnlineDocsQuery[url, "Elements"];

OnlineDocsQuery[url_, "Elements"] := {
	"Elements", "YAML", "StructuredYAML", "FullText", "Sections"
};

OnlineDocsQuery[url_, element_, "SizeSummary"] := Replace[
	OnlineDocsQuery[url, element, All],
	{
		data : _String | _List | _Association :> DataSizeSummary[data],
		_ :> Missing["NotApplicable"]
	}
];

OnlineDocsQuery[url_, el_String, "Elements"] := Replace[
	OnlineDocsQuery[url, el, All],
	{
		a_Association :> Keys[a],
		l : {___Association} :> DeleteDuplicates @ Flatten[Keys /@ l],
		_ :> Missing["NotApplicable"]
	}
];

OnlineDocsQuery[url_, el_String, part : _Key | {__Key}] := Replace[
	OnlineDocsQuery[url, el, All],
	{
		a_Association :> a[[part]],
		l : {___Association} :> l[[All, part]],
		_ :> Missing["NotApplicable"]
	}
];

OnlineDocsQuery[url_, "FullText", ___] := Replace[
	If[ FileExistsQ[url],
		url,
		FetchAndCacheOnlineDocPage[url]
	],
	s_String :> Import[s, "String"]
];

OnlineDocsQuery[url_, "YAML", ___] := Replace[
	OnlineDocsQuery[url, "FullText", All],
	s_String :> First[
		StringCases[s, StartOfString ~~ "---" ~~ Shortest[__] ~~ "\n---", 1],
		Missing["NotFound"]
	]
];

OnlineDocsQuery[url_, "Sections"] := OnlineDocsQuery[url, "Sections", All]

OnlineDocsQuery[url_, "Sections", All] := Replace[
	OnlineDocsQuery[url, "FullText"],
	s_String :> extractSections[s]
];

OnlineDocsQuery[url_, "StructuredYAML"] := OnlineDocsQuery[url, "StructuredYAML", All];

OnlineDocsQuery[url_, "StructuredYAML", All] := Replace[
	OnlineDocsQuery[url, "YAML", All],
	s_String :> YAMLToAssociation[s]
];


OnlineDocsQuery[url_, elements_List, rest___] := AssociationMap[
	OnlineDocsQuery[url, #, rest]&,
	elements
];

OnlineDocsQuery[args___] := Failure["InvalidArguments",
	<|"Function" -> OnlineDocsQuery, "Arguments" -> Hold[args]|>];


extractSections[s_] := Enclose @ Module[{
	text = s,
	headerIndices, headers,
	sectionIndices, sections
},
	headerIndices = ConfirmBy[
		StringPosition[text, StartOfLine ~~ "#" ~~ Shortest[__] ~~ EndOfLine],
		ListQ
	];
	If[ headerIndices =!= {}
		,
		headers = StringTrim @ StringTake[text, headerIndices];
		headerIndices = Append[headerIndices, {0, 0}];
		sectionIndices = Transpose @ {
			Most[headerIndices[[All, 2]]] + 1,
			Rest[headerIndices[[All, 1]]] - 1
		};
		sections = StringTrim @ StringTake[text, sectionIndices];
		AssociationThread[headers, sections]
		,
		<||>
	]
]

(* ================ OnlineDocsQuery End ================ *)


(* ================ YAMLToAssociation Start ================ *)

YAMLToAssociation[yaml_String] := Enclose @ Module[{
	inds, lines, data
},
	inds = StringPosition[yaml, StartOfLine ~~ LetterCharacter ~~ Shortest[__] ~~ ":"];
	If[ inds === {}
		,
		<||>
		,
		ConfirmAssert[MatrixQ[inds, IntegerQ]];
		inds = Append[inds[[All, 1]], 0];
		lines = ConfirmMatch[
			StringTake[
				yaml,
				Transpose @ {Most[inds], Rest[inds] - 1}
			],
			{__String}
		];
		data = ConfirmBy[Association[parseYAMLLine /@ lines], AssociationQ]
	]
];

(* Helper function to parse YAML lines into Wolfram associations *)
parseYAMLLine[s_] := Module[{key, val},
	key = StringTrim @ First @ StringCases[s, StartOfString ~~ Shortest[__] ~~ ":", 1];
	val = StringTrim @ StringDelete[s, StartOfString ~~ key];
	key = StringTrim[key, ":"];
	key -> parseYAMLValue[val]
];

parseYAMLValue[s_] /; !StringStartsQ[s, "-"] := StringTrim[s, ("\"" | WhitespaceCharacter)..];
parseYAMLValue[s_] := With[{
	lines = StringSplit[s, "\n"]
},
	StringTrim[lines, ("-" | WhitespaceCharacter)..]/; AllTrue[lines, StringStartsQ["-"]]
];
parseYAMLValue[s_] := With[{
	blocks = StringReplace[
		StringSplit[s, WhitespaceCharacter ... ~~ "-" ~~ WhitespaceCharacter ...],
		"\n" ~~ WhitespaceCharacter .. -> "\n"
	]
},
	YAMLToAssociation /@ blocks
];

(* ================ YAMLToAssociation End ================ *)

End[]

EndPackage[];