require "webrick"

module Jekyll
  module Commands
    class Serve
      class Servlet < WEBrick::HTTPServlet::FileHandler
        DEFAULTS = {
          "Cache-Control" => "private, max-age=0, proxy-revalidate, " \
            "no-store, no-cache, must-revalidate"
        }

        def initialize(server, root, callbacks)
          # So we can access them easily.
          @jekyll_opts = server.config[:JekyllOptions]
          set_defaults
          super
        end

        # Add the ability to tap file.html the same way that Nginx does on our
        # Docker images (or on Github pages.) The difference is that we might end
        # up with a different preference on which comes first.

        def search_file(req, res, basename)
          # /file.* > /file/index.html > /file.html
          super || super(req, res, "#{basename}.html")
        end

        #

        def do_GET(req, res)
          rtn = super
          validate_and_ensure_charset(req, res)
          res.header.merge!(@headers)
          rtn
        end

        #

        private
        def validate_and_ensure_charset(req, res)
          key = res.header.keys.grep(/content-type/i).first
          typ = res.header[key]

          unless typ =~ /;\s*charset=/
            res.header[key] = "#{typ}; charset=#{@jekyll_opts["encoding"]}"
          end
        end

        #

        private
        def set_defaults
          hash_ = @jekyll_opts.fetch("webrick", {}).fetch("headers", {})
          DEFAULTS.each_with_object(@headers = hash_) do |(key, val), hash|
            hash[key] = val if !hash.key?(key)
          end
        end
      end
    end
  end
end
