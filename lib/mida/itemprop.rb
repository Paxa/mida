require 'nokogiri'
require 'uri'
require 'mida/itemscope'

module Mida

  # Class that parses itemprop elements
  class Itemprop

    NON_TEXTCONTENT_ELEMENTS = {
      'a' => 'href',        'area' => 'href',
      'audio' => 'src',     'embed' => 'src',
      'iframe' => 'src',    'img' => 'src',
      'link' => 'href',     'meta' => 'content',
      'object' => 'data',   'source' => 'src',
      'time' => 'datetime', 'track' => 'src',
      'video' => 'src'
    }

    URL_ATTRIBUTES = ['data', 'href', 'src']

    # A Hash representing the properties.
    # Hash is of the form {'property name' => 'value'}
    attr_reader :properties

    # Create a new Itemprop object
    # [element]  The itemprop element to be parsed
    # [page_url] The url of the page, including filename, used to form
    #            absolute urls
    def initialize(element, page_url = nil, doc = nil)
      @element, @page_url, @doc = element, page_url, doc
      @properties = extract_properties
    end

    # Parse the element and return a hash representing the properties.
    # Hash is of the form {'property name' => 'value'}
    # [element]  The itemprop element to be parsed
    # [page_url] The url of the page, including filename, used to form
    #            absolute urls
    def self.parse(element, page_url = nil, doc = nil)
      self.new(element, page_url, doc).properties
    end

  private
    def extract_properties
      prop_names = extract_property_names
      prop_names.each_with_object({}) do |name, memo|
        memo[name] = extract_property
      end
    end

    # This returns an empty string if can't form a valid
    # absolute url as per the Microdata spec.
    def make_absolute_url(url)
      url = URI.escape(url)
      return url unless URI.parse(url).relative?
      begin
        URI.parse(@page_url).merge(url).to_s
      rescue URI::Error
        ''
      end
    end

    def non_textcontent_element?(element)
      NON_TEXTCONTENT_ELEMENTS.has_key?(element)
    end

    def url_attribute?(attribute)
      URL_ATTRIBUTES.include?(attribute)
    end

    def extract_property_names
      itemprop_attr = @element.attribute('itemprop')
      itemprop_attr ? itemprop_attr.value.split() : []
    end

    def extract_property_value
      element = @element.name
      if non_textcontent_element?(element)
        attribute = NON_TEXTCONTENT_ELEMENTS[element]
        if attribute_node = @element.attribute(attribute)
          url_attribute?(attribute) ? make_absolute_url(attribute_node.value) : attribute_node.value
        end
      else
        if !@doc || @doc.options[:content] == :text
          @element.inner_text.strip
        elsif @doc && @doc.options[:content] == :html
          @element.inner_html.strip
        end
      end
    end

    def extract_property
      if @element.attribute('itemscope')
        Itemscope.new(@element, @page_url, @doc)
      else
        extract_property_value
      end
    end

  end
end
