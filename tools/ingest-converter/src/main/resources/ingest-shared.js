var IngestConverter = {
    /**
     * Translates the JSON naming pattern (`name.qualifier.sub`) into the LS pattern
     * [name][qualifier][sub] for all applicable tokens in the given string.
     * This function correctly identifies and omits renaming of string literals.
     * @param string to replace naming pattern in
     * @returns {string} with Json naming translated into grok naming
     */
    dots_to_square_brackets: function (string) {

        function token_dots_to_square_brackets(string) {
            var adjusted;
            //Break out if this is not a naming pattern we convert
            if (string.match(/([\w_]+\.)+[\w_]+/)) {
                adjusted = string.replace(/(\w*)\.(\w*)/g, "$1][$2")
                    .replace(/\[(\w+)(}|$)/g, "[$1]$2")
                    .replace(/{(\w+):(\w+)]/g, "{$1:[$2]")
                    .replace(/^(\w+)]\[/g, "[$1][");
            } else {
                adjusted = string;
            }
            return adjusted;
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
    }, quote_string: function (string) {
        return "\"" + string.replace(/"/g, "\\\"") + "\"";
    }, wrap_in_curly: function (string) {
        return "{\n" + string + "\n}";
    }, create_field: function (name, content) {
        return name + " => " + content;
    }, create_hash: function (name, content) {
        return name + " " + this.wrap_in_curly(content);
    },

    /**
     * All hash fields in LS start on a new line.
     * @param fields Array of Strings of Serialized Hash Fields
     * @returns {string} Joined Serialization of Hash Fields
     */
    join_hash_fields: function (fields) {
        return fields.join("\n");
    },

    /**
     * Fixes indentation in LS string.
     * @param string LS string to fix indentation in, that has no indentation intentionally with
     * all lines starting on a token without preceding spaces.
     * @returns {string} LS string indented by 3 spaces per level
     */
    fix_indent: function (string) {

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
                // Only indent line if previous line ended on relevant control char.
            } else if (i > 0 && lines[i - 1].match(/(=>\s+".+"|,|\{|\}|\[|\])$/)) {
                lines[i] = indent(lines[i], count);
            }
        }
        return lines.join("\n");
    },

    /**
     * Converts Ingest/JSON style pattern array to LS pattern array, performing necessary variable
     * name and quote escaping adjustments.
     * @param patterns Pattern Array in JSON formatting
     * @returns {string} Pattern array in LS formatting
     */
    create_pattern_array: function (patterns) {
        return "[\n"
            + patterns.map(this.dots_to_square_brackets).map(this.quote_string).join(",\n")
            + "\n]";
    },

    create_array: function (ingest_array) {
        return "[\n"
            + ingest_array.map(this.quote_string).join(",\n")
            + "\n]";
    },

    /**
     * Converts Ingest/JSON style pattern array to LS pattern array or string if the given array
     * contains a single element only, performing necessary variable name and quote escaping
     * adjustments.
     * @param patterns Pattern Array in JSON formatting
     * @returns {string} Pattern array or string in LS formatting
     */
    create_pattern_array_or_field: function (patterns) {
        return patterns.length === 1
            ? this.quote_string(this.dots_to_square_brackets(patterns[0]))
            : this.create_pattern_array(patterns);
    },

    filter_hash: function(contents) {
        return this.fix_indent(this.create_hash("filter", contents))
    },

    filters_to_file: function(filters) {
        return filters.join("\n\n") + "\n";
    },

    /**
     * Does it have an on_failure field?
     * @param processor Json
     * @param name Name of the processor
     * @returns {boolean} True if has on failure
     */
    has_on_failure: function (processor, name) {
        return !!processor[name]["on_failure"];
    },

    get_on_failure: function (processor, name) {
        return processor[name]["on_failure"];
    },

    /**
     * Creates an if clause with the tag name
     * @param tag String tag name to find in [tags] field
     * @param on_failure_pipeline The on failure pipeline converted to LS to tack on in the conditional
     * @returns {string} a string representing a conditional logic
     */
    create_tag_conditional: function (tag, on_failure_pipeline) {
        return "if " + this.quote_string(tag) + " in [tags] {\n" +
                on_failure_pipeline + "\n" +
                "}";
    },

    get_elasticsearch_output: function () {
        return this.fix_indent("output {\n" +
            "elasticsearch {\n" +
            "hosts => \"localhost\"\n" +
            "}\n" +
            "}");
    },

    get_stdin_input: function () {
        return this.fix_indent("input {\n" +
            "stdin {\n" +
            "}\n" +
            "}");
    },

    get_stdout_output: function () {
        return this.fix_indent("output {\n" +
            "stdout {\n" +
            "codec => \"rubydebug\"\n" +
            "}\n" +
            "}");
    },

    append_io_plugins: function(filters_pipeline, append_stdio) {
        if (append_stdio === true) {
            return [IngestConverter.get_stdin_input(), filters_pipeline, IngestConverter.get_stdout_output()].join("\n");
        } else {
            return [filters_pipeline, IngestConverter.get_elasticsearch_output()].join("\n");
        }
    }
};
