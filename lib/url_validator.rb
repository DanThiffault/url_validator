require 'uri'
require 'active_model'
require 'addressable/uri'
require 'ipaddr'

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator

      def validate_each(record, attribute, value)
        message = options[:message] || "is not a valid URL"
        schemes = options[:schemes] || %w(http https)
        url_regexp = /^((#{schemes.join('|')}):\/\/){0,1}[a-z0-9]+([a-z0-9\-\.]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
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
        rescue Addressable::URI::InvalidURIError
          record.errors[attribute] << message
        end

        if uri
          normalized_value = Addressable::IDNA.to_ascii(prefixed_value).to_s
          begin
            IPAddr.new uri.host
            ip_based = true
          rescue
            ip_based = false
          end

          unless ip_based
            unless url_regexp =~ normalized_value
              record.errors[attribute] << message
            end
          end
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

