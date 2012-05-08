require "logstash/filters/base"
require "logstash/namespace"
require "xmlsimple"
require "rexml/document"
include REXML

# XML filter. Takes a field that contains XML and expands it into
# an actual datastructure.
class LogStash::Filters::Xml < LogStash::Filters::Base

  config_name "xml"
  plugin_status "experimental"

  # Config for xml to hash is:
  #
  #   source => dest
  #
  # XML in the value of the source field will be expanded into a
  # datastructure in the "dest" field. Note: if the "dest" field
  # already exists, it will be overridden.
  config /[A-Za-z0-9_-]+/, :validate => :string

  # xpath will additionally select string values (.to_s on whatever is selected)
  # from parsed XML (using each source field defined using the method above)
  # and place those values in the destination fields. Configuration:
  #
  # xpath => [ "xpath-syntax", "destination-field" ]
  #
  # Values returned by XPath parsring from xpath-synatx will be put in the 
  # destination field. Multiple values returned will be pushed onto the
  # destination field as an array. As such, multiple matches across
  # multiple source fields will produce duplicate entries in the field
  #
  # More on xpath: http://www.w3schools.com/xpath/
  # 
  # The xpath functions are particularly powerful:
  # http://www.w3schools.com/xpath/xpath_functions.asp
  # 
  config :xpath, :validate => :hash, :default => {}

  # By default the filter will store the whole parsed xml in the destination
  # field as described above. Setting this to false will prevent that.
  config :store_xml, :validate => :boolean, :default => true

  public
  def register
    @xml = {}

    @config.each do |field, dest|
      next if ( RESERVED + ["xpath","store_xml"] ).member?(field)

      @xml[field] = dest
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    matched = false

    @logger.debug("Running xml filter", :event => event)

    @xml.each do |key, dest|
      if event.fields[key]
        if event.fields[key].is_a?(String)
          event.fields[key] = [event.fields[key]]
        end

        if event.fields[key].length > 1
          @logger.warn("XML filter only works on fields of length 1",
                       :key => key, :value => event.fields[key])
          next
        end

        raw = event.fields[key].first

        # for some reason, an empty string is considered valid XML
        next if raw.strip.length == 0

        if @xpath
          begin
            doc = Document.new(raw)
          rescue => e
            event.tags << "_xmlparsefailure"
            @logger.warn("Trouble parsing xml with REXML::Document", :key => key, :raw => raw,
                          :exception => e, :backtrace => e.backtrace)
            next
          end

          @xpath.each do |xpath_src, xpath_dest|

            XPath.each(doc, xpath_src).each do |value|
              # some XPath functions return empty arrays as string
              if value.is_a?(Array)
                next if value.length == 0
              end

              unless value.nil?
                matched = true
                event[xpath_dest] ||= []
                event[xpath_dest] << value.to_s
              end
            end
          end
        end

        if @store_xml
          begin
            event[dest] = XmlSimple.xml_in(raw)
            matched = true
          rescue => e
            event.tags << "_xmlparsefailure"
            @logger.warn("Trouble parsing xml with XmlSimple", :key => key, :raw => raw,
                          :exception => e, :backtrace => e.backtrace)
            next
          end
        end

        filter_matched(event) if matched

      end
    end

    @logger.debug("Event after xml filter", :event => event)
  end # def filter
end # class LogStash::Filters::Xml
