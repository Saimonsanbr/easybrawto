require "http/client"
require "http/web_socket"
require "json"
require "uri"

module Easybrawto
  module CDP
    class Client
      @ws : HTTP::WebSocket? = nil
      @message_id : Int32 = 0
      @pending = {} of Int32 => Channel(JSON::Any)

      def initialize
        wait_for_browser()
        @ws = connect_to_tab()
        listen_async()
        sleep 0.2.seconds
        send("Page.enable", {} of String => JSON::Any)
      end

      def send(method : String, params : Hash(String, JSON::Any) = {} of String => JSON::Any) : JSON::Any
        id = next_id()
        ch = Channel(JSON::Any).new(1)
        @pending[id] = ch

        payload = {id: id, method: method, params: params}.to_json
        @ws.not_nil!.send(payload)

        select
        when result = ch.receive
          result
        when timeout(30.seconds)
          puts "\n[ERRO] Timeout: sem resposta do navegador para '#{method}'"
          puts "→ O navegador pode estar travado. Tente fechar e reabrir."
          exit 1
        end
      end

      def eval(js : String) : JSON::Any
        result = send("Runtime.evaluate", {
          "expression"    => JSON::Any.new(js),
          "returnByValue" => JSON::Any.new(true),
          "awaitPromise"  => JSON::Any.new(true),
        } of String => JSON::Any)

        if result.dig?("result", "result", "subtype").try(&.as_s?) == "error"
          msg = result.dig?("result", "result", "description").try(&.as_s?) || "erro desconhecido"
          puts "\n[ERRO] JavaScript: #{msg}"
          puts "→ Use .screenshot('debug.png') para ver o estado da página"
          exit 1
        end

        # caminho correto: result → result → value
        result.dig?("result", "result", "value") || JSON::Any.new(nil)
      end

      private def wait_for_browser
        30.times do
          begin
            HTTP::Client.get("http://localhost:#{Browser::CDP_PORT}/json")
            return
          rescue
            sleep 1.second
          end
        end
        puts "\n[ERRO] Porta CDP ocupada ou navegador não respondeu: #{Browser::CDP_PORT}"
        puts "→ Feche todas as janelas do Chrome e tente novamente"
        puts "→ macOS/Linux: lsof -ti:#{Browser::CDP_PORT} | xargs kill"
        exit 1
      end

      private def connect_to_tab : HTTP::WebSocket
        response = HTTP::Client.get("http://localhost:#{Browser::CDP_PORT}/json")
        tabs = JSON.parse(response.body).as_a

        page = tabs.find do |t|
          t["type"]?.try(&.as_s?) == "page" && t["webSocketDebuggerUrl"]?
        end

        unless page
          puts "\n[ERRO] Nenhuma aba de navegação encontrada (type: page)"
          puts "→ Tente fechar e reabrir o Chrome"
          exit 1
        end

        ws_url = page["webSocketDebuggerUrl"].as_s
        puts "[easybrawto] Conectando na aba: #{ws_url}"
        uri = URI.parse(ws_url)
        HTTP::WebSocket.new(uri)
      end

      private def listen_async
        spawn do
          @ws.not_nil!.on_message do |msg|
            data = JSON.parse(msg)
            if id = data["id"]?.try(&.as_i?)
              @pending[id]?.try { |ch| ch.send(data) }
              @pending.delete(id)
            end
          end
          @ws.not_nil!.run
        end
      end

      private def next_id : Int32
        @message_id += 1
      end
    end
  end
end
