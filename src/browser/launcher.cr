require "json"

module Easybrawto
  module Browser
    CHROME_PATHS_MACOS = [
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
      "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
      "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    ]

    CHROME_PATHS_LINUX = [
      "/usr/bin/google-chrome",
      "/usr/bin/google-chrome-stable",
      "/usr/bin/chromium-browser",
      "/usr/bin/chromium",
      "/usr/bin/brave-browser",
      "/snap/bin/chromium",
    ]

    def self.chrome_paths : Array(String)
      {% if flag?(:linux) %}
        CHROME_PATHS_LINUX
      {% else %}
        CHROME_PATHS_MACOS
      {% end %}
    end

    CDP_PORT = 9222

    def self.base_dir : String
      File.join(Path.home, ".easybrawto")
    end

    def self.profiles_json_path : String
      File.join(base_dir, "profiles.json")
    end

    def self.find_browser(name : String = "chrome") : String
      paths = chrome_paths.select { |p| p.downcase.includes?(name.downcase) }
      paths = chrome_paths if paths.empty?

      path = paths.find { |p| File.exists?(p) }

      unless path
        puts "\n[ERRO] Navegador não encontrado: '#{name}'"
        puts "→ Caminhos testados:"
        paths.each { |p| puts "   #{p}" }
        puts "→ Verifique se o navegador está instalado."
        exit 1
      end

      path
    end

    def self.launch(browser : String = "chrome", profile_path : String? = nil, profile_dir : String = "Default") : Process
      executable = find_browser(browser)
      base_dir = profile_path || temp_profile_dir()

      puts "[easybrawto] Iniciando #{browser}..."
      puts "[easybrawto] Perfil: #{base_dir}/#{profile_dir}"

      args = [
        "--remote-debugging-port=#{CDP_PORT}",
        "--user-data-dir=#{base_dir}",
        "--profile-directory=#{profile_dir}",
        "--no-first-run",
        "--no-default-browser-check",
      ]

      Process.new(executable, args, output: Process::Redirect::Close, error: Process::Redirect::Close)
    end

    def self.temp_profile_dir : String
      dir = "/tmp/easybrawto_#{rand(100_000)}"
      Dir.mkdir_p(dir)
      dir
    end

    def self.persistent_profile_dir(name : String) : String
      dir = File.join(Path.home, ".easybrawto", "profiles", name)
      Dir.mkdir_p(dir)
      dir
    end

    def self.open_profile(name : String, browser : String = "chrome")
      profile_path = File.join(Path.home, ".easybrawto", "profiles", name)

      is_new = !Dir.exists?(profile_path)

      Dir.mkdir_p(profile_path)

      puts ""
      puts "easybrawto — Gerenciador de perfis"
      puts "─────────────────────────────────"

      if is_new
        puts "[easybrawto] Criando novo perfil: '#{name}'"
      else
        puts "[easybrawto] Abrindo perfil existente: '#{name}'"
      end

      save_profile_metadata(name, browser, is_new)

      process = launch(browser, profile_path)

      puts "[easybrawto] Navegador aberto com o perfil '#{name}'"
      puts ""
      puts "  Faça login nas suas contas normalmente."
      puts "  Tudo ficará salvo para próximas execuções."
      puts ""
      puts "  Pressione Ctrl+C para fechar."
      puts ""

      Signal::INT.trap do
        puts "\n[easybrawto] Fechando navegador..."
        begin
          process.terminate
          process.wait
        rescue
        end
        puts "[easybrawto] Perfil '#{name}' salvo. Até mais!"
        exit 0
      end

      loop { sleep 1.second }
    end

    def self.list_profiles
      profiles = load_profiles_metadata

      puts ""
      puts "easybrawto — Perfis salvos"
      puts "──────────────────────────"

      if profiles.empty?
        puts "Nenhum perfil encontrado."
        puts ""
        puts "Crie um com:  ./easybrawto open nome_do_perfil"
        puts "              ./easybrawto abrir nome_do_perfil"
      else
        puts ""
        puts "  #{"Nome".ljust(20)} #{"Navegador".ljust(10)} #{"Criado em".ljust(22)} Último uso"
        puts "  #{"─" * 20} #{"─" * 10} #{"─" * 22} #{"─" * 22}"
        profiles.each do |p|
          name = (p["name"]?.try(&.as_s?) || "").ljust(20)
          browser = (p["browser"]?.try(&.as_s?) || "chrome").ljust(10)
          created = (p["created_at"]?.try(&.as_s?) || "").ljust(22)
          last = p["last_opened"]?.try(&.as_s?) || "nunca"
          puts "  #{name} #{browser} #{created} #{last}"
        end
        puts ""
        puts "Total: #{profiles.size} perfil(s)"
        puts ""
        puts "Abrir perfil: ./easybrawto open <nome>"
      end
      puts ""
    end

    private def self.save_profile_metadata(name : String, browser : String, is_new : Bool)
      Dir.mkdir_p(base_dir)
      profiles = load_profiles_metadata

      now = Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")

      existing = profiles.find { |p| p["name"]?.try(&.as_s?) == name }

      if existing
        new_profiles = profiles.map do |p|
          if p["name"]?.try(&.as_s?) == name
            times = p["times_used"]?.try(&.as_i?) || 0
            JSON.parse({
              name:        name,
              browser:     browser,
              created_at:  p["created_at"]?.try(&.as_s?) || now,
              last_opened: now,
              times_used:  times + 1,
            }.to_json)
          else
            p
          end
        end
        File.write(profiles_json_path, new_profiles.to_json)
      else
        new_entry = JSON.parse({
          name:        name,
          browser:     browser,
          created_at:  now,
          last_opened: now,
          times_used:  1,
        }.to_json)
        profiles << new_entry
        File.write(profiles_json_path, profiles.to_json)
      end
    rescue ex
      puts "  [aviso] Não foi possível salvar metadados: #{ex.message}"
    end

    private def self.load_profiles_metadata : Array(JSON::Any)
      return [] of JSON::Any unless File.exists?(profiles_json_path)
      data = JSON.parse(File.read(profiles_json_path))
      data.as_a
    rescue
      [] of JSON::Any
    end
  end
end
