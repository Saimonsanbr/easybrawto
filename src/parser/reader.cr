module Easybrawto
  module Parser
    record Command, name : String, args : Array(String)
    record Function, name : String, commands : Array(Command)
    record Script,
      browser : String,
      profile : String?,
      profile_dir : String,
      functions : Hash(String, Function),
      run_order : Array(String)

    # Aliases para palavras-chave estruturais
    STRUCT_ALIASES = {
      # português
      "navegador.perfil("          => "chrome.profile(",
      "navegador.manterPerfil("    => "chrome.persistProfile(",
      "navegador.perfilTemporario" => "chrome.tempProfile()",
      "navegador.tipo("            => "chrome.browser(",
      "funcoes "                   => "functions ",
      "rodar "                     => "run ",

      # japonês
      "ブラウザ.プロファイル("   => "chrome.profile(",
      "ブラウザ.保持プロファイル(" => "chrome.persistProfile(",
      "ブラウザ.タイプ("      => "chrome.browser(",
      "関数 "            => "functions ",
      "実行 "            => "run ",
    }

    def self.parse(filepath : String) : Script
      unless File.exists?(filepath)
        puts "\n[ERRO] Arquivo não encontrado: '#{filepath}'"
        exit 1
      end

      lines = File.read_lines(filepath)
      browser = "chrome"
      profile : String? = nil
      profile_dir = "Default"
      functions = {} of String => Function
      run_order = [] of String

      current_function : String? = nil
      current_commands = [] of Command

      lines.each_with_index do |raw_line, i|
        line = raw_line.strip
        next if line.empty? || line.starts_with?("#")

        # resolve aliases estruturais antes de qualquer processamento
        STRUCT_ALIASES.each do |alias_key, canonical|
          if line.starts_with?(alias_key)
            line = line.sub(alias_key, canonical)
            break
          end
        end

        if line.starts_with?("chrome.profile(")
          args = extract_args(line)
          profile = args[0]?
          profile_dir = args[1]? || "Default"
          next
        end

        if line.starts_with?("chrome.persistProfile(")
          profile = Browser.persistent_profile_dir(extract_arg(line))
          profile_dir = "Default"
          next
        end

        if line.starts_with?("chrome.tempProfile()")
          profile = nil
          profile_dir = "Default"
          next
        end

        if line.starts_with?("chrome.browser(")
          browser = extract_arg(line)
          next
        end

        if line.starts_with?("functions ")
          current_function = line
            .gsub("functions ", "")
            .gsub("{", "")
            .strip
          current_commands = [] of Command
          next
        end

        if line == "}" && current_function
          functions[current_function] = Function.new(current_function, current_commands.dup)
          current_function = nil
          next
        end

        if line.starts_with?(".") && current_function
          cmd, args = parse_command(line)
          current_commands << Command.new(cmd, args)
          next
        end

        if line.starts_with?("run ")
          fn_name = line.split(" ")[1]
          run_order << fn_name
          next
        end
      end

      Script.new(browser, profile, profile_dir, functions, run_order)
    end

    private def self.extract_arg(line : String) : String
      match = line.match(/'([^']*)'/)
      match ? match[1] : ""
    end

    private def self.extract_args(line : String) : Array(String)
      args = [] of String
      line.scan(/'([^']*)'/) { |m| args << m[1] }
      args
    end

    private def self.parse_command(line : String) : {String, Array(String)}
      match = line.match(/^\.(\w+)\((.*)\)$/)
      return {"unknown", [] of String} unless match

      name = match[1]
      raw_args = match[2].strip

      args = [] of String

      if raw_args.includes?("'")
        raw_args.scan(/'([^']*)'/) { |m| args << m[1] }
      elsif !raw_args.empty?
        args << raw_args
      end

      {name, args}
    end
  end
end
