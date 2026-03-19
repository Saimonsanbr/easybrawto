require "yaml"

module Easybrawto
  module Lang
    def self.load_aliases : Hash(String, String)
      aliases = {} of String => String
      lang_dir = File.join(File.dirname(Process.executable_path || "."), "..", "lang")
      lang_dir = "lang" unless Dir.exists?(lang_dir)

      unless Dir.exists?(lang_dir)
        return aliases
      end

      Dir.glob(File.join(lang_dir, "*.yml")).each do |file|
        begin
          data = YAML.parse(File.read(file))
          data.as_h.each do |canonical, alias_list|
            alias_list.as_a.each do |alias_name|
              name = alias_name.as_s
              if aliases.has_key?(name) && aliases[name] != canonical.as_s
                puts "[aviso] Conflito de alias '#{name}' em #{File.basename(file)} — ignorado"
              else
                aliases[name] = canonical.as_s
              end
            end
          end
        rescue ex
          puts "[aviso] Erro ao carregar idioma #{File.basename(file)}: #{ex.message}"
        end
      end

      aliases
    end
  end
end
