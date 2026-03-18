require "base64"

module Easybrawto
  module Commands
    class Actions
      def initialize(@cdp : CDP::Client)
      end

      def navigate(url : String)
        return if url.empty?
        puts "  .navigate('#{url}')"
        @cdp.send("Page.navigate", {"url" => JSON::Any.new(url)} of String => JSON::Any)
        sleep 2.seconds
        wait_load()
      end

      def wait_load
        puts "  .waitLoad()"
        20.times do
          sleep 0.5.seconds # espera antes de checar — dá tempo do fiber processar
          state = @cdp.eval("document.readyState").as_s? || ""
          return if state == "complete" || state == "interactive"
        end
        puts "\n[AVISO] Timeout no waitLoad: prosseguindo assim mesmo..."
      end

      def wait_for(selector : String)
        return if selector.empty?
        puts "  .waitFor('#{selector}')"
        js = build_find_js(selector)

        15.times do
          found = @cdp.eval(js).as_bool? || false
          return if found
          sleep 1.second
        end

        puts "\n[ERRO] Timeout: elemento não apareceu em 15 segundos: '#{selector}'"
        puts "→ Verifique se o seletor está correto"
        puts "→ Use .screenshot('debug.png') para ver o estado atual da página"
        exit 1
      end

      def click_button(target : String)
        return if target.empty?
        puts "  .clickButton('#{target}')"

        js = <<-JS
          (function() {
            var el = #{build_find_js_inline(target)};
            if (!el) return false;
            el.scrollIntoView({ behavior: 'instant', block: 'center' });
            el.click();
            return true;
          })()
        JS

        found = @cdp.eval(js).as_bool? || false

        unless found
          puts "\n[ERRO] Elemento não encontrado: '#{target}'"
          puts "→ Verifique o texto do botão (maiúsculas/minúsculas importam)"
          puts "→ Adicione .waitLoad() ou .waitFor('#{target}') antes desta linha"
          puts "→ Use .screenshot('debug.png') para ver o estado da página"
          exit 1
        end
      end

      def insert_text(selector : String, value : String)
        return if selector.empty?
        puts "  .insertText('#{selector}', '#{value}')"

        js = <<-JS
            (function() {
            function deepQuery(root) {
                var inputs = root.querySelectorAll('input, textarea');
                for (var el of inputs) {
                if (el.name === #{selector.to_json}) return el;
                if (el.placeholder === #{selector.to_json}) return el;
                if (el.getAttribute('aria-label') === #{selector.to_json}) return el;
                }
                var all = root.querySelectorAll('*');
                for (var el of all) {
                if (el.shadowRoot) {
                    var found = deepQuery(el.shadowRoot);
                    if (found) return found;
                }
                }
                return null;
            }

            var el = deepQuery(document);
            if (!el) return false;

            el.scrollIntoView({ behavior: 'instant', block: 'center' });
            el.focus();

            var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')
                        || Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value');
            if (setter && setter.set) {
                setter.set.call(el, #{value.to_json});
            } else {
                el.value = #{value.to_json};
            }

            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));

            return true;
            })()
        JS

        found = @cdp.eval(js).as_bool? || false

        unless found
          puts "\n[ERRO] Campo não encontrado: '#{selector}'"
          puts "→ Tente usar o ID: .insertText('#searchInput', 'valor')"
          puts "→ Ou a classe: .insertText('.campo-email', 'valor')"
          puts "→ Use .screenshot('debug.png') para inspecionar a página"
          exit 1
        end
      end

      def press_key(key : String)
        return if key.empty?
        puts "  .pressKey('#{key}')"

        code = key == "Enter" ? 13 : 0

        ["keyDown", "keyUp"].each do |type|
          @cdp.send("Input.dispatchKeyEvent", {
            "type"                  => JSON::Any.new(type),
            "key"                   => JSON::Any.new(key),
            "windowsVirtualKeyCode" => JSON::Any.new(code.to_i64),
            "text"                  => JSON::Any.new(key == "Enter" ? "\r" : ""),
          } of String => JSON::Any)
        end
      end

      def screenshot(filename : String)
        return if filename.empty?
        puts "  .screenshot('#{filename}')"
        result = @cdp.send("Page.captureScreenshot", {"format" => JSON::Any.new("png")} of String => JSON::Any)
        data = result.dig?("result", "data").try(&.as_s?)

        if data
          File.write(filename, Base64.decode(data))
          puts "  [ok] Screenshot salvo: #{filename}"
        else
          puts "  [aviso] Não foi possível salvar screenshot"
        end
      end

      def log(message : String)
        puts "  [log] #{message}"
      end

      def wait_seconds(seconds : Int32)
        puts "  .waitSeconds(#{seconds})"
        sleep seconds.seconds
      end

      private def build_find_js_inline(target : String) : String
        if target.starts_with?("#") || target.starts_with?(".")
          "document.querySelector(#{target.to_json})"
        else
          <<-JS
            (function() {
              var tags = ['button','a','input[type=submit]','[role=button]','input[type=button]'];
              for (var t of tags) {
                var els = document.querySelectorAll(t);
                for (var el of els) {
                  if (el.textContent.trim() === #{target.to_json}) return el;
                }
              }
              var el = document.querySelector('[aria-label=#{target.to_json}]');
              if (el) return el;
              for (var t of ['button','a']) {
                var els = document.querySelectorAll(t);
                for (var el of els) {
                  if (el.textContent.trim().includes(#{target.to_json})) return el;
                }
              }
              return null;
            })()
          JS
        end
      end

      private def build_find_js(selector : String) : String
        "!!(#{build_find_js_inline(selector)})"
      end

      private def build_input_find_js(selector : String) : String
        if selector.starts_with?("#") || selector.starts_with?(".")
          "document.querySelector(#{selector.to_json})"
        else
          js = <<-JS
            (function() {
                function deepQuery(root) {
                var inputs = root.querySelectorAll('input, textarea');
                for (var el of inputs) {
                    if (el.name === #{selector.to_json}) return el;
                    if (el.placeholder === #{selector.to_json}) return el;
                    if (el.getAttribute('aria-label') === #{selector.to_json}) return el;
                }
                var all = root.querySelectorAll('*');
                for (var el of all) {
                    if (el.shadowRoot) {
                    var found = deepQuery(el.shadowRoot);
                    if (found) return found;
                    }
                }
                return null;
                }
                return deepQuery(document);
            })()
            JS
          js
        end
      end
    end
  end
end
