module UrlValidator
  require 'open-uri'
  require 'singleton'

  class TldMatcher
    include ::Singleton

    TLD_LIST_URI = "http://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1"

    def tlds
      @tlds ||= generate_tld_indexing
    end

    def custom_tlds=(custom_tlds)
      @tlds = generate_tld_indexing(custom_tlds)
    end

    def tld_match?(host_name)
      host_combinations = host_name.strip.reverse.split('.').reduce([]) do |result, value|
        result << result.last + '.' + value if result.last
        result << value
      end

      (tlds & host_combinations).count > 0
    end

    protected
    def generate_tld_indexing(custom_tlds=[])
      tld_list = SortedSet.new

      custom_tlds.each { |tld| tld_list << tld.strip.reverse }

      open(TLD_LIST_URI) do |tld_source|
        tld_source.each_line do |source_line|
          source_line.strip!
          unless source_line.empty? || source_line[0] == "#"
            tld_list << source_line.reverse
          end
        end
      end

      tld_list
    end

  end
end