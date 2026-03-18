require "./browser/launcher"
require "./cdp/client"
require "./commands/actions"
require "./parser/reader"

module Easybrawto
  VERSION = "0.1.0"

  def self.run(script_path : String)
    puts "easybrawto v#{VERSION}"
    puts "→ Lendo script: #{script_path}\n"

    script = Parser.parse(script_path)
    process = Browser.launch(script.browser, script.profile, script.profile_dir)

    sleep 5.seconds
    cdp = CDP::Client.new
    actions = Commands::Actions.new(cdp)

    script.run_order.each do |fn_name|
      fn = script.functions[fn_name]?

      unless fn
        puts "\n[ERRO] Função não declarada: '#{fn_name}'"
        puts "→ Verifique se o nome em 'run #{fn_name}' bate com 'functions #{fn_name}'"
        exit 1
      end

      puts "\n[run] #{fn_name}"

      fn.commands.each do |cmd|
        # Usar ? em todos os args evita IndexError se argumento estiver faltando
        case cmd.name
        when "navigate"
          actions.navigate(cmd.args[0]? || "")
        when "waitLoad"
          actions.wait_load
        when "waitFor"
          actions.wait_for(cmd.args[0]? || "")
        when "clickButton"
          actions.click_button(cmd.args[0]? || "")
        when "insertText"
          actions.insert_text(cmd.args[0]? || "", cmd.args[1]? || "")
        when "pressKey"
          actions.press_key(cmd.args[0]? || "Enter")
        when "screenshot"
          actions.screenshot(cmd.args[0]? || "screenshot.png")
        when "log"
          actions.log(cmd.args[0]? || "")
        when "waitSeconds"
          actions.wait_seconds(cmd.args[0]?.try(&.to_i?) || 1)
        else
          puts "  [aviso] Comando desconhecido ignorado: '.#{cmd.name}'"
        end
      end
    end

    puts "\n[ok] Script finalizado."
    process.terminate
  end
end

if ARGV.size < 2 || ARGV[0] != "run"
  puts "Uso: easybrawto run <script.auto>"
  puts "Exemplo: easybrawto run examples/test.auto"
  exit 0
end

Easybrawto.run(ARGV[1])
