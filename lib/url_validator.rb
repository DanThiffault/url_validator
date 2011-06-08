require 'uri'
require 'active_model'
require 'addressable/uri'
require 'ipaddr'
require 'url_validator/tld_file_indexing'

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator

      def validate_each(record, attribute, value)
        message = options[:message] || "is not a valid URL"
        schemes = options[:schemes] || %w(http https)
        custom_tlds = options[:custom_tlds]
        preffered_schema = options[:preffered_schema] || "#{schemes.first}://"

        if value.blank? && !(options[:allow_blank] || options[:allow_nil])
          record.errors[attribute] << message
          return
        end

        if !value.start_with?(*schemes)
          prefixed_value = preffered_schema + value
        else
          prefixed_value = value
        end


        begin
          uri = Addressable::URI.parse(prefixed_value)
          uri.normalize!
        rescue Addressable::URI::InvalidURIError
          record.errors[attribute] << message
        end

        if uri
          if valid_host? uri.host
            begin
              IPAddr.new uri.host
              ip_based = true
            rescue
              ip_based = false
            end

            unless ip_based
              if custom_tlds # Check against custom domain suffixes
                ::UrlValidator::TldMatcher.instance.custom_tlds=custom_tlds
              end

#            Check domain against internet db
              valid_tld = ::UrlValidator::TldMatcher.instance.tld_match? uri.host

#            Ping website
#              TODO: Ping the website if requested

              unless valid_tld
                record.errors[attribute] << message
              end
            end
          else
            record.errors[attribute] << message
          end
        end


      end
      def valid_host?(host_name)
#        TODO: check for other invalid host characters
        if host_name && !host_name.include?(' ')
          true
        else
          false
        end
      end
    end

    module ClassMethods
      # Validates whether the value of the specified attribute is valid url.
      #
      #   class User
      #     include ActiveModel::Validations
      #     attr_accessor :website, :ftpsite
      #     validates_url :website, :allow_blank => true
      #     validates_url :ftpsite, :schemes => ['ftp']
      #   end
      # Configuration options:
      # * <tt>:message</tt> - A custom error message (default is: "is not a valid URL").
      # * <tt>:allow_nil</tt> - If set to true, skips this validation if the attribute is +nil+ (default is +false+).
      # * <tt>:allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is +false+).
      # * <tt>:schemes</tt> - Array of URI schemes to validate against. (default is +['http', 'https']+)
      def validates_url(*attr_names)
        validates_with UrlValidator, _merge_attributes(attr_names)
      end
    end
  end
end

