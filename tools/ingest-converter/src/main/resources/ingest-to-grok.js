/**
 * Converts Ingest JSON to Grok.
 */
function json_to_grok(json) {

    function quote_string(string) {
        return "\"" + string.replace(/"/g, "\\\"") + "\"";
    }

    function wrap_in_curly(string) {
        return "{\n" + string + "\n}";
    }

    function create_field(name, content) {
        return name + " => " + content;
    }

    function create_hash_field(name, content) {
        return create_field(name, wrap_in_curly(content));
    }

    function create_hash(name, content) {
        return name + " " + wrap_in_curly(content);
    }

    /**
     * Converts Ingest/JSON style pattern array to Grok pattern array, performing necessary variable
     * name and quote escaping adjustments.
     * @param patterns Pattern Array in JSON formatting
     * @returns {string} Pattern array in Grok formatting
     */
    function create_pattern_array(patterns) {
        
        /**
         * Translates the JSON naming pattern (`name.qualifier.sub`) into the grok pattern
         * [name][qualifier][sub] for all applicable tokens in the given string.
         * This function correctly identifies and omits renaming of string literals.
         * @param string to replace naming pattern in
         * @returns {string} with Json naming translated into grok naming
         */
        function dots_to_square_brackets(string) {

            function token_dots_to_square_brackets(string) {
                return string.replace(/(\w*)\.(\w*)/g, "$1][$2").replace(/(\w+)}/g, "$1]}")
                    .replace(/{(\w+):(\w+)]/g, "{$1:[$2]");
            }

            var literals = string.match(/\(\?:%{.*\|-\)/);
            var i;
            var tokens = [];
            // Copy String before Manipulation
            var right = string;
            if (literals) {
                for (i = 0; i < literals.length; ++i) {
                    var parts = right.split(literals[i], 2);
                    right = parts[1];
                    tokens.push(token_dots_to_square_brackets(parts[0]));
                    tokens.push(literals[i]);
                }
            }
            tokens.push(token_dots_to_square_brackets(right));
            return tokens.join("");
        }
        
        return "[\n" + patterns.map(dots_to_square_brackets).map(quote_string).join(",\n") + "\n]";
    }

    /**
     * Fixes indentation in Grok string.
     * @param string Grok string to fix indentation in, that has no indentation intentionally with 
     * all lines starting on a token without preceding spaces.
     * @returns {string} Grok string indented by 3 spaces per level
     */
    function fix_indent(string) {
        
        function indent(string, shifts) {
            return new Array(shifts * 3 + 1).join(" ") + string;
        }
        
        var lines = string.split("\n");
        var count = 0;
        var i;
        for (i = 0; i < lines.length; ++i) {
            if (lines[i].match(/(\{|\[)$/)) {
                lines[i] = indent(lines[i], count);
                ++count;
            } else if (lines[i].match(/(\}|\])$/)) {
                --count;
                lines[i] = indent(lines[i], count);
            } else {
                lines[i] = indent(lines[i], count);
            }
        }
        return lines.join("\n");
    }

    var parsed = JSON.parse(json);
    var processors = parsed["processors"];
    return processors.map(function (filter) {
        return fix_indent(
            create_hash(
                "filter",
                create_hash(
                    "grok",
                    create_hash_field(
                        "match",
                        create_field(
                            quote_string(filter["grok"]["field"]),
                            create_pattern_array(filter["grok"]["patterns"])
                        )
                    )
                )
            )
        )
    }).join("\n\n") + "\n";
}
