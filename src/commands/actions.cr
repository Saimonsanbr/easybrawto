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
          sleep 0.5.seconds
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

      def wait_for_text(text : String)
        return if text.empty?
        puts "  .waitForText('#{text}')"

        15.times do
          found = @cdp.eval("document.body.innerText.includes(#{text.to_json})").as_bool? || false
          return if found
          sleep 1.second
        end

        puts "\n[ERRO] Timeout: texto não apareceu em 15 segundos: '#{text}'"
        puts "→ Verifique se o texto está correto"
        puts "→ Use .screenshot('debug.png') para ver o estado da página"
        exit 1
      end

      def wait_seconds(seconds : Int32)
        puts "  .waitSeconds(#{seconds})"
        sleep seconds.seconds
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

      def click_if_exists(target : String)
        return if target.empty?
        puts "  .clickIfExists('#{target}')"

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
        puts "  [aviso] '#{target}' não encontrado, continuando..." unless found
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

            var el = #{selector.to_json}.startsWith('#') || #{selector.to_json}.startsWith('.')
              ? document.querySelector(#{selector.to_json})
              : deepQuery(document);

            if (!el) return false;

            el.scrollIntoView({ behavior: 'instant', block: 'center' });
            el.focus();

            var proto = el.tagName === 'TEXTAREA'
              ? HTMLTextAreaElement.prototype
              : HTMLInputElement.prototype;

            var descriptor = Object.getOwnPropertyDescriptor(proto, 'value');
            if (descriptor && descriptor.set) {
              descriptor.set.call(el, #{value.to_json});
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
          puts "→ Tente usar o ID: .insertText('#campo', 'valor')"
          puts "→ Use .screenshot('debug.png') para inspecionar a página"
          exit 1
        end
      end

      def clear_field(selector : String)
        return if selector.empty?
        puts "  .clearField('#{selector}')"

        js = <<-JS
          (function() {
            var el = #{build_input_find_js(selector)};
            if (!el) return false;
            el.focus();
            el.value = '';
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          })()
        JS

        found = @cdp.eval(js).as_bool? || false
        unless found
          puts "\n[ERRO] Campo não encontrado: '#{selector}'"
          puts "→ Use .screenshot('debug.png') para inspecionar a página"
          exit 1
        end
      end

      def select_option(selector : String, value : String)
        return if selector.empty?
        puts "  .selectOption('#{selector}', '#{value}')"

        js = <<-JS
          (function() {
            var el = null;

            if (#{selector.to_json}.startsWith('#') || #{selector.to_json}.startsWith('.')) {
              el = document.querySelector(#{selector.to_json});
            }

            if (!el) {
              var selects = document.querySelectorAll('select');
              for (var s of selects) {
                if (s.name === #{selector.to_json}) { el = s; break; }
                if (s.id === #{selector.to_json}) { el = s; break; }
                if (s.getAttribute('aria-label') === #{selector.to_json}) { el = s; break; }
              }
            }

            if (!el) return false;

            var opts = Array.from(el.options);
            var opt = opts.find(o => o.text === #{value.to_json})
                  || opts.find(o => o.text.trim() === #{value.to_json}.trim())
                  || opts.find(o => o.value === #{value.to_json});

            if (!opt) return false;

            el.value = opt.value;
            el.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          })()
        JS

        found = @cdp.eval(js).as_bool? || false
        unless found
          puts "\n[ERRO] Dropdown não encontrado ou opção inexistente: '#{selector}' → '#{value}'"
          puts "→ Verifique o name/id do select e o texto exato da opção"
          exit 1
        end
      end

      def check_box(selector : String)
        return if selector.empty?
        puts "  .checkBox('#{selector}')"

        js = <<-JS
          (function() {
            var el = null;

            if (#{selector.to_json}.startsWith('#') || #{selector.to_json}.startsWith('.')) {
              el = document.querySelector(#{selector.to_json});
            }

            if (!el) {
              el = document.getElementById(#{selector.to_json})
                || document.querySelector('[name="' + #{selector.to_json} + '"]')
                || document.querySelector('[aria-label="' + #{selector.to_json} + '"]');
            }

            if (!el) return false;

            if (!el.checked) {
              el.click();
              el.dispatchEvent(new Event('change', { bubbles: true }));
            }

            return true;
          })()
        JS

        found = @cdp.eval(js).as_bool? || false
        unless found
          puts "\n[ERRO] Checkbox não encontrado: '#{selector}'"
          puts "→ Use o id: .checkBox('#aceitar-termos')"
          puts "→ Ou o name: .checkBox('termos')"
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

      def scroll(direction : String, amount : Int32 = 0)
        puts "  .scroll('#{direction}'#{amount > 0 ? ", #{amount}" : ""})"

        js = case direction
             when "down"   then "window.scrollBy(0, #{amount})"
             when "up"     then "window.scrollBy(0, -#{amount})"
             when "bottom" then "window.scrollTo(0, document.body.scrollHeight)"
             when "top"    then "window.scrollTo(0, 0)"
             else
               puts "  [aviso] direção inválida: '#{direction}' — use down, up, top ou bottom"
               return
             end

        @cdp.eval(js)
        sleep 0.3.seconds
      end

      def reload
        puts "  .reload()"
        @cdp.send("Page.reload", {} of String => JSON::Any)
        wait_load()
      end

      def go_back
        puts "  .goBack()"
        @cdp.send("Page.goBack", {} of String => JSON::Any)
        sleep 1.second
        wait_load()
      end

      def go_forward
        puts "  .goForward()"
        @cdp.send("Page.goForward", {} of String => JSON::Any)
        sleep 1.second
        wait_load()
      end

      def get_value(selector : String)
        return if selector.empty?
        puts "  .getValue('#{selector}')"

        js = <<-JS
          (function() {
            var el = #{build_input_find_js(selector)};
            if (!el) return null;
            return el.value;
          })()
        JS

        value = @cdp.eval(js).as_s? || ""
        puts "  [getValue] #{selector} → \"#{value}\""
      end

      def get_attribute(selector : String, attribute : String)
        return if selector.empty?
        puts "  .getAttribute('#{selector}', '#{attribute}')"

        js = <<-JS
          (function() {
            var el = document.querySelector(#{selector.to_json});
            if (!el) return null;
            return el.getAttribute(#{attribute.to_json});
          })()
        JS

        value = @cdp.eval(js).as_s? || ""
        puts "  [getAttribute] #{selector}[#{attribute}] → \"#{value}\""
      end

      def run_js(code : String)
        return if code.empty?
        puts "  .runJS(...)"
        result = @cdp.eval(code)
        puts "  [runJS] → #{result.to_json}" unless result.raw.nil?
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
          <<-JS
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
        end
      end
    end
  end
end
