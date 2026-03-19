require "./browser/launcher"
require "./cdp/client"
require "./commands/actions"
require "./parser/reader"
require "./lang/loader"

module Easybrawto
  VERSION = "0.2.0"

  # Carrega aliases uma vez no startup
  ALIASES = Lang.load_aliases

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
        # resolve alias para o comando canônico em inglês
        cmd_name = ALIASES[cmd.name]? || cmd.name

        case cmd_name
        when "navigate"      then actions.navigate(cmd.args[0]? || "")
        when "waitLoad"      then actions.wait_load
        when "waitFor"       then actions.wait_for(cmd.args[0]? || "")
        when "waitForText"   then actions.wait_for_text(cmd.args[0]? || "")
        when "waitSeconds"   then actions.wait_seconds(cmd.args[0]?.try(&.to_i?) || 1)
        when "clickButton"   then actions.click_button(cmd.args[0]? || "")
        when "clickIfExists" then actions.click_if_exists(cmd.args[0]? || "")
        when "insertText"    then actions.insert_text(cmd.args[0]? || "", cmd.args[1]? || "")
        when "clearField"    then actions.clear_field(cmd.args[0]? || "")
        when "selectOption"  then actions.select_option(cmd.args[0]? || "", cmd.args[1]? || "")
        when "checkBox"      then actions.check_box(cmd.args[0]? || "")
        when "pressKey"      then actions.press_key(cmd.args[0]? || "Enter")
        when "scroll"        then actions.scroll(cmd.args[0]? || "down", cmd.args[1]?.try(&.to_i?) || 300)
        when "reload"        then actions.reload
        when "goBack"        then actions.go_back
        when "goForward"     then actions.go_forward
        when "getValue"      then actions.get_value(cmd.args[0]? || "")
        when "getAttribute"  then actions.get_attribute(cmd.args[0]? || "", cmd.args[1]? || "")
        when "runJS"         then actions.run_js(cmd.args[0]? || "")
        when "screenshot"    then actions.screenshot(cmd.args[0]? || "screenshot.png")
        when "log"           then actions.log(cmd.args[0]? || "")
        else
          puts "  [aviso] Comando desconhecido ignorado: '.#{cmd.name}'"
        end
      end
    end

    puts "\n[ok] Script finalizado."
    begin
      process.terminate
    rescue
    end
  end
end

if ARGV.size < 2 || ARGV[0] != "run"
  puts "Uso: easybrawto run <script.auto>"
  puts "Exemplo: easybrawto run examples/test.auto"
  exit 0
end

Easybrawto.run(ARGV[1])
