/// The configuration file of DIL.
///
/// The file is searched for in the following order:
/// $(OL
///   $(LI The file path set in the environment variable DILCONF.)
///   $(LI The current working directory.)
///   $(LI The directory set in the environment variable HOME.)
///   $(LI The executable's directory.)
///   $(LI The /etc directory on Linux.)
/// )
/// The program will fail with an error msg if this file couldn't be found.$(BR)
///
/// Any environment variable used inside a string is expanded to its value.
/// The variables BINDIR and DATADIR are set by DIL. Examples:
/// $(UL
///   $(LI ${HOME} -> the home directory (e.g. "/home/name" or "C:\Documents and Settings\name").)
///   $(LI ${BINDIR} -> the absolute path to the executable's directory (e.g. "/home/name/dil/bin" or "C:\dil\bin").)
///   $(LI ${DATADIR} -> the data directory of DIL (e.g. "/home/name/dil/data" or "C:\dil\data").)
/// )
///
/// Relative paths are resolved and made absolute using the current working directory.
module dilconf;

/// Files needed by DIL are located in this directory.
var DATADIR = "${BINDIR}/../../data";

/// Predefined version identifiers.
var VERSION_IDS = [];

/// An array of import paths to look for modules.
var IMPORT_PATHS = []; /// E.g.: ["src/", "import/"]

/// DDoc macro file paths.
///
/// Macro definitions in ddoc_files[n] override the ones in ddoc_files[n-1].$(BR)
///
/// E.g.: ["src/mymacros.ddoc", "othermacros.ddoc"]
var DDOC_FILES = ["${DATADIR}/predefined.ddoc"];

/// Path to the language file.
var LANG_FILE = "${DATADIR}/lang_en.d";
/// Path to the xml map.
var XML_MAP = "${DATADIR}/xml_map.d";
/// Path to the html map.
var HTML_MAP = "${DATADIR}/html_map.d";

/// Path to the files of kandil.
var KANDILDIR = "${DATADIR}/../kandil";

/// Customizable formats for error messages.
///
/// $(UL
///   $(LI 0: file path to the source text.)
///   $(LI 1: line number.)
///   $(LI 2: column number.)
///   $(LI 3: error message.)
/// )
var LEXER_ERROR = "{0}({1},{2})L: {3}";
var PARSER_ERROR = "{0}({1},{2})P: {3}"; /// ditto
var SEMANTIC_ERROR = "{0}({1},{2})S: {3}"; /// ditto

/// The width of the tabulator character set in your editor.
///
/// Important for calculating correct column numbers for compiler messages.
var TAB_WIDTH = 4;
