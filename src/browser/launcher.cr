module Easybrawto
  module Browser
    CHROME_PATHS = [
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
      "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
      "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    ]

    CDP_PORT = 9222

    def self.find_browser(name : String = "chrome") : String
      paths = CHROME_PATHS.select { |p| p.downcase.includes?(name.downcase) }
      paths = CHROME_PATHS if paths.empty?

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
  end
end
